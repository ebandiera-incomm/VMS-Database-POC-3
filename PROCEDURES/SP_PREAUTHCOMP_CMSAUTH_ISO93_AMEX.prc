
CREATE OR REPLACE PROCEDURE VMSCMS.SP_PREAUTHCOMP_CMSAUTH_ISO93_AMEX (P_INST_CODE        IN NUMBER,
                                                P_MSG              IN VARCHAR2,
                                                P_RRN              VARCHAR2,
                                                P_DELIVERY_CHANNEL VARCHAR2,
                                                P_TERM_ID          VARCHAR2,
                                                P_TXN_CODE         VARCHAR2,
                                                P_TXN_MODE         VARCHAR2,
                                                P_TRAN_DATE        VARCHAR2,
                                                P_TRAN_TIME        VARCHAR2,
                                                P_CARD_NO          VARCHAR2,
                                                P_TXN_AMT          NUMBER,
                                                P_MCC_CODE         VARCHAR2,
                                                P_CURR_CODE        VARCHAR2,
                                                P_MERCHANT_NAME    VARCHAR2,
                                                P_MERCHANT_CITY    VARCHAR2,
                                                P_ATMNAME_LOC      VARCHAR2,
                                                P_CONSODIUM_CODE   IN VARCHAR2,
                                                P_PARTNER_CODE     IN VARCHAR2,
                                                P_EXPRY_DATE       IN VARCHAR2,
                                                P_STAN             IN VARCHAR2,
                                                P_MBR_NUMB         IN VARCHAR2,
                                                P_RVSL_CODE        IN NUMBER,
                                                P_ORGNL_CARDNO     IN VARCHAR2, 
                                                P_ORGNL_RRN        IN VARCHAR2,
                                                P_ORGNL_TRANDATE   IN VARCHAR2, 
                                                P_ORGNL_TRANTIME   IN VARCHAR2,
                                                P_ORGNL_TERMID     IN VARCHAR2,
                                                P_COMP_COUNT       IN VARCHAR2,
                                                P_LAST_INDICATOR   IN VARCHAR2, 
                                                P_MERC_ID            IN VARCHAR2,
                                                P_COUNTRY_CODE       IN VARCHAR2,
                                                P_NETWORK_ID         IN VARCHAR2,
                                                P_INTERCHANGE_FEEAMT IN NUMBER,
                                                P_MERCHANT_ZIP       IN VARCHAR2,
                                                P_POS_VERFICATION   IN VARCHAR2,
                                                P_INTERNATIONAL_IND IN VARCHAR2,
                                                P_ORGNL_MCC_CODE    IN VARCHAR2, 
                                                p_org_stan          IN       VARCHAR2,      
                                                P_NETWORKID_SWITCH    IN VARCHAR2, 
                                                P_NETWORKID_ACQUIRER    IN VARCHAR2,
                                                p_network_setl_date    IN  VARCHAR2,
                                                P_CVV_VERIFICATIONTYPE IN  VARCHAR2,
                                                P_PULSE_TRANSACTIONID        IN       VARCHAR2,
                                                P_VISA_TRANSACTIONID          IN       VARCHAR2,
                                                P_MC_TRACEID                 IN       VARCHAR2,
                                                P_CARDVERIFICATION_RESULT      IN       VARCHAR2,
                                                p_req_resp_code    IN NUMBER, 
                                                P_AUTH_ID           OUT VARCHAR2,
                                                P_RESP_CODE         OUT VARCHAR2,
                                                P_RESP_MSG          OUT VARCHAR2,
                                                P_LEDGER_BAL        OUT VARCHAR2, 
                                                P_CAPTURE_DATE      OUT DATE,
                                                P_ISO_RESPCDE       OUT VARCHAR2 
                                                ,P_MERC_CNTRYCODE     IN       VARCHAR2 DEFAULT NULL
                                                ,P_MS_PYMNT_TYPE      in     varchar2 default null
                                                ,P_MS_PYMNT_DESC      IN      VARCHAR2  DEFAULT NULL
                                                 ,P_RESP_TIME OUT VARCHAR2
                                                ,P_RESPTIME_DETAIL OUT VARCHAR2
												,p_surchrg_ind   IN VARCHAR2 DEFAULT '2' --Added for VMS-5856
                                                ,p_resp_id       OUT VARCHAR2 --Added for sending to FSS (VMS-8018)
                                                 ) IS

  /*************************************************
     * modified by      : Deepa
     * modified Date    : 08-OCT-12
     * Modified Reason  : Modified for defect 9654
     * Reviewer         : Dhiraj
     * Reviewed Date    : 27-Dec-2012
     * Release Number   : CMS3.5.1_RI0023_B0003

     * Modified By      :  Sagar
     * Modified Date    :  22-Feb-2013
     * Modified For     :  FSS-781
     * Modified Reason  :  To match original transaction details
                           of completion transaction based on 4 rules
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  22-Feb-2013
     * Release Number   :  CMS3.5.1_RI0023.2_B0011

     * Modified By      :  Sagar
     * Modified Date    :  08-Mar-2013
     * Modified For     :  Defect 0010555
     * Modified Reason  :  To retrun acct balance in resp message
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  08-Mar-2013
     * Release Number   :  CMS3.5.1_RI0023.2_B0020

     * Modified by      :  Pankaj S.
     * Modified Reason  :  10871
     * Modified Date    :  19-Apr-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :
     * Build Number     :

     * Modified By      : Sagar M.
     * Modified Date    : 06-May-2013
     * Modified Reason  : OLS changes
     * Reviewer         : Dhiraj
     * Reviewed Date    : 06-May-2013
     * Build Number     : RI0024.1.1_B0001

     * Modified By      : DHINAKARAN B
     * Modified Date    : 19-JUN-2013
     * Modified For     : OLS changes(Mantis ID-11323)
     * Modified Reason  : In Statementlog table LedgerBalance,wrongly showing in Completion for pre-authtransaction.
     * Reviewer         : Dhiraj
     * Reviewed Date    : 19-JUN-2013
     * Build Number     : RI0024.2_B0006

     * Modified by      :  Arunprasath
     * Modified Reason  :  Exception added for Resource Busy
     * Modified Date    :  26-JUN-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  26-JUN-2013
     * Build Number     :  RI0024.2_B0009

     * Modified by      : Deepa T
     * Modified for     : Mantis ID 11344,11123
     * Modified Reason  : Log the AcquirerNetworkID received in tag 005 and TermFIID received in tag 020 ,
                            Logging of network settlement date for OLS transactions
     * Modified Date    : 26-Jun-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  26-JUN-2013
     * Build Number     :  RI0024.2_B0009

     * Modified by      : Ramesh A
     * Modified for     : Mantis ID 0011447
     * Modified Reason  : Medagate : PERMRULE_VERIFY_FLAG not updated for SAF advices (failure transactions)
     * Modified Date    : 28-Jun-2013
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     : RI0024.2_B0011

     * Modified by      : Sagar
     * Modified for     : FSS-1246
     * Modified Reason  : To check and reject duplicate completion transaction
     * Modified Date    : 09-Jul-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : RI0024.3_B0002

    * Modified by      : Sachin P.
    * Modified for     : Mantis ID -11611,11612
    * Modified Reason  : 11611-Input parameters needs to be included for the CVV verification
                         We are doing and it needs to be logged in transactionlog
                         11612-Output parameter needs to be included to return the cms_iso_respcde of cms_response_mast
    * Modified Date    : 18-Jul-2013
    * Reviewer         :
    * Reviewed Date    :
    * Build Number     : RI0024.3_B0005

    * Modified by      : Sagar M.
    * Modified for     : MVHOST-500
    * Modified Reason  : To check message type in case of Duplicate RRN check
                          and reject if same RRN repeats with 1200,1201,1220,1221
    * Modified Date    : 26-Jun-2013
    * Reviewer         : Dhiarj
    * Reviewed Date    :
    * Build Number     : RI0024.3.1_B0001


    * Modified by      : Sagar
    * Modified for     : FSS-1246 Review observations
    * Modified Reason  : Review observations
    * Modified Date    : 24-Jul-2013
    * Reviewer         : Dhiraj
    * Reviewed Date    : 19-aug-2013
    * Build Number     : RI0024.4_B0002


    * Modified by      : Sachin P
    * Modified for     : Mantis Id:11692
    * Modified Reason  : In Force post completion transaction, txn amount is logged as incorrect(i.e txn amount+fee amount)
                         in cms_preauth_transaction,CMS_PREAUTH_TRANS_HIST tables and during preauth transaction,
                         approve amount is logged with fee amount.In Preauth completion procedure
                        'Successful preauth completion already done' check does not have the inst code condition.
    * Modified Date    : 24-Jul-2013
    * Reviewer         : Dhiraj
    * Reviewed Date    : 19-aug-2013
    * Build Number     : RI0024.4_B0002

    * Modified by      : Sagar
    * Modified for     : MVHOST-354
    * Modified Reason  : To include Rule5 changes and comparing approve amount in the 5% range of v_tran_amt
    * Modified Date    : 26-Aug-2013
    * Reviewer         : Dhiraj
    * Reviewed Date    :
    * Build Number     : RI0024.4_B0005

    * Modified by      : Sagar M.
    * Modified for     : FSS-1246
    * Modified Reason  : Performacne changes
    * Modified Date    : 24-Aug-2013
    * Reviewer         : Sachin
    * Reviewed Date    : 24-Aug-2013
    * Build Number     : RI0024.4_B0005

    * Modified by      : Sagar M.
    * Modified for     : 0012198 (1.7.3.5 Chnages integrated into 1.7.4 version)
    * Modified Reason  : To reject duplicate STAN transaction
    * Modified Date    : 29-Aug-2013
    * Reviewer         : Dhiarj
    * Reviewed Date    : 29-Aug-2013
    * Build Number     : RI0024.3.5_B0001

    * Modified by      : Sagar
    * Modified for     : MVHOST-354
    * Modified Reason  : Review observation changes
    * Modified Date    : 03-Aug-2013
    * Reviewer         : Dhiraj
    * Reviewed Date    : 04-Aug-2013
    * Build Number     : RI0024.4_B0009

    * Modified by      : Sagar M.
    * Modified for     : FSS-1246 (RI0024.3.8.3_B0001 changes merged - FSS-1349)
    * Modified Reason  : Performacne fix to compare txn card number with customer_card_no column of transactionlog
    * Modified Date    : 23-Oct-2013
    * Reviewer         : Dhiraj
    * Reviewed Date    : 23-Oct-2013
    * Build Number     : RI0024.5.2_B0001

    * Modified by      : DHINAKARAN B
    * Modified for     : MANTIS ID-12953
    * Modified Reason  : Support the Cash Disbursement Preauth transaction for the with message type 1100 and MCC-6010
    * Modified Date    : 03-JAN-2014
    * Reviewer         : Dhiraj
    * Reviewed Date    : 07-jan-14
    * Build Number     : RI0027_B0002

     * Modified by      : DHINAKARAN B
     * Modified for     : MANTIS ID-13467
     * Modified Reason  : Implement the 1.7.6.5 changes on 2.0 to Logging the Delivery channel and txn code in CMS_PREAUTH_TRANS_HIST table
     * Modified Date    : 22-jan-14
     * Reviewer         :
     * Reviewed Date    : RI0027_B0004

     * Modified By      : MageshKumar S
     * Modified Date    : 28-Jan-2014
     * Modified for     : MVCSD-4471
     * Modified Reason  : Narration change for FEE amount
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     : RI0027.1_B0001

     * Modified By     : Abdul Hameed M.A
     * Modified Date    : 12-Feb-2014
     * Modified for     : MANTIS ID-13645
     * Modified Reason  : To log the last 4 digit of pan  number in cms_preauth_trans_hist table.
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     : RI0027.1_B0001

     * Modified by       : Sagar
     * Modified for      :
     * Modified Reason   : Concurrent Processsing Issue
                            (1.7.6.7 changes integarted)
     * Modified Date     : 04-Mar-2014
     * Reviewer          : Dhiarj
     * Reviewed Date     : 06-Mar-2014
     * Build Number      : RI0027.1.1_B0001


     * Modified by       : Abdul Hameed M.A
     * Modified for      : Mantis ID 13893
     * Modified Reason   : Added card number for duplicate RRN check
     * Modified Date     : 06-Mar-2014
     * Reviewer          : Dhiraj
     * Reviewed Date     : 06-Mar-2014
     * Build Number      : RI0027.2_B0002

     * Modified by           :  Abdul Hameed M.A
     * Modified Reason   :  To hold the Preauth completion fee at the time of preauth
     * Modified for      :  FSS 837
     * Modified Date     :  27-JUNE-2014
     * Reviewer          :  Spankaj
     * Build Number      :  RI0027.3_B0001

     * Modified by       : Dhinakaran B
     * Modified for      : VISA Certtification Changes integration in 2.3
     * Modified Date     : 08-JUL-2014
     * Reviewer          : Spankaj
     * Reviewed Date     : Ri0027.3_B0002

     * Modified by         :  Abdul Hameed M.A
     * Modified for      :  Mantis ID 15606
     * Modified Date     :  21-JULY-2014
     * Reviewer          :  Spankaj
     * Build Number      : RI0027.3_B0005

     * Modified by       : MageshKumar S.
     * Modified Date     : 25-July-14
     * Modified For      : FWR-48
     * Modified reason   : GL Mapping removal changes
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3.1_B0001

     * Modified by       : Dhinakaran B
     * Modified Date     : 07-Nov-14
     * Modified For      : FSS-1967
     * Modified reason   : Debit completion matching only with the Debit Auth Transaction
                           i.e(completion txn(12) match with the any auth txns except MR preauth)
     * Reviewer          : Spankaj
     * Build Number      : RI0027.4.2.1

     * Modified by       : Dhinakaran B
     * Modified Date     : 07-Nov-14
     * Modified For      : Multiple  auth completion chages
     * Reviewer          :
     * Build Number      :

     * Modified by       : Dhinakaran B
     * Modified Date     : 15-Nov-14
     * Modified For      : Log the Txn amount for response code 168 and 22 cases
     * Reviewer         :  Saravanakumar
     * Build Number     : RI0027.4.2.2_B0002

     * Modified by       : Dhinakaran B
     * Modified Date     :26-Nov-14
     * Modified For      : 15909 -total completion count greater than completion sequence number  Rule validation should not applicable
     * Reviewer         :
     * Build Number     :  RI0027.4.3_B0005

     * Modified by       : Dhinakaran B
     * Modified Date     :28-Nov-14
     * Modified For      : 15918

      * Modified Date    : 30-DEC-2014
      * Modified By      : Dhinakaran B
      * Modified for     : MVHOST-1080/To Log the Merchant id null
      * Reviewer         : PANKAJ S.
      * Build Number     : RI0027.5_B0005

      * Modified by      : MAGESHKUMAR S.
      * Modified Date    : 03-FEB-2015
      * Modified For     : FSS-2065(2.4.2.4.1 null4.3.1 integration)
      * Reviewer         : PANKAJ S.
      * Build Number     : RI0027.5_B0006

      * Modified By      : MageshKumar S
      * Modified Date    : 11-FEB-2015
      * Modified for     : INSTCODE REMOVAL(2.4.2.4.2 null4.3.1 integration)
      * Reviewer         : Spankaj
      * Release Number   : RI0027.5_B0007

      * Modified By      : Abdul Hameed M.A
      * Modified Date    : 11-FEB-2015
      * Modified for     : DFCTNM-4
      * Reviewer         : Spankaj
      * Release Number   : RI0027.5_B0007

     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 19-FEB-2015
     * Modified for     : Added limit validation for CR settlement
     * Reviewer         : Spankaj
     * Release Number   : RI0027.5_B0008

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
     * Modified For     :  DFCTNM-4
     * Modified Date    :  3-Mar-2015
     * Reviewer         :  Spankaj
     * Build Number     : RI0027.5

     * Modified By      :  Akhil byready
     * Modified For     :  FSS-3404-Balancing exception issue on daily balance reconciliation for concurrent transactions from OLS
     * Modified Date    :  05-May-2015
     * Reviewer         :  Spankaj
     * Build Number     :  RI0027.5.3.1

     * Modified By      :  Magesh Kumar S
     * Modified For     :  Modified for 3.0.3 release
     * Modified Date    :  08-JUNE-2015
     * Reviewer         :  Spankaj
     * Build Number     :  VMSGPRHOSTCSD_3.0.3_B00001

     * Modified By      :  Magesh Kumar S
     * Modified For     :  Modified for 3.0.3 release(gpr card status check removed for completion txns)
     * Modified Date    :  11-JUNE-2015
     * Reviewer         :  Spankaj
     * Build Number     :  VMSGPRHOSTCSD_3.0.3_B00003

    * Modified by      : Ramesh A
    * Modified for     : FSS-3610
    * Modified Date    : 31-Aug-2015
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOST_3.1_B0008

     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 09-SEP-2015
     * Modified for     : FSS 3643
     * Reviewer         : Spankaj
     * Release Number   : VMSGPRHOSTCSD_3.1_B00010

     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 11-SEP-2015
     * Modified for     : 16192
     * Reviewer         : Spankaj
     * Release Number   : VMSGPRHOSTCSD_3.1_B00010

     * Modified By      :  Ramesh A
     * Modified For     :  FSS-3679
     * Modified Date    :  07-OCT-2015
     * Modified Reason  :  To reverse fee amount
     * Reviewer         :  Saravana kumar
     * Build Number     :  RI0027.3.2_B0004

     * Modified by      : Narayanaswamy.T
     * Modified for     : FSS-4119 - ATM withdrawal transactions should contain terminal id and city in the statement
     * Modified Date    : 01-Mar-2016
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOST_4.0_B0001

     * Modified by      : Pankaj S.
     * Modified for     : Performance changes
     * Modified Date    : 27-June-2016
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOST_4.0.4

     * Modified by      :Saravanankumar
     * Modified for     : FSS-4614
     * Modified Date    : 03-Aug-2016
     * Reviewer         : Pankaj S.
     * Build Number     : VMSGPRHOST_4.0.7

     * Modified by      : Pankaj S.
     * Modified for     : FSS-5126: Free Fee Issue
     * Modified Date    : 26-June-2017
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_17.06   


         * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
    * Modified By      : MageshKumar S
    * Modified Date    : 18/07/2017
    * Purpose          : FSS-5157
    * Reviewer         : Saravanan/Pankaj S. 
    * Release Number   : VMSGPRHOST17.07

                       * Modified by       : Akhil
     * Modified Date     : 05-JAN-18
     * Modified For      : VMS-103
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.12
     * Modified by       : Sivakumar M
     * Modified Date     : 19-Sep-18
     * Modified For      : VMS-547
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_R05.1

     * Modified By      : DHINAKARAN B
     * Modified Date    : 15-NOV-2018
     * Purpose          : VMS-619 (RULE)
     * Reviewer         : Saravanakumar A 
     * Release Number   : R08 
     
     * Modified By      : DHINAKARAN B
     * Modified Date    : 25-FEB-2020
     * Purpose          : VMS-1089
     * Reviewer         : Saravanakumar A 
     * Release Number   : R27_build_1 
	 
	 * Modified By      : BASKAR KRISHNAN
     * Modified Date    : 29-APR-2020
     * Purpose          : VMS-2441
     * Reviewer         : Saravanakumar A 
     * Release Number   : R30_build_1 
	 
	 * Modified By      : BASKAR KRISHNAN
     * Modified Date    : 06-MAY-2020
     * Purpose          : VMS-1374 
     * Reviewer         : SARAVANAKUMAR A 
     * Release Number   : R30_build_2
     
     * Modified By      : MAGESHKUMAR
     * Modified Date    : 16-JUNE-2020
     * Purpose          : VMS-2709(Refactor MR processing logic to directly enforce limit check without any prior validations)
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : R32_build_1
	 
	 * Modified By      : PUVANESH.N
     * Modified Date    : 07-SEP-2021
     * Purpose          : VMS-4652 - AC 2: Settlement file for MoneySend credit transaction
     * Reviewer         : SARAVANAKUMAR A 
     * Release Number   : R51 - BUILD 2 
	 
	* Modified By      : Karthick/Jey
    * Modified Date    : 05-20-2022
    * Purpose          : Archival changes.
    * Reviewer         : venkat Singamaneni
    * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991

    * Modified By      : Magesh S.
    * Modified Date    : 05-19-2023
    * Purpose          : VMS-7383:Amex Split Shipments - Interim Fix
    * Reviewer         : venkat Singamaneni
    * Release Number   : VMSGPRHOST_R80
    
    * Modified By      : John Gingrich
    * Modified Date    : 08-28-2023
    * Purpose          : Concurrent Pre-Auth Reversals
    * Reviewer         : 
    * Release Number   : VMSGPRHOSTR85 for VMS-5551

    * Modified By      : Areshka A.
    * Modified Date    : 03-Nov-2023
    * Purpose          : VMS-8018: Added new out parameter (response id) for sending to FSS
    * Reviewer         : 
    * Release Number   : 
	
	* Modified By      : Mohan E.
    * Modified Date    : 09-09-2024
    * Purpose          : VMS_9133 Remove the Threshold Limits on the same Authorization for Multiple Settlements
    * Reviewer         : Pankaj/Venkat
    * Release Number   : R103
    
  *************************************************/

  V_ERR_MSG            VARCHAR2(900) := 'OK';
  V_ACCT_BALANCE       NUMBER;
  V_LEDGER_BAL         NUMBER;
  V_TRAN_AMT           NUMBER;
  V_AUTH_ID            VARCHAR2(14);
  V_TOTAL_AMT          NUMBER;
  V_Tran_Date          Date;
 -- V_FUNC_CODE          CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_PROD_CODE          CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE       CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_FEE_AMT            NUMBER;
  V_TOTAL_FEE          NUMBER;
  V_UPD_AMT            NUMBER;
  V_UPD_LEDGER_AMT     NUMBER;
  V_NARRATION          VARCHAR2(300);
  V_FEE_OPENING_BAL    NUMBER;
  V_Resp_Cde           Varchar2(3);
  --V_EXPRY_DATE         DATE;
  V_DR_CR_FLAG         VARCHAR2(2);
  V_OUTPUT_TYPE        VARCHAR2(2);
  V_Applpan_Cardstat   Cms_Appl_Pan.Cap_Card_Stat%Type;
  --V_PRECHECK_FLAG      NUMBER;
 -- V_Preauth_Flag       Number;
  --V_AVAIL_PAN          CMS_AVAIL_TRANS.CAT_PAN_CODE%TYPE;
  --V_GL_UPD_FLAG        TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
  --V_GL_ERR_MSG         VARCHAR2(500);
  --V_SAVEPOINT          NUMBER := 0;
  --V_TRAN_FEE           NUMBER;
  V_ERROR              VARCHAR2(500);
  --V_BUSINESS_DATE_TRAN DATE;
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
  V_WAIV_PERCNT      CMS_PRODCATTYPE_WAIV.CPW_WAIV_PRCNT%TYPE;
  V_ERR_WAIV         VARCHAR2(300);
  V_LOG_ACTUAL_FEE   NUMBER;
  V_LOG_WAIVER_AMT   NUMBER;
  V_AUTH_SAVEPOINT   NUMBER DEFAULT 0;
  --V_ACTUAL_EXPRYDATE DATE;
  V_BUSINESS_DATE    DATE;
  V_Txn_Type         Number(1);
  --V_MINI_TOTREC      NUMBER(2);
 -- V_MINISTMT_ERRMSG  VARCHAR2(500);
 -- V_MINISTMT_OUTPUT  VARCHAR2(900);
  --V_FEE_ATTACH_TYPE  VARCHAR2(1);
  --V_CHECK_MERCHANT   NUMBER(1);
  Exp_Reject_Record Exception;
 -- V_TERMINAL_DOWNLOAD_IND VARCHAR2(1);
  --V_TERMINAL_COUNT        NUMBER;
  --V_ATMONLINE_LIMIT       CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
 -- V_POSONLINE_LIMIT       CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
 -- V_TEMP_EXPIRY           CMS_APPL_PAN.CAP_EXPRY_DATE%TYPE;
  --V_BIN_CODE              NUMBER(6);
 -- V_TERMINAL_BIN_COUNT    NUMBER;
  --V_ATM_USAGEAMNT         CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_AMT%TYPE;
  --V_POS_USAGEAMNT         CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_AMT%TYPE;
  --V_ATM_USAGELIMIT        CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_LIMIT%TYPE;
  --V_POS_USAGELIMIT        CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_LIMIT%TYPE;
 -- V_PREAUTH_AMOUNT        NUMBER;
  --V_PREAUTH_TXNAMOUNT     NUMBER;
 -- V_PREAUTH_DATE          DATE;
  --V_PREAUTH_VALID_FLAG    CHARACTER(1);
  V_PREAUTH_EXPIRY_FLAG   CHARACTER(1);
  --V_PREAUTH_HOLD          VARCHAR2(1);
  --V_PREAUTH_PERIOD        NUMBER;
 -- V_PREAUTH_USAGE_LIMIT   NUMBER;
  V_CARD_ACCT_NO          VARCHAR2(20);
  V_HOLD_AMOUNT           NUMBER := 0;
 -- V_PREAUTH_EXP_DATE DATE;
  V_HASH_PAN         CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN         CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_ORGNL_HASH_PAN   CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  --V_RRN_COUNT        NUMBER;
  V_TRAN_TYPE        VARCHAR2(2);
 -- V_DATE             DATE;
 -- V_TIME             VARCHAR2(10);
  V_MAX_CARD_BAL     NUMBER;
  --V_CURR_DATE        DATE;
  --V_TOTAL_HOLD_AMT   NUMBER;
  V_PRE_AUTH_CHECK   CHAR(1) := 'N';
  --V_COUNT NUMBER := 0;
  V_PROXY_HOLD_AMOUNT VARCHAR2(12) := '';
  V_LAST_COMP_IND    VARCHAR2(1) := '';
  V_PROXUNUMBER      CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER      CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_AUTH_ID_GEN_FLAG VARCHAR2(1);
  V_TRANS_DESC VARCHAR2(50);
   V_HOLD_DAYS   CMS_TXNCODE_RULE.CTR_HOLD_DAYS%TYPE;
  P_HOLD_AMOUNT NUMBER;
  V_FEEAMNT_TYPE CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
  V_PER_FEES     CMS_FEE_MAST.CFM_PER_FEES%TYPE;
  V_FLAT_FEES    CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_CLAWBACK     CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
  V_FEE_PLAN     CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;
  V_FREETXN_EXCEED VARCHAR2(1);
  V_DURATION VARCHAR2(20);
  V_FEEATTACH_TYPE  VARCHAR2(2);
  v_oldest_preauth          DATE;
  v_rule                    varchar2(5); 
  v_rowid                   varchar2(40);
  v_sqlrowcnt               number;      
  v_cpt_rrn                 cms_preauth_transaction.cpt_rrn%type;     
  v_comp_txn_code             varchar2(2);                             
   v_totalamt                  transactionlog.total_amount%TYPE;
   v_acct_type                 cms_acct_mast.cam_type_code%TYPE;
   v_timestamp                 timestamp(3);
    v_org_rrn                 transactionlog.rrn%TYPE;
  -- v_cms_iso_respcde         cms_response_mast.cms_iso_respcde%TYPE;
   V_Mcc_Verify_Flag       Varchar2(1);
 -- v_dup_comp_check        number(5); 
   v_incr_tran_amt         NUMBER; 
   v_decr_tran_amt         NUMBER; 
   V_STAN_COUNT                  NUMBER; 
   V_FEE_DESC         cms_fee_mast.cfm_fee_desc%TYPE; 
  v_completion_fee cms_preauth_transaction.cpt_completion_fee%TYPE;
v_fee_reverse_amount  NUMBER;
v_comp_total_fee NUMBER;
v_complfee_increment_type VARCHAR2(1);
   V_PREAUTH_TYPE           CMS_TRANSACTION_MAST.CTM_PREAUTH_TYPE%TYPE;
   v_chnge_crdstat   VARCHAR2(2):='N';
   V_De_Cr_Flag_Mcauth  Varchar2(2);
  -- v_orgnl_rrn  TRANSACTIONLOG.ORGNL_RRN%TYPE;
  -- v_total_hold_fee  number;
   V_preauth_compfee       NUMBER;
   v_tran_reversal_flag   TRANSACTIONLOG.TRAN_REVERSE_FLAG%TYPE;
   --v_CPH_TXN_DATE        CMS_PREAUTH_TRANS_HIST.CPH_TXN_DATE%TYPE;
   --v_CPH_TXN_TIME        CMS_PREAUTH_TRANS_HIST.CPH_TXN_TIME%TYPE;
   --v_CPH_RRN             CMS_PREAUTH_TRANS_HIST.CPH_RRN%TYPE;
   --v_CPH_ORGNL_CARD_NO    CMS_PREAUTH_TRANS_HIST.CPH_ORGNL_CARD_NO%TYPE;
   --v_CPH_DELIVERY_CHANNEL CMS_PREAUTH_TRANS_HIST.CPH_DELIVERY_CHANNEL%TYPE;
   --v_CPH_TRAN_CODE        CMS_PREAUTH_TRANS_HIST.CPH_TRAN_CODE%TYPE;
   V_FORCEPOST_FLAG       varchar2(1) := 'N';
   V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE;
   v_prfl_flag             cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_prfl_code             cms_appl_pan.cap_prfl_code%TYPE;
   V_COMB_HASH             PKG_LIMITS_CHECK.TYPE_HASH;
   V_MRLIMITBREACH_COUNT  number default 0;
   --V_MRMINMAXLMT_IGNOREFLAG  varchar2 (1) default 'N';
    V_MS_PYMNT_TYPE CMS_PAYMENT_TYPE.cpt_payment_type%type;
    v_start_time timestamp;
    v_mili VARCHAR2(100);
    v_total_completion_amt  number:=0;
    v_duplicate_comp_check varchar2(1):='N';
    v_completion_count NUMBER:=0;
    v_ignore_dup_cnt NUMBER:=0;
    v_preauth_txnamt number;
    v_dup_stan_allow varchar2(1);
    V_Dup_Sixnine_Stan Varchar2(1);
    V_Concurrent_Flag  Number; 
    v_ignore_rrn_cnt NUMBER; 
    v_complfree_flag   cms_preauth_transaction.cpt_complfree_flag%TYPE;
    v_badcredit_flag             cms_prod_cattype.cpc_badcredit_flag%TYPE;
   v_badcredit_transgrpid       vms_group_tran_detl.vgd_group_id%TYPE;
   v_cnt                        NUMBER(2); 
   v_card_stat                  cms_appl_pan.cap_card_stat%TYPE   := '12';
   l_profile_code   cms_prod_cattype.cpc_profile_code%type;
      v_enable_flag                VARCHAR2 (20)                          := 'Y';
   v_initialload_amt         cms_acct_mast.cam_new_initialload_amt%type;
   v_org_txn_code             cms_preauth_transaction.cpt_txn_code%TYPE;
   v_org_mcc_code             cms_preauth_transaction.cpt_mcc_code%TYPE;
   v_org_internation_ind_resp  cms_preauth_transaction.cpt_internation_ind_response%TYPE;
   v_org_pos_verification     cms_preauth_transaction.cpt_pos_verification%TYPE;
   v_org_date                 cms_preauth_transaction.cpt_ins_date%TYPE;
   v_org_payment_type         cms_preauth_transaction.cpt_payment_type%TYPE;
   v_org_prfl_flag            cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_org_tran_type            cms_transaction_mast.ctm_tran_type%TYPE;
  --v_alpha_cntry_code gen_cntry_mast.gcm_alpha_cntry_code%TYPE;
   V_PARAM_VALUE           	  CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
   
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
   v_Retdate  date; --Added for VMS-5739/FSP-991
   v_de38_authid     transactionlog.auth_id%TYPE; --Added for VMS-7383
BEGIN
  SAVEPOINT V_AUTH_SAVEPOINT;
  V_RESP_CDE := '1';
  P_RESP_MSG         := 'OK';
  V_AUTH_ID_GEN_FLAG := 'N';
  V_TRAN_AMT := P_TXN_AMT;
  V_TOTALAMT := P_TXN_AMT;
  V_TIMESTAMP:=systimestamp;
   V_MS_PYMNT_TYPE:=P_MS_PYMNT_TYPE;
     v_start_time := systimestamp;  
  v_de38_authid:=p_consodium_code; --Added for VMS-7383
  
  BEGIN
    BEGIN
     V_HASH_PAN := GETHASH(P_CARD_NO);
    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '21'; 
       V_ERR_MSG  := 'Error while converting pan ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
     V_ORGNL_HASH_PAN := GETHASH(P_ORGNL_CARDNO);
    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while converting pan ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
     V_ENCR_PAN := FN_EMAPS_MAIN(P_CARD_NO);
    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '21'; 
       V_ERR_MSG  := 'Error while converting pan ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_CARD_NO||P_RRN||to_char(V_TIMESTAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        V_RESP_CDE := '21';
        V_ERR_MSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     end;

    BEGIN
     SELECT CAP_PROD_CODE,
           Cap_Card_Type,
           --CAP_EXPRY_DATE,
           Cap_Card_Stat,
           --CAP_ATM_ONLINE_LIMIT,
           --CAP_POS_ONLINE_LIMIT,
           CAP_PROXY_NUMBER,
           CAP_ACCT_NO,
           cap_prfl_code

       INTO V_PROD_CODE,
           V_Prod_Cattype,
           --V_EXPRY_DATE,
           V_Applpan_Cardstat,
          -- V_ATMONLINE_LIMIT,
           --V_ATMONLINE_LIMIT,
           V_PROXUNUMBER,
           V_ACCT_NUMBER,
           v_prfl_code
       FROM CMS_APPL_PAN
      WHERE CAP_PAN_CODE = V_HASH_PAN;
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
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,
           CTM_TRAN_DESC
           ,CTM_PREAUTH_TYPE
           ,ctm_prfl_flag
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,
            V_TRANS_DESC
            ,V_PREAUTH_TYPE
            ,v_prfl_flag
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
      v_trans_desc := 'Transaction type ' || p_txn_code; 
       V_RESP_CDE := '12'; 
       V_ERR_MSG  := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
                  ' and delivery channel ' || P_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN TOO_MANY_ROWS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'More than one transaction defined for txn code ';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting the details fromtransaction ';
       RAISE EXP_REJECT_RECORD;
    END;

   if V_MS_PYMNT_TYPE is not null then
    if(  V_PREAUTH_TYPE='D') then
                if (P_MSG in ('1220','1221')) then
                 V_TRANS_DESC:='MoneySend Funding Settlement';
                 elsif P_MSG in ('1200','1201') then
                 V_TRANS_DESC:='MoneySend Funding';
                 end if;
    ELSIF (  V_PREAUTH_TYPE='C') then
      if (P_MSG in ('1200','1201')) then
                 V_TRANS_DESC:='MoneySend Payment';
       end if;
     end if;

   if V_MS_PYMNT_TYPE='P' then
   V_MS_PYMNT_TYPE:=null;
   end if;

   end if;

    /*BEGIN
     V_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');
    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '45';
       V_ERR_MSG  := 'Problem while converting transaction date ' ||
                  SUBSTR(SQLERRM, 1, 200);
       Raise Exp_Reject_Record;
    END;*/

    BEGIN
     V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
                        SUBSTR(TRIM(P_TRAN_TIME), 1, 10),
                        'yyyymmdd hh24:mi:ss');
    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '32';
       V_ERR_MSG  := 'Problem while converting transaction time ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

         IF p_req_resp_code >= 100
      THEN
       -- IF(P_TXN_CODE='23' OR P_TXN_CODE='27' OR (P_DELIVERY_CHANNEL='01' AND P_TXN_CODE='12')) THEN
         V_TRAN_AMT := P_TXN_AMT;
         ---v_resp_cde := '1';
         v_resp_cde := '314';
         v_err_msg := 'Authorization / Financial transaction denied';
         RAISE exp_reject_record;
     -- END IF;
      END IF;

    BEGIN

     SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;

     V_AUTH_ID_GEN_FLAG := 'Y';
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Error while generating authid ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21'; 
       RAISE EXP_REJECT_RECORD;
    END;



    BEGIN
	
	    --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');
	 
    IF (v_Retdate>v_Retperiod) THEN                                             --Added for VMS-5739/FSP-991
	
      SELECT COUNT(1)
      INTO V_STAN_COUNT
      FROM TRANSACTIONLOG
      WHERE  CUSTOMER_CARD_NO  = V_HASH_PAN
      AND   BUSINESS_DATE = P_TRAN_DATE
      AND   DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
      AND   ADD_INS_DATE BETWEEN TRUNC(SYSDATE-1)  AND SYSDATE
      AND   SYSTEM_TRACE_AUDIT_NO = P_STAN;
	  
	ELSE
	
	  SELECT COUNT(1)
      INTO V_STAN_COUNT
      FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                            --Added for VMS-5739/FSP-991
      WHERE  CUSTOMER_CARD_NO  = V_HASH_PAN
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

    Exception 
      When Exp_Reject_Record  Then   
        RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
      V_RESP_CDE := '21';
      V_ERR_MSG  := 'Error while checking duplicate STAN ' ||SUBSTR(SQLERRM,1,200);
      RAISE EXP_REJECT_RECORD;
     End;

    --SN:Added for 4.0.4 performance changes
      BEGIN
        sp_autonomous_preauth_log(V_AUTH_ID,p_stan, p_tran_date,
        V_HASH_PAN,  P_INST_CODE, p_delivery_channel , v_err_msg);
       --Added VMS-5551
       IF v_err_msg != 'OK' THEN
       V_RESP_CDE     := '191';
       RAISE exp_reject_record;
       END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        v_resp_cde := '12';
        v_err_msg  := 'Concurrent check Failed' || SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;
    --EN:Added for 4.0.4 performance changes

     BEGIN
           for i in (SELECT cip_param_value,cip_param_key
                      FROM cms_inst_param
                     WHERE cip_param_key in('CUTOFF','CESS','SERVICETAX','DUPSTAN_COMPL_ALLOW','DUPSTAN_SIXNINE_ALOW') AND cip_inst_code = p_inst_code
                   )
            loop

                 if i.cip_param_key = 'SERVICETAX'
                 then

                     v_servicetax_percent := i.cip_param_value;

                 elsif i.cip_param_key = 'CESS'
                 then
                     v_cess_percent := i.cip_param_value;

                 elsif  i.cip_param_key = 'CUTOFF'
                 then

                     v_cutoff_time := i.cip_param_value;

                 elsif  i.cip_param_key = 'DUPSTAN_COMPL_ALLOW'
                 then

                     v_dup_stan_allow := i.cip_param_value;

                  elsif  i.cip_param_key = 'DUPSTAN_SIXNINE_ALOW'
                 then

                     v_dup_sixnine_stan := i.cip_param_value;

                 end if;

            end loop;

      EXCEPTION WHEN OTHERS
      THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while selecting institution parameters ';
            RAISE exp_reject_record;
      END;

        if v_servicetax_percent is null
        then

            v_resp_cde := '21';
            v_err_msg := 'Service Tax is  not defined in the system';
            RAISE exp_reject_record;

        elsif v_cess_percent is null
        then

            v_resp_cde := '21';
            v_err_msg := 'Cess is not defined in the system';
            RAISE exp_reject_record;

        elsif v_cutoff_time is null
        then

            v_cutoff_time := 0;
            v_resp_cde := '21';
            v_err_msg := 'Cutoff time is not defined in the system';
            RAISE exp_reject_record;

        End If;


           if (v_dup_stan_allow='Y' or v_dup_sixnine_stan='Y')  then

        BEGIN

        SELECT count(1) into v_ignore_dup_cnt
        from
        VMS_AUTHCOMPL_STAN
        where VAS_INST_CODE=p_inst_code
        AND  VAS_STAN_NO=p_org_stan;

        EXCEPTION

        WHEN OTHERS
        THEN
               v_resp_cde := '21';                     
              v_err_msg := 'Error while salaecting data from auth compl stan  '||substr(sqlerrm,1,100);
              RAISE exp_reject_record;

        END;

      end if;

      IF  v_ignore_dup_cnt=0 THEN

      BEGIN
	  
	    --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_trandate), 1, 8), 'yyyymmdd');
	   
     IF (v_Retdate>v_Retperiod)  THEN                         --Added for VMS-5739/FSP-991
	 
         SELECT rrn
           INTO v_org_rrn                        
           FROM transactionlog
          WHERE system_trace_audit_no = p_org_stan
             AND  business_date||business_time = p_orgnl_trandate||p_orgnl_trantime
            AND customer_card_no = v_hash_pan
            AND delivery_channel = p_delivery_channel
            AND   rownum = 1;
			
	 ELSE
	 
	     SELECT rrn
         INTO v_org_rrn                        
         FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST      --Added for VMS-5739/FSP-991
         WHERE system_trace_audit_no = p_org_stan
         AND  business_date||business_time = p_orgnl_trandate||p_orgnl_trantime
         AND customer_card_no = v_hash_pan
         AND delivery_channel = p_delivery_channel
         AND   rownum = 1;
	 
	 END IF;
	 
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_err_msg := '';
     /*   WHEN TOO_MANY_ROWS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'More than one matching record found in the master';
            RAISE exp_reject_record;*/
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
               'Error while selecting master data'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

    END IF;

     IF TO_NUMBER(P_COMP_COUNT) = 0 OR P_LAST_INDICATOR = 'L' THEN
     V_LAST_COMP_IND := 'L';
    ELSE
     V_Last_Comp_Ind := 'N';
    END IF;

    BEGIN
      SELECT count(1) into v_ignore_rrn_cnt
      from
      VMS_AUTHCOMPL_STAN
      Where Vas_Inst_Code=P_Inst_Code
      AND  vas_rrn_starts_with=upper(substr(P_RRN,1,1));
    EXCEPTION
      WHEN OTHERS THEN
        V_Resp_Cde := '21';                     
        v_err_msg := 'Error while salaecting data from auth compl stan for rrn '||substr(sqlerrm,1,100);
        RAISE exp_reject_record;
    End;

    If V_Ignore_Rrn_Cnt <> 0 And V_Ignore_Dup_Cnt <> 0 Then 
      Null;
    else
       Begin

           v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_trandate), 1, 8), 'yyyymmdd');
		   
		IF (v_Retdate>v_Retperiod) THEN 
		
           select NVL(z.tran_reverse_flag,'N')
           into v_tran_reversal_flag
           from
           (select tran_reverse_flag
           From Transactionlog
           Where --orgnl_card_no = v_orgnl_hash_pan --Comaanded for FSS-4614
          -- And   
           ORIGINAL_STAN = p_org_stan
           and   orgnl_business_Date = p_orgnl_trandate
           and   orgnl_business_time = p_orgnl_trantime
           and   response_code = '00'
           AND   delivery_channel = p_delivery_channel
           and   customer_card_no = v_hash_pan             
           and   MSGTYPE in ('1200','1201','1220','1221')
           and   COMPLETION_COUNT = TO_NUMBER(P_COMP_COUNT)
           AND  CR_DR_FLAG=V_DR_CR_FLAG
           ORDER BY ADD_INS_DATE DESC ) Z
           WHERE ROWNUM=1;
		   
		ELSE
		
      	   select NVL(z.tran_reverse_flag,'N')
           into v_tran_reversal_flag
           from
           (select tran_reverse_flag
           From VMSCMS_HISTORY.TRANSACTIONLOG_HIST      --Added for VMS-5739/FSP-991
           Where --orgnl_card_no = v_orgnl_hash_pan --Comaanded for FSS-4614
          -- And   
           ORIGINAL_STAN = p_org_stan
           and   orgnl_business_Date = p_orgnl_trandate
           and   orgnl_business_time = p_orgnl_trantime
           and   response_code = '00'
           AND   delivery_channel = p_delivery_channel
           and   customer_card_no = v_hash_pan             
           and   MSGTYPE in ('1200','1201','1220','1221')
           and   COMPLETION_COUNT = TO_NUMBER(P_COMP_COUNT)
           AND  CR_DR_FLAG=V_DR_CR_FLAG
           ORDER BY ADD_INS_DATE DESC ) Z
           WHERE ROWNUM=1;
				
		END IF;


            IF v_tran_reversal_flag <> 'Y' AND v_ignore_dup_cnt =0 THEN

                if v_dup_stan_allow='Y' and TO_NUMBER(P_COMP_COUNT)=0  then

                 v_duplicate_comp_check:='Y';
               else

                V_RESP_CDE := '155';
                V_ERR_MSG  := 'Successful preauth completion already done';
                RAISE EXP_REJECT_RECORD;

               end if;
               ELSE

               v_forcepost_flag :='Y';

               END IF;

      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
         NULL;
      when  EXP_REJECT_RECORD
      then
          raise;
      when others
      then
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while fetching duplicate completion count ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;

      End;


      if v_duplicate_comp_check='Y' then

      BEGIN
        
		--Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_orgnl_trandate), 1, 8), 'yyyymmdd');
	  
	  IF (v_Retdate>v_Retperiod) THEN                                      --Added for VMS-5739/FSP-991
	  
       select  SUM (DECODE (reversal_code, 0, amount, -amount)),SUM ( CASE WHEN reversal_code = 0 AND amount = v_tran_amt THEN 1
                                    WHEN reversal_code <> 0 AND amount = v_tran_amt THEN -1
                                    ELSE 0
                       END) into v_total_completion_amt,v_completion_count
           From Transactionlog
           Where --orgnl_card_no = v_orgnl_hash_pan --Comaanded for FSS-4614
         -- And   
          ORIGINAL_STAN = p_org_stan
           and   orgnl_business_Date = p_orgnl_trandate
           and   orgnl_business_time = p_orgnl_trantime
           and   response_code = '00'
           AND   delivery_channel = p_delivery_channel
           and   customer_card_no = v_hash_pan
           and   COMPLETION_COUNT = TO_NUMBER(P_COMP_COUNT)
           AND  CR_DR_FLAG=DECODE(reversal_code,0,V_DR_CR_FLAG,DECODE(V_DR_CR_FLAG,'CR','DR','DR','CR','NA'))
         AND NVL(tran_reverse_flag,'N')<>'Y';
		 
	  ELSE
	  
	       select  SUM (DECODE (reversal_code, 0, amount, -amount)),SUM ( CASE WHEN reversal_code = 0 AND amount = v_tran_amt THEN 1
                                    WHEN reversal_code <> 0 AND amount = v_tran_amt THEN -1
                                    ELSE 0
                       END) into v_total_completion_amt,v_completion_count
           From VMSCMS_HISTORY.TRANSACTIONLOG_HIST                            --Added for VMS-5739/FSP-991
           Where --orgnl_card_no = v_orgnl_hash_pan --Comaanded for FSS-4614
         -- And   
          ORIGINAL_STAN = p_org_stan
           and   orgnl_business_Date = p_orgnl_trandate
           and   orgnl_business_time = p_orgnl_trantime
           and   response_code = '00'
           AND   delivery_channel = p_delivery_channel
           and   customer_card_no = v_hash_pan
           and   COMPLETION_COUNT = TO_NUMBER(P_COMP_COUNT)
           AND  CR_DR_FLAG=DECODE(reversal_code,0,V_DR_CR_FLAG,DECODE(V_DR_CR_FLAG,'CR','DR','DR','CR','NA'))
         AND NVL(tran_reverse_flag,'N')<>'Y';
	  
	  
	  
	  END IF;

      EXCEPTION
       when others
      then
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while fetching toal completion amount ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;

      End;
      End If;
 end if;

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
                    V_Prod_Cattype);

       IF V_ERR_MSG <> 'OK' THEN
        V_RESP_CDE := '44';
        RAISE EXP_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
        V_RESP_CDE := '69'; 
        V_ERR_MSG  := 'Error from currency conversion ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
    ELSE
      V_RESP_CDE := '43';
     V_ERR_MSG  := 'INVALID AMOUNT';
     RAISE EXP_REJECT_RECORD;
    END IF;


    /*BEGIN
     SELECT PTP_PARAM_VALUE
       INTO V_PRECHECK_FLAG
       FROM PCMS_TRANAUTH_PARAM
      WHERE PTP_PARAM_NAME = 'PRE CHECK' AND PTP_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21'; 
       V_ERR_MSG  := 'Master set up is not done for Authorization Process for pre check'; 
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21'; 
       V_ERR_MSG  := 'Error while selecting precheck flag' ||
                  SUBSTR(SQLERRM, 1, 200);
       Raise Exp_Reject_Record;
    END; 

     BEGIN
     SELECT PTP_PARAM_VALUE
       INTO V_PREAUTH_FLAG
       FROM PCMS_TRANAUTH_PARAM
      WHERE PTP_PARAM_NAME = 'PRE AUTH' AND PTP_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Master set up is not done for Authorization Process for pre auth'; 
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21'; 
       V_ERR_MSG  := 'Error while selecting precheck flag' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    IF V_PREAUTH_FLAG = 1 THEN
    
    
          BEGIN 
          select gcm_alpha_cntry_code  
          INTO  v_alpha_cntry_code  
          from gen_cntry_mast
          WHERE gcm_curr_code= P_COUNTRY_CODE  AND GCM_INST_CODE=1;
          EXCEPTION 
          WHEN OTHERS THEN 
            v_alpha_cntry_code:=null;
          END;
          
     BEGIN

       SP_ELAN_PREAUTHORIZE_TXN(P_CARD_NO,
                           P_MCC_CODE,
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
           IF P_MSG IS NOT NULL AND P_MSG IN(1220,1221) THEN
            IF UPPER(V_ERR_MSG) = 'INVALID MERCHANT CODE' THEN
              V_RESP_CDE :=1;
              V_ERR_MSG  :='OK';
              V_MCC_VERIFY_FLAG :='N';
            ELSE
             RAISE EXP_REJECT_RECORD;
            END IF;
          ELSE
             RAISE EXP_REJECT_RECORD;
          END IF;
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


--Moved before concurrent check for FSS-4614
       /*      Begin
       SELECT COUNT(1)
         INTO V_STAN_COUNT
         FROM TRANSACTIONLOG
        WHERE 
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

      END;*/

    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO,
            cam_type_code ,nvl(cam_new_initialload_amt,cam_initialload_amt)
       INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO,
            v_acct_type,v_initialload_amt 
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO = v_acct_number                
            AND CAM_INST_CODE = P_INST_CODE
           FOR UPDATE; 
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '14';
       V_ERR_MSG  := 'Invalid Card ';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                  SQLERRM;
       RAISE EXP_REJECT_RECORD;
    END;

    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;

    P_RESPTIME_DETAIL := '1: ' || v_mili ;

    IF  NVL(P_LAST_INDICATOR,'L') <> 'N' AND v_forcepost_flag <> 'Y' THEN
      BEGIN

             SELECT min(cpt_ins_date)
             INTO   v_oldest_preauth
             FROM VMSCMS.CMS_PREAUTH_TRANSACTION                   --Added for VMS-5739/FSP-991
             WHERE cpt_mbr_no    = p_mbr_numb
             AND   cpt_inst_code = p_inst_code
             AND   cpt_rrn       = v_org_rrn 
             AND   cpt_card_no   = v_orgnl_hash_pan
             AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
             AND cpt_preauth_type = v_preauth_type
             AND   cpt_expiry_flag = 'N';
			 IF SQL%ROWCOUNT = 0 THEN
			 
             SELECT min(cpt_ins_date)
             INTO   v_oldest_preauth
             FROM VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                   --Added for VMS-5739/FSP-991
             WHERE cpt_mbr_no    = p_mbr_numb
             AND   cpt_inst_code = p_inst_code
             AND   cpt_rrn       = v_org_rrn 
             AND   cpt_card_no   = v_orgnl_hash_pan
             AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
             AND cpt_preauth_type = v_preauth_type
             AND   cpt_expiry_flag = 'N';
			 END IF;


             IF v_oldest_preauth is null
             THEN

                 SELECT min(cpt_ins_date)
                 INTO   v_oldest_preauth
                 FROM VMSCMS.CMS_PREAUTH_TRANSACTION                    --Added for VMS-5739/FSP-991
                 WHERE cpt_mbr_no    = p_mbr_numb
                 AND   cpt_inst_code = p_inst_code
                 AND   CPT_APPROVE_AMT   = V_TRAN_AMT
                 AND   cpt_card_no   = v_orgnl_hash_pan
               AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                 AND cpt_preauth_type = v_preauth_type
                 AND   cpt_expiry_flag = 'N';
				  IF SQL%ROWCOUNT = 0 THEN
				  SELECT min(cpt_ins_date)
                 INTO   v_oldest_preauth
                 FROM VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                  --Added for VMS-5739/FSP-991
                 WHERE cpt_mbr_no    = p_mbr_numb
                 AND   cpt_inst_code = p_inst_code
                 AND   CPT_APPROVE_AMT   = V_TRAN_AMT
                 AND   cpt_card_no   = v_orgnl_hash_pan
               AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                 AND cpt_preauth_type = v_preauth_type
                 AND   cpt_expiry_flag = 'N';
				  END IF;



                 IF v_oldest_preauth is null
                 THEN

                     SELECT min(cpt_ins_date)
                     INTO   v_oldest_preauth
                     FROM   VMSCMS.CMS_PREAUTH_TRANSACTION                   --Added for VMS-5739/FSP-991
                     WHERE  cpt_mbr_no      =  p_mbr_numb
                     AND    cpt_inst_code   =  p_inst_code
                     AND    cpt_card_no     =  v_orgnl_hash_pan
                     AND    cpt_terminalid  =  p_orgnl_termid
                     AND    cpt_mcc_code    =  p_orgnl_mcc_code
                  AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                     AND cpt_preauth_type = v_preauth_type
                     AND   cpt_expiry_flag = 'N';
					 IF SQL%ROWCOUNT = 0 THEN
					   SELECT min(cpt_ins_date)
                     INTO   v_oldest_preauth
                     FROM   VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                    --Added for VMS-5739/FSP-991
                     WHERE  cpt_mbr_no      =  p_mbr_numb
                     AND    cpt_inst_code   =  p_inst_code
                     AND    cpt_card_no     =  v_orgnl_hash_pan
                     AND    cpt_terminalid  =  p_orgnl_termid
                     AND    cpt_mcc_code    =  p_orgnl_mcc_code
                  AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                     AND cpt_preauth_type = v_preauth_type
                     AND   cpt_expiry_flag = 'N';
					 END IF;

                     IF   v_oldest_preauth is null
                     THEN
                        SELECT cpt_preauth_txncode
                          INTO v_comp_txn_code
                          FROM cms_preauthcomp_txncode
                         WHERE cpt_inst_code = p_inst_code AND cpt_compl_txncode = p_txn_code;

                         BEGIN
                           IF(V_PREAUTH_TYPE!='C') THEN 
                            sp_elan_preauthcomp_txn  (p_card_no,
                                                      p_mcc_code,
                                                      p_curr_code,
                                                      v_tran_date,
                                                      v_comp_txn_code,
                                                      p_inst_code,
                                                      p_tran_date,
                                                      v_tran_amt,
                                                      p_delivery_channel,
                                                      p_merc_id,
                                                      p_country_code,
                                                      p_hold_amount,
                                                      v_hold_days,
                                                      v_resp_cde,
                                                      v_err_msg
                                                     );

                            IF (v_resp_cde <> '1' OR TRIM (v_err_msg) <> 'OK')
                            THEN

                               v_err_msg := 'From Completion '||v_err_msg;
                               RAISE exp_reject_record;
                            END IF;
                          END IF;  
                         EXCEPTION
                            WHEN exp_reject_record
                            THEN
                               RAISE;
                            WHEN OTHERS
                            THEN
                               v_resp_cde := '21';
                               v_err_msg :=
                                   'Error from pre_auth_comp process ' || SUBSTR (SQLERRM, 1, 200);
                               RAISE exp_reject_record;
                         END;

                         SELECT min(cpt_ins_date)
                         INTO   v_oldest_preauth
                         FROM   VMSCMS.CMS_PREAUTH_TRANSACTION                   --Added for VMS-5739/FSP-991
                         WHERE  cpt_mbr_no    = p_mbr_numb
                         AND    cpt_inst_code = p_inst_code
                         AND    cpt_card_no   = v_orgnl_hash_pan
                         AND    cpt_mcc_code  = p_orgnl_mcc_code
                         AND    CPT_APPROVE_AMT     = P_HOLD_AMOUNT
                     AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                         AND cpt_preauth_type = v_preauth_type
                         AND   cpt_expiry_flag = 'N';
						 IF SQL%ROWCOUNT = 0 THEN
						 SELECT min(cpt_ins_date)
                         INTO   v_oldest_preauth
                         FROM   VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                   --Added for VMS-5739/FSP-991
                         WHERE  cpt_mbr_no    = p_mbr_numb
                         AND    cpt_inst_code = p_inst_code
                         AND    cpt_card_no   = v_orgnl_hash_pan
                         AND    cpt_mcc_code  = p_orgnl_mcc_code
                         AND    CPT_APPROVE_AMT     = P_HOLD_AMOUNT
                     AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                         AND cpt_preauth_type = v_preauth_type
                         AND   cpt_expiry_flag = 'N';
						 END IF;

                         if v_oldest_preauth is null
                         then

                              v_incr_tran_amt := v_tran_amt + (v_tran_amt*5/100);

                              v_decr_tran_amt := v_tran_amt - (v_tran_amt*5/100);

                                 SELECT min(cpt_ins_date)
                                 INTO   v_oldest_preauth
                                 FROM   VMSCMS.CMS_PREAUTH_TRANSACTION                   --Added for VMS-5739/FSP-991
                                 WHERE cpt_mbr_no      = p_mbr_numb
                                 AND   cpt_inst_code   = p_inst_code
                                 AND   cpt_card_no     = v_orgnl_hash_pan
                                 AND   cpt_mcc_code    = p_orgnl_mcc_code
                                 AND   to_number(cpt_approve_amt) between round(v_decr_tran_amt,2) and round(v_incr_tran_amt,2)
                              AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                                 AND cpt_preauth_type = v_preauth_type
                                 AND   cpt_expiry_flag = 'N';
								  IF SQL%ROWCOUNT = 0 THEN
								                                   SELECT min(cpt_ins_date)
                                 INTO   v_oldest_preauth
                                 FROM   VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                   --Added for VMS-5739/FSP-991
                                 WHERE cpt_mbr_no      = p_mbr_numb
                                 AND   cpt_inst_code   = p_inst_code
                                 AND   cpt_card_no     = v_orgnl_hash_pan
                                 AND   cpt_mcc_code    = p_orgnl_mcc_code
                                 AND   to_number(cpt_approve_amt) between round(v_decr_tran_amt,2) and round(v_incr_tran_amt,2)
                              AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                                 AND cpt_preauth_type = v_preauth_type
                                 AND   cpt_expiry_flag = 'N';
								  END IF;

                            if v_oldest_preauth is null
                            then

                               v_pre_auth_check := 'N';
                               v_rule := 'U';


                            else


                                BEGIN

                                 Select Rowid,
                                        --cpt_txn_amnt,
                                        --cpt_preauth_validflag,
                                        cpt_totalhold_amt,
                                        cpt_expiry_flag,
                                        cpt_rrn,
                                        nvl(cpt_completion_fee,'0') 
                                        ,CPT_APPROVE_AMT,
                                        nvl(cpt_complfree_flag,'N'),
                                        cpt_txn_code,
                                        cpt_mcc_code,
                                        cpt_internation_ind_response,
                                        cpt_pos_verification,
                                        cpt_ins_date,
                                        cpt_payment_type
                                 Into   V_Rowid,
                                       -- v_preauth_amount,
                                       -- v_preauth_valid_flag,
                                        v_hold_amount,
                                        v_preauth_expiry_flag,
                                        v_cpt_rrn,
                                        v_completion_fee
                                        ,v_preauth_txnamt,
                                        v_complfree_flag,
                                        v_org_txn_code,
                                        v_org_mcc_code,
                                        v_org_internation_ind_resp,
                                        v_org_pos_verification,
                                        v_org_date,
                                        v_org_payment_type
                                 FROM   VMSCMS.CMS_PREAUTH_TRANSACTION                   --Added for VMS-5739/FSP-991
                                 WHERE cpt_mbr_no      = p_mbr_numb
                                 AND   cpt_inst_code   = p_inst_code
                                 AND   cpt_card_no     = v_orgnl_hash_pan
                                 AND   cpt_mcc_code    = p_orgnl_mcc_code
                                 AND   to_number(cpt_approve_amt) between round(v_decr_tran_amt,2) and round(v_incr_tran_amt,2)
                                 and   cpt_ins_date = v_oldest_preauth
                             AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                                 AND   cpt_expiry_flag = 'N'
                                 AND cpt_preauth_type = v_preauth_type
                                 AND    rownum < 2;
								 IF SQL%ROWCOUNT = 0 THEN
								 Select Rowid,
                                        --cpt_txn_amnt,
                                        --cpt_preauth_validflag,
                                        cpt_totalhold_amt,
                                        cpt_expiry_flag,
                                        cpt_rrn,
                                        nvl(cpt_completion_fee,'0') 
                                        ,CPT_APPROVE_AMT,
                                        nvl(cpt_complfree_flag,'N'),
                                        cpt_txn_code,
                                        cpt_mcc_code,
                                        cpt_internation_ind_response,
                                        cpt_pos_verification,
                                        cpt_ins_date,
                                        cpt_payment_type
                                 Into   V_Rowid,
                                       -- v_preauth_amount,
                                       -- v_preauth_valid_flag,
                                        v_hold_amount,
                                        v_preauth_expiry_flag,
                                        v_cpt_rrn,
                                        v_completion_fee
                                        ,v_preauth_txnamt,
                                        v_complfree_flag,
                                        v_org_txn_code,
                                        v_org_mcc_code,
                                        v_org_internation_ind_resp,
                                        v_org_pos_verification,
                                        v_org_date,
                                        v_org_payment_type
                                 FROM   VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                   --Added for VMS-5739/FSP-991
                                 WHERE cpt_mbr_no      = p_mbr_numb
                                 AND   cpt_inst_code   = p_inst_code
                                 AND   cpt_card_no     = v_orgnl_hash_pan
                                 AND   cpt_mcc_code    = p_orgnl_mcc_code
                                 AND   to_number(cpt_approve_amt) between round(v_decr_tran_amt,2) and round(v_incr_tran_amt,2)
                                 and   cpt_ins_date = v_oldest_preauth
                             AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                                 AND   cpt_expiry_flag = 'N'
                                 AND cpt_preauth_type = v_preauth_type
                                 AND    rownum < 2;
								 END IF;

                                EXCEPTION  WHEN OTHERS
                                THEN
                                    v_resp_cde := '21';
                                    v_err_msg := 'Error while selecting the oldest PreAuth details for rule 5 '
                                                 ||substr(sqlerrm,1,200);
                                    RAISE exp_reject_record;
                                END;

                                v_pre_auth_check := 'Y';
                                v_rule := 'Rule5';


                            end if;
                         ELSE


                            BEGIN

                             Select Rowid,
                                   -- cpt_txn_amnt,
                                    --cpt_preauth_validflag,
                                    cpt_totalhold_amt,
                                    cpt_expiry_flag,
                                    cpt_rrn,
                                    nvl(cpt_completion_fee,'0') 
                                     ,CPT_APPROVE_AMT,
                                     nvl(cpt_complfree_flag,'N'),
                                     cpt_txn_code,
                                     cpt_mcc_code,
                                     cpt_internation_ind_response,
                                     cpt_pos_verification,
                                     cpt_ins_date,
                                     cpt_payment_type
                             Into   V_Rowid,
                                   -- v_preauth_amount,
                                   -- v_preauth_valid_flag,
                                    v_hold_amount,
                                    v_preauth_expiry_flag,
                                    v_cpt_rrn,
                                    v_completion_fee 
                                    ,v_preauth_txnamt,
                                    v_complfree_flag,
                                    v_org_txn_code,
                                    v_org_mcc_code,
                                    v_org_internation_ind_resp,
                                    v_org_pos_verification,
                                    v_org_date,
                                    v_org_payment_type
                             FROM   VMSCMS.CMS_PREAUTH_TRANSACTION                   --Added for VMS-5739/FSP-991
                             WHERE  cpt_mbr_no    =  p_mbr_numb
                             AND    cpt_inst_code =  p_inst_code
                             AND    cpt_card_no   = v_orgnl_hash_pan
                             AND    cpt_mcc_code  = p_orgnl_mcc_code
                             AND    cpt_ins_date  = v_oldest_preauth
                             AND    CPT_APPROVE_AMT     = P_HOLD_AMOUNT
                        AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                             AND   cpt_expiry_flag = 'N'
                             AND cpt_preauth_type = v_preauth_type
                             AND    rownum < 2;
							   IF SQL%ROWCOUNT = 0 THEN
							   Select Rowid,
                                   -- cpt_txn_amnt,
                                    --cpt_preauth_validflag,
                                    cpt_totalhold_amt,
                                    cpt_expiry_flag,
                                    cpt_rrn,
                                    nvl(cpt_completion_fee,'0') 
                                     ,CPT_APPROVE_AMT,
                                     nvl(cpt_complfree_flag,'N'),
                                     cpt_txn_code,
                                     cpt_mcc_code,
                                     cpt_internation_ind_response,
                                     cpt_pos_verification,
                                     cpt_ins_date,
                                     cpt_payment_type
                             Into   V_Rowid,
                                   -- v_preauth_amount,
                                   -- v_preauth_valid_flag,
                                    v_hold_amount,
                                    v_preauth_expiry_flag,
                                    v_cpt_rrn,
                                    v_completion_fee 
                                    ,v_preauth_txnamt,
                                    v_complfree_flag,
                                    v_org_txn_code,
                                    v_org_mcc_code,
                                    v_org_internation_ind_resp,
                                    v_org_pos_verification,
                                    v_org_date,
                                    v_org_payment_type
                             FROM   VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                   --Added for VMS-5739/FSP-991
                             WHERE  cpt_mbr_no    =  p_mbr_numb
                             AND    cpt_inst_code =  p_inst_code
                             AND    cpt_card_no   = v_orgnl_hash_pan
                             AND    cpt_mcc_code  = p_orgnl_mcc_code
                             AND    cpt_ins_date  = v_oldest_preauth
                             AND    CPT_APPROVE_AMT     = P_HOLD_AMOUNT
                        AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                             AND   cpt_expiry_flag = 'N'
                             AND cpt_preauth_type = v_preauth_type
                             AND    rownum < 2;
							   END IF;

                            EXCEPTION WHEN OTHERS
                            THEN
                                v_resp_cde := '21';
                                v_err_msg := 'Error while selecting the oldest PreAuth details for rule 4 '
                                             ||substr(sqlerrm,1,200);
                                RAISE exp_reject_record;
                            END;

                            v_pre_auth_check := 'Y';
                            v_rule := 'Rule4';

                         END IF;  

                     ELSE

                        BEGIN

                             Select Rowid,
                                   -- cpt_txn_amnt,
                                    --cpt_preauth_validflag,
                                    cpt_totalhold_amt,
                                    cpt_expiry_flag,
                                    cpt_rrn,
                                    nvl(cpt_completion_fee,'0') 
                                     ,CPT_APPROVE_AMT,
                                     nvl(cpt_complfree_flag,'N'),
                                     cpt_txn_code,
                                     cpt_mcc_code,
                                     cpt_internation_ind_response,
                                     cpt_pos_verification,
                                     cpt_ins_date,
                                     cpt_payment_type
                             Into   V_Rowid,
                                    --v_preauth_amount,
                                   -- v_preauth_valid_flag,
                                    v_hold_amount,
                                    v_preauth_expiry_flag,
                                    v_cpt_rrn,
                                    v_completion_fee
                                    ,v_preauth_txnamt,
                                    v_complfree_flag,
                                    v_org_txn_code,
                                    v_org_mcc_code,
                                    v_org_internation_ind_resp,
                                    v_org_pos_verification,
                                    v_org_date,
                                    v_org_payment_type
                             FROM   VMSCMS.CMS_PREAUTH_TRANSACTION                   --Added for VMS-5739/FSP-991
                             WHERE  cpt_mbr_no      =  p_mbr_numb
                             AND    cpt_inst_code   =  p_inst_code
                             AND    cpt_card_no     =  v_orgnl_hash_pan
                             AND    cpt_terminalid  =  p_orgnl_termid
                             AND    cpt_mcc_code    =  p_orgnl_mcc_code
                             AND    cpt_ins_date    =  v_oldest_preauth
                          AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                             AND   cpt_expiry_flag = 'N'
                             AND cpt_preauth_type = v_preauth_type
                             and    rownum < 2;
							  IF SQL%ROWCOUNT = 0 THEN
							  Select Rowid,
                                   -- cpt_txn_amnt,
                                    --cpt_preauth_validflag,
                                    cpt_totalhold_amt,
                                    cpt_expiry_flag,
                                    cpt_rrn,
                                    nvl(cpt_completion_fee,'0') 
                                     ,CPT_APPROVE_AMT,
                                     nvl(cpt_complfree_flag,'N'),
                                     cpt_txn_code,
                                     cpt_mcc_code,
                                     cpt_internation_ind_response,
                                     cpt_pos_verification,
                                     cpt_ins_date,
                                     cpt_payment_type
                             Into   V_Rowid,
                                    --v_preauth_amount,
                                   -- v_preauth_valid_flag,
                                    v_hold_amount,
                                    v_preauth_expiry_flag,
                                    v_cpt_rrn,
                                    v_completion_fee
                                    ,v_preauth_txnamt,
                                    v_complfree_flag,
                                    v_org_txn_code,
                                    v_org_mcc_code,
                                    v_org_internation_ind_resp,
                                    v_org_pos_verification,
                                    v_org_date,
                                    v_org_payment_type
                             FROM   VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                   --Added for VMS-5739/FSP-991
                             WHERE  cpt_mbr_no      =  p_mbr_numb
                             AND    cpt_inst_code   =  p_inst_code
                             AND    cpt_card_no     =  v_orgnl_hash_pan
                             AND    cpt_terminalid  =  p_orgnl_termid
                             AND    cpt_mcc_code    =  p_orgnl_mcc_code
                             AND    cpt_ins_date    =  v_oldest_preauth
                          AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                             AND   cpt_expiry_flag = 'N'
                             AND cpt_preauth_type = v_preauth_type
                             and    rownum < 2;
							  END IF;

                        EXCEPTION WHEN OTHERS
                        THEN
                            v_resp_cde := '21';
                            v_err_msg := 'Error while selecting the oldest PreAuth details for rule 3 '
                                         ||substr(sqlerrm,1,200);
                            RAISE exp_reject_record;
                        END;

                        v_pre_auth_check := 'Y';
                        v_rule := 'Rule3';

                     END IF; 

                 ELSE

                    BEGIN

                      Select Rowid,
                             --cpt_txn_amnt,
                             --cpt_preauth_validflag,
                             cpt_totalhold_amt,
                             cpt_expiry_flag,
                             cpt_rrn,
                             nvl(cpt_completion_fee,'0') 
                              ,CPT_APPROVE_AMT,
                              nvl(cpt_complfree_flag,'N'),
                              cpt_txn_code,
                              cpt_mcc_code,
                              cpt_internation_ind_response,
                              cpt_pos_verification,
                              cpt_ins_date,
                              cpt_payment_type
                      Into   V_Rowid,
                             --v_preauth_amount,
                             --v_preauth_valid_flag,
                             v_hold_amount,
                             v_preauth_expiry_flag,
                             v_cpt_rrn,
                             v_completion_fee 
                             ,v_preauth_txnamt,
                             v_complfree_flag,
                             v_org_txn_code,
                             v_org_mcc_code,
                             v_org_internation_ind_resp,
                             v_org_pos_verification,
                             v_org_date,
                             v_org_payment_type
                      FROM  VMSCMS.CMS_PREAUTH_TRANSACTION                   --Added for VMS-5739/FSP-991
                      WHERE cpt_mbr_no    = p_mbr_numb
                      AND   cpt_inst_code = p_inst_code
                      AND   CPT_APPROVE_AMT   = V_TRAN_AMT 
                      AND   cpt_card_no   = v_orgnl_hash_pan
                      AND   cpt_ins_date  = v_oldest_preauth
                AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                      AND   cpt_expiry_flag = 'N'
                      AND cpt_preauth_type = v_preauth_type
                      and   rownum < 2 ;
					   IF SQL%ROWCOUNT = 0 THEN
					   Select Rowid,
                             --cpt_txn_amnt,
                             --cpt_preauth_validflag,
                             cpt_totalhold_amt,
                             cpt_expiry_flag,
                             cpt_rrn,
                             nvl(cpt_completion_fee,'0') 
                              ,CPT_APPROVE_AMT,
                              nvl(cpt_complfree_flag,'N'),
                              cpt_txn_code,
                              cpt_mcc_code,
                              cpt_internation_ind_response,
                              cpt_pos_verification,
                              cpt_ins_date,
                              cpt_payment_type
                      Into   V_Rowid,
                             --v_preauth_amount,
                             --v_preauth_valid_flag,
                             v_hold_amount,
                             v_preauth_expiry_flag,
                             v_cpt_rrn,
                             v_completion_fee 
                             ,v_preauth_txnamt,
                             v_complfree_flag,
                             v_org_txn_code,
                             v_org_mcc_code,
                             v_org_internation_ind_resp,
                             v_org_pos_verification,
                             v_org_date,
                             v_org_payment_type
                      FROM  VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                  --Added for VMS-5739/FSP-991
                      WHERE cpt_mbr_no    = p_mbr_numb
                      AND   cpt_inst_code = p_inst_code
                      AND   CPT_APPROVE_AMT   = V_TRAN_AMT 
                      AND   cpt_card_no   = v_orgnl_hash_pan
                      AND   cpt_ins_date  = v_oldest_preauth
                AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                      AND   cpt_expiry_flag = 'N'
                      AND cpt_preauth_type = v_preauth_type
                      and   rownum < 2 ;
					   END IF;

                    EXCEPTION WHEN OTHERS
                    THEN
                        v_resp_cde := '21';
                        v_err_msg := 'Error while selecting the oldest PreAuth details for rule 2 '
                                     ||substr(sqlerrm,1,200);
                        RAISE exp_reject_record;
                    END;

                    v_pre_auth_check := 'Y';
                    v_rule := 'Rule2';


                 END IF;   

             ELSE


                BEGIN

                  Select Rowid,
                         --cpt_txn_amnt,
                         --cpt_preauth_validflag,
                         cpt_totalhold_amt,
                         cpt_expiry_flag,
                         cpt_rrn,
                         nvl(cpt_completion_fee,'0') 
                          ,CPT_APPROVE_AMT,
                          nvl(cpt_complfree_flag,'N'),
                          cpt_txn_code,
                          cpt_mcc_code,
                          cpt_internation_ind_response,
                          cpt_pos_verification,
                          cpt_ins_date,
                          cpt_payment_type
                  Into   V_Rowid,
                        -- v_preauth_amount,
                         --v_preauth_valid_flag,
                         v_hold_amount,
                         v_preauth_expiry_flag,
                         v_cpt_rrn,
                        v_completion_fee
                        ,v_preauth_txnamt,
                        v_complfree_flag,
                        v_org_txn_code,
                        v_org_mcc_code,
                        v_org_internation_ind_resp,
                        v_org_pos_verification,
                        v_org_date,
                        v_org_payment_type
                  FROM  VMSCMS.CMS_PREAUTH_TRANSACTION                    --Added for VMS-5739/FSP-991
                  WHERE cpt_mbr_no    = p_mbr_numb
                  AND   cpt_inst_code = p_inst_code
                  AND   cpt_rrn       = v_org_rrn 
                  AND   cpt_card_no   = v_orgnl_hash_pan
                  AND   cpt_ins_date  = v_oldest_preauth
            AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                  AND   cpt_expiry_flag = 'N'
                  AND cpt_preauth_type = v_preauth_type
                  and   rownum < 2;
				  IF SQL%ROWCOUNT = 0 THEN
				  

                  Select Rowid,
                         --cpt_txn_amnt,
                         --cpt_preauth_validflag,
                         cpt_totalhold_amt,
                         cpt_expiry_flag,
                         cpt_rrn,
                         nvl(cpt_completion_fee,'0') 
                          ,CPT_APPROVE_AMT,
                          nvl(cpt_complfree_flag,'N'),
                          cpt_txn_code,
                          cpt_mcc_code,
                          cpt_internation_ind_response,
                          cpt_pos_verification,
                          cpt_ins_date,
                          cpt_payment_type
                  Into   V_Rowid,
                        -- v_preauth_amount,
                         --v_preauth_valid_flag,
                         v_hold_amount,
                         v_preauth_expiry_flag,
                         v_cpt_rrn,
                        v_completion_fee
                        ,v_preauth_txnamt,
                        v_complfree_flag,
                        v_org_txn_code,
                        v_org_mcc_code,
                        v_org_internation_ind_resp,
                        v_org_pos_verification,
                        v_org_date,
                        v_org_payment_type
                  FROM  VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                   --Added for VMS-5739/FSP-991
                  WHERE cpt_mbr_no    = p_mbr_numb
                  AND   cpt_inst_code = p_inst_code
                  AND   cpt_rrn       = v_org_rrn 
                  AND   cpt_card_no   = v_orgnl_hash_pan
                  AND   cpt_ins_date  = v_oldest_preauth
            AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y')
                  AND   cpt_expiry_flag = 'N'
                  AND cpt_preauth_type = v_preauth_type
                  and   rownum < 2;
				END IF;

                EXCEPTION WHEN OTHERS
                THEN
                    v_resp_cde := '21';                    
                    v_err_msg := 'Error while selecting the oldest PreAuth details for rule 1 '||substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
                END;

                v_pre_auth_check := 'Y';
                v_rule := 'Rule1';


             END IF;  

      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_PRE_AUTH_CHECK := 'N';
         v_rule := 'U';
      when others
      then

        v_resp_cde := '21';                      
        v_err_msg := 'Error while rule wise check '||substr(sqlerrm,1,100);
        RAISE exp_reject_record;

      END;
    ELSE
     v_pre_auth_check := 'N';
     v_rule := 'U';
    END IF;

    --SN: Added for VMS-7383
    IF v_rule = 'U' THEN
        SELECT MIN (cpt_ins_date)
          INTO v_oldest_preauth
          FROM cms_preauth_transaction
         WHERE     cpt_mbr_no = p_mbr_numb
               AND cpt_inst_code = p_inst_code
               AND cpt_card_no = v_orgnl_hash_pan
               AND cpt_preauth_validflag <> 'N'
               AND cpt_expiry_flag = 'N'
               AND cpt_preauth_type = v_preauth_type
               AND EXISTS
                       (SELECT 1
                          FROM transactionlog
                         WHERE     business_date = cpt_txn_date
                               AND business_time = cpt_txn_time
                               --and   system_trace_audit_no = p_org_stan
                               AND rrn = cpt_rrn
                               AND response_code = '00'
                               AND delivery_channel = p_delivery_channel
                               AND customer_card_no = cpt_card_no
                               AND auth_id = v_de38_authid
                               AND instcode = p_inst_code
                               AND NVL (tran_reverse_flag, 'N') <> 'Y');
                             
        IF v_oldest_preauth IS NULL THEN
           v_pre_auth_check := 'N';
           v_rule := 'U';

        ELSE
            BEGIN
                SELECT ROWID,
                       cpt_totalhold_amt,
                       cpt_expiry_flag,
                       cpt_rrn,
                       NVL (cpt_completion_fee, '0'),
                       cpt_approve_amt,
                       NVL (cpt_complfree_flag, 'N'),
                       cpt_txn_code,
                       cpt_mcc_code,
                       cpt_internation_ind_response,
                       cpt_pos_verification,
                       cpt_ins_date,
                       cpt_payment_type
                  INTO v_rowid,
                       v_hold_amount,
                       v_preauth_expiry_flag,
                       v_cpt_rrn,
                       v_completion_fee,
                       v_preauth_txnamt,
                       v_complfree_flag,
                       v_org_txn_code,
                       v_org_mcc_code,
                       v_org_internation_ind_resp,
                       v_org_pos_verification,
                       v_org_date,
                       v_org_payment_type
                  FROM cms_preauth_transaction
                 WHERE     cpt_mbr_no = p_mbr_numb
                       AND cpt_inst_code = p_inst_code
                       AND cpt_card_no = v_orgnl_hash_pan
                       AND cpt_ins_date = v_oldest_preauth
                       AND cpt_preauth_validflag <> 'N'
                       AND cpt_expiry_flag = 'N'
                       AND cpt_preauth_type = v_preauth_type
                       AND ROWNUM < 2;                
                       
            EXCEPTION
                WHEN OTHERS THEN
                    v_resp_cde := '21';
                    v_err_msg :='Error while selecting the oldest PreAuth details for rule 6 '
                        || SUBSTR (SQLERRM, 1, 200);
                    RAISE exp_reject_record;
            END;

            v_pre_auth_check := 'Y';
            v_rule := 'Rule6';
            v_duplicate_comp_check := 'N';
            END IF;    
    END IF;
    --EN: Added for VMS-7383
    
        if v_duplicate_comp_check='Y' AND v_ignore_dup_cnt=0 then

        if v_total_completion_amt >= v_preauth_txnamt then


         IF v_completion_count > 0 THEN
                 V_RESP_CDE := '155';
                V_ERR_MSG  := 'Successful preauth completion already done';
                RAISE EXP_REJECT_RECORD;


          END IF;



        end if;

    end if;
	
		IF P_DELIVERY_CHANNEL = '02' AND P_TXN_CODE = '37' AND V_PRE_AUTH_CHECK = 'Y' THEN
		
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
        
        IF V_HOLD_AMOUNT = 0 AND V_PARAM_VALUE = 'Y' THEN
             V_RESP_CDE := '21';
             V_ERR_MSG  := 'No Hold Amount/Zero Hold Amount';
             RAISE EXP_REJECT_RECORD;
	    
		ELSIF V_HOLD_AMOUNT <> V_TRAN_AMT AND V_PARAM_VALUE = 'Y' THEN
                V_RESP_CDE := '21';
             	V_ERR_MSG  := 'Hold Amount and Transaction Amount are different.';
             RAISE EXP_REJECT_RECORD;
		END IF;
	END IF;
	
	--SN:Added for VMS-7383
	IF v_last_comp_ind = 'L' AND v_tran_amt < v_hold_amount THEN
        v_last_comp_ind:='N';
	END IF;
	--EN:Added for VMS-7383

   if(v_PREAUTH_TYPE='C') then

    BEGIN
          SELECT COUNT (1)
            INTO v_mrlimitbreach_count
            FROM cms_mrlimitbreach_merchantname
           WHERE cpt_inst_code = p_inst_code
             AND UPPER (TRIM (p_merchant_name)) LIKE cmm_merchant_name || '%';

         /* IF v_mrlimitbreach_count > 0
          THEN
             V_Mrminmaxlmt_Ignoreflag := 'Y';
          END IF;*/
    EXCEPTION
       WHEN OTHERS
       THEN
          V_RESP_CDE := '21';
          V_ERR_MSG  := 'Error While Occured checking the  limit breach count'|| SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
    end;

    
     end if;

    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;

    P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 2: ' || v_mili ;

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
                      P_INTERNATIONAL_IND, 
                      P_POS_VERFICATION, 
                      V_RESP_CDE,
                      P_MSG,
                      P_RVSL_CODE,
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
                      V_FEEAMNT_TYPE, 
                      V_CLAWBACK, 
                      V_FEE_PLAN, 
                      V_PER_FEES,
                      V_FLAT_FEES,
                      V_FREETXN_EXCEED, 
                      V_DURATION, 
                      V_FEEATTACH_TYPE, 
                      V_FEE_DESC,
                      v_complfree_flag,
                      p_surchrg_ind --Added VMS-5856
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

     BEGIN
     SP_CALCULATE_WAIVER(P_INST_CODE,
                     P_CARD_NO,
                     '000',
                     V_PROD_CODE,
                     V_PROD_CATTYPE,
                     V_FEE_CODE,
                     V_FEE_PLAN,
                     V_TRAN_DATE,
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

    V_FEE_AMT := NVL(V_FEE_AMT,0);
    v_feeamnt_type := NVL(v_feeamnt_type,'N');
    V_LOG_ACTUAL_FEE := V_FEE_AMT; 
    V_FEE_AMT        := ROUND(V_FEE_AMT -
                        ((V_FEE_AMT * V_WAIV_PERCNT) / 100),
                        2);
    V_LOG_WAIVER_AMT := V_LOG_ACTUAL_FEE - V_FEE_AMT;

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

    V_TOTAL_FEE := NVL(ROUND(V_FEE_AMT + V_SERVICETAX_AMOUNT + V_CESS_AMOUNT, 2),0); 

        IF(v_total_fee                =v_completion_fee) THEN
          v_fee_reverse_amount       :=0;
          v_comp_total_fee           :=0;
          v_complfee_increment_type  :='N';
            V_preauth_compfee:=0;
        ELSIF(v_total_fee             > v_completion_fee) THEN
          IF v_feeamnt_type          <> 'N' THEN
            v_fee_reverse_amount     :=0;
            v_comp_total_fee         :=v_total_fee-v_completion_fee;
            V_COMPLFEE_INCREMENT_TYPE:='D';
            V_PREAUTH_COMPFEE:=0;
          ELSIF v_feeamnt_type        = 'N' AND ( TO_NUMBER (p_comp_count) > 1  or v_duplicate_comp_check='Y') THEN
            v_fee_reverse_amount     :=0;
            v_comp_total_fee         :=0;
            v_complfee_increment_type:='N';
            V_FEE_AMT :=0;
            V_preauth_compfee:=0;
            V_TOTAL_FEE :=0;
            V_FEE_CODE:=null;
          ELSIF v_feeamnt_type        = 'N' AND (TO_NUMBER (p_comp_count) = 1  or TO_NUMBER (p_comp_count) = 0) THEN
            v_fee_reverse_amount     :=0;
            v_comp_total_fee         :=v_total_fee-v_completion_fee;
            v_complfee_increment_type:='D';
            V_preauth_compfee:=0;

          END IF;
        ELSE
          IF(v_total_fee                < v_completion_fee) THEN
            IF v_feeamnt_type          <> 'N' AND V_LAST_COMP_IND ='L' THEN
              v_fee_reverse_amount     :=v_completion_fee-v_total_fee;
              v_comp_total_fee         :=v_fee_reverse_amount;
              v_complfee_increment_type:='C';
              V_preauth_COMPFEE:=0;
                V_FEE_CODE:=null;
            ELSIF v_feeamnt_type       <> 'N' AND V_LAST_COMP_IND <> 'L' THEN
              v_fee_reverse_amount     :=0;
              v_comp_total_fee         :=0;
              V_preauth_compfee:=v_completion_fee -v_total_fee;
              v_completion_fee         :=V_FEE_AMT;
              V_COMPLFEE_INCREMENT_TYPE:='N';
                V_FEE_CODE:=null;
            ELSIF v_feeamnt_type        = 'N' AND (TO_NUMBER (p_comp_count) > 1  or v_duplicate_comp_check='Y') THEN
              v_fee_reverse_amount     :=0;
              v_comp_total_fee         :=0;
              v_complfee_increment_type:='N';
              V_FEE_AMT :=0;
              V_TOTAL_FEE :=0;
               V_preauth_compfee:=0;
                V_FEE_CODE:=null;
            ELSIF v_feeamnt_type        = 'N' AND (TO_NUMBER (p_comp_count) = 1 or TO_NUMBER (p_comp_count) = 0) THEN
              v_fee_reverse_amount     :=v_completion_fee-v_total_fee;
              v_comp_total_fee         :=v_fee_reverse_amount;
              v_complfee_increment_type:='C';
              V_preauth_compfee:=0;
                V_FEE_CODE:=null;

            END IF;
          END IF;
        END IF;

     IF V_DR_CR_FLAG = 'CR' AND V_PREAUTH_TYPE!='C' THEN  
     V_TOTAL_AMT      := V_TRAN_AMT - V_TOTAL_FEE;
     V_UPD_AMT        := V_ACCT_BALANCE + V_TOTAL_AMT;
     V_UPD_LEDGER_AMT := V_LEDGER_BAL + V_TOTAL_AMT;
    ELSIF V_DR_CR_FLAG = 'CR' AND V_PREAUTH_TYPE='C' THEN
     V_TOTAL_AMT      := V_TRAN_AMT - V_TOTAL_FEE;
     V_UPD_AMT        := V_ACCT_BALANCE  + V_TOTAL_AMT;
     V_UPD_LEDGER_AMT := V_LEDGER_BAL +V_TOTAL_AMT;
     p_resp_msg := TO_CHAR (v_acct_balance);
    ELSIF V_DR_CR_FLAG = 'DR' THEN
     V_TOTAL_AMT      := V_TRAN_AMT + V_TOTAL_FEE;
     V_UPD_AMT        := (V_HOLD_AMOUNT + V_ACCT_BALANCE) - V_TOTAL_AMT;
     V_UPD_LEDGER_AMT := (V_HOLD_AMOUNT + V_LEDGER_BAL) - V_TOTAL_AMT;
     p_resp_msg := TO_CHAR (v_acct_balance);            
    ELSIF V_DR_CR_FLAG = 'NA' THEN
     IF V_TOTAL_FEE = 0 THEN
       V_TOTAL_AMT := 0;
     ELSE
       V_TOTAL_AMT := V_TOTAL_FEE;
     END IF;

     V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
     V_UPD_LEDGER_AMT := V_UPD_LEDGER_AMT - V_TOTAL_AMT;
    ELSE
     V_RESP_CDE := '12'; 
     V_ERR_MSG  := 'Invalid transflag    txn code ' || P_TXN_CODE;
     RAISE EXP_REJECT_RECORD;
    END IF;

    v_totalamt:=TRIM (TO_CHAR (v_total_amt, '999999999999999990.99')); 

    BEGIN

     SELECT DECODE(V_PRE_AUTH_CHECK,
                'Y',
                V_HOLD_AMOUNT || V_PREAUTH_EXPIRY_FLAG ||
                V_LAST_COMP_IND,
                0)
       INTO V_PROXY_HOLD_AMOUNT
       FROM DUAL;
   EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Error while generating V_PROXY_HOLD_AMOUNT ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;
    begin

      SELECT cpc_profile_code,cpc_badcredit_flag,cpc_badcredit_transgrpid
      into l_profile_code,v_badcredit_flag,v_badcredit_transgrpid
      FROM cms_prod_cattype
      WHERE CPC_INST_CODE = p_inst_code
      and   cpc_prod_code = v_prod_code
      and   cpc_card_type = v_prod_cattype;
    exception
        when others then
            V_ERR_MSG  := 'Error while getting details from prod cattype ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    end;
    IF (V_PREAUTH_TYPE='C') THEN
      BEGIN
             SELECT TO_NUMBER(CBP_PARAM_VALUE)         
             INTO V_MAX_CARD_BAL
             FROM CMS_BIN_PARAM
             WHERE CBP_INST_CODE = P_INST_CODE AND
                    CBP_PARAM_NAME = 'Max Card Balance' AND
                    CBP_PROFILE_CODE=l_profile_code;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'NO DATA CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
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
      v_auth_id,
      '10',
      p_rrn,
      P_TRAN_DATE,
      P_TRAN_TIME,
      V_RESP_CDE,
      V_ERR_MSG );

      IF V_RESP_CDE <> '00' AND V_ERR_MSG <> 'OK' THEN
        RAISE EXP_REJECT_RECORD;
      END IF;

    EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
      RAISE;

    WHEN OTHERS THEN
      v_resp_cde := '21';
      V_ERR_MSG   := 'Error while logging system initiated card status change ' || SUBSTR (SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;

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
--        IF (V_UPD_LEDGER_AMT > V_MAX_CARD_BAL) OR (V_UPD_AMT > V_MAX_CARD_BAL) THEN
--         BEGIN
--             IF V_APPLPAN_CARDSTAT<>'12' THEN 
--             IF v_badcredit_flag = 'Y' THEN
--             execute immediate 'SELECT  count(*) 
--                FROM vms_group_tran_detl
--                WHERE vgd_group_id ='|| v_badcredit_transgrpid||'
--                AND vgd_tran_detl LIKE 
--                (''%'||P_DELIVERY_CHANNEL ||':'|| p_txn_code||'%'')'
--            into v_cnt;
--                IF v_cnt = 1 THEN
--                     v_card_stat := '18';
--               END IF;    
--            END IF;
--               UPDATE CMS_APPL_PAN
--                 SET CAP_CARD_STAT = v_card_stat
--                WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
--               IF SQL%ROWCOUNT = 0 THEN
--                V_ERR_MSG  := 'updating the card status is not happened';
--                V_RESP_CDE := '21';
--                RAISE EXP_REJECT_RECORD;
--               END IF;
--               v_chnge_crdstat:='Y';
--            END IF;
--          EXCEPTION
--           WHEN EXP_REJECT_RECORD THEN
--            RAISE EXP_REJECT_RECORD;
--           WHEN OTHERS THEN
--            V_ERR_MSG  := 'Error while updating the card status';
--            V_RESP_CDE := '21';
--            RAISE EXP_REJECT_RECORD;
--         END;
--        END IF;
    END IF;

     v_fee_reverse_amount:=nvl(v_fee_reverse_amount,0);
    v_completion_fee:=nvl(v_completion_fee,0);
    
    
    
    IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y' THEN
    BEGIN
          pkg_limits_check.sp_limits_check (v_hash_pan,
                                            NULL,
                                            NULL,
                                            p_mcc_code,
                                            p_txn_code,
                                            v_tran_type,
                                            NULL,
                                            NULL,
                                            p_inst_code,
                                            NULL,
                                            v_prfl_code,
                                            v_tran_amt,
                                            p_delivery_channel,
                                            v_comb_hash,
                                            v_resp_cde,
                                            V_ERR_MSG,
                                           v_mrlimitbreach_count,
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
     end if;
    
    
    
    

    BEGIN

     SP_UPD_TRANSACTION_ACCNT_AUTH(P_INST_CODE,
                             V_TRAN_DATE,
                             V_PROD_CODE,
                             V_PROD_CATTYPE,
                             V_TRAN_AMT, 
                             null,
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
                             V_PROXY_HOLD_AMOUNT,
                             P_MSG,
                             V_RESP_CDE,
                             V_ERR_MSG,
                             v_completion_fee); 

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

    BEGIN

     IF TRIM(V_TRANS_DESC) IS NOT NULL THEN

       V_NARRATION := V_TRANS_DESC || '/';

     END IF;

     IF TRIM(P_MERCHANT_NAME) IS NOT NULL THEN

       V_NARRATION := V_NARRATION || P_MERCHANT_NAME || '/';

     END IF;

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
      WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error in finding the narration ' ||
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
  END;

    IF V_DR_CR_FLAG <> 'NA' THEN
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
         csl_time_stamp,
         csl_card_type
         )
       VALUES
        (V_HASH_PAN,
         v_ledger_bal, 
         V_TRAN_AMT,
         V_DR_CR_FLAG,
         V_TRAN_DATE,
         DECODE(V_DR_CR_FLAG,
               'DR',
               v_ledger_bal - V_TRAN_AMT,
               'CR',
               v_ledger_bal + V_TRAN_AMT, 
               'NA',
               v_ledger_bal),
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
         V_CARD_ACCT_NO,
         1,
         SYSDATE,
         P_MERCHANT_NAME, 
         P_MERCHANT_CITY,
         P_ATMNAME_LOC,
         SUBSTR(P_CARD_NO,-4),    
         v_prod_code,
         v_acct_type,
         v_timestamp,V_PROD_CATTYPE
         );
     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Problem while inserting into statement log for tran amt ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

   /*  BEGIN
       SP_DAILY_BIN_BAL(P_CARD_NO,
                    V_TRAN_DATE,
                    V_TRAN_AMT,
                    V_DR_CR_FLAG,
                    P_INST_CODE,
                    '',
                    V_ERR_MSG);

        if  V_ERR_MSG <> 'OK'    
        then
            v_err_msg := 'Error from SP_DAILY_BIN_BAL :- '||v_err_msg;
            RAISE EXP_REJECT_RECORD;
        end if;

     EXCEPTION when EXP_REJECT_RECORD 
     then
       RAISE EXP_REJECT_RECORD;

     WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Error while calling SP_DAILY_BIN_BAL ' ||
                    SUBSTR(SQLERRM, 1, 200);
        Raise Exp_Reject_Record;
     END;*/
    END IF;

    IF V_TOTAL_FEE <> 0 OR V_FREETXN_EXCEED = 'N' THEN 
     BEGIN
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
           csl_prod_code,
           csl_acct_type,
           csl_time_stamp,csl_card_type
           )
        VALUES
          (V_HASH_PAN,
           V_FEE_OPENING_BAL,
           V_TOTAL_FEE,
           'DR',
           V_TRAN_DATE,
           V_FEE_OPENING_BAL - V_TOTAL_FEE,
           V_FEE_DESC, 
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
           SUBSTR(P_CARD_NO,-4),            
           v_prod_code,
           v_acct_type,
           v_timestamp,v_acct_type
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
     IF V_FEEAMNT_TYPE = 'A' THEN

        V_FLAT_FEES := ROUND(V_FLAT_FEES -
                            ((V_FLAT_FEES * V_WAIV_PERCNT) / 100),2);


            V_PER_FEES  := ROUND(V_PER_FEES -
                        ((V_PER_FEES * V_WAIV_PERCNT) / 100),2);
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
             csl_time_stamp,csl_card_type
             )
           VALUES
            (V_HASH_PAN,
             V_FEE_OPENING_BAL,
             V_FLAT_FEES,
             'DR',
             V_TRAN_DATE,
             V_FEE_OPENING_BAL - V_FLAT_FEES,
             'Fixed Fee debited for ' || V_FEE_DESC,
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
             SUBSTR(P_CARD_NO,-4),
             v_prod_code,
             v_acct_type,
             v_timestamp,v_acct_type
             );
          EXCEPTION WHEN OTHERS                      
           THEN
                v_resp_cde := '21';
                v_err_msg :='Problem while inserting into statement log for Fixed fee '|| SUBSTR (SQLERRM, 1, 100);
           RAISE exp_reject_record;

          END;

         IF V_PER_FEES <> 0 THEN --Added for VMS-5856
       V_FEE_OPENING_BAL := V_FEE_OPENING_BAL - V_FLAT_FEES;

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
             csl_time_stamp,csl_card_type
             )
           VALUES
            (V_HASH_PAN,
             V_FEE_OPENING_BAL,
             V_PER_FEES,
             'DR',
             V_TRAN_DATE,
             V_FEE_OPENING_BAL - V_PER_FEES,
             'Percentage Fee debited for ' || V_FEE_DESC,
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
             SUBSTR(P_CARD_NO,-4), 
             v_prod_code,
             v_acct_type,
             v_timestamp,v_acct_type
             );

         EXCEPTION WHEN OTHERS                   
           THEN
                v_resp_cde := '21';
                v_err_msg :='Problem while inserting into statement log for Percetage fee '|| SUBSTR (SQLERRM, 1, 100);
           RAISE exp_reject_record;

         END;
END IF;
     ELSE

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
               csl_time_stamp,csl_card_type
               )
            VALUES
              (V_HASH_PAN,
               V_FEE_OPENING_BAL,
               V_TOTAL_FEE,
               'DR',
               V_TRAN_DATE,
               V_FEE_OPENING_BAL - V_TOTAL_FEE,
               V_FEE_DESC, 
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
               SUBSTR(P_CARD_NO,-4), 
               v_prod_code,
               v_acct_type,
               v_timestamp,v_acct_type
               );

           EXCEPTION WHEN OTHERS            
           THEN
                v_resp_cde := '21';
                v_err_msg :='Problem occured while inserting into statement log '|| SUBSTR (SQLERRM, 1, 100);
           RAISE exp_reject_record;

           END;


     END IF;


    EXCEPTION WHEN exp_reject_record       
    THEN
        RAISE;

    WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Problem while inserting into statement log for tran fee ' ||
        SUBSTR(SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    END IF;
    END IF;

  
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
        ctd_ins_user,
        ctd_ins_date,
        ctd_completion_fee,ctd_complfee_increment_type,CTD_COMPFEE_CODE,CTD_COMPFEEATTACH_TYPE,CTD_COMPFEEPLAN_ID
        ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,CTD_CARDVERIFICATION_RESULT
        ,CTD_REQ_RESP_CODE
         ,CTD_PAYMENT_TYPE,ctd_hashkey_id,CTD_AUTH_ID
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
        V_TRAN_AMT,
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
         P_NETWORK_ID,
        P_INTERCHANGE_FEEAMT,
        P_MERCHANT_ZIP,
        P_MERC_ID,
        P_MERC_CNTRYCODE,
        1,
        SYSDATE,
        v_comp_total_fee,v_complfee_increment_type,v_fee_code,v_feeattach_type,v_fee_plan 
        ,  P_PULSE_TRANSACTIONID,
        P_VISA_TRANSACTIONID,
        P_MC_TRACEID,
       P_CARDVERIFICATION_RESULT
       ,P_REQ_RESP_CODE 
        ,P_MS_PYMNT_DESC,v_hashkey_id,V_AUTH_ID
        );
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from response master ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;

    P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 3: ' || v_mili ;

    V_RESP_CDE := '1';

    BEGIN
     BEGIN

         BEGIN

           INSERT INTO CMS_PREAUTH_TRANS_HIST
            (CPH_CARD_NO,
             CPH_MBR_NO,
             CPH_INST_CODE,
             CPH_CARD_NO_ENCR,
             CPH_PREAUTH_VALIDFLAG,
             CPH_COMPLETION_FLAG,
             CPH_TXN_AMNT,
             CPH_APPROVE_AMT,
             CPH_RRN,
             CPH_TXN_DATE,
             CPH_TXN_TIME,
             CPH_ORGNL_RRN,
             CPH_ORGNL_TXN_DATE,
             CPH_ORGNL_TXN_TIME,
             CPH_ORGNL_CARD_NO,
             CPH_TERMINALID,
             CPH_ORGNL_TERMINALID,
             CPH_COMP_COUNT,
             CPH_TRANSACTION_FLAG,
             CPH_TOTALHOLD_AMT,
             CPH_ACCT_NO,      
             CPH_ORGNL_MCCCODE, 
             CPH_MATCH_RRN       
             ,CPH_DELIVERY_CHANNEL
             ,CPH_TRAN_CODE,
             CPH_PANNO_LAST4DIGIT ,
             cph_completion_fee 
             ,CPH_PREAUTH_TYPE
             )
           VALUES
            (V_HASH_PAN,
             P_MBR_NUMB,
             P_INST_CODE,
             V_ENCR_PAN,
             'N',
             'C',
             V_TRAN_AMT, 
             trim(to_char(nvl(V_TRAN_AMT,0),'999999999999999990.99')),
             P_RRN,
             P_TRAN_DATE,
             P_TRAN_TIME,
             v_org_rrn,   
             P_ORGNL_TRANDATE,
             P_ORGNL_TRANTIME,
             V_ORGNL_HASH_PAN,
             P_TERM_ID,
             P_ORGNL_TERMID,
             TO_NUMBER (p_comp_count),
             'C',
             '0.00',
             V_ACCT_NUMBER,          
             p_orgnl_mcc_code,      
             v_cpt_rrn               
             ,P_DELIVERY_CHANNEL
             ,P_TXN_CODE,
              (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))), 
              V_TOTAL_FEE 
              ,V_PREAUTH_TYPE
             );

         EXCEPTION WHEN OTHERS            
         THEN
                v_resp_cde := '21';
                v_err_msg :='Problem occured while inserting into preauth hist '|| SUBSTR (SQLERRM, 1, 100);
           RAISE exp_reject_record;

         END;

       IF V_PRE_AUTH_CHECK = 'N' THEN

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
               cpt_completion_fee,CPT_PREAUTH_TYPE)
            VALUES
              (V_HASH_PAN,
              V_TRAN_AMT,   
               null,
               P_RRN,
               'N',
               P_INST_CODE,
               P_MBR_NUMB,
               V_ENCR_PAN,
               'Y',
              trim(to_char(nvl(v_tran_amt,0),'999999999999999990.99')),
               P_RRN,
               P_TRAN_DATE,
               P_TRAN_TIME,
               P_TERM_ID,
               'Y',
               '0.00',
               'C',
               V_ACCT_NUMBER,
               v_total_fee,V_PREAUTH_TYPE);

           EXCEPTION WHEN OTHERS            
           THEN
                v_resp_cde := '21';
                v_err_msg :='Problem occured while inserting into preauth txn '|| SUBSTR (SQLERRM, 1, 100);
           RAISE exp_reject_record;

           END;

       ELSE

        IF V_TRAN_AMT >= V_HOLD_AMOUNT 
        THEN
            BEGIN
                 UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION    --Added for VMS-5739/FSP-991
                  SET  cpt_totalhold_amt = '0.00', 
                       cpt_transaction_flag = 'C',
                       cpt_txn_amnt = V_TRAN_AMT,
                       cpt_transaction_rrn = cpt_transaction_rrn||decode(cpt_transaction_rrn,NULL,'',',')||p_rrn,
                       cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,NULL,'',',')||v_rule 
                       ,cpt_completion_fee=V_preauth_compfee
                  WHERE rowid = v_rowid
                AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y');
            EXCEPTION WHEN OTHERS THEN                                      --Added for vms_9133
                UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION    --Added for VMS-5739/FSP-991
                  SET  cpt_totalhold_amt = '0.00', 
                       cpt_transaction_flag = 'C',
                       cpt_txn_amnt = V_TRAN_AMT,
                       cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,NULL,'',',')||v_rule 
                       ,cpt_completion_fee=V_preauth_compfee
                  WHERE rowid = v_rowid
                AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y');

            END;
			
			IF SQL%ROWCOUNT = 0 THEN
            BEGIN
                UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST    --Added for VMS-5739/FSP-991
                  SET  cpt_totalhold_amt = '0.00', 
                       cpt_transaction_flag = 'C',
                       cpt_txn_amnt = V_TRAN_AMT,
                       cpt_transaction_rrn = cpt_transaction_rrn||decode(cpt_transaction_rrn,NULL,'',',')||p_rrn,
                       cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,NULL,'',',')||v_rule 
                       ,cpt_completion_fee=V_preauth_compfee
                  WHERE rowid = v_rowid
                AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y');
            EXCEPTION WHEN OTHERS THEN                          --Added for vms_9133
                UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST    --Added for VMS-5739/FSP-991
                  SET  cpt_totalhold_amt = '0.00', 
                       cpt_transaction_flag = 'C',
                       cpt_txn_amnt = V_TRAN_AMT,
                       cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,NULL,'',',')||v_rule 
                       ,cpt_completion_fee=V_preauth_compfee
                  WHERE rowid = v_rowid
                AND cpt_preauth_validflag <> DECODE(v_duplicate_comp_check,'N','N','Y');
            END;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_err_msg :=
                           'Problem while updating data in CMS_PREAUTH_TRANSACTION 1 '
                        || SUBSTR (SQLERRM, 1, 300);
                     v_resp_cde := '21';
                     RAISE exp_reject_record;
                  END IF;
			END IF;
                  v_sqlrowcnt := SQL%ROWCOUNT;

             IF V_LAST_COMP_IND <> 'L' THEN     
                BEGIN
                    SELECT ctm_prfl_flag, CTM_TRAN_TYPE
                       INTO v_org_prfl_flag, v_org_tran_type
                       FROM CMS_TRANSACTION_MAST
                      WHERE CTM_TRAN_CODE = v_org_txn_code AND
                           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
                           CTM_INST_CODE = P_INST_CODE;
                    EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                      v_trans_desc := 'Transaction type ' || p_txn_code; 
                       V_RESP_CDE := '12'; 
                       V_ERR_MSG  := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
                                  ' and delivery channel ' || P_DELIVERY_CHANNEL;
                       RAISE EXP_REJECT_RECORD;
                     WHEN TOO_MANY_ROWS THEN
                       V_RESP_CDE := '21';
                       V_ERR_MSG  := 'More than one transaction defined for txn code ';
                       RAISE EXP_REJECT_RECORD;
                     WHEN OTHERS THEN
                       V_RESP_CDE := '21';
                       V_ERR_MSG  := 'Error while selecting the details fromtransaction ';
                       RAISE EXP_REJECT_RECORD;
                END;

                IF v_prfl_code IS NOT NULL AND v_org_prfl_flag = 'Y' THEN
                   IF V_HOLD_AMOUNT - V_TRAN_AMT <> 0 then
                     BEGIN
                       PKG_LIMITS_CHECK.sp_limitcnt_rever_reset
                                 (P_INST_CODE,
                                  null,
                                  null,
                                  v_org_mcc_code,    
                                  v_org_txn_code,
                                  v_org_tran_type,
                                  v_org_internation_ind_resp,
                                  v_org_pos_verification,
                                  v_prfl_code,
                                  V_HOLD_AMOUNT - V_TRAN_AMT,
                                  '0',
                                  p_delivery_channel,
                                  v_hash_pan,
                                  v_org_date,
                                  v_resp_cde,
                                  v_err_msg,
                                  v_org_payment_type
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
                END IF;
             END IF;   


        ELSE

          V_TOTAL_AMT := V_HOLD_AMOUNT - V_TRAN_AMT;

          IF V_TOTAL_AMT > 0
          THEN
            BEGIN
                UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION             --Added for VMS-5739/FSP-991
                  SET CPT_TRANSACTION_FLAG = 'C',
                     CPT_TOTALHOLD_AMT    = trim(to_char(V_TOTAL_AMT,'999999999999999990.99')), 
                     CPT_TXN_AMNT         = V_TRAN_AMT,
                     CPT_TRANSACTION_RRN  =  cpt_transaction_rrn||decode(cpt_transaction_rrn,NULL,'',',')||p_rrn,
                     cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,NULL,'',',')||v_rule 
                      ,cpt_completion_fee=V_preauth_compfee 
                  WHERE rowid = v_rowid;
            EXCEPTION WHEN OTHERS THEN                                  --Added for vms_9133
                UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION             --Added for VMS-5739/FSP-991
                  SET CPT_TRANSACTION_FLAG = 'C',
                     CPT_TOTALHOLD_AMT    = trim(to_char(V_TOTAL_AMT,'999999999999999990.99')), 
                     CPT_TXN_AMNT         = V_TRAN_AMT,
                     cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,NULL,'',',')||v_rule 
                      ,cpt_completion_fee=V_preauth_compfee 
                  WHERE rowid = v_rowid;
            END;
				  
					 IF SQL%ROWCOUNT = 0 
					  THEN  
                BEGIN
					   UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST            --Added for VMS-5739/FSP-991
					  SET CPT_TRANSACTION_FLAG = 'C',
						 CPT_TOTALHOLD_AMT    = trim(to_char(V_TOTAL_AMT,'999999999999999990.99')), 
						 CPT_TXN_AMNT         = V_TRAN_AMT,
						 CPT_TRANSACTION_RRN  =  cpt_transaction_rrn||decode(cpt_transaction_rrn,NULL,'',',')||p_rrn,
						 cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,NULL,'',',')||v_rule 
						  ,cpt_completion_fee=V_preauth_compfee 
					  WHERE rowid = v_rowid;
                EXCEPTION WHEN OTHERS THEN                  --Added for vms_9133
                       UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST            --Added for VMS-5739/FSP-991
					  SET CPT_TRANSACTION_FLAG = 'C',
						 CPT_TOTALHOLD_AMT    = trim(to_char(V_TOTAL_AMT,'999999999999999990.99')), 
						 CPT_TXN_AMNT         = V_TRAN_AMT,
						 cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,NULL,'',',')||v_rule 
						  ,cpt_completion_fee=V_preauth_compfee 
					  WHERE rowid = v_rowid;
                END;

					  IF SQL%ROWCOUNT = 0 
					  THEN
						 v_err_msg :=
							   'Problem while updating data in CMS_PREAUTH_TRANSACTION 2 '
							|| SUBSTR (SQLERRM, 1, 300);
						 v_resp_cde := '21';
						 RAISE exp_reject_record;
					  END IF;
				END IF;
                  v_sqlrowcnt := SQL%ROWCOUNT;


          ELSE
            BEGIN
                UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION             --Added for VMS-5739/FSP-991
                  SET CPT_TOTALHOLD_AMT    = '0.00',
                     CPT_TRANSACTION_FLAG = 'C',
                     CPT_TXN_AMNT         = V_TRAN_AMT,
                     CPT_TRANSACTION_RRN  =  cpt_transaction_rrn||decode(cpt_transaction_rrn,NULL,'',',')||p_rrn,
                     cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,NULL,'',',')||v_rule 
                      ,cpt_completion_fee=V_preauth_compfee 
                  WHERE rowid = v_rowid;
            EXCEPTION WHEN OTHERS THEN                              --Added for VMS_9133
                UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION             --Added for VMS-5739/FSP-991
                  SET CPT_TOTALHOLD_AMT    = '0.00',
                     CPT_TRANSACTION_FLAG = 'C',
                     CPT_TXN_AMNT         = V_TRAN_AMT,
                     cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,NULL,'',',')||v_rule 
                      ,cpt_completion_fee=V_preauth_compfee 
                  WHERE rowid = v_rowid;
            END;
				  
				   IF SQL%ROWCOUNT = 0
                  THEN
                  
            BEGIN
					  UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST            --Added for VMS-5739/FSP-991
                  SET CPT_TOTALHOLD_AMT    = '0.00',
                     CPT_TRANSACTION_FLAG = 'C',
                     CPT_TXN_AMNT         = V_TRAN_AMT,
                     CPT_TRANSACTION_RRN  =  cpt_transaction_rrn||decode(cpt_transaction_rrn,NULL,'',',')||p_rrn,
                     cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,NULL,'',',')||v_rule 
                      ,cpt_completion_fee=V_preauth_compfee 
                  WHERE rowid = v_rowid;
            EXCEPTION WHEN OTHERS THEN                          --Added for VMS_9133
                      UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST            --Added for VMS-5739/FSP-991
                  SET CPT_TOTALHOLD_AMT    = '0.00',
                     CPT_TRANSACTION_FLAG = 'C',
                     CPT_TXN_AMNT         = V_TRAN_AMT,
                     cpt_match_rule = cpt_match_rule||decode(cpt_match_rule,NULL,'',',')||v_rule 
                      ,cpt_completion_fee=V_preauth_compfee 
                  WHERE rowid = v_rowid;
            END;
				  
                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_err_msg :=
                           'Problem while updating data in CMS_PREAUTH_TRANSACTION 3 '
                           || SUBSTR (SQLERRM, 1, 300);
                     v_resp_cde := '21';
                     RAISE exp_reject_record;
                  END IF;
			 END IF;
                  v_sqlrowcnt := SQL%ROWCOUNT;


          END IF;

        END IF;

           IF V_LAST_COMP_IND = 'L'
            THEN

                   UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION             --Added for VMS-5739/FSP-991
                    SET CPT_PREAUTH_VALIDFLAG  = 'N',
                        CPT_TOTALHOLD_AMT      = '0.00',
                        CPT_EXP_RELEASE_AMOUNT = (V_HOLD_AMOUNT - V_TRAN_AMT),
                        CPT_COMPLETION_FLAG    = 'Y',
                        cpt_match_rule = decode (v_sqlrowcnt,'0',cpt_match_rule||decode(cpt_match_rule,NULL,'',',')||v_rule,cpt_match_rule) -- Added for FSS-781
                         ,cpt_completion_fee=V_preauth_compfee 
                    WHERE rowid = v_rowid
                      AND cpt_preauth_validflag = DECODE(v_duplicate_comp_check,'N','Y','N');

                      IF SQL%ROWCOUNT = 0 
                      THEN
                         v_err_msg :=
                               'Problem while updating data in CMS_PREAUTH_TRANSACTION 4 '
                            || SUBSTR (SQLERRM, 1, 300);
                         v_resp_cde := '21';
                         RAISE exp_reject_record;
                      END IF;

                       BEGIN
                           SELECT ctm_prfl_flag, CTM_TRAN_TYPE
                             INTO v_org_prfl_flag, v_org_tran_type
                             FROM CMS_TRANSACTION_MAST
                            WHERE CTM_TRAN_CODE = v_org_txn_code AND
                                 CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
                                 CTM_INST_CODE = P_INST_CODE;
                          EXCEPTION
                           WHEN NO_DATA_FOUND THEN
                            v_trans_desc := 'Transaction type ' || p_txn_code; 
                             V_RESP_CDE := '12'; 
                             V_ERR_MSG  := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
                                        ' and delivery channel ' || P_DELIVERY_CHANNEL;
                             RAISE EXP_REJECT_RECORD;
                           WHEN TOO_MANY_ROWS THEN
                             V_RESP_CDE := '21';
                             V_ERR_MSG  := 'More than one transaction defined for txn code ';
                             RAISE EXP_REJECT_RECORD;
                           WHEN OTHERS THEN
                             V_RESP_CDE := '21';
                             V_ERR_MSG  := 'Error while selecting the details fromtransaction ';
                             RAISE EXP_REJECT_RECORD;
                          END;

                      IF v_prfl_code IS NOT NULL AND v_org_prfl_flag = 'Y' THEN
                        IF V_HOLD_AMOUNT - V_TRAN_AMT <> 0 then
                          BEGIN
                             PKG_LIMITS_CHECK.sp_limitcnt_rever_reset
                                       (P_INST_CODE,
                                        null,
                                        null,
                                        v_org_mcc_code,    
                                        v_org_txn_code,
                                        v_org_tran_type,
                                        v_org_internation_ind_resp,
                                        v_org_pos_verification,
                                        v_prfl_code,
                                        V_HOLD_AMOUNT - V_TRAN_AMT,
                                        '0',
                                        p_delivery_channel,
                                        v_hash_pan,
                                        v_org_date,
                                        v_resp_cde,
                                        v_err_msg,
                                        v_org_payment_type
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
                          END IF;


           END IF;
       END IF;

    EXCEPTION WHEN exp_reject_record      
    THEN
          RAISE;

    WHEN OTHERS THEN
        V_ERR_MSG  := 'Problem While Updating the Pre-Auth Completion transaction details of the card' ||        
                    SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;

    END;

    BEGIN
       SELECT  cam_acct_bal,cam_ledger_bal
             INTO v_acct_balance,v_ledger_bal
             FROM cms_acct_mast
            WHERE cam_acct_no = v_acct_number    
                 AND cam_inst_code = p_inst_code;
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          v_resp_cde := '14';
          v_err_msg := 'Invalid Card ';
          RAISE exp_reject_record;
       WHEN OTHERS
       THEN
          v_resp_cde := '21';
          v_err_msg :=
                'Error while selecting data from card Master for card number '
             || SQLERRM;
          RAISE exp_reject_record;
    END;

     BEGIN
     SELECT CMS_B24_RESPCDE, 
            cms_iso_respcde 
       INTO P_RESP_CODE,
             p_iso_respcde 
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
    p_resp_msg := TO_CHAR (v_acct_balance);            
     P_LEDGER_BAL := TO_CHAR (v_ledger_bal);  
     P_RESP_ID := V_RESP_CDE; --Added for VMS-8018

    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from response master for respose code' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

       if(v_PREAUTH_TYPE='C') then
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
    end;
    end if;
    end if;

       Begin
    sp_autonomous_preauth_logclear(v_auth_id);
    exception
    When others then
    null;
    End;
  EXCEPTION
    --<< MAIN EXCEPTION >>
    WHEN EXP_REJECT_RECORD THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO
        INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_ACCT_NUMBER
        From Cms_Acct_Mast
        Where Cam_Acct_No =V_Acct_Number
           /* (SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              Where Cap_Pan_Code = V_Hash_Pan And
                   CAP_INST_CODE = P_INST_CODE)*/ AND
            CAM_INST_CODE = P_INST_CODE;
     EXCEPTION
       WHEN OTHERS THEN
        V_ACCT_BALANCE := 0;
        V_LEDGER_BAL   := 0;
     END;

     BEGIN
       P_RESP_MSG  := V_ERR_MSG;
       P_RESP_CODE := V_RESP_CDE;
       P_RESP_ID   := V_RESP_CDE; --Added for VMS-8018
      SELECT CMS_B24_RESPCDE,
              cms_iso_respcde      
        INTO P_RESP_CODE,
            p_iso_respcde 
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
          ctd_ins_user,
         ctd_ins_date,
          ctd_completion_fee,ctd_complfee_increment_type,CTD_COMPFEE_CODE,CTD_COMPFEEATTACH_TYPE,CTD_COMPFEEPLAN_ID 
          ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,CTD_CARDVERIFICATION_RESULT
         ,CTD_REQ_RESP_CODE 
          ,CTD_PAYMENT_TYPE,ctd_hashkey_id,CTD_AUTH_ID
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
         V_TRAN_AMT, 
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
           v_comp_total_fee,v_complfee_increment_type,v_fee_code,v_feeattach_type,v_fee_plan
            ,  P_PULSE_TRANSACTIONID,
        P_VISA_TRANSACTIONID,
        P_MC_TRACEID,
         P_CARDVERIFICATION_RESULT
      ,P_REQ_RESP_CODE  
       ,P_MS_PYMNT_DESC,v_hashkey_id,V_AUTH_ID
         );

       P_RESP_MSG := V_ERR_MSG;
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69';
        P_RESP_ID   := '69'; --Added for VMS-8018
        ROLLBACK;
        RETURN;
     END;

         Begin
    sp_autonomous_preauth_logclear(v_auth_id);
    exception
    When others then
    null;
    End;
    WHEN OTHERS THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;

     BEGIN
       SELECT CMS_B24_RESPCDE, 
              cms_iso_respcde 
        INTO P_RESP_CODE,
             p_iso_respcde
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
        P_RESP_CODE := '69';
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
         CTD_NETWORK_ID,
         CTD_INTERCHANGE_FEEAMT,
         CTD_MERCHANT_ZIP,
         CTD_MERCHANT_ID,
         CTD_COUNTRY_CODE,
         ctd_ins_user,
         ctd_ins_date,
          ctd_completion_fee,ctd_complfee_increment_type,CTD_COMPFEE_CODE,CTD_COMPFEEATTACH_TYPE,CTD_COMPFEEPLAN_ID 
          ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,
         CTD_CARDVERIFICATION_RESULT
         ,CTD_REQ_RESP_CODE  
          ,CTD_PAYMENT_TYPE,ctd_hashkey_id,CTD_AUTH_ID

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
         V_TRAN_AMT,
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
           v_comp_total_fee,v_complfee_increment_type,v_fee_code,v_feeattach_type,v_fee_plan 
            ,P_PULSE_TRANSACTIONID,
        P_VISA_TRANSACTIONID,
        P_MC_TRACEID,
       P_CARDVERIFICATION_RESULT
       ,P_REQ_RESP_CODE 
        ,P_MS_PYMNT_DESC,v_hashkey_id,V_AUTH_ID
         );
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; 
        P_RESP_ID   := '69'; --Added for VMS-8018
        ROLLBACK;
        RETURN;
     END;
  END;

   IF V_RESP_CDE  in ('1','314') THEN

    V_BUSINESS_TIME := TO_CHAR(V_TRAN_DATE, 'HH24:MI');

    IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
     V_BUSINESS_DATE := TRUNC(V_TRAN_DATE) + 1;
    ELSE
     V_BUSINESS_DATE := TRUNC(V_TRAN_DATE);
    END IF;

    BEGIN
     SELECT CAM_ACCT_BAL
       INTO V_ACCT_BALANCE
       From Cms_Acct_Mast
      Where Cam_Acct_No =V_Acct_Number
           /*(SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN
                 And Cap_Mbr_Numb = P_Mbr_Numb And
                 CAP_INST_CODE = P_INST_CODE)*/ AND
           CAM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '14'; 
       V_ERR_MSG  := 'Invalid Card ';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                  SQLERRM;
       RAISE EXP_REJECT_RECORD;
    END;

    IF V_OUTPUT_TYPE = 'N' THEN
     p_resp_msg := TO_CHAR (v_acct_balance);       
    END IF;
  END IF;

  IF V_AUTH_ID_GEN_FLAG = 'N' THEN

    BEGIN

       SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL; 
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG  := 'Error while generating authid ' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '89'; 
       P_RESP_ID   := '89'; --Added for VMS-8018
       ROLLBACK;
    END;

  END IF;

  IF v_dr_cr_flag IS NULL THEN
  BEGIN
    SELECT ctm_credit_debit_flag,
           TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')), ctm_tran_type
      INTO v_dr_cr_flag,
           v_txn_type, v_tran_type
      FROM cms_transaction_mast
     WHERE ctm_tran_code = p_txn_code
       AND ctm_delivery_channel = p_delivery_channel
       AND ctm_inst_code = p_inst_code;
  EXCEPTION
     WHEN OTHERS THEN
        NULL;
  END;
  END IF;



if P_ISO_RESPCDE in ('L49','L50') and P_TXN_CODE in ('25','35')  then
  begin
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
      v_auth_id,
      '10',
      p_rrn,
      P_TRAN_DATE,
      P_TRAN_TIME,
      V_RESP_CDE,
      P_RESP_MSG );

      IF V_RESP_CDE <> '00' AND P_RESP_MSG <> 'OK' THEN
        RAISE EXP_REJECT_RECORD;
      END IF;

    EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
      RAISE;

    WHEN OTHERS THEN
      v_resp_cde := '21';
      V_ERR_MSG   := 'Error while logging system initiated card status change ' || SUBSTR (SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;

    END;
               END IF;
            END IF;
         END IF;
  
  end;
END IF;
  IF v_prod_code is NULL THEN
  BEGIN
    SELECT cap_prod_code, cap_card_type, cap_acct_no,cap_proxy_number  
      INTO v_prod_code, v_prod_cattype, v_acct_number,V_PROXUNUMBER  
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
     IF p_req_resp_code >= 100
          THEN
           -- IF(P_TXN_CODE='23' OR P_TXN_CODE='27' OR (P_DELIVERY_CHANNEL='01' AND P_TXN_CODE='12')) THEN
    P_LEDGER_BAL:=V_LEDGER_BAL;
  -- END IF;
    END IF;

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
      RESPONSE_ID,
      CARDSTATUS,
      NETWORK_ID,
      INTERCHANGE_FEEAMT,
      MERCHANT_ZIP,
      MERCHANT_ID,
      COUNTRY_CODE,
     FEE_PLAN,
      POS_VERIFICATION, 
      INTERNATION_IND_RESPONSE, 
      FEEATTACHTYPE, 
      MERCHANT_NAME,
      MERCHANT_CITY,
      MERCHANT_STATE,  
      MATCH_RULE,      
      error_msg,
      acct_type,
      time_stamp,
      original_stan,  
      add_ins_user,
      PERMRULE_VERIFY_FLAG, 
      NETWORKID_SWITCH,
      NETWORKID_ACQUIRER,
      NETWORK_SETTL_DATE,
      ORGNL_CARD_NO,      
      ORGNL_RRN,           
      ORGNL_BUSINESS_DATE,
      ORGNL_BUSINESS_TIME, 
      ORGNL_TERMINAL_ID,  
      completion_count,     
      CVV_VERIFICATIONTYPE,  
      remark ,
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
       DECODE (p_iso_respcde , '00', 'C', 'F'), 
      p_iso_respcde, 
      P_TRAN_DATE,
      SUBSTR(P_TRAN_TIME, 1, 10),
      V_HASH_PAN,
      NULL,
      NULL,
      NULL,
      P_INST_CODE,
    NVL(v_totalamt,'0.00'),
      NULL,
      NULL,
      P_MCC_CODE,
      P_CURR_CODE,
      NULL, 
      V_PROD_CODE,
      V_PROD_CATTYPE,
      '0.00', 
      NULL,
      P_ATMNAME_LOC,
      V_AUTH_ID,
      V_TRANS_DESC,
      TRIM (TO_CHAR (nvl(v_tran_amt,0), '999999999999999990.99')),  
      P_MERC_CNTRYCODE,
      '0.00',
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      null,
      P_STAN,
      P_INST_CODE,
      V_FEE_CODE,
      nvl(V_FEE_AMT,0),
      nvl(V_SERVICETAX_AMOUNT,0), 
      nvl(V_CESS_AMOUNT,0),
      DECODE( v_de_cr_flag_mcauth,'CR','CR','DR','DR',V_DR_CR_FLAG),
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
      V_ACCT_BALANCE,
      V_LEDGER_BAL,
      V_RESP_CDE,
      V_APPLPAN_CARDSTAT, 
      P_NETWORK_ID,
      P_INTERCHANGE_FEEAMT,
      P_MERCHANT_ZIP,
      P_MERC_ID,
      P_COUNTRY_CODE,
     V_FEE_PLAN, 
      P_POS_VERFICATION, 
      P_INTERNATIONAL_IND,
      V_FEEATTACH_TYPE, 
      P_MERCHANT_NAME, 
      P_MERCHANT_CITY,
      P_ATMNAME_LOC, 
      v_rule ,       
      v_err_msg,v_acct_type,nvl(v_timestamp,systimestamp),
      p_org_stan,
      1 ,
      V_MCC_VERIFY_FLAG, 
      P_NETWORKID_SWITCH , 
      P_NETWORKID_ACQUIRER,
      p_network_setl_date,  
      v_orgnl_hash_pan,  
      v_org_rrn,     
      p_orgnl_trandate, 
      p_orgnl_trantime,
      p_orgnl_termid,  
      p_comp_count,    
      NVL(P_CVV_VERIFICATIONTYPE,'N'),  
      V_ERR_MSG,
      DECODE(p_surchrg_ind,'2',NULL,p_surchrg_ind) --Added for VMS-5856
      );
    P_CAPTURE_DATE := V_BUSINESS_DATE;
    P_AUTH_ID      := V_AUTH_ID;
  EXCEPTION
    WHEN OTHERS THEN
     ROLLBACK;
     P_RESP_CODE := '69';
     P_RESP_ID   := '69'; --Added for VMS-8018
     P_Resp_Msg  := 'Problem while inserting data into transaction log  ' ||
                 SUBSTR(SQLERRM, 1, 300);
  END;

      Begin
    sp_autonomous_preauth_logclear(v_auth_id);
    exception
    When others then
    null;
    End;

  IF p_req_resp_code >= 100  THEN 
    P_Iso_Respcde :='00';
    P_RESP_CODE :='000';
  END IF;
    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;

    P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 4: ' || v_mili ;
     P_RESP_TIME := v_mili;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    P_RESP_CODE := '69'; 
    P_RESP_ID   := '69'; --Added for VMS-8018
    P_RESP_MSG  := 'Main exception from  authorization ' ||
                Substr(Sqlerrm, 1, 300);
END;
/
show error