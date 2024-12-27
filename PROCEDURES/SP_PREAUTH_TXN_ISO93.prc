create or replace PROCEDURE                                  vmscms.SP_PREAUTH_TXN_ISO93 (P_INST_CODE         IN NUMBER,
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
                                         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                         P_MERC_ID            IN VARCHAR2,
                                         P_COUNTRY_CODE       IN VARCHAR2,
                                         P_NETWORK_ID         IN VARCHAR2,
                                         P_INTERCHANGE_FEEAMT IN NUMBER,
                                         P_MERCHANT_ZIP       IN VARCHAR2,
                                         /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                         P_POS_VERFICATION   IN VARCHAR2, --Added by Deepa
                                         P_INTERNATIONAL_IND IN VARCHAR2,
                                         P_MCC_CODE          IN VARCHAR2,  -- Added for FSS-781
                                         p_partial_preauth_ind   IN       VARCHAR2, -- Added for OLS
                                         P_ZIP_CODE            IN VARCHAR2, --  Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013
                                         P_ADDRVERIFY_FLAG     IN VARCHAR2, --  Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013
                                         P_NETWORKID_SWITCH    IN VARCHAR2, --Added on 20130626 for the Mantis ID 11344
                                         P_NETWORKID_ACQUIRER    IN VARCHAR2,-- Added on 20130626 for the Mantis ID 11344
                                         p_network_setl_date    IN  VARCHAR2, --Added on 20130626 for the Mantis ID 11123
                                         --Sn added by Pankaj S. for Mantis ID-11540
                                         P_MERCHANT_NAME       IN VARCHAR2,
                                         P_MERCHANT_CITY       IN VARCHAR2,
                                         --En added by Pankaj S. for Mantis ID-11540
                                         P_CVV_VERIFICATIONTYPE IN  VARCHAR2, --Added on 17.07.2013 for the Mantis ID 11611
                                          P_ONEDOLLAR_PREAUTH    IN VARCHAR2, ----Added for MVHOST-926 on 19-May-2014
                                         P_PULSE_TRANSACTIONID        IN       VARCHAR2,--Added for MVHOST 926
                                         P_VISA_TRANSACTIONID          IN       VARCHAR2,--Added for MVHOST 926
                                         P_MC_TRACEID                 IN       VARCHAR2,--Added for MVHOST 926
                                         P_CARDVERIFICATION_RESULT      IN       VARCHAR2,--Added for MVHOST 926
                                         P_AUTH_ID           OUT VARCHAR2,
                                         P_RESP_CODE         OUT VARCHAR2,
                                         P_RESP_MSG          OUT VARCHAR2,
                                         p_ledger_bal         OUT      VARCHAR2,  -- Added for OLS
                                         P_CAPTURE_DATE      OUT DATE,
                                         p_partialauth_amount OUT      VARCHAR2, -- Added for OLS
                                         P_ADDR_VERFY_RESPONSE OUT VARCHAR2 , --  Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013
                                         P_ISO_RESPCDE        OUT VARCHAR2  --Added on 17.07.2013 for the Mantis ID 11612
                                         ,P_INCR_INDICATOR    IN  VARCHAR2
                                         ,P_MERC_CNTRYCODE     IN       VARCHAR2 DEFAULT NULL
                     ,P_RESP_TIME OUT VARCHAR2
                                         ,P_RESPTIME_DETAIL OUT VARCHAR2
                      ,P_MS_PYMNT_TYPE      in     varchar2 default null
                                         ,P_MS_PYMNT_DESC      in      varchar2  default null
                                         ,P_cust_addr      IN VARCHAR2   DEFAULT NULL ,
                                         p_hostfloorlmt_flag  IN VARCHAR2  DEFAULT NULL
                                         ,p_product_type IN VARCHAR2 default 'O'
                                         ,p_expiry_date_check IN VARCHAR2 default 'Y'
										 ,p_surchrg_ind   IN VARCHAR2 DEFAULT '2' --Added for VMS-5856
                                         ,p_expected_clearing_date           IN VARCHAR2 --Added for VMS_9194
                                         ,p_marketspecific_dataidentifier    IN VARCHAR2 --Added for VMS_9194
                                         ,p_resp_id   OUT VARCHAR2 --Added for sending to FSS (VMS-8018)
                                         ,p_card_present_indicator in varchar2 default null --Added for VMS_9272
                                         ) IS
  /************************************************************************************************************

     * Modified By      : Saravanakumar
     * Modified Date    : 09/01/2013
     * Modified Reason  : To include the changes which were released in 19.8
     * Reviewer         : Dhiraj
     * Reviewed Date    : 09/01/2013
     * Release Number   : CMS3.5.1_RI0023_B0011

     * Modified By      : Sagar
     * Modified Date    : 25-Feb-2013
     * Modified For     : FSS-781
                          Defect 10406
     * Modified Reason  : 1) Added input parameter P_MCC_CODE FSS-781
                          2) To insert input MCC code into CMS_PREAUTH_TRANSACTION and TRANSACTIONLOG table FSS-781
                          3) To ignore hold days from Elan when v_hold_days = 0 FSS-781
                          4) Commented Max card balance check as per defect 10406
     * Release Number   : CMS3.5.1_RI0023.2_B0011

     * Modified By      :  Deepa T
     * Modified Date    :  06-Mar-2013
     * Modified For     :  Mantis ID- 10538
     * Modified Reason  :  To log the amount for AVS declined transactions.If the amount logged it will be displaed in CSR
     * Reviewer         : Dhiraj
     * Reviewed Date    : 06-Mar-2013
     * Release Number   : CMS3.5.1_RI0023.2_B0015

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

     * Modified By      : MageshKumar.S
     * Modified Date    : 11-May-2013
     * Modified Reason  : OLS changes for AVS and ZIP validation changes
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : RI0024.1.1_B0001

     * Modified by      : DHINAKARAN B
     * Modified Date    : 18-Jun-13
     * Modified For     : MANTIS ID-11278
     * Modified reason  : Internation Transaction is allowed even if the International transaction is not enabled for the BIN
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     : RI0024.1.5_B0001

     * Modified by      : Ravi N
     * Modified for     : Mantis ID 0011282
     * Modified Reason  : Correction of Insufficient balance spelling mistake
     * Modified Date    : 20-Jun-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 20-Jun-2013
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

     * Modified by      : Pankaj S.
     * Modified for     : Mantis ID 0011540
     * Modified Reason  : Merchant related information (like name, city and state) logging
                          in transactionlog and statements log tables.
     * Modified Date    : 09_July_2013
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : RI0024.3_B0003

     * Modified by      : Pankaj S.
     * Modified for     : Mantis ID 0011447
     * Modified Reason  : Medagate : PERMRULE_VERIFY_FLAG not updated for SAF advices (failure transactions)
     * Modified Date    : 10_July_2013
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : RI0024.3_B0003

     * Modified by      : Sachin P.
     * Modified for     : Mantis ID -11611,11612
     * Modified Reason  :11611-Input parameters needs to be included for the CVV verification
                          We are doing and it needs to be logged in transactionlog
                         11612-Output parameter needs to be included to return the cms_iso_respcde of cms_response_mast
     * Modified Date    : 17-Jul-2013
     * Reviewer         : Sagarm
     * Reviewed Date    : 22.07.2013
     * Build Number     : RI0024.3_B0005

     * Modified by      : S.Ramkumar
     * Modified for     : FSS - 1278
     * Modified Reason  : VMS to send Partial Preauth Response for all preauth with MCC - 5542
     * Modified Date    : 12-Aug-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 13-Aug-2013
     * Build Number     : RI0024.3.1_B0005

     * Modified by      : S.Ramkumar
     * Modified for     : To send approved amount for all approved transactions of MCC-5542
     * Modified Reason  : VMS to send partial amount in response since 5542 preauth is considered as partial preauth
     * Modified Date    : 16-Aug-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 13-Aug-2013
     * Build Number     : RI0024.3.2_B0001

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

     * Modified by      : Sagar M.
     * Modified for     : 0012198
     * Modified Reason  : To reject duplicate STAN transaction
     * Modified Date    : 29-Aug-2013
     * Reviewer         : Dhiarj
     * Reviewed Date    : 29-Aug-2013
     * Build Number     : RI0024.3.5_B0001

     * Modified by       :  Pankaj S.
     * Modified for      :  MVCSD-4445/MVHOST-363
     * Modified Reason   :  Modified for 3 decimal amount issue
     * Modified Date     :  03-Sep-2013
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  03-Sep-2013
     * Build Number      :  RI0024.3.6_B0002

     * Modified by      :  Siva Kumar M
     * Modified Reason  :  Defect Id: 12166
     * Modified Date    :  12-Sept-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  12-Sept-2013
     * Build Number     :  RI0024.4_B0011

     * Modified by       :  Sachin P.
     * Modified for      :  FSS-1313 (1.7.3.8 changes merged)
     * Modified Reason   :  PULSE Transaction logic based on partial indicator
     * Modified Date     :  17-Sep-2013
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  17-Sep-2013
     * Build Number      :  RI0024.4.3_B0001

     * Modified by       :  Pankaj S.
     * Modified Reason   :  Enabling Limit configuration and validation for Preauth(1.7.3.9 changes integrate)
     * Modified Date     :  23-Oct-2013
     * Reviewer          :  Dhiraj
     * Reviewed Date     :
     * Build Number      : RI0024.5.2_B0001

      * Modified by      : Sachin P
      * Modified for     : 12087 ,12568
      * Modified Reason  : 12087:Fee amount not deducted from ledger balance in transaction log table
                           12568:Purchase Transaction with Partial Indiator, Fee and P-4 >
                           Account Bal. is failing with Insufficient Balance.
      * Modified Date    : 29.Oct.2013
      * Reviewer         :
      * Reviewed Date    :
      * Build Number     : RI0024.6_B0004

       * Modified by      : Deepa T
      * Modified for     : 12929,12928
      * Modified Reason  : 12928:If we are mapping POS preauth transaction fee for a particular MCC then fee is not debited.
                            Only if the MCC is selected as ALL then fee is debited.
                           12929:If the Preauth with 20% hold amount with sufficient balance then P4 is not responded with 20% hold amount.
                           We are sending the transaction amount received in P-4
      * Modified Date    : 04.Nov.2013
      * Reviewer         : Saravanakumar
      * Reviewed Date    : 04.Nov.2013
      * Build Number     : RI0024.6_B0006

     * Modified by      : Ramesh
     * Modified for     : FSS-1388
     * Modified Reason  : AVS ZIP code validation changes (It will match first 5 digits of zip code if both txn and customer zipcode is in numeric.)
     * Modified Date    : 20.Dec.2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 23.Dec.2013
     * Build Number     : RI0024.6.3_B0006

     * Modified by      : Ramesh
     * Modified for     : Defect id :13297 and 13296
     * Modified Reason  : The Address Verification Indicator Occurs as N instead of W   and    Zip code validation for Elan Transaction: Not display the address verification indicat
     * Modified Date    : 26.Dec.2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 26.Dec.2013
     * Build Number     : RI0024.6.3_B0007

     * Modified by      : DHINAKARAN B
     * Modified for     : MANTIS ID-12953
     * Modified Reason  : Support the Cash Disbursement Preauth transaction for the with message type 1100 and MCC-6010
     * Modified Date    : 07-jan-14
     * Reviewer         : Dhiraj
     * Reviewed Date    : RI0027_B0002

     * Modified by       :  Pankaj S.
     * Modified Reason   :  3 decimal amount issue
     * Modified Date     :  16-Jan-2014
     * Reviewer          :  Dhiraj
     * Reviewed Date     :
     * Build Number      :

     * Modified by      : DHINAKARAN B
     * Modified for     : MANTIS ID-13467
     * Modified Reason  : Implement the 1.7.6.5 changes on 2.0 to Logging the Delivery channel and txn code in CMS_PREAUTH_TRANS_HIST table
     * Modified Date    : 22-jan-14
     * Reviewer         :
     * Reviewed Date    :

     * Modified By      : MageshKumar S
     * Modified Date    : 28-Jan-2014
     * Modified for     : MVCSD-4471
     * Modified Reason  : Narration change for FEE amount
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     : RI0027.1_B0001

     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 11-Feb-2014
     * Modified for     : MANTIS ID-13135
     * Modified Reason  : To log address verify indicator in transactionlog table.
     * Reviewer         : DHIRAJ
     * Reviewed Date    :
     * Build Number     : RI0027.1_B0001

     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 12-Feb-2014
     * Modified for     : MANTIS ID-13645
     * Modified Reason  : To log the last 4 digit of pan  number in cms_preauth_trans_hist table.
     * Reviewer         : DHIRAJ
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

      * Modified By      : Abdul Hameed M.A
     * Modified Date    : 10-Apr-2014
     * Modified for     : Mantis ID 14132
     * Modified Reason  : MCC code is passing to the SP_STATUS_CHECK_GPR for approving the txn with mcc code 6010 is configured as approved.
     * Reviewer         : spankaj
     * Reviewed Date    : 14-April-2014
     * Build Number     : RI0027.2_B0002

     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 21-Apr-2014
     * Modified for     : FSS-1534
     * Reviewer         : spankaj
     * Build Number     : RI0027.2.1_B0003

     * Modified by       :  Abdul Hameed M.A
     * Modified Reason   :  To hold the completion fee at the time of preauth
     * Modified for      :  FSS 837
     * Modified Date     :  27-JUNE-2014
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3_B0001

     * Modified by       : Dhinakaran B
     * Modified for      : VISA Certtification Changes integration in 2.3
     * Modified Date     : 08-JUL-2014
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3_B0002

     * Modified by       :  Abdul Hameed M.A
     * Modified Reason   : Pre-Auth Transaction holding the Pre-Auth Fees second time from the account balance.
     * Modified for      : Mantis ID 15590
     * Modified Date     : 16-july-2014
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3_B0004

      * Modified by       :  Abdul Hameed M.A
     * Modified Reason   : Account balance is wrongly received in DE 54
     * Modified for      : Mantis ID 15604
     * Modified Date     : 21-july-2014
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3_B0005

     * Modified by       : MageshKumar S.
     * Modified Date     : 25-July-14
     * Modified For      : FWR-48
     * Modified reason   : GL Mapping removal changes
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3.1_B0001

      * Modified by       : Saravanakumar
     * Modified Date     : 25-Sep-2014
     * Modified For      : Performance changes
     * Reviewer          : Spankaj
     * Build Number      : RI0027.2.6.1_B0002

      * Modified Date    : 29-SEP-2014
       * Modified By      : Abdul Hameed M.A
       * Modified for     : FWR 70
       * Reviewer        :  spankaj
       * Release Number   : RI0027.4_B0002

     * Modified Date    : 18-Nov2014
     * Modified By      : Dhinakaran B
     * Modified for     : Incremental Preauth
     * Reviewer         :
     * Release Number   :

     * Modified Date    : 20-Nov2014
     * Modified By      : Dhinakaran B
     * Modified for     : Incremental Preauth Review changes
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 21-Nov-2014
     * Release Number   : RI0027.4.2.2_B0003

     * Modified Date    : 11-Dec-2014
     * Modified By      : Sai Prasad
     * Modified for     : VISA AVS CHANGES
     * Reviewer         : Spankaj
     * Release Number   : RI0027.4.2.3

     * Modified Date    : 11-DEC-2014
     * Modified By      : MageshKumar S
     * Modified for     : OLS Perf Improvement - Mantis:15855
     * Reviewer         : spankaj
     * Release Number   : RI0027.4.2.4

     * Modified Date    : 30-DEC-2014
     * Modified By      : Dhinakaran B
     * Modified for     : MVHOST-1080/To Log the Merchant id & CountryCode
     * Reviewer         : PANKAJ S.
     * Build Number     : RI0027.5_B0005

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

        * Modified By      :  Abdul Hameed M.A
     * Modified For     :  DFCTNM-4
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
     * Modified For     :   FSS-3486
     * Modified Date    :  21-May-2015
     * Reviewer         :  Saravana Kumar M
     * Build Number     : VMSGPRHOSTCSD_3.0.2_B0001

     * Modified By      :  Siva Kumar m
     * Modified For     :   FSS-3490/MVCSD-5617
     * Modified Date    :  26-May-2015
     * Reviewer         :  Saravana Kumar A
     * Build Number     : VMSGPRHOSTCSD_3.0.3_B0001

     * Modified By      :  MageshKumar S
     * Modified For     :  MCC-5542 Changes
     * Modified Date    :  21-July-2015
     * Reviewer         :  PANKAJ S
     * Build Number     :  VMSGPRHOSTCSD_3.0.4_B0002

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

     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 24-DEC-2015
     * Modified for     : MVCAN-1342
     * Reviewer         : Spankaj
     * Release Number   : VMSGPRHOST_3.3_B0001

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

    * Modified By      :  MageshKumar S
    * Modified For     :  FSS-4363 Changes
    * Modified Date    :  21-MAY-2016
    * Reviewer         :  Saravanan/Pankaj
    * Build Number     :  VMSGPRHOSTCSD_4.1_B0001
         * Modified by      : Saravanakumar
    * Modified Date    : 20-Mar-17
    * Modified For     : FSS-4647
    * Modified reason  : Redemption Delay Changes
    * Reviewer         : Pankaj S.
    * Build Number     : VMSGPRHOST_17.3

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

    * Modified By      :  MageshKumar S
    * Modified For     :  FSS-5252
    * Modified Date    :  07-SEP-2017
    * Reviewer         :  Saravanan/Pankaj
    * Build Number     :  VMSGPRHOSTCSD17.05.05_B0001

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

	* Modified by      : Vini
    * Modified Date    : 18-Jan-2018
    * Modified For     : VMS-162
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOSTCSD_18.01

     * Modified By      : DHINAKARAN B
     * Modified Date    : 15-NOV-2018
     * Purpose          : VMS-619 (RULE)
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : R08


     * Modified By      : DHINAKARAN B
     * Modified Date    : 25-FEB-2020
     * Purpose          : VMS-1985
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : R27_build_1

	   * Modified By      : Karthick/Jey
	   * Modified Date    : 05-19-2022
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
    
    * Modified By      : Mohan E.
    * Modified Date    : 27-AUG-2024
    * Purpose          : VMS_9194 Visa (1.4) Introduction of the Extended Authorization and Expected Clearing Date
    * Reviewer         : Pankaj S./Venkat
    * Release Number   : R104B3
	
	* Modified By      : Mohan E.
    * Modified Date    : 29-OCT-2024
    * Purpose          : VMS-9272 MCC Pre-Auths: Card Not Present (CNP) Rule Subset Creation
    * Reviewer         : Venkat
    * Release Number   : R105B3
    
    * Modified By      : Mohan E.
    * Modified Date    : 13-NOV-2024
    * Purpose          : VMS_9340 Visa (1.4) Introduction of the Extended Authorization and Expected Clearing Date
    * Reviewer         : Venkat
    * Release Number   : R106B1

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
  V_ATM_USAGEAMNT             CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_AMT%TYPE;
  V_POS_USAGEAMNT             CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_AMT%TYPE;
  V_ATM_USAGELIMIT            CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_LIMIT%TYPE;
  V_POS_USAGELIMIT            CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_LIMIT%TYPE;
  V_PREAUTH_DATE              DATE;
  V_PREAUTH_HOLD              VARCHAR2(1);
  V_PREAUTH_PERIOD            NUMBER;
  V_PREAUTH_USAGE_LIMIT       NUMBER;
  V_CARD_ACCT_NO              VARCHAR2(20);
  V_HOLD_AMOUNT               NUMBER;
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
  /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
  V_HOLD_DAYS   CMS_TXNCODE_RULE.CTR_HOLD_DAYS%TYPE;
  P_HOLD_AMOUNT NUMBER;
  -- start Added on 06112012
VT_PREAUTH_HOLD        VARCHAR2(1);
VT_PREAUTH_PERIOD      NUMBER;
vp_preauth_exp_period cms_prod_mast.cpm_pre_auth_exp_date%TYPE ;
VP_PREAUTH_HOLD        VARCHAR2(1);
VP_PREAUTH_PERIOD      NUMBER;
vi_preauth_exp_period  cms_inst_param.cip_param_value%TYPE ;
VI_PREAUTH_HOLD        VARCHAR2(1);
VI_PREAUTH_PERIOD      NUMBER;
-- end  Added on 06112012
  /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
  --Added by Deepa On June 19 2012 for Fees Changes
  V_FEEAMNT_TYPE CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
  V_PER_FEES     CMS_FEE_MAST.CFM_PER_FEES%TYPE;
  V_FLAT_FEES    CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_CLAWBACK     CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
  V_FEE_PLAN     CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;
  V_FREETXN_EXCEED VARCHAR2(1); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_DURATION VARCHAR2(20); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_FEEATTACH_TYPE  VARCHAR2(2); -- Added by Trivikram on 5th Sept 2012
  --Sn added by Pankaj S. for 10871
  v_acct_type   cms_acct_mast.cam_type_code%TYPE;
  v_timestamp   timestamp(3);
  --En added by Pankaj S. for 10871
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

   --Sn Added by Pankaj S. for enabling limit validation
   v_prfl_flag             cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_prfl_code             cms_appl_pan.cap_prfl_code%TYPE;
   v_comb_hash             pkg_limits_check.type_hash;
   --En Added by Pankaj S. for enabling limit validation
   V_TRAN_AMT_NOHOLD           NUMBER;  --Added for Mantis ID-12929
   V_ADJUSTMENT_FLAG        CMS_TRANSACTION_MAST.CTM_ADJUSTMENT_FLAG%TYPE;
   V_FEE_DESC         cms_fee_mast.cfm_fee_desc%TYPE;  -- Added for MVCSD-4471

   -- Sn Added for FSS 837
   v_completion_txn_code VARCHAR2(2);
   v_comp_fee_code             cms_fee_mast.cfm_fee_code%TYPE;
   v_comp_fee_crgl_catg        cms_prodcattype_fees.cpf_crgl_catg%TYPE;
   v_comp_fee_crgl_code        cms_prodcattype_fees.cpf_crgl_code%TYPE;
   v_comp_fee_crsubgl_code     cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
   v_comp_fee_cracct_no        cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_comp_fee_drgl_catg        cms_prodcattype_fees.cpf_drgl_catg%TYPE;
   v_comp_fee_drgl_code        cms_prodcattype_fees.cpf_drgl_code%TYPE;
   v_comp_fee_drsubgl_code     cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
   v_comp_fee_dracct_no        cms_prodcattype_fees.cpf_dracct_no%TYPE;
   v_comp_servicetax_percent   cms_inst_param.cip_param_value%TYPE;
   v_comp_cess_percent         cms_inst_param.cip_param_value%TYPE;
   v_comp_servicetax_amount    NUMBER;
   v_comp_cess_amount          NUMBER;
   v_comp_st_calc_flag         cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
   v_comp_cess_calc_flag       cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
   v_comp_st_cracct_no         cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
   v_comp_st_dracct_no         cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
   v_comp_cess_cracct_no       cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
   v_comp_cess_dracct_no       cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
   v_comp_waiv_percnt          cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
   v_comp_feeamnt_type         cms_fee_mast.cfm_feeamnt_type%TYPE;
   v_comp_per_fees             cms_fee_mast.cfm_per_fees%TYPE;
   v_comp_flat_fees            cms_fee_mast.cfm_fee_amt%TYPE;
   v_comp_clawback             cms_fee_mast.cfm_clawback_flag%TYPE;
   v_comp_fee_plan             cms_fee_feeplan.cff_fee_plan%TYPE;
   v_comp_freetxn_exceed       VARCHAR2 (1);
   v_comp_duration             VARCHAR2 (20);
   v_comp_feeattach_type       VARCHAR2 (2);
   v_comp_fee_amt              NUMBER;
   v_comp_err_waiv             VARCHAR2 (300);
   V_COMP_FEE_DESC             cms_fee_mast.cfm_fee_desc%TYPE;
   v_comp_error                VARCHAR2 (500);
   v_comp_total_fee            NUMBER:=0;
   v_tot_hold_amt              NUMBER;
   --En Added for FSS 837

   v_zip_code_trimmed VARCHAR2(10);--Added for 15165

   --SN Added for FWR 70
   v_removespacenum_txn  VARCHAR2 (10);
V_REMOVESPACENUM_CUST   VARCHAR2 (10);
V_REMOVESPACECHAR_TXN   varchar2 (10);
V_REMOVESPACECHAR_CUST   VARCHAR2 (10);
--EN Added for FWR 70
 v_comp_fee_hold             NUMBER;
 v_preauth_amt               cms_preauth_transaction.cpt_totalhold_amt%TYPE default '0';  --default value added for FSS-3486
 v_completion_fee            cms_preauth_transaction.cpt_completion_fee%TYPE;
 v_comp_hold_fee_diff        NUMBER;
 v_comp_hold_cr_flag         VARCHAR2 (1);
 v_complfee_increment_type   VARCHAR2 (1);
 v_incr_indicator            VARCHAR2(1);
 V_TRANSACTIONcomp_FLAG  cms_preauth_transaction.CPT_TRANSACTION_FLAG%TYPE;
 v_addrverification_flag       transactionlog.ADDR_VERIFY_INDICATOR%TYPE;

 V_REPEAT_MSGTYPE           TRANSACTIONLOG.MSGTYPE%TYPE DEFAULT '1101';
 V_STAN_CHECKFLAG           varchar2(1);
  V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE;
  V_ADDR_ONE CMS_ADDR_MAST.CAM_ADD_ONE%type;
  V_ADDR_TWO CMS_ADDR_MAST.CAM_ADD_TWO%type;
  V_REMOVESPACE_ADDRCUST     VARCHAR2(100);
  V_REMOVESPACE_ADDRTXN      VARCHAR2(20);
  V_REMOVESPACECHAR_ADDRCUST VARCHAR2(100);
  V_REMOVESPACECHAR_ADDRTXN  VARCHAR2(20);
  V_ADDR_VERFY               number;
  V_REMOVESPACECHAR_ADDRONECUST   varchar2(100);
  V_MS_PYMNT_TYPE CMS_PAYMENT_TYPE.cpt_payment_type%type;
  v_start_time timestamp;
  v_mili VARCHAR2(100);
  V_PREAUTH_PRODFLAG         CMS_PRODUCT_PARAM.CPP_PREAUTH_PRODFLAG%TYPE; --Added for MCC-5542 changes of 3.0.4 release
  V_PREAUTH_NETWORKFLAG         CMS_PRODUCT_PARAM.CPP_HOSTFLOOR_NETWORK%TYPE; --Added for FSS-4363 Changes of 4.1 release
  v_redemption_delay_flag cms_acct_mast.cam_redemption_delay_flag%type;
  v_delayed_amount number:=0;
  v_comlfree_flag varchar2(1);
  v_alpha_cntry_code gen_cntry_mast.gcm_alpha_cntry_code%TYPE;
  v_feature_value cms_inst_param.cip_param_value%TYPE;

  v_Retperiod  date;  --Added for VMS-5739/FSP-991
  v_Retdate  date; --Added for VMS-5739/FSP-991
  
  v_expected_clearing_date  date;           --Added for VMS_9194
  v_extended_auth_date      date;           --Added for VMS_9194
  v_param_value           varchar2(20);     --Added for VMS_9194
  v_extended_auth_identifier varchar2(20) := p_marketspecific_dataidentifier;  --Added for VMS_9194

BEGIN
v_start_time := systimestamp;
  SAVEPOINT V_AUTH_SAVEPOINT;
  V_RESP_CDE := '1';
  P_RESP_MSG := 'OK';
  V_TRAN_AMT := P_TXN_AMT;--modified by Deepa on Mar-06-2013
  v_partial_appr := 'N';
  --Modified to log the amount for the declined transactions of preauth also.As the AVS declined transaction was not displayed in CSR.
    V_TIMESTAMP:=systimestamp;
     V_MS_PYMNT_TYPE:=P_MS_PYMNT_TYPE;
  BEGIN
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

    --Moved by Saravanakumar on 25-Sep-2014
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
           CAP_CUST_CODE ,       -- Added on 11-May-2013 for AVS and ZIP validation changes
           cap_prfl_code  --Added by Pankaj S. for enabling limit validation
       INTO V_PROD_CODE,
           V_PROD_CATTYPE,
           V_EXPRY_DATE,
           V_APPLPAN_CARDSTAT,
           V_ATMONLINE_LIMIT,
           V_ATMONLINE_LIMIT,
           V_PROXUNUMBER,
           V_ACCT_NUMBER,
           V_CAP_CUST_CODE,      -- Added on 11-May-2013 for AVS and ZIP validation changes
           v_prfl_code  --Added by Pankaj S. for enabling limit validation
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

    IF p_incr_indicator = 'I' THEN
     v_incr_indicator  :='1';
    ELSE
      v_incr_indicator  :='0';
    END IF;

--Commended by Saravanakumar on 25-Sep-2014
    --Sn find narration
   /* BEGIN
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

    --Sn generate auth id
    BEGIN

     --     SELECT TO_CHAR(SYSDATE, 'YYYYMMDD')  || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
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

--Commended by Saravanakumar on 25-Sep-2014
    --SN CHECK INST CODE
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
           ctm_prfl_flag  --Added by Pankaj S. for enabling limit validation
            ,CTM_ADJUSTMENT_FLAG,
            CTM_TRAN_DESC--Added by Saravanakumar on 25-Sep-2014
       INTO V_DR_CR_FLAG,
           V_OUTPUT_TYPE,
           V_TXN_TYPE,
           V_TRAN_TYPE,
           V_TRAN_PREAUTH_FLAG,
           v_prfl_flag  --Added by Pankaj S. for enabling limit validation
           ,V_ADJUSTMENT_FLAG,
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
   if V_MS_PYMNT_TYPE is not null then
  -- V_TRANS_DESC:='MoneySend'||' '||V_TRANS_DESC;
   V_TRANS_DESC:='MoneySend Funding Auth';
   if V_MS_PYMNT_TYPE='P' then
   V_MS_PYMNT_TYPE:=null;
   end if;

   end if;


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



    /* ADDED FOR FSS-2065
      -----------------------------------------
      --SN: Added for Duplicate STAN check 0012198
      -----------------------------------------

    IF v_incr_indicator <> '1' THEN

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

    END IF;
      -----------------------------------------
      --SN: Added for Duplicate STAN check 0012198
      -----------------------------------------
    */

    --Sn Duplicate RRN Check
/*    BEGIN
     SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM TRANSACTIONLOG
      WHERE RRN = P_RRN AND --Changed for admin dr cr.
           BUSINESS_DATE = P_TRAN_DATE AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; --Added by ramkumar.Mk on 25 march 2012
     IF V_RRN_COUNT > 0 THEN
       V_RESP_CDE := '22';
       V_ERR_MSG  := 'Duplicate RRN from the Terminal' || P_TERM_ID || 'on' ||
                  P_TRAN_DATE;
       RAISE EXP_REJECT_RECORD;
     END IF;
     EXCEPTION--Added Exception by Arunprasath on 25 june 2013
     WHEN EXP_REJECT_RECORD THEN
     RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting RRN ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;
    END;
*/

-- MODIFIED BY ABDUL HAMEED M.A ON 06-03-2014
 /*BEGIN
      sp_dup_rrn_check (v_hash_pan, p_rrn, p_tran_date, p_delivery_channel, p_msg, p_txn_code, v_err_msg,v_incr_indicator );
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
    END;*/ --OLS Perf Improvement
    --En get date

    --Check for Duplicate rrn for Pre-Auth if pre-auth is expire or valid flag is N
    --checking for inccremental pre-auth

/*    --Sn Getting BIN Level Configuration details

    BEGIN

     SELECT CBL_INTERNATIONAL_CHECK --, CBL_ADDR_VER_CHECK
       INTO V_INTERNATIONAL_IND -- , V_ADDRVRIFY_FLAG
       FROM CMS_BIN_LEVEL_CONFIG
      WHERE CBL_INST_BIN = SUBSTR(P_CARD_NO, 1, 6) AND
           CBL_INST_CODE = P_INST_CODE;

    EXCEPTION
     WHEN NO_DATA_FOUND THEN

       V_INTERNATIONAL_IND := 'Y';
--       V_ADDRVRIFY_FLAG    := 'Y';

     WHEN OTHERS THEN

       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while seelcting BIN level Configuration' || SUBSTR (SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

    END;

    --En Getting BIN Level Configuration details
*/

    BEGIN

    SELECT  CPC_ADDR_VERIFICATION_CHECK,
            CPC_INTERNATIONAL_CHECK,
            CPC_ENCRYPT_ENABLE,
            NVL(CPC_ADDR_VERIFICATION_RESPONSE, 'U')
       INTO  V_ADDRVRIFY_FLAG,
             V_INTERNATIONAL_IND,
             V_ENCRYPT_ENABLE,
             V_ADDRVERIFY_RESP
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

    --En Address Verificationflag check based on BIN level configuration

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

    --Sn Added for MCC-5542 Changes of 3.0.4 release
     BEGIN
    SELECT CPP_PREAUTH_PRODFLAG,CPP_HOSTFLOOR_NETWORK --Added for FSS-4363 Changes
      INTO V_PREAUTH_PRODFLAG,V_PREAUTH_NETWORKFLAG
      FROM CMS_PRODUCT_PARAM
     WHERE CPP_INST_CODE = P_INST_CODE AND CPP_PROD_CODE = V_PROD_CODE;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
        V_RESP_CDE := '21';
        V_ERR_MSG := 'Product Details not Found in product param table';
        RAISE EXP_REJECT_RECORD;
     WHEN OTHERS  THEN
        V_RESP_CDE := '21';
        V_ERR_MSG :='Error while selecting CPP_PREAUTH_PRODFLAG  ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
   END;
   --En Added for MCC-5542 Changes of 3.0.4 release

     BEGIN          -- Query added for OLS changes

         SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO,
                cam_type_code,nvl(cam_redemption_delay_flag,'N') --added by Pankaj S. for 10871
           INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO,
                v_acct_type,v_redemption_delay_flag --added by Pankaj S. for 10871
           FROM CMS_ACCT_MAST
          WHERE CAM_ACCT_NO =V_ACCT_NUMBER--Modified by Saravanakumar on 25-Sep-2014
               /*(SELECT CAP_ACCT_NO
                 FROM CMS_APPL_PAN
                WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
                     CAP_INST_CODE = P_INST_CODE) */AND
               CAM_INST_CODE = P_INST_CODE;

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
       END;
        -- Query added for OLS changes

       IF v_redemption_delay_flag = 'Y'
       THEN
          vmsredemptiondelay.check_delayed_load (v_acct_number,
                                                 v_delayed_amount,
                                                 v_err_msg);

          IF v_err_msg <> 'OK'
          THEN
             RAISE exp_reject_record;
          END IF;

          IF v_delayed_amount > 0
          THEN
             v_acc_bal := v_acct_balance - v_delayed_amount;
          END IF;
       END IF;

    --Sn find the tran amt
    IF ((V_TRAN_TYPE = 'F') OR (V_TRAN_PREAUTH_FLAG = 'Y')) THEN
     IF (P_TXN_AMT >= 0) THEN
       --V_TRAN_AMT := P_TXN_AMT;--Commented by Deepa on Mar-06-2013 to log the amount for AVS declined transactions also.

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

           IF TO_NUMBER (p_partial_preauth_ind) = 1 -- If condition added for OLS changes
           THEN
              /* Start Added by Dhiraj G on 30112012 for Account Balance Issue  */
              IF v_acc_bal <= 0
              THEN
                 v_resp_cde := '15';
                 v_err_msg :=
                             'Account Balance is Zero or Less Than Zero ';
                 -- || V_HASH_PAN;                              --Commented on 02-Jan-2013 for Defect 9770
                 RAISE exp_reject_record;
              END IF;

              /* End Added by Dhiraj G on 30112012 for Account Balance Issuence   */
              IF v_tran_amt > v_acc_bal
              THEN
                 v_tran_amt := v_acc_bal;
                 p_partialauth_amount := v_tran_amt;
                 v_partial_appr := 'Y';
              -- Added by Trivikram on 02/mar/2013 for Partial Preauth Approve Respose ID
              ELSE
                 --v_tran_amt := p_txn_amt;  --Commented by Pankaj S. for 3 decimal places amount issue

                --SN VMS to approve all preauth transactions with MCCode - 5542 transactions as partially approved    FSS - 1278
                 IF P_MCC_CODE = '5542' AND UPPER (TRIM(p_networkid_switch)) <> 'PULSE'
                 THEN
                    -- Do not force the partial auth for AMEX unless the feature is disabled
                    IF UPPER(TRIM(p_networkid_switch)) = 'AMEX'
                    THEN
                       BEGIN
                          -- if not in the DB or null then assume it is enabled
                          SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
                            INTO v_feature_value
                            FROM vmscms.cms_inst_param
                           WHERE cip_inst_code = 1
                             AND cip_param_key = 'AMEX_5542_PREAUTH_FEATURE';
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              v_feature_value := 'Y';
                        END;
                        -- only do the partial auth if the feature is disabled
                        IF v_feature_value = 'N'
                        THEN
                           p_partialauth_amount := v_tran_amt;
                           v_partial_appr := 'Y';
                        END IF;
                    ELSE
                       p_partialauth_amount := v_tran_amt;
                       v_partial_appr := 'Y';
                    END IF;
                 END IF;


              END IF;

          ELSE -- IF PARTIAL PREAUTH INDR IS '0' --Sn added for Mcc-5542 Changes

             IF v_acc_bal <= 0 THEN

                 v_resp_cde := '15';
                 v_err_msg :='Account Balance is Zero or Less Than Zero ';
                 RAISE exp_reject_record;

             END IF;

              IF (UPPER (TRIM (p_networkid_switch)) = 'VISANET' OR UPPER (TRIM (p_networkid_switch)) = 'BANKNET'
			  OR UPPER (TRIM (p_networkid_switch)) = 'AMEX'
              OR UPPER (TRIM (p_networkid_switch)) = UPPER (TRIM (V_PREAUTH_NETWORKFLAG))) --Added for FSS-4363 Changes
              THEN

                IF P_MCC_CODE = '5542' THEN

                IF NVL(V_PREAUTH_PRODFLAG,'D') = 'E' THEN

                   V_RESP_CDE := '913';
                   V_ERR_MSG  := 'Partial Approval Indicator Not Provided By Merchant';
                   RAISE EXP_REJECT_RECORD;

                ELSE

                 IF v_tran_amt > v_acc_bal THEN

                   V_RESP_CDE := '15';
                   V_ERR_MSG  := 'Insufficient Balance ';
                   RAISE EXP_REJECT_RECORD;

                  ELSE

                  IF p_hostfloorlmt_flag = 'N' THEN
                      v_partial_appr := 'Y';
          END IF;
                     p_partialauth_amount := v_tran_amt;
                END IF;

                END IF;
                END IF;

           END IF;

         END IF; --En added for Mcc-5542 Changes

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



    --En find card detail

     --Sn Internation Flag check added for MANTIS ID-11278 on 18062013
    IF P_INTERNATIONAL_IND = '1' AND V_INTERNATIONAL_IND <> 'Y'  THEN

       V_RESP_CDE := '38';
       V_ERR_MSG  := 'INTERNATIONAL TRANSACTION NOT SUPPORTED';
       RAISE EXP_REJECT_RECORD;
    END IF;
    --End Sn Internation Flag check

      v_zip_code_trimmed:=TRIM(P_ZIP_CODE); --Added for 15165
    --St: Added for OLS  changes( AVS and ZIP validation changes) on 11/05/2013

     IF UPPER (TRIM (p_networkid_switch)) = 'VISANET' and
                                TRIM (p_addrverify_flag) IS NULL and TRIM (p_zip_code) IS NOT NULL  THEN
      v_addrverification_flag :='2';
      ELSE
      v_addrverification_flag :=p_addrverify_flag;
      END IF;

        IF V_ADDRVRIFY_FLAG = 'Y' AND v_addrverification_flag in('2','3') then

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
                WHERE CAM_INST_CODE = P_INST_CODE AND CAM_CUST_CODE = V_CAP_CUST_CODE
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
                    IF SUBSTR (v_zip_code_trimmed, 1, 5) = SUBSTR (v_zip_code, 1, 5) then -- Added on 20/12/13 for FSS-1388
                 P_ADDR_VERFY_RESPONSE := 'W';
                    else
                           P_ADDR_VERFY_RESPONSE := 'N';
                    end if;

                elsif v_txn_nonnumeric_chk <> '0' and v_cust_nonnumeric_chk = '0' then -- It Means txn zip code is aplhanumeric and cust zip code is numeric

                    if  v_zip_code_trimmed = v_zip_code then
                P_ADDR_VERFY_RESPONSE := 'W';
                    else
                          P_ADDR_VERFY_RESPONSE := 'N';
                    end if;

                elsif v_txn_nonnumeric_chk = '0' and v_cust_nonnumeric_chk <> '0' then -- It Means txn zip code is numeric and cust zip code is alphanumeric

                    SELECT REGEXP_REPLACE(v_zip_code,'([A-Z ,a-z ])', '') into v_numeric_zip FROM dual;

                    if  v_zip_code_trimmed = v_numeric_zip then

                P_ADDR_VERFY_RESPONSE := 'W';
                    else
                          P_ADDR_VERFY_RESPONSE := 'N';

                    end if;

                elsif v_txn_nonnumeric_chk <> '0' and v_cust_nonnumeric_chk <> '0' then -- It Means txn zip code and cust zip code is alphanumeric

                     v_inputzip_length := length(p_zip_code);

                     if v_inputzip_length = length(v_zip_code) then  -- both txn and cust zip length is equal

                         if  v_zip_code_trimmed = v_zip_code then

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
                            --en --Added for FWR 70
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

         IF v_addrverification_flag in('2','3') THEN

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
  IF V_ADDRVRIFY_FLAG = 'Y' then
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
    IF NOT (p_product_type='C' AND  p_expiry_date_check='N') THEN
    --- st Expiry date validation for ols changes
     BEGIN
     IF P_EXPRY_DATE <> TO_CHAR(V_EXPRY_DATE, 'YYMM') THEN
      --  V_RESP_CDE := '13';            commented for MVCSD-5617
       -- V_ERR_MSG  := 'EXPIRY DATE NOT EQUAL TO APPL EXPRY DATE ';
        V_RESP_CDE := '905';
        V_ERR_MSG  := 'Expiry Date not Matched ';

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

    --Sn GPR Card status check
  /*  BEGIN
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
                     P_POS_VERFICATION,   --Added IN Parameters in SP_STATUS_CHECK_GPR for pos sign indicator,international indicator,mcccode by Besky on 08-oct-12
                    -- NULL,
                   P_MCC_CODE,--Modified  on 10/04/2014 for 14132
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

    --Sn check for Preauth
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
                        -- P_COUNTRY_CODE,  modified for FSS-3490
                           P_MERC_CNTRYCODE,
                           P_HOLD_AMOUNT,
                           V_HOLD_DAYS,
                           V_RESP_CDE,
                           V_ERR_MSG,
                           v_alpha_cntry_code,
                           p_card_present_indicator);  --Added for VMS_9272

       /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
       IF (V_RESP_CDE <> '1' OR TRIM(V_ERR_MSG) <> 'OK') THEN
        --IF P_DELIVERY_CHANNEL IN ('01', '02') AND P_TXN_CODE = '11' THEN
          IF     P_DELIVERY_CHANNEL IN ('01', '02') AND V_TRAN_PREAUTH_FLAG = 'Y'
            AND V_ADJUSTMENT_FLAG = 'N' AND V_DR_CR_FLAG = 'NA' THEN
          IF P_HOLD_AMOUNT != NULL THEN
            V_TRAN_AMT := ROUND(P_HOLD_AMOUNT,2);  --ROUND added for 3 decimal amount issue
          ELSE
            V_TRAN_AMT := V_TRAN_AMT;
          END IF;

        END IF;

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

    --En check for preauth

    --SN - commented for fwr-48

    --Sn find function code attached to txn code
  /*  BEGIN
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

    --En find function code attached to txn code

    --EN - commented for fwr-48

    --Sn find prod code and card type and available balance for the card number
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO,
            cam_type_code --added by Pankaj S. for 10871
       INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO,
            v_acct_type  --added by Pankaj S. for 10871
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =V_ACCT_NUMBER--Modified by Saravanakumar on 25-Sep-2014
           /*(SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
                 CAP_INST_CODE = P_INST_CODE)*/ AND
           CAM_INST_CODE = P_INST_CODE
       FOR UPDATE; --SN:Added on 25-Jun-2013
        --FOR UPDATE NOWAIT;  --SN:COMMENTED for FSS-Preauth normal transaction details with same RRN - Response 89 instead of 22 - Resource busy on 25-Jun-2013 by Arunprasath
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

     IF v_delayed_amount > 0 THEN
          v_acct_balance := v_acc_bal;
     END IF;

    --En find prod code and card type for the card number

    --En Check PreAuth Completion txn

     --added for FSS-Preauth normal transaction details with same RRN - Response 89 instead of 22 - Resource busy on 24-Jun-2013 by Arunprasath
        --Sn Duplicate RRN Check
  /*  BEGIN
     SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM TRANSACTIONLOG
      WHERE RRN = P_RRN AND --Changed for admin dr cr.
           BUSINESS_DATE = P_TRAN_DATE AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; --Added by ramkumar.Mk on 25 march 2012
     IF V_RRN_COUNT > 0 THEN
       V_RESP_CDE := '22';
       V_ERR_MSG  := 'Duplicate RRN from the Terminal' || P_TERM_ID || 'on' ||
                  P_TRAN_DATE;
       RAISE EXP_REJECT_RECORD;
     END IF;
     EXCEPTION--Added Exception by Arunprasath on 25 june 2013
     WHEN EXP_REJECT_RECORD THEN
     RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting RRN ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;
    END;
    --En Duplicate RRN Check
   */

   -- MODIFIED BY ABDUL HAMEED M.A ON 06-03-2014
 BEGIN
    IF V_REPEAT_MSGTYPE = p_msg THEN
      sp_dup_rrn_check (v_hash_pan, p_rrn, p_tran_date, p_delivery_channel, p_msg, p_txn_code, v_err_msg,v_incr_indicator );
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
        --Sn Added for Concurrent Processsing Issue
    ------------------------------------------------------
    BEGIN

        SELECT NVL (cip_param_value, 'N')
        INTO v_stan_checkflag
        FROM cms_inst_param
        WHERE cip_inst_code = P_INST_CODE AND cip_param_key = 'PREAUTHSTANCHECK';
    EXCEPTION
    WHEN OTHERS THEN
      v_stan_checkflag :='N';
    END;


      select (extract(day from systimestamp - v_start_time) *86400+
    extract(hour from systimestamp - v_start_time) *3600+
    extract(minute from systimestamp - v_start_time) *60+
    extract(second from systimestamp - v_start_time) *1000) into v_mili from dual ;
    P_RESPTIME_DETAIL := '1: ' || v_mili ;

     IF v_incr_indicator <> '1' AND v_stan_checkflag = 'Y' THEN
      BEGIN

		 --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL
       WHERE  OPERATION_TYPE='ARCHIVE'
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';

       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');

	 IF (v_Retdate>v_Retperiod) THEN                                                        --Added for VMS-5739/FSP-991

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
         FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                          --Added for VMS-5739/FSP-991
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
    END IF;
    ------------------------------------------------------
        --En Added for Concurrent Processsing Issue
    ------------------------------------------------------
        select (extract(day from systimestamp - v_start_time) *86400+
    extract(hour from systimestamp - v_start_time) *3600+
    extract(minute from systimestamp - v_start_time) *60+
    extract(second from systimestamp - v_start_time) *1000) into v_mili from dual ;

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
                      P_INTERNATIONAL_IND, --Added by Deepa for Fees Changes
                      P_POS_VERFICATION, --Added by Deepa for Fees Changes
                      V_RESP_CDE, --Added by Deepa for Fees Changes
                      P_MSG, --Added by Deepa for Fees Changes
                      P_RVSL_CODE, --Added by Deepa on June 25 2012 for Reversal txn Fee
                     -- NULL, --P_MCC_CoDe Added by Trivinkram on 05-sep-2012
                     P_MCC_CODE,--Modified for the mantis issue- 12928
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
                      V_FEEAMNT_TYPE, --Added by Deepa for Fees Changes
                      V_CLAWBACK, --Added by Deepa for Fees Changes
                      V_FEE_PLAN, --Added by Deepa for Fees Changes
                      V_PER_FEES, --Added by Deepa for Fees Changes
                      V_FLAT_FEES, --Added by Deepa for Fees Changes
                      V_FREETXN_EXCEED, -- Added by Trivikram for logging fee of free transaction
                      V_DURATION, -- Added by Trivikram for logging fee of free transaction
                      V_FEEATTACH_TYPE, -- Added by Trivikram on Sep 05 2012
                      V_FEE_DESC , -- Added for MVCSD-4471
                      'N',p_surchrg_ind --Added for VMS05856
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
    /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
   -- IF P_DELIVERY_CHANNEL IN ('01', '02') AND P_TXN_CODE = '11' THEN
       IF     P_DELIVERY_CHANNEL IN ('01', '02') AND V_TRAN_PREAUTH_FLAG = 'Y'
            AND V_ADJUSTMENT_FLAG = 'N' AND V_DR_CR_FLAG = 'NA' THEN
     IF P_HOLD_AMOUNT IS NOT NULL THEN
     V_TRAN_AMT_NOHOLD:= V_TRAN_AMT;--Added for Mantis ID-12929
       V_TRAN_AMT := ROUND(P_HOLD_AMOUNT,2) ; --ROUND added for 3 decimal amount issue
   /*   IF V_TRAN_AMT_NOHOLD <> V_TRAN_AMT THEN --Sn Added for Mantis ID-12929
       P_PARTIALAUTH_AMOUNT :=V_TRAN_AMT;
       END IF;-- En Added for Mantis ID-12929*/--Commented on 21-Apr-2014 for FSS-1534
     END IF;
    END IF;
    /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */

     --SN Added on 29.10.2013 for 12568
     IF TO_NUMBER(P_PARTIAL_PREAUTH_IND) = 1 and V_TOTAL_FEE <> 0 THEN

          IF V_TOTAL_FEE >= v_acct_balance THEN

           V_RESP_CDE := '15';
            V_ERR_MSG  := 'Insufficient Balance ';
            RAISE EXP_REJECT_RECORD;

          ELSIF V_TRAN_AMT + V_TOTAL_FEE  > V_ACC_BAL
          THEN

          --SN Added  on 21-Apr-2014 for FSS-1534
                   IF (P_HOLD_AMOUNT IS NOT NULL)
                   THEN
                    V_TRAN_AMT           := V_ACC_BAL - V_TOTAL_FEE;
                    IF(V_TRAN_AMT >=V_TRAN_AMT_NOHOLD)
                    THEN
                          V_TRAN_AMT           :=V_TRAN_AMT_NOHOLD;
                          P_PARTIALAUTH_AMOUNT := V_TRAN_AMT;
                          v_partial_appr := 'Y';
                    ELSE
                          V_TRAN_AMT           :=V_ACC_BAL - V_TOTAL_FEE;
                          P_PARTIALAUTH_AMOUNT := V_TRAN_AMT;
                          v_partial_appr := 'Y';
                     END IF;
                    ELSE
             --EN Added  on 21-Apr-2014 for FSS-1534
            V_TRAN_AMT           := V_ACC_BAL - V_TOTAL_FEE;
            P_PARTIALAUTH_AMOUNT := V_TRAN_AMT;
            v_partial_appr := 'Y';
             END IF;
          END IF;
     ELSIF TO_NUMBER(P_PARTIAL_PREAUTH_IND) = 1 and P_HOLD_AMOUNT IS NOT NULL THEN
     IF V_TRAN_AMT > V_ACC_BAL THEN

          --  V_TRAN_AMT           := V_ACC_BAL ;  --Modified on 21-Apr-2014 for FSS-1534
           V_TRAN_AMT           :=V_TRAN_AMT_NOHOLD; --Modified  on 21-Apr-2014 for FSS-1534
           P_PARTIALAUTH_AMOUNT := V_TRAN_AMT;

            v_partial_appr := 'Y';

     END IF;

     END IF;
    --EN Added on 29.10.2013 for 12568

     --Sn Added for FSS 837
 BEGIN
 IF(v_tran_amt=0)
 THEN
 v_comp_fee_amt:=0;
 v_comp_fee_hold:=0;
 ELSE

           --  SN added to find the completion txn fee for the auth adjustment txn
            BEGIN
                SELECT cpt_compl_txncode
              INTO v_completion_txn_code
              FROM cms_preauthcomp_txncode
               WHERE cpt_inst_code = p_inst_code AND cpt_preauth_txncode = p_txn_code;

                EXCEPTION
             WHEN NO_DATA_FOUND THEN
              v_completion_txn_code:='00';
             WHEN OTHERS THEN
               V_RESP_CDE := '21';
               V_ERR_MSG  := 'Error while selecting data for Completion transaction code ' ||
                          SQLERRM;
               RAISE EXP_REJECT_RECORD;
               END;

              IF v_incr_indicator = '1' THEN

                BEGIN
                        SELECT CPT_TOTALHOLD_AMT,NVL(CPT_COMPLETION_FEE,'0'), --nvl added for mantis id:0015618
                             nvl(cpt_complfree_flag,'N')
                              INTO V_PREAUTH_AMT,v_completion_fee,
                              v_comlfree_flag
                              FROM VMSCMS.CMS_PREAUTH_TRANSACTION                  --Added for VMS-5739/FSP-991
                              WHERE      CPT_CARD_NO = V_HASH_PAN
                                         AND CPT_RRN = P_RRN
                                         AND CPT_PREAUTH_VALIDFLAG = 'Y'
                                         AND CPT_EXPIRY_FLAG = 'N';
						IF SQL%ROWCOUNT = 0 THEN
						SELECT CPT_TOTALHOLD_AMT,NVL(CPT_COMPLETION_FEE,'0'), --nvl added for mantis id:0015618
                             nvl(cpt_complfree_flag,'N')
                              INTO V_PREAUTH_AMT,v_completion_fee,
                              v_comlfree_flag
                              FROM VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                   --Added for VMS-5739/FSP-991
                              WHERE      CPT_CARD_NO = V_HASH_PAN
                                         AND CPT_RRN = P_RRN
                                         AND CPT_PREAUTH_VALIDFLAG = 'Y'
                                         AND CPT_EXPIRY_FLAG = 'N';
						END IF;

                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    V_ERR_MSG :='No Matching Preauth was found for Incremental preauth ';
                    V_RESP_CDE := '56';
                    RAISE EXP_REJECT_RECORD;
                WHEN OTHERS
                            THEN
                        V_ERR_MSG :=
                            'Error while selecting  CMS_PREAUTH_TRANSACTION '
                            || SUBSTR (SQLERRM, 1, 300);
                            V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END;

            END IF;


         sp_tran_fees_cmsauth (p_inst_code,
                               p_card_no,
                               p_delivery_channel,
                               '1',
                               p_txn_mode,
                               v_completion_txn_code,
                               p_curr_code,
                               p_consodium_code,
                               p_partner_code,
                               V_TRAN_AMT+V_PREAUTH_AMT,
                               v_tran_date,
                               p_international_ind,
                               p_pos_verfication,
                               v_resp_cde,
                               '1220',
                               p_rvsl_code,
                               p_mcc_code,
                               v_comp_fee_amt,
                               v_comp_error,
                               v_comp_fee_code,
                               v_comp_fee_crgl_catg,
                               v_comp_fee_crgl_code,
                               v_comp_fee_crsubgl_code,
                               v_comp_fee_cracct_no,
                               v_comp_fee_drgl_catg,
                               v_comp_fee_drgl_code,
                               v_comp_fee_drsubgl_code,
                               v_comp_fee_dracct_no,
                               v_comp_st_calc_flag,
                               v_comp_cess_calc_flag,
                               v_comp_st_cracct_no,
                               v_comp_st_dracct_no,
                               v_comp_cess_cracct_no,
                               v_comp_cess_dracct_no,
                               v_comp_feeamnt_type,
                               v_comp_clawback,
                               v_comp_fee_plan,
                               v_comp_per_fees,
                               v_comp_flat_fees,
                               v_comp_freetxn_exceed,
                               v_comp_duration,
                               v_comp_feeattach_type,
                               V_COMP_FEE_DESC
                              );

         IF v_comp_error <> 'OK'
         THEN
            v_resp_cde := '21';
            v_err_msg := v_comp_error;
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
                   'Error from fee calc process ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;

      END;

      if v_comlfree_flag='Y' and v_comp_freetxn_exceed='N' then
            begin
                vmsfee.fee_freecnt_reverse
                      (v_acct_number, v_comp_fee_code, V_ERR_MSG);
                IF V_ERR_MSG <> 'OK'
                THEN
                    V_RESP_CDE := '21';
                    RAISE EXP_REJECT_RECORD;
                END IF;
            exception
                  when EXP_REJECT_RECORD then
                      raise;
                  when others then
                     V_RESP_CDE := '21';
                    V_ERR_MSG :=
                        'Error from fee count reverse procedure ' || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
            end;
        end if;


  --Sn calculate waiver on the fee
      BEGIN
         sp_calculate_waiver (p_inst_code,
                              p_card_no,
                              '000',
                              v_prod_code,
                              v_prod_cattype,
                              v_comp_fee_code,
                              v_comp_fee_plan,
                              v_tran_date,
                              v_comp_waiv_percnt,
                              v_comp_err_waiv
                             );

         IF v_comp_err_waiv <> 'OK'
         THEN
            v_resp_cde := '21';
            v_err_msg := v_comp_err_waiv;
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
                'Error from waiver calc process ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En calculate waiver on the fee

      --Sn apply waiver on fee amount
      v_comp_fee_amt := ROUND (v_comp_fee_amt - ((v_comp_fee_amt * v_comp_waiv_percnt) / 100), 2);

      --En apply waiver on fee amount

      --Sn apply service tax and cess
      IF v_comp_st_calc_flag = 1
      THEN
         v_comp_servicetax_amount := (v_comp_fee_amt * v_comp_servicetax_percent) / 100;
      ELSE
         v_comp_servicetax_amount := 0;
      END IF;

      IF v_comp_cess_calc_flag = 1
      THEN
         v_comp_cess_amount := (v_comp_servicetax_amount * v_comp_cess_percent) / 100;
      ELSE
         v_comp_cess_amount := 0;
      END IF;

      v_comp_total_fee :=
                    ROUND (v_comp_fee_amt + v_comp_servicetax_amount + v_comp_cess_amount, 2);
      if v_comlfree_flag='Y' then
            v_comp_total_fee:=0;
      end if;
      --En apply service tax and cess
      v_comp_fee_hold:=v_comp_total_fee;

      IF v_comp_total_fee > '0'
         THEN
            IF v_incr_indicator = 1
            THEN
                   IF v_comp_total_fee = v_completion_fee
                   THEN
                      v_comp_hold_fee_diff := 0;
                   ELSIF v_comp_total_fee > v_completion_fee
                   THEN
                      v_comp_hold_fee_diff := v_comp_total_fee - v_completion_fee;
                   ELSIF v_comp_total_fee < v_completion_fee
                   THEN
                      v_comp_hold_fee_diff := v_comp_total_fee - v_completion_fee;
                   END IF;

               IF v_tran_amt + v_total_fee + v_comp_hold_fee_diff >
                                                                v_acct_balance
               THEN
                  IF TO_NUMBER (p_partial_preauth_ind) = '1'
                  THEN
                     IF v_comp_total_fee = v_completion_fee
                     THEN
                        v_comp_total_fee := '0';
                        v_tot_hold_amt := v_tran_amt;
                        v_complfee_increment_type := 'N';
                     ELSIF v_comp_total_fee > v_completion_fee
                     THEN
                        v_comp_hold_fee_diff :=
                                          v_comp_total_fee - v_completion_fee;
                        v_complfee_increment_type := 'D';
                        v_comp_total_fee := v_comp_hold_fee_diff;
                        v_tran_amt := v_tran_amt - v_comp_hold_fee_diff;
                        v_tot_hold_amt := v_tran_amt+v_comp_total_fee;
                        v_partial_appr := 'Y';
                     ELSIF v_comp_total_fee < v_completion_fee
                         THEN
                            v_comp_hold_fee_diff :=
                                              v_completion_fee - v_comp_total_fee;
                            v_comp_total_fee := v_comp_hold_fee_diff;
                            v_complfee_increment_type := 'C';
                            v_tran_amt := v_tran_amt+v_comp_total_fee;
                            v_tot_hold_amt := v_tran_amt-v_comp_total_fee;
                     END IF;
                  ELSE
                     v_resp_cde := '15';
                     v_err_msg := 'Insufficient Balance';
                     RAISE exp_reject_record;
                  END IF;
               ELSE
                  IF TO_NUMBER (p_partial_preauth_ind) = '1'
                      THEN
                     IF v_comp_total_fee = v_completion_fee
                     THEN
                        v_comp_total_fee := '0';
                        v_tot_hold_amt := v_tran_amt;
                        v_complfee_increment_type := 'N';
                     ELSIF v_comp_total_fee > v_completion_fee
                     THEN
                        v_comp_hold_fee_diff :=
                                          v_comp_total_fee - v_completion_fee;
                        v_complfee_increment_type := 'D';
                        v_comp_total_fee := v_comp_hold_fee_diff;
                        v_tran_amt := v_tran_amt - v_comp_hold_fee_diff;
                        v_tot_hold_amt := v_tran_amt+v_comp_total_fee;
                     ELSIF v_comp_total_fee < v_completion_fee
                         THEN
                            v_comp_hold_fee_diff :=
                                              v_completion_fee - v_comp_total_fee;
                            v_comp_total_fee := v_comp_hold_fee_diff;
                            v_complfee_increment_type := 'C';
                            v_tran_amt := v_tran_amt+v_comp_total_fee;
                            v_tot_hold_amt := v_tran_amt-v_comp_total_fee;
                     END IF;

                  ELSE
                   IF v_comp_total_fee = v_completion_fee
                  THEN
                     v_comp_total_fee := '0';
                     v_tot_hold_amt := v_tran_amt;
                     v_complfee_increment_type := 'N';
                  ELSIF v_comp_total_fee > v_completion_fee
                  THEN
                     v_comp_hold_fee_diff :=
                                          v_comp_total_fee - v_completion_fee;
                     v_complfee_increment_type := 'D';
                     v_comp_total_fee := v_comp_hold_fee_diff;
                     v_tot_hold_amt := v_tran_amt + v_comp_hold_fee_diff;
                  ELSIF v_comp_total_fee < v_completion_fee
                  THEN
                     v_comp_hold_fee_diff :=
                                          v_completion_fee - v_comp_total_fee;
                     v_comp_total_fee := v_comp_hold_fee_diff;
                     v_complfee_increment_type := 'C';
                     v_tot_hold_amt := v_tran_amt - v_comp_hold_fee_diff;
                  END IF;

                  END IF;
               END IF;
            ELSE                    -- direct partial preauth transaction.....
               IF v_tran_amt + v_total_fee + v_comp_total_fee >
                                                               v_acct_balance
               THEN
                  IF TO_NUMBER (p_partial_preauth_ind) = 1
                  THEN

                    IF v_acct_balance > (v_total_fee+v_comp_total_fee) THEN
                     v_tran_amt :=v_acct_balance - (v_total_fee+v_comp_total_fee);
                     v_tot_hold_amt := v_tran_amt+v_comp_total_fee;
                     v_complfee_increment_type := 'D';
                     v_partial_appr := 'Y';
                    ELSE
                     v_resp_cde := '15';
                     v_err_msg := 'Insufficient Balance';
                     RAISE exp_reject_record;
                    END IF;
                  ELSE
                     v_resp_cde := '15';
                     v_err_msg := 'Insufficient Balance';
                     RAISE exp_reject_record;
                  END IF;
               ELSE
                  v_tot_hold_amt := v_tran_amt + v_comp_total_fee;
                  v_complfee_increment_type := 'D';
               END IF;
            END IF;
      ELSE
            v_tot_hold_amt := v_tran_amt;
      END IF;


       IF TO_NUMBER (p_partial_preauth_ind) = 1 AND v_partial_appr = 'Y' then
              p_partialauth_amount := v_tran_amt;
       END IF;


  /*IF TO_NUMBER(P_PARTIAL_PREAUTH_IND) = 1 and v_comp_total_fee <> 0 THEN

 --   IF v_comp_total_fee >= v_acct_balance THEN
         IF v_comp_total_fee >= v_acct_balance-V_TOTAL_FEE THEN --Modified for 15590

           V_RESP_CDE := '15';
            V_ERR_MSG  := 'Insufficient Balance ';
            RAISE EXP_REJECT_RECORD;

        --  ELSIF V_TRAN_AMT + v_comp_total_fee  > V_ACC_BAL --Modified for 15590
          ELSIF V_TRAN_AMT + v_comp_total_fee  > V_ACC_BAL -V_TOTAL_FEE
          THEN

          --V_TRAN_AMT           := V_ACC_BAL - v_comp_total_fee ;
            V_TRAN_AMT           := V_ACC_BAL - v_comp_total_fee -V_TOTAL_FEE;    --Modified for 15590
            P_PARTIALAUTH_AMOUNT := V_TRAN_AMT;
            v_partial_appr := 'Y';

          END IF;


        --  v_tot_hold_amt:=V_TRAN_AMT+v_comp_total_fee+V_TOTAL_FEE;
        v_tot_hold_amt:=V_TRAN_AMT+v_comp_total_fee; --Modified for 15590

END IF;

  --v_tot_hold_amt:=V_TRAN_AMT+v_comp_total_fee+V_TOTAL_FEE;
  v_tot_hold_amt:=V_TRAN_AMT+v_comp_total_fee; --Modified for 15590
--EN added to find the completion txn feefor the auth adjustment txn
    --En Added for FSS 837
    */


     select (extract(day from systimestamp - v_start_time) *86400+
    extract(hour from systimestamp - v_start_time) *3600+
    extract(minute from systimestamp - v_start_time) *60+
    extract(second from systimestamp - v_start_time) *1000) into v_mili from dual ;

     P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 3: ' || v_mili ;
    --Sn Added by Pankaj S. for enabling limit validation
    IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y' THEN
    BEGIN
          pkg_limits_check.sp_limits_check (v_hash_pan,
                                            NULL,
                                            NULL,
                                            p_mcc_code,
                                            p_txn_code,
                                            v_tran_type,
                                            p_international_ind,
                                            p_pos_verfication,
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
    --En Added by Pankaj S. for enabling limit validation

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

     IF V_TRAN_PREAUTH_FLAG = 'Y' THEN

       V_TOTAL_AMT := v_tot_hold_amt + V_TOTAL_FEE;
     ELSE

       V_TOTAL_AMT := V_TOTAL_FEE;

     END IF;

     V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
     V_UPD_LEDGER_AMT := V_LEDGER_BAL; -- - V_TOTAL_AMT; srini

    ELSE
     V_RESP_CDE := '12'; --Ineligible Transaction
     V_ERR_MSG  := 'Invalid transflag    txn code ' || P_TXN_CODE;
     RAISE EXP_REJECT_RECORD;
    END IF;

    --En find total transaction    amout

    --Sn check balance

    IF V_UPD_AMT < 0 THEN
     V_RESP_CDE := '15'; --Ineligible Transaction
     V_ERR_MSG  := 'Insufficient Balance '; -- modified by Ravi N for Mantis ID 0011282
     RAISE EXP_REJECT_RECORD;

    END IF;

    --En check balance


      /*  -- Commented since same is not require as per defect 10406

        -- Check for maximum card balance configured for the product profile.
        BEGIN
         SELECT TO_NUMBER(CBP_PARAM_VALUE)
           INTO V_MAX_CARD_BAL
           FROM CMS_BIN_PARAM
          WHERE CBP_INST_CODE = P_INST_CODE AND
               CBP_PARAM_NAME = 'Max Card Balance' AND
               CBP_PROFILE_CODE IN
               (SELECT CPM_PROFILE_CODE
                 FROM CMS_PROD_MAST
                WHERE CPM_PROD_CODE = V_PROD_CODE);
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'CARD BALANCE CONFIGURATION NOT AVAILABLE FOR THE PRODUCT PROFILE ' ||
                      V_PROD_CODE;
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;

        --Sn check balance
        IF (V_UPD_LEDGER_AMT > V_MAX_CARD_BAL) OR (V_UPD_AMT > V_MAX_CARD_BAL) THEN
         V_RESP_CDE := '30';
         V_ERR_MSG  := 'EXCEEDING MAXIMUM CARD BALANCE';
         RAISE EXP_REJECT_RECORD;
        END IF;
        --En check balance

      */   -- Commented since same is not require as per defect 10406

    --Sn create gl entries and acct update
    BEGIN
     SP_UPD_TRANSACTION_ACCNT_AUTH(P_INST_CODE,
                             V_TRAN_DATE,
                             V_PROD_CODE,
                             V_PROD_CATTYPE,
                             --V_TRAN_AMT,
                             v_tot_hold_amt,-- modified for FSS-837 changes
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
    --Commended by Saravanakumar on 25-Sep-2014
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

   -- v_timestamp:=systimestamp; --added by Pankaj S. for 10871

   /* IF v_comp_hold_cr_flag = 'H'
      THEN
         v_tran_amt := v_tot_hold_amt + v_comp_hold_fee_diff;
         v_total_amt := v_tran_amt;
      END IF;*/

    --Sn create a entry in statement log
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
         CSL_ACCT_NO, --Added by Deepa to log the account number ,INS_DATE and INS_USER
         CSL_INS_USER,
         CSL_INS_DATE,
         CSL_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
         CSL_MERCHANT_CITY,
         CSL_MERCHANT_STATE,
         CSL_PANNO_LAST4DIGIT, --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
         --Sn added by Pankaj S. for 10871
         csl_prod_code,csl_card_type,
         csl_acct_type,
         csl_time_stamp
         --En added by Pankaj S. for 10871
         )
       VALUES
        (V_HASH_PAN,
         v_ledger_bal, --V_ACCT_BALANCE replaced by Pankaj S. with v_ledger_bal for 10871
         V_TRAN_AMT,
         V_DR_CR_FLAG,
         V_TRAN_DATE,
         DECODE(V_DR_CR_FLAG,
               'DR',
               v_ledger_bal - V_TRAN_AMT,  --V_ACCT_BALANCE replaced by Pankaj S. with v_ledger_bal for 10871
               'CR',
               v_ledger_bal + V_TRAN_AMT, --V_ACCT_BALANCE replaced by Pankaj S. with v_ledger_bal for 10871
               'NA',
               v_ledger_bal), --V_ACCT_BALANCE replaced by Pankaj S. with v_ledger_bal for 10871
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
         --Sn Added by Pankaj S. for Mantis ID 11540
         P_MERCHANT_NAME,--NULL, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
         P_MERCHANT_CITY,--NULL,
         --En Added by Pankaj S. for Mantis ID 11540
         P_ATMNAME_LOC,
         (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))), --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
          --Sn added by Pankaj S. for 10871
         v_prod_code,V_PROD_CATTYPE,
         v_acct_type,
         v_timestamp
         --En added by Pankaj S. for 10871
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

    --Sn find fee opening balance
    IF V_TOTAL_FEE <> 0 OR V_FREETXN_EXCEED = 'N' THEN -- Modified by Trivikram on 26-July-2012 for logging fee of free transaction
     BEGIN
       SELECT DECODE(V_DR_CR_FLAG,
                  'DR',
                  v_ledger_bal - V_TRAN_AMT, --V_ACCT_BALANCE replaced by Pankaj S. with v_ledger_bal for 10871
                  'CR',
                  v_ledger_bal + V_TRAN_AMT, --V_ACCT_BALANCE replaced by Pankaj S. with v_ledger_bal for 10871
                  'NA',
                  v_ledger_bal) --V_ACCT_BALANCE replaced by Pankaj S. with v_ledger_bal for 10871
        INTO V_FEE_OPENING_BAL
        FROM DUAL;
     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '12';
        V_ERR_MSG  := 'Error in acct balance calculation based on transflag' ||
                    V_DR_CR_FLAG;
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
           CSL_PANNO_LAST4DIGIT, --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
           --Sn added by Pankaj S. for 10871
           csl_prod_code,
           csl_acct_type,
           csl_time_stamp
           --En added by Pankaj S. for 10871
           )
        VALUES
          (V_HASH_PAN,
           V_FEE_OPENING_BAL,
           V_TOTAL_FEE,
           'DR',
           V_TRAN_DATE,
           V_FEE_OPENING_BAL - V_TOTAL_FEE,
           --'Complimentary ' || V_DURATION ||' '|| V_NARRATION, -- Commented for MVCSD-4471 -- Modified by Trivikram  on 27-July-2012
           V_FEE_DESC, -- Added for MVCSD-4471
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
           --Sn Added by Pankaj S. for Mantis ID 11540
           P_MERCHANT_NAME,--NULL, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
           P_MERCHANT_CITY,--NULL,
           --En Added by Pankaj S. for Mantis ID 11540
           P_ATMNAME_LOC,
           SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO)), --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
           --Sn added by Pankaj S. for 10871
           v_prod_code,
           v_acct_type,
           v_timestamp
           --En added by Pankaj S. for 10871
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
          --Sn added by Pankaj S. for 10871
         csl_prod_code,
         csl_acct_type,
         csl_time_stamp
         --En added by Pankaj S. for 10871
         )
       VALUES
        (V_HASH_PAN,
         V_FEE_OPENING_BAL,
         V_FLAT_FEES,
         'DR',
         V_TRAN_DATE,
         V_FEE_OPENING_BAL - V_FLAT_FEES,
       --  'Fixed Fee debited for ' || V_NARRATION, ---- Commented for MVCSD-4471
         'Fixed Fee debited for ' || V_FEE_DESC, -- Added for MVCSD-4471
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
         --Sn Added by Pankaj S. for Mantis ID 11540
         P_MERCHANT_NAME,--NULL,
         P_MERCHANT_CITY,--NULL,
         --En Added by Pankaj S. for Mantis ID 11540
         P_ATMNAME_LOC,
         (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),
          --Sn added by Pankaj S. for 10871
         v_prod_code,
         v_acct_type,
         v_timestamp
         --En added by Pankaj S. for 10871
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
         CSL_ACCT_NO, --Added by Deepa to log the account number ,INS_DATE and INS_USER
         CSL_INS_USER,
         CSL_INS_DATE,
         CSL_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
         CSL_MERCHANT_CITY,
         CSL_MERCHANT_STATE,
         CSL_PANNO_LAST4DIGIT, --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
          --Sn added by Pankaj S. for 10871
         csl_prod_code,
         csl_acct_type,
         csl_time_stamp
         --En added by Pankaj S. for 10871
         )
       VALUES
        (V_HASH_PAN,
         V_FEE_OPENING_BAL,
         V_PER_FEES,
         'DR',
         V_TRAN_DATE,
         V_FEE_OPENING_BAL - V_PER_FEES,
        -- 'Percetage Fee debited for ' || V_NARRATION, -- Commented for MVCSD-4471
         'Percentage Fee debited for ' || V_FEE_DESC,  -- Added for MVCSD-4471
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
         --Sn Added by Pankaj S. for Mantis ID 11540
         P_MERCHANT_NAME,--NULL, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
         P_MERCHANT_CITY,--NULL,
         --En Added by Pankaj S. for Mantis ID 11540
         P_ATMNAME_LOC,
         (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),
          --Sn added by Pankaj S. for 10871
         v_prod_code,
         v_acct_type,
         v_timestamp
         --En added by Pankaj S. for 10871
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
           CSL_PANNO_LAST4DIGIT, --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
           --Sn added by Pankaj S. for 10871
           csl_prod_code,
           csl_acct_type,
           csl_time_stamp
           --En added by Pankaj S. for 10871
         )
        VALUES
          (V_HASH_PAN,
           V_FEE_OPENING_BAL,
           V_TOTAL_FEE,
           'DR',
           V_TRAN_DATE,
           V_FEE_OPENING_BAL - V_TOTAL_FEE,
           --'Fee debited for ' || V_NARRATION, -- Commented for MVCSD-4471
           V_FEE_DESC, -- Added for MVCSD-4471
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
           --Sn Added by Pankaj S. for Mantis ID 11540
           P_MERCHANT_NAME,--NULL, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
           P_MERCHANT_CITY,--NULL,
           --En Added by Pankaj S. for Mantis ID 11540
           P_ATMNAME_LOC,
           SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO)), --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
            --Sn added by Pankaj S. for 10871
           v_prod_code,
           v_acct_type,
           v_timestamp
           --En added by Pankaj S. for 10871
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
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        CTD_NETWORK_ID,
        CTD_INTERCHANGE_FEEAMT,
        CTD_MERCHANT_ZIP,
        CTD_MERCHANT_ID,
        CTD_COUNTRY_CODE,
        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        ctd_ins_user, -- Added for OLS changes
        ctd_ins_date,  -- Added for OLS changes
        ctd_completion_fee, --Added for FSS 837
        ctd_complfee_increment_type,CTD_COMPFEE_CODE,CTD_COMPFEEATTACH_TYPE,CTD_COMPFEEPLAN_ID --Added for FSS 837
        ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,CTD_CARDVERIFICATION_RESULT--Added for MVHOST 926
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
        P_TXN_AMT,--V_TRAN_AMT, --P_TXN_AMT, modified for 10871 modified for defect id:12166
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
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        P_NETWORK_ID,
        P_INTERCHANGE_FEEAMT,
        P_MERCHANT_ZIP,
        P_MERC_ID,
        P_MERC_CNTRYCODE,
        /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        1,
        sysdate,
v_comp_total_fee,v_complfee_increment_type,v_comp_fee_code,v_comp_feeattach_type,v_comp_fee_plan --Added for FSS 837
        ,P_PULSE_TRANSACTIONID,--Added for MVHOST 926
        P_VISA_TRANSACTIONID,--Added for MVHOST 926
        P_MC_TRACEID,--Added for MVHOST 926
        P_CARDVERIFICATION_RESULT--Added for MVHOST 926
        ,P_MS_PYMNT_DESC,v_hashkey_id
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
    --Commended by Saravanakumar on 25-Sep-2014
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
     P_RESP_MSG := TO_CHAR(V_UPD_AMT+v_delayed_amount);
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

      /*BEGIN -- Added for OLS changes

         IF v_partial_appr = 'Y' AND v_resp_cde = '1'
         THEN
         -- Added by Trivikram on 02/mar/2013, for preauth partial approve Response Code
            v_resp_cde := '2';
         END IF;

      END; */

    BEGIN
     --Add for PreAuth Transaction of CMSAuth;
     --Sn creating entries for preauth txn
     --if incoming message not contains checking for prod preauth expiry period
     --if preauth expiry period is not configured checking for instution expirty period
     BEGIN
       IF V_TRAN_PREAUTH_FLAG = 'Y' THEN
        /* IF V_PRODUCT_PREAUTH_EXPPERIOD IS NULL THEN
          BEGIN
            SELECT CPM_PRE_AUTH_EXP_DATE
             INTO V_PREAUTH_EXP_PERIOD
             FROM CMS_PROD_MAST
            WHERE CPM_PROD_CODE = V_PROD_CODE;
          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while selecting  CMS_PROD_MAST ' ||
                        SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
          IF V_PREAUTH_EXP_PERIOD IS NULL THEN
            BEGIN
             SELECT CIP_PARAM_VALUE
               INTO V_PREAUTH_EXP_PERIOD
               FROM CMS_INST_PARAM
              WHERE CIP_INST_CODE = P_INST_CODE AND
                   CIP_PARAM_KEY = 'PRE-AUTH EXP PERIOD';
            EXCEPTION
             WHEN OTHERS THEN
               V_ERR_MSG  := 'Error while selecting  CMS_INST_PARAM ' ||
                          SUBSTR(SQLERRM, 1, 300);
               V_RESP_CDE := '21';
               RAISE EXP_REJECT_RECORD;
            END;

            V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
            V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
          ELSE
            V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
            V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
          END IF;
        ELSE
          V_PREAUTH_HOLD   := SUBSTR(TRIM(V_PRODUCT_PREAUTH_EXPPERIOD),
                                1,
                                1);
          V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PRODUCT_PREAUTH_EXPPERIOD),
                                2,
                                2);

          IF V_PREAUTH_PERIOD = '00' THEN
            BEGIN
             SELECT CPM_PRE_AUTH_EXP_DATE
               INTO V_PREAUTH_EXP_PERIOD
               FROM CMS_PROD_MAST
              WHERE CPM_PROD_CODE = V_PROD_CODE;
            EXCEPTION
             WHEN OTHERS THEN
               V_ERR_MSG  := 'Error while selecting  CMS_PROD_MAST1 ' ||
                          SUBSTR(SQLERRM, 1, 300);
               V_RESP_CDE := '21';
               RAISE EXP_REJECT_RECORD;
            END;

            IF V_PREAUTH_EXP_PERIOD IS NULL THEN
             BEGIN
               SELECT CIP_PARAM_VALUE
                INTO V_PREAUTH_EXP_PERIOD
                FROM CMS_INST_PARAM
                WHERE CIP_INST_CODE = P_INST_CODE AND
                    CIP_PARAM_KEY = 'PRE-AUTH EXP PERIOD';
             EXCEPTION
               WHEN OTHERS THEN
                V_ERR_MSG  := 'Error while selecting  CMS_INST_PARAM1 ' ||
                            SUBSTR(SQLERRM, 1, 300);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
             END;

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
        */
        /* Start Added by Dhiraj G on 06112012  for Pre -Auth Hold days changes */
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
        /* End  Added by Dhiraj G on 06112012  for Pre -Auth Hold days changes */
        /*
           preauth period will be added with transaction date based on preauth_hold
           IF v_preauth_hold is '0'--'Minute'
           '1'--'Hour'
           '2'--'Day'
          */
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */

        /*   --Commented on 21092012 Dhiraj Gaikwad
        IF P_DELIVERY_CHANNEL IN ('01', '02') AND P_TXN_CODE = '11' THEN
          IF V_HOLD_DAYS IS NOT NULL THEN
            IF V_HOLD_DAYS > V_PREAUTH_PERIOD THEN
             V_PREAUTH_PERIOD := V_HOLD_DAYS;
            END IF;
          END IF;
        END IF; */


        --IF P_DELIVERY_CHANNEL IN ('01', '02') AND P_TXN_CODE = '11' THEN
          IF     P_DELIVERY_CHANNEL IN ('01', '02') AND V_TRAN_PREAUTH_FLAG = 'Y'
            AND V_ADJUSTMENT_FLAG = 'N' AND V_DR_CR_FLAG = 'NA' THEN
          IF V_HOLD_DAYS IS NOT NULL
          AND V_HOLD_DAYS <> '0'    -- Added on 26-Feb-2013 during FSS-781 changes
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


        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        
        --SN Added for VMS_9194 
        
        BEGIN
         SELECT CIP_PARAM_VALUE
           INTO V_PARAM_VALUE
           FROM CMS_INST_PARAM
          WHERE CIP_PARAM_KEY = 'EXTENDED_AUTH_VMS9194_TOGGLE' AND CIP_INST_CODE = P_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_PARAM_VALUE := 'Y'; 
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'Error while selecting param value ';
          RETURN;
        END;

        IF  V_PARAM_VALUE = 'Y'  then
                       
                BEGIN
                    IF p_expected_clearing_date is not null then
                                        
                        select to_date(p_expected_clearing_date,'YDDD')
                        into v_expected_clearing_date 
                        from dual;                         
                    END IF; 
                    
                    IF p_marketspecific_dataidentifier = 'X' then
                    
                        select V_TRAN_DATE + 30
                        into v_extended_auth_date
                        from dual;
                    END IF;
                    
					IF (v_expected_clearing_date < V_TRAN_DATE) and p_marketspecific_dataidentifier is null then                    
                          V_PARAM_VALUE := 'N';
                    END IF;
       
                EXCEPTION
                    WHEN OTHERS THEN
                        V_RESP_CDE := '21';
                        V_ERR_MSG  := 'Error in calculating preauth expiry date';
                        RAISE EXP_REJECT_RECORD;
                END;
        END IF;   

       IF  (p_expected_clearing_date IS NOT NULL OR p_marketspecific_dataidentifier = 'X' ) AND V_PARAM_VALUE = 'Y'  THEN       
        
             BEGIN
                SELECT GREATEST (nvl(v_expected_clearing_date,to_date('1900-01-01','YYYY-MM-DD')), nvl(v_extended_auth_date,to_date('1900-01-01','YYYY-MM-DD')))
                INTO V_PREAUTH_DATE
                FROM DUAL;   
             EXCEPTION
                WHEN OTHERS THEN
                        V_RESP_CDE := '21';
                        V_ERR_MSG  := 'Error in calculating greatest date';
                        RAISE EXP_REJECT_RECORD;
             END;
            
       ELSE
    --EN Added for VMS_9194
    
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
               SELECT cpt_transaction_flag
                 INTO v_transactioncomp_flag
                 FROM VMSCMS.CMS_PREAUTH_TRANSACTION                                   --Added for VMS-5739/FSP-991
                WHERE cpt_card_no = v_hash_pan
                  AND cpt_rrn = p_rrn
                  AND cpt_preauth_validflag = 'Y'
                  AND cpt_expiry_flag = 'N';
				IF SQL%ROWCOUNT = 0 THEN
				  SELECT cpt_transaction_flag
                 INTO v_transactioncomp_flag
                 FROM VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                                  --Added for VMS-5739/FSP-991
                WHERE cpt_card_no = v_hash_pan
                  AND cpt_rrn = p_rrn
                  AND cpt_preauth_validflag = 'Y'
                  AND cpt_expiry_flag = 'N';
				END IF;

               IF v_transactioncomp_flag = 'C'
               THEN
                  v_err_msg := 'Completion already done for this preauth ';
                  v_resp_cde := '57';
                  RAISE exp_reject_record;
               END IF;

               IF v_incr_indicator = '1'
               THEN
                  v_trantype := 'I';

                  BEGIN
                    -- Sn added for VMS_9340
                    IF  (p_expected_clearing_date IS NOT NULL OR p_marketspecific_dataidentifier = 'X' ) AND V_PARAM_VALUE = 'Y'  THEN
                    
                     UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION                               
                        SET cpt_totalhold_amt = ROUND (cpt_totalhold_amt + v_tran_amt, 2),
                            cpt_transaction_flag = 'I',
                            cpt_txn_amnt = ROUND (v_tran_amt, 2),                            
                            cpt_completion_fee =
                               DECODE (v_complfee_increment_type,
                                       'C', cpt_completion_fee - v_comp_total_fee,
                                       'D', cpt_completion_fee + v_comp_total_fee,
                                       cpt_completion_fee
                                      ),
                            cpt_extended_auth_date = v_extended_auth_date,              
                            cpt_expected_clearing_date = v_expected_clearing_date,      
                            cpt_extended_auth_identifier = v_extended_auth_identifier   
                      WHERE cpt_card_no = v_hash_pan
                        AND cpt_rrn = p_rrn
                        AND cpt_preauth_validflag = 'Y'
                        AND cpt_expiry_flag = 'N'
                        AND cpt_inst_code = p_inst_code;

						IF SQL%ROWCOUNT = 0
                     THEN
					    UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                              --Added for VMS-5739/FSP-991
                        SET cpt_totalhold_amt = ROUND (cpt_totalhold_amt + v_tran_amt, 2),
                            cpt_transaction_flag = 'I',
                            cpt_txn_amnt = ROUND (v_tran_amt, 2),
                            cpt_completion_fee =
                               DECODE (v_complfee_increment_type,
                                       'C', cpt_completion_fee - v_comp_total_fee,
                                       'D', cpt_completion_fee + v_comp_total_fee,
                                       cpt_completion_fee
                                      ),
							cpt_extended_auth_date = v_extended_auth_date,              --Added for VMS_9194
                            cpt_expected_clearing_date = v_expected_clearing_date,      --Added for VMS_9194
                            cpt_extended_auth_identifier = v_extended_auth_identifier   --Added for VMS_9194
                      WHERE cpt_card_no = v_hash_pan
                        AND cpt_rrn = p_rrn
                        AND cpt_preauth_validflag = 'Y'
                        AND cpt_expiry_flag = 'N'
                        AND cpt_inst_code = p_inst_code;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_err_msg :=
                                    'Problem while updating data in  PREAUTH TRANSACTION';
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                     END IF;
				END IF;
                
                ELSE
                -- En added for VMS_9340
                UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION                               --Added for VMS-5739/FSP-991
                        SET cpt_totalhold_amt = ROUND (cpt_totalhold_amt + v_tran_amt, 2),
                            cpt_transaction_flag = 'I',
                            cpt_txn_amnt = ROUND (v_tran_amt, 2),
                            cpt_expiry_date = v_preauth_date,
                            cpt_completion_fee =
                               DECODE (v_complfee_increment_type,
                                       'C', cpt_completion_fee - v_comp_total_fee,
                                       'D', cpt_completion_fee + v_comp_total_fee,
                                       cpt_completion_fee
                                      ),
                            cpt_extended_auth_date = v_extended_auth_date,              --Added for VMS_9194
                            cpt_expected_clearing_date = v_expected_clearing_date,      --Added for VMS_9194
                            cpt_extended_auth_identifier = v_extended_auth_identifier   --Added for VMS_9194
                      WHERE cpt_card_no = v_hash_pan
                        AND cpt_rrn = p_rrn
                        AND cpt_preauth_validflag = 'Y'
                        AND cpt_expiry_flag = 'N'
                        AND cpt_inst_code = p_inst_code;

						IF SQL%ROWCOUNT = 0
                     THEN
					    UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                              --Added for VMS-5739/FSP-991
                        SET cpt_totalhold_amt = ROUND (cpt_totalhold_amt + v_tran_amt, 2),
                            cpt_transaction_flag = 'I',
                            cpt_txn_amnt = ROUND (v_tran_amt, 2),
                            cpt_expiry_date = v_preauth_date,
                            cpt_completion_fee =
                               DECODE (v_complfee_increment_type,
                                       'C', cpt_completion_fee - v_comp_total_fee,
                                       'D', cpt_completion_fee + v_comp_total_fee,
                                       cpt_completion_fee
                                      ),
							cpt_extended_auth_date = v_extended_auth_date,              --Added for VMS_9194
                            cpt_expected_clearing_date = v_expected_clearing_date,      --Added for VMS_9194
                            cpt_extended_auth_identifier = v_extended_auth_identifier   --Added for VMS_9194
                      WHERE cpt_card_no = v_hash_pan
                        AND cpt_rrn = p_rrn
                        AND cpt_preauth_validflag = 'Y'
                        AND cpt_expiry_flag = 'N'
                        AND cpt_inst_code = p_inst_code;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_err_msg :=
                                    'Problem while updating data in  PREAUTH TRANSACTION';
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                     END IF;
				END IF;
                END IF;
                  EXCEPTION
                  WHEN exp_reject_record THEN
                     RAISE;
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while updating  PREAUTH TRANSACTION '
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
               ELSE
                  v_resp_cde := '56';
                  v_err_msg := 'Not a Valid Pre-Auth' || SUBSTR (SQLERRM, 1, 300);
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
               IF(p_incr_indicator IS NOT NULL) THEN
                    IF (UPPER(TRIM(p_networkid_switch)) = 'AMEX' AND p_incr_indicator = 'E') THEN
                        v_trantype := 'E';
                    ELSE
                        v_trantype := 'N';
                    END IF;
                ELSE
                    v_trantype := 'N';
                END IF;


                  BEGIN
                     INSERT INTO cms_preauth_transaction
                                 (cpt_card_no, cpt_txn_amnt, cpt_expiry_date,
                                  cpt_sequence_no, cpt_preauth_validflag, cpt_inst_code,
                                  cpt_mbr_no, cpt_card_no_encr, cpt_completion_flag,
                                  cpt_approve_amt,
                                  cpt_rrn, cpt_txn_date, cpt_txn_time, cpt_terminalid,
                                  cpt_expiry_flag,
                                  cpt_totalhold_amt,
                                  cpt_transaction_flag, cpt_acct_no, cpt_mcc_code,
                                  cpt_completion_fee,
                                  --Sn Added for Transactionlog Functional Removal Phase-II changes
                                  cpt_delivery_channel, cpt_txn_code, cpt_merchant_id,
                                  cpt_merchant_name,  cpt_merchant_city, cpt_merchant_state,
                                  cpt_merchant_zip,  cpt_pos_verification, cpt_internation_ind_response,
                                  --En Added for Transactionlog Functional Removal Phase-II changes
                                  cpt_complfree_flag,
                                  cpt_payment_type,
                                  cpt_extended_auth_date,       --Added for VMS_9194
                                  cpt_expected_clearing_date,   --Added for VMS_9194
                                  cpt_extended_auth_identifier  --Added for VMS_9194
                                 )
                          VALUES (v_hash_pan, v_tran_amt, v_preauth_date,
                                  '1', 'Y', p_inst_code,
                                  p_mbr_numb, v_encr_pan, 'N',
                                  TRIM (TO_CHAR (NVL (v_tran_amt, 0),
                                                 '999999999999999990.99'
                                                )
                                       ),
                                  p_rrn, p_tran_date, p_tran_time, p_term_id,
                                  'N',
                                  TRIM (TO_CHAR (NVL (v_tran_amt, 0),
                                                 '999999999999999990.99'
                                                )
                                       ),
                                  v_trantype, v_acct_number, p_mcc_code,
                                  v_comp_total_fee,
                                  --Sn Added for Transactionlog Functional Removal Phase-II changes
                                 p_delivery_channel, p_txn_code, p_merc_id,
                                 p_merchant_name, p_merchant_city, p_atmname_loc,
                                 p_merchant_zip, p_pos_verfication, p_international_ind,
                                 --En Added for Transactionlog Functional Removal Phase-II changes
                                 CASE WHEN v_comp_freetxn_exceed='N' THEN 'Y' END,
                                 V_MS_PYMNT_TYPE,
                                 v_extended_auth_date,      --Added for VMS_9194
                                 v_expected_clearing_date,   --Added for VMS_9194
                                 v_extended_auth_identifier --Added for VMS_9194
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'Error while inserting PREAUTH TRANSACTION '
                           || SUBSTR (SQLERRM, 1, 300);
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                  END;
            WHEN exp_reject_record THEN
                    RAISE;
            WHEN OTHERS THEN
                  v_err_msg := 'Error while selecting v_preauth_count  from PREAUTH TRANSACTION '
                     || SUBSTR (SQLERRM, 1, 300);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
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
              CPH_ACCT_NO, --Added by Deepa on 26-Nov-2012 to log the Account number of preauth transactions
              --Sn Added by Pankaj S. for Mantis ID 11540
              CPH_MERCHANT_NAME,
              CPH_MERCHANT_STATE,
              CPH_MERCHANT_CITY
              --En Added by Pankaj S. for Mantis ID 11540
              ,CPH_DELIVERY_CHANNEL
              ,CPH_TRAN_CODE,
              CPH_PANNO_LAST4DIGIT,  --Added by Abdul Hameed M.A on 12 Feb 2014 for Mantis ID 13645
               cph_completion_fee --Added for FSS 837
              ,CPH_EXTENDED_AUTH_DATE       --Added for VMS_9194
              ,CPH_EXPECTED_CLEARING_DATE   --Added for VMS_9194
              ,CPH_EXTENDED_AUTH_IDENTIFIER --Added for VMS_9194
             )
            VALUES
             (V_HASH_PAN,
              v_tran_amt , -- V_TOTAL_AMT, replaced by v_tran_amt for OLS changes
              V_PREAUTH_DATE,
              p_rrn , -- 1 replaced by p_rrn for OLS changes
              'Y',
              P_INST_CODE,
              P_MBR_NUMB,
              V_ENCR_PAN,
              'N',
              --trim(to_char(nvl(V_TOTAL_AMT,0),'999999999999999990.99')),  --formatted for 10871
                        --Commented and modified on 24.07.2013 for 11692
              TRIM (TO_CHAR (nvl(v_tran_amt,0),'999999999999999990.99')),
              P_RRN,
              P_TRAN_DATE,
              P_TERM_ID,
              'N',
              V_TRANTYPE,
              trim(to_char(nvl(V_TRAN_AMT,0),'999999999999999990.99')),  --formatted for 10871
              P_RRN,
              V_ACCT_NUMBER, --Added by Deepa on 26-Nov-2012 to log the Account number of preauth transactions
              --Sn added by Pankaj S. for Mantis ID-11540
              P_MERCHANT_NAME,
              P_ATMNAME_LOC,
              P_MERCHANT_CITY
              --En added by Pankaj S. for Mantis ID-11540
              ,P_DELIVERY_CHANNEL
              ,P_TXN_CODE, -- Added for Mantis ID -13467
               (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))), --Added by Abdul Hameed M.A on 12 Feb 2014 for Mantis ID 13645
               v_comp_total_fee --Added for FSS 837
               ,v_extended_auth_date        --Added for VMS_9194
               , v_expected_clearing_date   --Added for VMS_9194
               ,v_extended_auth_identifier  --Added for VMS_9194
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

--Commended by Saravanakumar on 25-Sep-2014
     ---Sn Updation of Usage limit and amount
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
    --En Added by Pankaj S. for enabling limit validation

    BEGIN
        IF v_partial_appr = 'Y' AND v_resp_cde = '1' THEN
               v_resp_cde := '2';
         END IF;
    END;

    P_RESP_ID := V_RESP_CDE; --Added for VMS-8018
    BEGIN
     SELECT CMS_B24_RESPCDE, --Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
            cms_iso_respcde  -- Added for OLS changes
       INTO P_RESP_CODE,
            --v_cms_iso_respcde    -- Added for OLS changes
            P_ISO_RESPCDE --Commented and replaced  on 17.07.2013 for the Mantis ID 11612
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

--SN added for VMS_8140
        BEGIN
            sp_autonomous_preauth_logclear(v_auth_id);
        EXCEPTION
            When others then
            null;
        END;
--EN added for VMS_8140

       select (extract(day from systimestamp - v_start_time) *86400+
    extract(hour from systimestamp - v_start_time) *3600+
    extract(minute from systimestamp - v_start_time) *60+
    extract(second from systimestamp - v_start_time) *1000) into v_mili from dual ;

     P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 4: ' || v_mili ;
     P_RESP_TIME := v_mili;
  EXCEPTION
    --<< MAIN EXCEPTION >>
    WHEN EXP_REJECT_RECORD THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
        INTO V_ACCT_BALANCE, V_LEDGER_BAL
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =V_ACCT_NUMBER--Modified by Saravanakumar on 25-Sep-2014
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

        IF v_delayed_amount>0 AND v_resp_cde='15' THEN
             v_resp_cde:='1000';
        END IF;

       P_RESP_ID := V_RESP_CDE; --Added for VMS-8018

       -- Assign the response code to the out parameter
       SELECT CMS_B24_RESPCDE, --Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
              cms_iso_respcde  -- Added for OLS changes
        INTO P_RESP_CODE,
             --v_cms_iso_respcde  -- Added for OLS changes
             P_ISO_RESPCDE --Commented and replaced  on 17.07.2013 for the Mantis ID 11612
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
         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         CTD_NETWORK_ID,
         CTD_INTERCHANGE_FEEAMT,
         CTD_MERCHANT_ZIP,
         CTD_MERCHANT_ID,
         CTD_COUNTRY_CODE,
         /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         ctd_ins_user, -- Added for OLS changes
         ctd_ins_date,  -- Added for OLS changes
         ctd_completion_fee, --Added for FSS 837
         ctd_complfee_increment_type,CTD_COMPFEE_CODE,CTD_COMPFEEATTACH_TYPE,CTD_COMPFEEPLAN_ID --Added for FSS 837
         ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,CTD_CARDVERIFICATION_RESULT--Added for MVHOST 926
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
         P_TXN_AMT,--V_TRAN_AMT, --P_TXN_AMT, modified for 10871 modified for defect id:12166
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
         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         P_NETWORK_ID,
         P_INTERCHANGE_FEEAMT,
         P_MERCHANT_ZIP,
         P_MERC_ID,
         P_MERC_CNTRYCODE,
         /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         1,
         sysdate,
         v_comp_total_fee,v_complfee_increment_type,v_comp_fee_code,v_comp_feeattach_type,v_comp_fee_plan --Added for FSS 837
          ,P_PULSE_TRANSACTIONID,--Added for MVHOST 926
        P_VISA_TRANSACTIONID,--Added for MVHOST 926
        P_MC_TRACEID,--Added for MVHOST 926
        P_CARDVERIFICATION_RESULT--Added for MVHOST 926
        ,P_MS_PYMNT_DESC,v_hashkey_id
         );

       P_RESP_MSG := V_ERR_MSG;
    select (extract(day from systimestamp - v_start_time) *86400+
    extract(hour from systimestamp - v_start_time) *3600+
    extract(minute from systimestamp - v_start_time) *60+
    extract(second from systimestamp - v_start_time) *1000) into v_mili from dual ;

     P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 4: ' || v_mili ;
     P_RESP_TIME := v_mili;
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

--Commended by Saravanakumar on 25-Sep-2014
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
             --v_cms_iso_respcde
             P_ISO_RESPCDE --Commented and replaced  on 17.07.2013 for the Mantis ID 11612
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
         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         CTD_NETWORK_ID,
         CTD_INTERCHANGE_FEEAMT,
         CTD_MERCHANT_ZIP,
         CTD_MERCHANT_ID,
         CTD_COUNTRY_CODE,
         /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         ctd_ins_user, -- Added for OLS changes
         ctd_ins_date,  -- Added for OLS changes
         ctd_completion_fee,ctd_complfee_increment_type,CTD_COMPFEE_CODE,CTD_COMPFEEATTACH_TYPE,CTD_COMPFEEPLAN_ID --Added for FSS 837
         ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,CTD_CARDVERIFICATION_RESULT--Added for MVHOST 926
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
         P_TXN_AMT,--V_TRAN_AMT, --P_TXN_AMT, modified for 10871 modified for defect id:12166
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
         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         P_NETWORK_ID,
         P_INTERCHANGE_FEEAMT,
         P_MERCHANT_ZIP,
         P_MERC_ID,
         P_MERC_CNTRYCODE,
         /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         1,
         sysdate,
         v_comp_total_fee,v_complfee_increment_type,v_comp_fee_code,v_comp_feeattach_type,v_comp_fee_plan --Added for FSS 837
         ,P_PULSE_TRANSACTIONID,--Added for MVHOST 926
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
  IF V_RESP_CDE = '1' OR v_resp_cde = '2' -- OR condition Added for OLS changes
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
      WHERE CAM_ACCT_NO =V_ACCT_NUMBER--Modified by Saravanakumar on 25-Sep-2014
           /*(SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
                 CAP_INST_CODE = P_INST_CODE)*/ AND
           CAM_INST_CODE = P_INST_CODE;
        --FOR UPDATE NOWAIT;                                                    -- Commented for Concurrent Processsing Issue
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

     V_LEDGER_BAL := p_ledger_bal;--Added on 29.10.2013 for 12087

    --En find prod code and card type for the card number
    IF V_OUTPUT_TYPE = 'N' THEN
     --Balance Inquiry
     P_RESP_MSG := TO_CHAR(V_UPD_AMT+v_delayed_amount);
    END IF;
  END IF;

  --En create GL ENTRIES

  --Sn added by Pankaj S. for 10871
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
       if V_MS_PYMNT_TYPE is not null then
   --V_TRANS_DESC:='MoneySend'||' '||V_TRANS_DESC;
    V_TRANS_DESC:='MoneySend Funding Auth';
   end if;
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
  --En added by Pankaj S. for 10871

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
      CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
      /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
      NETWORK_ID,
      INTERCHANGE_FEEAMT,
      MERCHANT_ZIP,
      MERCHANT_ID,
      COUNTRY_CODE,
      /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
      FEE_PLAN,
      POS_VERIFICATION, --Added by Deepa on July 03 2012 to log the verification of POS
      FEEATTACHTYPE, -- Added by Trivikram on 05-Sep-2012
      --Sn added by Pankaj S. for 10871
      acct_type,
      error_msg,
      time_stamp,
      --En added by Pankaj S. for 10871
      partial_preauth_ind, -- Added for OLS changes
      add_ins_user,         -- Added for OLS changes
      NETWORKID_SWITCH, --Added on 20130626 for the Mantis ID 11344
      NETWORKID_ACQUIRER, --Added on 20130626 for the Mantis ID 11344
      NETWORK_SETTL_DATE, --Added on 20130626 for the Mantis ID 11123
      --Sn Added by Pankaj S. for Mantis ID 11540
      MERCHANT_NAME,
      MERCHANT_STATE,
      MERCHANT_CITY,
      --En Added by Pankaj S. for Mantis ID 11540
      CVV_VERIFICATIONTYPE,  --Added on 17.07.2013 for the Mantis ID 11611
      addr_verify_indicator, -- added on 11.02.2013 for mantis id 13135
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
      --DECODE(P_RESP_CODE, '00', 'C', 'F'),  -- Commented for OLS changes
      --DECODE (v_cms_iso_respcde, '00', 'C', 'F'), --Added for OLS changes
      DECODE (P_ISO_RESPCDE, '00', 'C', 'F'), --Commented and replaced  on 17.07.2013 for the Mantis ID 11612
      --P_RESP_CODE,        -- Commented for OLS changes
      --v_cms_iso_respcde,      --Added for OLS changes
      P_ISO_RESPCDE ,--Commented and replaced  on 17.07.2013 for the Mantis ID 11612
      P_TRAN_DATE,
      P_TRAN_TIME,
      V_HASH_PAN,
      NULL,
      NULL, --P_topup_acctno    ,
      NULL, --P_topup_accttype,
      P_BANK_CODE,
      TRIM(TO_CHAR(nvl(V_TOTAL_AMT,0), '999999999999999990.99')), --modified for 10871
      NULL,
      NULL,
      P_MCC_CODE,  -- Added for FSS-781
      P_CURR_CODE,
      NULL, -- P_add_charge,
      V_PROD_CODE,
      V_PROD_CATTYPE,
      nvl(P_TIP_AMT,'0.00'),  --formatted by Pankaj S. for 10871
      P_DECLINE_RULEID,
      P_ATMNAME_LOC,
      V_AUTH_ID,
      V_TRANS_DESC,
      TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')), --modified for 10871
      P_MERC_CNTRYCODE, --modified by Pankaj S. for 10871
      '0.00', --modified by Pankaj S. for 10871 -- Partial amount (will be given for partial txn)
      P_MCCCODE_GROUPID,
      P_CURRCODE_GROUPID,
      P_TRANSCODE_GROUPID,
      P_RULES,
      NULL,
      V_GL_UPD_FLAG,
      P_STAN,
      P_INST_CODE,
      V_FEE_CODE,
      nvl(V_FEE_AMT,0),--modified for 10871
      nvl(V_SERVICETAX_AMOUNT,0),--modified for 10871
      nvl(V_CESS_AMOUNT,0),--modified for 10871
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
      P_ADDR_VERFY_RESPONSE, -- added for ols changes
      V_PROXUNUMBER,
      P_RVSL_CODE,
      V_ACCT_NUMBER,
      V_ACCT_BALANCE,
      V_LEDGER_BAL,
      P_INTERNATIONAL_IND, --Added by Deepa on July 03 2012 to log International Indicator
      V_RESP_CDE,
      V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
      /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
      P_NETWORK_ID,
      P_INTERCHANGE_FEEAMT,
      P_MERCHANT_ZIP,
      P_MERC_ID,
      P_COUNTRY_CODE,
      /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
      V_FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
      P_POS_VERFICATION, --Added by Deepa on July 03 2012 to log the verification of POS
      V_FEEATTACH_TYPE ,-- Added by Trivikram on 05-Sep-2012
      --Sn added by Pankaj S. for 10871
      v_acct_type,
      v_err_msg,
      nvl(v_timestamp,systimestamp),
      --En added by Pankaj S. for 10871
      p_partial_preauth_ind,
      1,
      P_NETWORKID_SWITCH , --Added on 20130626 for the Mantis ID 11344
      P_NETWORKID_ACQUIRER,-- Added on 20130626 for the Mantis ID 11344
      p_network_setl_date,  --Added on 20130626 for the Mantis ID 11123
      --Sn added by Pankaj S. for Mantis ID-11540
      P_MERCHANT_NAME,
      P_ATMNAME_LOC,
      P_MERCHANT_CITY,
      --En added by Pankaj S. for Mantis ID-11540
      NVL(P_CVV_VERIFICATIONTYPE,'N'),  --Added on 17.07.2013 for the Mantis ID 11611
      P_ADDRVERIFY_FLAG, -- added on 11.02.2013 for mantis id 13135
      DECODE(v_resp_cde,'1000','Decline due to redemption delay',V_ERR_MSG), --Added for error msg need to display in CSR(declined by rule)
      DECODE(p_surchrg_ind,'2',NULL,p_surchrg_ind) --Added for VMS-5856
      );

    P_CAPTURE_DATE := V_BUSINESS_DATE;
    P_AUTH_ID      := V_AUTH_ID;
    select (extract(day from systimestamp - v_start_time) *86400+
    extract(hour from systimestamp - v_start_time) *3600+
    extract(minute from systimestamp - v_start_time) *60+
    extract(second from systimestamp - v_start_time) *1000) into v_mili from dual ;

     P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 4: ' || v_mili ;
     P_RESP_TIME := v_mili;
  EXCEPTION
    WHEN OTHERS THEN
     ROLLBACK;
     P_RESP_CODE := '69'; -- Server Declione
     P_RESP_ID   := '69'; --Added for VMS-8018
     P_RESP_MSG  := 'Problem while inserting data into transaction log  ' ||
                 SUBSTR(SQLERRM, 1, 300);
  END;
  --En create a entry in txn log


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