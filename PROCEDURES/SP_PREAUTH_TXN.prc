set define off;
create or replace
PROCEDURE VMSCMS.SP_PREAUTH_TXN (
    P_INST_CODE                 IN      NUMBER,
    P_MSG                         IN      VARCHAR2,
    P_RRN                                  VARCHAR2,
    P_DELIVERY_CHANNEL                 VARCHAR2,
    P_TERM_ID                             VARCHAR2,
    P_TXN_CODE                             VARCHAR2,
    P_TXN_MODE                             VARCHAR2,
    P_TRAN_DATE                          VARCHAR2,
    P_TRAN_TIME                          VARCHAR2,
    P_CARD_NO                             VARCHAR2,
    P_BANK_CODE                          VARCHAR2,
    P_TXN_AMT                             NUMBER,
    P_MERCHANT_NAME                     VARCHAR2,
    P_MERCHANT_CITY                     VARCHAR2,
    P_MCC_CODE                             VARCHAR2,
    P_CURR_CODE                          VARCHAR2,
    P_POS_VERFICATION                  VARCHAR2, --Modified by Deepa On June 19th for Fees Changes
    P_CATG_ID                             VARCHAR2,
    P_TIP_AMT                             VARCHAR2,
    P_DECLINE_RULEID                     VARCHAR2,
    P_ATMNAME_LOC                         VARCHAR2,
    P_MCCCODE_GROUPID                  VARCHAR2,
    P_CURRCODE_GROUPID                 VARCHAR2,
    P_TRANSCODE_GROUPID                 VARCHAR2,
    P_RULES                                 VARCHAR2,
    P_PREAUTH_DATE                      DATE,
    P_CONSODIUM_CODE            IN      VARCHAR2,
    P_PARTNER_CODE             IN      VARCHAR2,
    P_EXPRY_DATE                IN      VARCHAR2,
    P_STAN                        IN      VARCHAR2,
    P_MBR_NUMB                    IN      VARCHAR2,
    P_PREAUTH_EXPPERIOD        IN      VARCHAR2,
    P_INCR_INDICATOR            IN      VARCHAR2,
    P_PREAUTH_SEQNO            IN      VARCHAR2,
    P_RVSL_CODE                 IN      NUMBER,
    P_ZIP_CODE                    IN      VARCHAR2, --T.Narayanan Changed for Address Verification Indicator Changes.
    P_PARTIAL_PREAUTH_IND    IN      VARCHAR2, --Added for Partial Preauth srinivasu
    P_INTERNATIONAL_IND        IN      VARCHAR2,                                             --
    P_ADDRVERIFY_FLAG         IN      VARCHAR2,
    /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
    P_MERC_ID                    IN      VARCHAR2,
    P_COUNTRY_CODE             IN      VARCHAR2,
    P_NETWORK_ID                IN      VARCHAR2,
    P_INTERCHANGE_FEEAMT     IN      NUMBER,
    P_MERCHANT_ZIP             IN      VARCHAR2,
    /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
    P_NETWORK_SETL_DATE        IN      VARCHAR2, -- Added on 201112 for logging N/W settlement date in transactionlog
    P_NETWORKID_SWITCH        IN      VARCHAR2, --Added on 20130626 for the Mantis ID 11344
    P_AUTH_ID                        OUT VARCHAR2,
    P_RESP_CODE                     OUT VARCHAR2,
    P_RESP_MSG                        OUT VARCHAR2,
    P_CAPTURE_DATE                 OUT DATE,
    P_ADDR_VERFY_RESPONSE        OUT VARCHAR2,
    P_PARTIALAUTH_AMOUNT         OUT VARCHAR2 --T.Narayanan Changed for Address Verification Indicator Changes.
    ,P_RESP_ID                   OUT VARCHAR2 --Added for sending to FSS (VMS-8018)
                                                        )
IS
    /***************************************************************************************************
        * Modified By          :  Sagar
        * Modified Date      :  24-Jan-2013
        * Modified For       :  Modified for defect 10121, 10122
        * Modified Reason   :  1) To update preauth date by adding expiry period and txn_date
                                      2) To pass transaction amount in CPH_TXN_AMNT and ignore toatal amount
        * Reviewer              :  Dhiraj
        * Reviewed Date      :  25-Jan-2013
        * Release Number      :  RI0023.1_B0008

        * Modified By          :  Sagar
        * Modified Date      :  25-Feb-2013
        * Modified For       :  FSS-781
                                      Defect--10406
        * Modified Reason   :  1) To insert input MCC code into CMS_PREAUTH_TRANSACTION table FSS-781
                                      2) To ignore hold days from Elan when v_hold_days = 0 FSS-781
                                      3) Commented max card balance check Defect--10406
        * Release Number      :  CMS3.5.1_RI0023.2_B0011

        * Modified By          :  Deepa T
        * Modified Date      :  06-Mar-2013
        * Modified For       :  Mantis ID- 10538
        * Modified Reason   :  To log the amount for AVS declined transactions.If the amount logged it will be displaed in CSR
        * Reviewer              :  Dhiraj
        * Reviewed Date      :  06-Mar-2013
        * Release Number      :  CMS3.5.1_RI0023.2_B0015

        * Modified By          :  Sagar M.
        * Modified Date      :  14-Mar-2013
        * Modified For       :  FSS-943
        * Modified Reason   :  Country code and Zip code validations
        * Reviewer              :  Dhiraj
        * Reviewed Date      :  14-Mar-2013
        * Release Number      :  CMS3.5.1_RI0024_B0004

        * Modified By          :  Ramesh.A
        * Modified Date      :  23-Mar-2013
        * Modified For       :  MVHOST-300,301
        * Modified Reason   :  AVS & ZIP validation changes
        * Reviewer              :  NA
        * Reviewed Date      :  NA
        * Release Number      :  CMS3.5.1_RI0024.0.1_B0001

        * Modified By          :  Dhinakaran B
        * Modified Date      :  25 -APR-2013
        * Modified For       :  MVHOST-346
        * Modified Reason   :  Enable claw back option for the non-financial transactions
        * Reviewer              :
        * Reviewed Date      :
        * Release Number      :  RI0024.1_B0011

        * Modified by          :  Pankaj S.
        * Modified Reason   :  10871
        * Modified Date      :  19-Apr-2013
        * Reviewer              :  Dhiraj
        * Reviewed Date      :
        * Build Number       :  RI0024.1_B0013

        * Modified by          :  Ranveer Meel.
        * Modified Reason   :  Preauth normal transaction details with same RRN - Response 89 instead of 22 - Resource busy
        * Modified Date      :  18-JUN-2013
        * Reviewer              :  Saravana kumar
        * Reviewed Date      :  18-JUN-2013
        * Build Number       :  RI0024.2_B0004

        * Modified by         : Ravi N
        * Modified for      : Mantis ID 0011282
        * Modified Reason  : Correction of Insufficient balance spelling mistake
        * Modified Date     : 20-Jun-2013
        * Reviewer             : Dhiraj
        * Reviewed Date     : 18-JUN-2013
        * Build Number      : RI0024.2_B0006

        * Modified by         : Deepa T
        * Modified for      : Mantis ID 11344
        * Modified Reason  : Log the Network ID as ELAN
        * Modified Date     : 26-Jun-2013
        * Reviewer             : Dhiraj
        * Reviewed Date     : 27-06-2013
        * Build Number      : RI0024.2_B0009

        * Modified by         : Sagar
        * Modified for      : FSS-1246
        * Modified Reason  : To validate preauth expiry period value
        * Modified Date     : 09-Jul-2013
        * Reviewer             : Dhiraj
        * Reviewed Date     :
        * Build Number      : RI0024.3_B0004

        * Modified by         : Sagar
        * Modified for      : FSS-1246 Review observations
        * Modified Reason  : Review observations
        * Modified Date     : 09-Jul-2013
        * Reviewer             : Dhiraj
        * Reviewed Date     :
        * Build Number      : RI0024.3_B000

        * Modified by          : Sachin P
        * Modified for       : Mantis Id:11692
        * Modified Reason   : In Force post completion transaction, txn amount is logged as incorrect(i.e txn amount+fee amount)
                                    in cms_preauth_transaction,CMS_PREAUTH_TRANS_HIST tables and during preauth transaction,
                                    approve amount is logged with fee amount.In Preauth completion procedure
                                  'Successful preauth completion already done' check does not have the inst code condition.
        * Modified Date      : 24-Jul-2013
        * Reviewer              : Dhiraj
        * Reviewed Date      : 19-aug-2013
        * Build Number       : RI0024.4_B0002

        * Modified by          :  Pankaj S.
        * Modified for       :  MVCSD-4445/MVHOST-363
        * Modified Reason   :  Modified for 3 decimal amount issue
        * Modified Date      :  03-Sep-2013
        * Reviewer              :  Dhiraj
        * Reviewed Date      :  03-Sep-2013
        * Build Number       :  RI0024.3.6_B0002


        * Modified by         :  Siva Kumar M
        * Modified Reason  :  Defect Id: 12166
        * Modified Date     :  12-Sept-2013
        * Reviewer             :  Dhiraj
        * Reviewed Date     :  12-Sept-2013
        * Build Number      :  RI0024.4_B0011

        * Modified by          :  Pankaj S.
        * Modified Reason   :  Enabling Limit configuration and validation for Preauth(1.7.3.9 changes integrate)
        * Modified Date      :  23-Oct-2013
        * Reviewer              :  Dhiraj
        * Reviewed Date      :
        * Build Number       : RI0024.5.2_B0001

        * Modified by         : Sachin P
        * Modified for      : 12087 ,12568
        * Modified Reason  : 12087:Fee amount not deducted from ledger balance in transaction log table
                                    12568:Purchase Transaction with Partial Indiator, Fee and P-4 >
                                    Account Bal. is failing with Insufficient Balance.
        * Modified Date     : 29.Oct.2013
        * Reviewer             : Dhiraj
        * Reviewed Date     : 29.Oct.2013
        * Build Number      : RI0024.6_B0004

        * Modified by         : Ramesh
        * Modified for      : FSS-1388
        * Modified Reason  : AVS ZIP code validation changes (It will match first 5 digits of zip code if both txn and customer zipcode is in numeric.)
        * Modified Date     : 20.Dec.2013
        * Reviewer             : Dhiraj
        * Reviewed Date     : 23.Dec.2013
        * Build Number      : RI0024.6.3_B0006

        * Modified by         : Ramesh
        * Modified for      : Defect id :13297 & 13296
        * Modified Reason  : The Address Verification Indicator Occurs as N instead of W   and     Zip code validation for Elan Transaction: Not display the address verification indicat
        * Modified Date     : 26.Dec.2013
        * Reviewer             : Dhiraj
        * Reviewed Date     : 26.Dec.2013
        * Build Number      : RI0024.6.3_B0007

        * Modified by          :  Pankaj S.
        * Modified Reason   :  3 decimal amount issue(MVHOST-750)
        * Modified Date      :  16-Jan-2014
        * Reviewer              :  Dhiraj
        * Reviewed Date      :  16-Jan-2014
        * Build Number       : RI0027_B0004

        * Modified By         : MageshKumar S
        * Modified Date     : 28-Jan-2014
        * Modified for      : MVCSD-4471
        * Modified Reason  : Narration change for FEE amount
        * Reviewer             : Dhiraj
        * Reviewed Date     : 28-Jan-2014
        * Build Number      : RI0027.1_B0001

        * Modified by          : Sagar
        * Modified for       :
        * Modified Reason   : Concurrent Processsing Issue
                                      (1.7.6.7 changes integarted)
        * Modified Date      : 04-Mar-2014
        * Reviewer              : Dhiarj
        * Reviewed Date      : 06-Mar-2014
        * Build Number       : RI0027.1.1_B0001

        * Modified by          : Abdul Hameed M.A
        * Modified for       : Mantis ID 13893
        * Modified Reason   : Added card number for duplicate RRN check
        * Modified Date      : 06-Mar-2014
        * Reviewer              : Dhiraj
        * Reviewed Date      : 06-Mar-2014
        * Build Number       : RI0027.2_B0002

        * Modified By          : Sankar S
        * Modified Date      : 08-APR-2014
        * Modified for       :
        * Modified Reason  : 1.Round functions added upto 2nd decimal for amount columns in CMS_CHARGE_DTL,CMS_ACCTCLAWBACK_DTL,
                                             CMS_STATEMENTS_LOG,TRANSACTIONLOG.
                                                 2.V_TRAN_AMT initial value assigned as zero.
        * Reviewer                  : Pankaj S.
        * Reviewed Date      : 08-APR-2014
        * Build Number       : CMS3.5.1_RI0027.2_B0005
        
    * modified by       : Amudhan S/Siva Kumar
    * modified Date     : 23-may-14
    * modified for      : FWR 64/FSS-837
    * modified reason   : To restrict clawback fee entries as per the configuration done by user/To hold the Preauth completion fee at the time of preauth.
    * Reviewer          : Spankaj
    * Build Number      : RI0027.3_B0001
    
    
    * modified by       : Siva Kumar
    * modified Date     : 21-July-14
    * modified for      : Mantis Id:0015595 
    * modified reason   : Partial Pre-Auth Transaction Issues 
    * Reviewer          : Spankaj
    * Build Number      : RI0027.3_B0005
    
    * modified by       : Siva Kumar
    * modified Date     : 23-July-14
    * modified for      : Mantis Id:0015618
    * modified reason   : Incremental Pre-Auth is Failing with ORA error
    * Reviewer          : Spankaj
    * Build Number      : RI0027.3_B0006
    
    * Modified By      :  Mageshkumar S   
    * Modified For     :  FWR-48
    * Modified Date    :  25-July-2014
    * Modified Reason  :  GL Mapping Removal Changes.
    * Reviewer         :  Spankaj
    * Build Number     :  RI0027.3.1_B0001
    
     * Modified Date    : 29-SEP-2014
       * Modified By      : Abdul Hameed M.A
       * Modified for     : FWR 70
       * Reviewer        :  spankaj
       * Release Number   : Ri0027.4_B0002
       
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

    * Modified By      : Sreeja D
    * Modified Date    : 19/02/2018
    * Purpose          : 17.12.3/AVS AMEX
    * Reviewer         : Saravanankumar A
    * Release Number   : VMSGPRHOST17.12.3
	
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

    ******************************************************************************************************/
    V_ERR_MSG                    VARCHAR2 (900) := 'OK';
    V_ACCT_BALANCE             NUMBER;
    V_LEDGER_BAL                NUMBER;
    V_TRAN_AMT                    NUMBER := 0;  --Modified by Sankar S on 08-Apr-2014
    V_AUTH_ID                    VARCHAR2 (14);
    V_TOTAL_AMT                 NUMBER;
    V_TRAN_DATE                 DATE;
    V_FUNC_CODE                 CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
    V_PROD_CODE                 CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
    V_PROD_CATTYPE             CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
    V_FEE_AMT                    NUMBER;
    V_TOTAL_FEE                 NUMBER;
    V_UPD_AMT                    NUMBER;
    V_UPD_LEDGER_AMT            NUMBER;
    V_NARRATION                 VARCHAR2 (300);
    V_FEE_OPENING_BAL         NUMBER;
    V_RESP_CDE                    VARCHAR2 (5);
    V_EXPRY_DATE                DATE;
    V_DR_CR_FLAG                VARCHAR2 (2);
    V_OUTPUT_TYPE                VARCHAR2 (2);
    V_APPLPAN_CARDSTAT        CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
    V_ATMONLINE_LIMIT         CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
    V_POSONLINE_LIMIT         CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
    V_PRECHECK_FLAG            NUMBER;
    V_PREAUTH_FLAG             NUMBER;
    V_GL_UPD_FLAG                TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
    V_GL_ERR_MSG                VARCHAR2 (500);
    V_SAVEPOINT                 NUMBER := 0;
    V_TRAN_FEE                    NUMBER;
    V_ERROR                        VARCHAR2 (500);
    V_BUSINESS_DATE_TRAN     DATE;
    V_BUSINESS_TIME            VARCHAR2 (5);
    V_CUTOFF_TIME                VARCHAR2 (5);
    V_CARD_CURR                 VARCHAR2 (5);
    V_FEE_CODE                    CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
    V_FEE_CRGL_CATG            CMS_PRODCATTYPE_FEES.CPF_CRGL_CATG%TYPE;
    V_FEE_CRGL_CODE            CMS_PRODCATTYPE_FEES.CPF_CRGL_CODE%TYPE;
    V_FEE_CRSUBGL_CODE        CMS_PRODCATTYPE_FEES.CPF_CRSUBGL_CODE%TYPE;
    V_FEE_CRACCT_NO            CMS_PRODCATTYPE_FEES.CPF_CRACCT_NO%TYPE;
    V_FEE_DRGL_CATG            CMS_PRODCATTYPE_FEES.CPF_DRGL_CATG%TYPE;
    V_FEE_DRGL_CODE            CMS_PRODCATTYPE_FEES.CPF_DRGL_CODE%TYPE;
    V_FEE_DRSUBGL_CODE        CMS_PRODCATTYPE_FEES.CPF_DRSUBGL_CODE%TYPE;
    V_FEE_DRACCT_NO            CMS_PRODCATTYPE_FEES.CPF_DRACCT_NO%TYPE;
    --st AND cess
    V_SERVICETAX_PERCENT     CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
    V_CESS_PERCENT             CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
    V_SERVICETAX_AMOUNT        NUMBER;
    V_CESS_AMOUNT                NUMBER;
    V_ST_CALC_FLAG             CMS_PRODCATTYPE_FEES.CPF_ST_CALC_FLAG%TYPE;
    V_CESS_CALC_FLAG            CMS_PRODCATTYPE_FEES.CPF_CESS_CALC_FLAG%TYPE;
    V_ST_CRACCT_NO             CMS_PRODCATTYPE_FEES.CPF_ST_CRACCT_NO%TYPE;
    V_ST_DRACCT_NO             CMS_PRODCATTYPE_FEES.CPF_ST_DRACCT_NO%TYPE;
    V_CESS_CRACCT_NO            CMS_PRODCATTYPE_FEES.CPF_CESS_CRACCT_NO%TYPE;
    V_CESS_DRACCT_NO            CMS_PRODCATTYPE_FEES.CPF_CESS_DRACCT_NO%TYPE;
    --
    V_WAIV_PERCNT                CMS_PRODCATTYPE_WAIV.CPW_WAIV_PRCNT%TYPE;
    V_ERR_WAIV                    VARCHAR2 (300);
    V_LOG_ACTUAL_FEE            NUMBER;
    V_LOG_WAIVER_AMT            NUMBER;
    V_AUTH_SAVEPOINT            NUMBER DEFAULT 0;
    V_ACTUAL_EXPRYDATE        DATE;
    V_BUSINESS_DATE            DATE;
    V_TXN_TYPE                    NUMBER (1);
    V_MINI_TOTREC                NUMBER (2);
    V_MINISTMT_ERRMSG         VARCHAR2 (500);
    V_MINISTMT_OUTPUT         VARCHAR2 (900);
    EXP_REJECT_RECORD         EXCEPTION;
	  V_ATM_USAGEAMNT            CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_AMT%TYPE;
    V_POS_USAGEAMNT            CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_AMT%TYPE;
    V_ATM_USAGELIMIT            CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_LIMIT%TYPE;
    V_POS_USAGELIMIT            CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_LIMIT%TYPE;
    V_PREAUTH_DATE             DATE;
    V_PREAUTH_HOLD             VARCHAR2 (1);
    V_PREAUTH_PERIOD            NUMBER;
    V_PREAUTH_USAGE_LIMIT    NUMBER;
    V_CARD_ACCT_NO             VARCHAR2 (20);
    V_HOLD_AMOUNT                NUMBER;
    V_HASH_PAN                    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
    V_ENCR_PAN                    CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
    V_RRN_COUNT                 NUMBER;
    V_TRAN_TYPE                 VARCHAR2 (2);
    V_DATE                        DATE;
    V_TIME                        VARCHAR2 (10);
    V_MAX_CARD_BAL             NUMBER;
    V_CURR_DATE                 DATE;
    V_PREAUTH_EXP_PERIOD     VARCHAR2 (10);
    V_PREAUTH_COUNT            NUMBER;
    V_PREAUTH_CNT                NUMBER;
    V_TRANTYPE                    VARCHAR2 (2);
    V_ZIP_CODE                    VARCHAR2 (20);
    V_ACC_BAL                    VARCHAR2 (15);
    V_INTERNATIONAL_IND          CMS_PROD_CATTYPE.CPC_INTERNATIONAL_CHECK%TYPE;
    V_ADDRVRIFY_FLAG             CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_CHECK%TYPE;
	  V_ENCRYPT_ENABLE             CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
    V_ADDRVERIFY_RESP            CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_RESPONSE%TYPE;
    V_PROXUNUMBER                CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
    V_ACCT_NUMBER                CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
    V_TRANS_DESC                VARCHAR2 (50);
    V_AUTH_ID_GEN_FLAG        VARCHAR2 (1);
    V_STATUS_CHK                NUMBER;
    V_TRAN_PREAUTH_FLAG        CMS_TRANSACTION_MAST.CTM_PREAUTH_FLAG%TYPE;
    /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
    V_HOLD_DAYS                 CMS_TXNCODE_RULE.CTR_HOLD_DAYS%TYPE;
    V_HOLD_AMNT                 NUMBER;
    -- start Added on 06112012
    VT_PREAUTH_HOLD            VARCHAR2 (1);
    VT_PREAUTH_PERIOD         NUMBER;
    vp_preauth_exp_period    cms_prod_mast.cpm_pre_auth_exp_date%TYPE;
    VP_PREAUTH_HOLD            VARCHAR2 (1);
    VP_PREAUTH_PERIOD         NUMBER;
    vi_preauth_exp_period    cms_inst_param.cip_param_value%TYPE;
    VI_PREAUTH_HOLD            VARCHAR2 (1);
    VI_PREAUTH_PERIOD         NUMBER;
    -- end  Added on 06112012
    /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
    --Added by Deepa On June 19 2012 for Fees Changes
    V_FEEAMNT_TYPE             CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
    V_PER_FEES                    CMS_FEE_MAST.CFM_PER_FEES%TYPE;
    V_FLAT_FEES                 CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
    V_CLAWBACK                    CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
    V_FEE_PLAN                    CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;
    V_FREETXN_EXCEED            VARCHAR2 (1); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
    V_DURATION                    VARCHAR2 (20); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
    V_FEEATTACH_TYPE            VARCHAR2 (2); -- Added by Trivikram on 5th Sept 2012
    V_ZIP_CODE_IN                TRANSACTIONLOG.ZIP_CODE%TYPE; --Added by Deepa to validate 5 digits of ZIP code on OCT-19-2012


    v_first3_custzip            cms_addr_mast.cam_pin_code%TYPE; --Added for FSS-943 on 14-Mar-2013
    v_inputzip_length         NUMBER (3);       --Added for FSS-943 on 14-Mar-2013
    v_nonnumeric_chk            VARCHAR2 (2);      --Added for FSS-943 on 14-Mar-2013
    v_numeric_zip                cms_addr_mast.cam_pin_code%TYPE; --Added for FSS-943 on 14-Mar-2013
    v_cap_cust_code            cms_appl_pan.cap_cust_code%TYPE; --Added for FSS-943 on 14-Mar-2013

    v_txn_nonnumeric_chk     VARCHAR2 (2); --Added for MVHOST-300 & 301 ( AVS & ZIP validation changes) on 23/04/2013
    v_cust_nonnumeric_chk    VARCHAR2 (2); --Added for MVHOST-300 & 301 ( AVS & ZIP validation changes) on 23/04/2013
    v_removespace_txn         VARCHAR2 (10); --Added for MVHOST-300 & 301 ( AVS & ZIP validation changes) on 23/04/2013
    v_removespace_cust        VARCHAR2 (10); --Added for MVHOST-300 & 301 ( AVS & ZIP validation changes) on 23/04/2013

    v_actual_fee_amnt         NUMBER; --Added For Clawback Changes (MVHOST - 346) on 25/04/2013
    v_clawback_count            NUMBER; --Added For Clawback Changes (MVHOST - 346) on 25/04/2013
    v_acct_bal_fee             cms_acct_mast.cam_acct_bal%TYPE; --Added For Clawback Changes (MVHOST - 346) on 25/04/2013
    v_clawback_amnt            cms_fee_mast.cfm_fee_amt%TYPE; --Added For Clawback Changes (MVHOST - 346) on 25/04/2013
    v_clawback_txn             cms_transaction_mast.ctm_login_txn%TYPE; --Added For Clawback Changes (MVHOST - 346) on 25/04/2013
    --Sn added by Pankaj S. for 10871
    v_acct_type                 cms_acct_mast.cam_type_code%TYPE;
    v_timestamp                 TIMESTAMP (3);
    --En added by Pankaj S. for 10871

    v_preauth_expperiod        cms_inst_param.cip_param_value%TYPE; -- Added for FSS-1246

    --Sn Added by Pankaj S. for enabling limit validation
    v_prfl_flag                 cms_transaction_mast.ctm_prfl_flag%TYPE;
    v_prfl_code                 cms_appl_pan.cap_prfl_code%TYPE;
    v_comb_hash                 pkg_limits_check.type_hash;
    --En Added by Pankaj S. for enabling limit validation

    V_FEE_DESC                    cms_fee_mast.cfm_fee_desc%TYPE; -- Added for MVCSD-4471
   v_tot_clwbck_count CMS_FEE_MAST.cfm_clawback_count%TYPE; -- Added for FWR 64
  v_chrg_dtl_cnt    NUMBER;     -- Added for FWR 64
  
  
  
  -- Added for FSS-837 on 23-06-2014 
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
   v_comp_total_fee            NUMBER;
   v_tot_hold_amt              NUMBER;
   v_partial_appr              VARCHAR2 (1);
   V_PREAUTH_AMT               CMS_PREAUTH_TRANSACTION.CPT_TOTALHOLD_AMT%TYPE;
   v_completion_fee               CMS_PREAUTH_TRANSACTION.CPT_COMPLETION_FEE%type;
   v_comp_total_fee_log  varchar2(1);
   v_comp_hold_cr_flag      Varchar2(1);
   v_comp_hold_fee_diff       number;
   V_COMPLFEE_INCREMENT_TYPE   varchar2(1);
   v_comp_fee_hold number;
   v_comlfree_flag  varchar2(1);
  
  --SN Added for FWR 70
v_removespacenum_txn  VARCHAR2 (10);
V_REMOVESPACENUM_CUST   VARCHAR2 (10);
V_REMOVESPACECHAR_TXN   varchar2 (10);
V_REMOVESPACECHAR_CUST   VARCHAR2 (10);
--EN Added for FWR 70
  v_redemption_delay_flag cms_acct_mast.cam_redemption_delay_flag%type;
  v_delayed_amount number:=0; 
  

BEGIN
    SAVEPOINT V_AUTH_SAVEPOINT;
    V_RESP_CDE := '1';
    P_RESP_MSG := 'OK';

    V_TRAN_AMT := P_TXN_AMT;                      --modified by Deepa on Mar-06-2013
  
    --Modified to log the amount for the declined transactions of preauth also.As the AVS declined transaction was not displayed in CSR.

    BEGIN
        --SN CREATE HASH PAN
        BEGIN
            V_HASH_PAN := GETHASH (P_CARD_NO);
        EXCEPTION
            WHEN OTHERS
            THEN
                V_ERR_MSG :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --EN CREATE HASH PAN

        --SN create encr pan
        BEGIN
            V_ENCR_PAN := FN_EMAPS_MAIN (P_CARD_NO);
        EXCEPTION
            WHEN OTHERS
            THEN
                V_ERR_MSG :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --EN create encr pan

      /*  --Sn find narration
        BEGIN
            SELECT CTM_TRAN_DESC
              INTO V_TRANS_DESC
              FROM CMS_TRANSACTION_MAST
             WHERE      CTM_TRAN_CODE = P_TXN_CODE
                     AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                     AND CTM_INST_CODE = P_INST_CODE;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_TRANS_DESC := 'Transaction type ' || P_TXN_CODE;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG :=
                    'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En find narration*/

        --Sn generate auth id
        BEGIN
            --SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;
            --       SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') ||
            SELECT LPAD (SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;

            V_AUTH_ID_GEN_FLAG := 'Y';
        EXCEPTION
            WHEN OTHERS
            THEN
                V_ERR_MSG :=
                    'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
                V_RESP_CDE := '21';                             -- Server Declined
                RAISE EXP_REJECT_RECORD;
        END;

        --En generate auth id

        --sN CHECK INST CODE
        BEGIN
            IF P_INST_CODE IS NULL
            THEN
                V_RESP_CDE := '12';                         -- Invalid Transaction
                V_ERR_MSG :=
                    'Institute code cannot be null ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
            END IF;
        EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
                RAISE;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '12';                         -- Invalid Transaction
                V_ERR_MSG :=
                    'Institute code cannot be null ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --eN CHECK INST CODE

        --En check txn currency
        BEGIN
            V_DATE := TO_DATE (SUBSTR (TRIM (P_TRAN_DATE), 1, 8), 'yyyymmdd');
        EXCEPTION
            WHEN OTHERS
            THEN
                V_RESP_CDE := '45';                     -- Server Declined -220509
                V_ERR_MSG :=
                    'Problem while converting transaction date '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        BEGIN
            V_TRAN_DATE :=
                TO_DATE (
                        SUBSTR (TRIM (P_TRAN_DATE), 1, 8)
                    || ' '
                    || SUBSTR (TRIM (P_TRAN_TIME), 1, 10),
                    'yyyymmdd hh24:mi:ss');
        EXCEPTION
            WHEN OTHERS
            THEN
                V_RESP_CDE := '32';                     -- Server Declined -220509
                V_ERR_MSG :=
                    'Problem while converting transaction time '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En get date

        --Sn find debit and credit flag
        BEGIN
            SELECT CTM_CREDIT_DEBIT_FLAG, CTM_OUTPUT_TYPE, TO_NUMBER (DECODE (CTM_TRAN_TYPE,  'N', '0',  'F', '1')), CTM_TRAN_TYPE, CTM_PREAUTH_FLAG
                     , CTM_LOGIN_TXN, --Added For Clawback (MVhost 346)changes on 250413
                                          ctm_prfl_flag, --Added by Pankaj S. for enabling limit validation
                                          CTM_TRAN_DESC
              INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE, V_TRAN_PREAUTH_FLAG
                     , v_clawback_txn, v_prfl_flag, --Added by Pankaj S. for enabling limit validation
                     V_TRANS_DESC
              FROM CMS_TRANSACTION_MAST
             WHERE      CTM_TRAN_CODE = P_TXN_CODE
                     AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                     AND CTM_INST_CODE = P_INST_CODE;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '12';                       --Ineligible Transaction
                V_ERR_MSG :=
                        'Transflag  not defined for txn code '
                    || P_TXN_CODE
                    || ' and delivery channel '
                    || P_DELIVERY_CHANNEL;
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '12';                       --Ineligible Transaction
                V_ERR_MSG :=
                        'Error while selecting  CMS_TRANSACTION_MAST'
                    || SUBSTR (SQLERRM, 1, 200)
                    || P_TXN_CODE
                    || ' and delivery channel '
                    || P_DELIVERY_CHANNEL;
                RAISE EXP_REJECT_RECORD;
        END;

        --En find debit and credit flag

        --Check for Duplicate rrn for Pre-Auth if pre-auth is expire or valid flag is N
        --checking for inccremental pre-auth
        /*
        BEGIN

    /*
             IF V_PREAUTH_COUNT > 0 THEN
              V_RESP_CDE := '22';
              V_ERR_MSG  := 'Duplicate RRN Pre-Auth';
              RAISE EXP_REJECT_RECORD;
             END IF;
          ELSE
             IF P_INCR_INDICATOR = '1' THEN
              SELECT COUNT(*)
                 INTO V_PREAUTH_COUNT
                 FROM CMS_PREAUTH_TRANSACTION
                WHERE CPT_CARD_NO = V_HASH_PAN AND CPT_RRN = P_RRN AND
                      (CPT_PREAUTH_VALIDFLAG = 'N' OR CPT_EXPIRY_FLAG = 'Y');

              IF V_PREAUTH_COUNT > 0 THEN
                 V_RESP_CDE := '22';
                 V_ERR_MSG    := 'Duplicate RRN Pre-Auth';
                 RAISE EXP_REJECT_RECORD;
              END IF;
             ELSE
              V_RESP_CDE := '22';
              V_ERR_MSG  := 'Duplicate RRN Pre-Auth';
              RAISE EXP_REJECT_RECORD;
             END IF;
          END IF;
         EXCEPTION
          WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
             V_RESP_CDE := '22';
             V_ERR_MSG    := 'ERROR IN PREAUTH RRN CHECK' ||
                            SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
         END;
        */
        -- MODIFIED BY ABDUL HAMEED M.A ON 06-03-2014
        BEGIN
            sp_dup_rrn_check (v_hash_pan,
                                    p_rrn,
                                    p_tran_date,
                                    p_delivery_channel,
                                    p_msg,
                                    p_txn_code,
                                    v_err_msg,
                                    P_INCR_INDICATOR);

            IF v_err_msg <> 'OK'
            THEN
                v_resp_cde := '22';
                RAISE exp_reject_record;
            END IF;
        EXCEPTION
            WHEN exp_reject_record
            THEN
                RAISE;
            WHEN OTHERS
            THEN
                v_resp_cde := '22';
                v_err_msg :=
                    'Error while checking RRN' || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;
        END;

/*        --Sn Getting BIN Level Configuration details

        BEGIN
            SELECT CBL_INTERNATIONAL_CHECK --, CBL_ADDR_VER_CHECK
              INTO V_INTERNATIONAL_IND -- , V_ADDRVRIFY_FLAG
              FROM CMS_BIN_LEVEL_CONFIG
             WHERE CBL_INST_BIN = SUBSTR (P_CARD_NO, 1, 6)
                     AND CBL_INST_CODE = P_INST_CODE;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_INTERNATIONAL_IND := 'Y';
             --   V_ADDRVRIFY_FLAG := 'Y';
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG := 'Error while seelcting BIN level Configuration' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En Getting BIN Level Configuration details
*/ 

        --Sn find card detail -- Exiting query only position is changed
        BEGIN
            SELECT CAP_PROD_CODE, CAP_CARD_TYPE, CAP_EXPRY_DATE, CAP_CARD_STAT, CAP_ATM_ONLINE_LIMIT
                     , CAP_POS_ONLINE_LIMIT, CAP_PROXY_NUMBER, CAP_ACCT_NO, CAP_CUST_CODE, -- Added on 14-Mar-2013 during FSS-943 changes
                                                                                                                 cap_prfl_code --Added by Pankaj S. for enabling limit validation
              INTO V_PROD_CODE, V_PROD_CATTYPE, V_EXPRY_DATE, V_APPLPAN_CARDSTAT, V_ATMONLINE_LIMIT
                     , V_ATMONLINE_LIMIT, V_PROXUNUMBER, V_ACCT_NUMBER, V_CAP_CUST_CODE, -- Added on 14-Mar-2013 during FSS-943 changes
                                                                                                              v_prfl_code --Added by Pankaj S. for enabling limit validation
              FROM CMS_APPL_PAN
             WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '14';
                V_ERR_MSG := 'CARD NOT FOUND ' || V_HASH_PAN;
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG :=
                    'Problem while selecting card detail'
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;
        
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
   
       --Sn International Indicator check

        IF P_INTERNATIONAL_IND = '1'
        THEN
            IF V_INTERNATIONAL_IND <> 'Y'
            THEN
                V_RESP_CDE := '38';
                V_ERR_MSG := 'International Transaction Not supported';
                RAISE EXP_REJECT_RECORD;
            END IF;
        END IF;

--St: Added on 23/04/2013 for MVHOST-300 & 301 ( AVS & ZIP validation changes).
        IF V_ADDRVRIFY_FLAG = 'Y' AND UPPER (P_ADDRVERIFY_FLAG) = 'U'
        THEN
            IF P_ZIP_CODE IS NULL
            THEN                                                                 --tag not present
                V_RESP_CDE := '105';
                V_ERR_MSG := 'Required Property Not Present : ZIP';
                RAISE EXP_REJECT_RECORD;
            ELSIF TRIM (P_ZIP_CODE) IS NULL
            THEN                                     --tag present but value empty or space
                P_ADDR_VERFY_RESPONSE := 'U';
            ELSE
                BEGIN
                    SELECT decode(v_encrypt_enable,'Y', fn_dmaps_main(cam_pin_code),cam_pin_code)
                      INTO V_ZIP_CODE
                      FROM CMS_ADDR_MAST
                     WHERE CAM_INST_CODE = P_INST_CODE AND CAM_CUST_CODE = V_CAP_CUST_CODE -- Added instead of passing it from subquery for performance during FSS-943 Changes
                                                                      AND CAM_ADDR_FLAG = 'P';

                    v_first3_custzip := SUBSTR (V_ZIP_CODE, 1, 3);
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        V_RESP_CDE := '21';
                        V_ERR_MSG := 'No data found in CMS_ADDR_MAST ' || V_HASH_PAN;
                        RAISE EXP_REJECT_RECORD;
                    WHEN OTHERS
                    THEN
                        V_RESP_CDE := '21';
                        V_ERR_MSG :=
                            'Error while seelcting CMS_ADDR_MAST '
                            || SUBSTR (SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
                END;

                SELECT REGEXP_INSTR (p_zip_code, '([A-Z,a-z])')
                  INTO v_txn_nonnumeric_chk
                  FROM DUAL;

                SELECT REGEXP_INSTR (V_ZIP_CODE, '([A-Z,a-z])')
                  INTO v_cust_nonnumeric_chk
                  FROM DUAL;

                IF v_txn_nonnumeric_chk = '0' AND v_cust_nonnumeric_chk = '0'
                THEN                         -- It Means txn and cust zip code is numeric
                    --IF    p_zip_code = v_zip_code then -- Commented on 20/12/13 for FSS-1388
                    IF SUBSTR (p_zip_code, 1, 5) = SUBSTR (v_zip_code, 1, 5) -- Added on 20/12/13 for FSS-1388
                    THEN
                        P_ADDR_VERFY_RESPONSE := 'W';
                    ELSE
                        P_ADDR_VERFY_RESPONSE := 'N';
                    END IF;
                ELSIF v_txn_nonnumeric_chk <> '0' AND v_cust_nonnumeric_chk = '0'
                THEN -- It Means txn zip code is aplhanumeric and cust zip code is numeric
                    IF p_zip_code = v_zip_code
                    THEN
                        P_ADDR_VERFY_RESPONSE := 'W';
                    ELSE
                        P_ADDR_VERFY_RESPONSE := 'N';
                    END IF;
                ELSIF v_txn_nonnumeric_chk = '0' AND v_cust_nonnumeric_chk <> '0'
                THEN -- It Means txn zip code is numeric and cust zip code is alphanumeric
                    SELECT REGEXP_REPLACE (v_zip_code, '([A-Z ,a-z ])', '')
                      INTO v_numeric_zip
                      FROM DUAL;

                    IF p_zip_code = v_numeric_zip
                    THEN
                        P_ADDR_VERFY_RESPONSE := 'W';
                    ELSE
                        P_ADDR_VERFY_RESPONSE := 'N';
                    END IF;
                ELSIF v_txn_nonnumeric_chk <> '0'
                        AND v_cust_nonnumeric_chk <> '0'
                THEN      -- It Means txn zip code and cust zip code is alphanumeric
                    v_inputzip_length := LENGTH (p_zip_code);

                    IF v_inputzip_length = LENGTH (v_zip_code)
                    THEN                          -- both txn and cust zip length is equal
                        IF p_zip_code = v_zip_code
                        THEN
                            P_ADDR_VERFY_RESPONSE := 'W';
                        ELSE
                            P_ADDR_VERFY_RESPONSE := 'N';
                        END IF;
                    ELSE
                        SELECT REGEXP_REPLACE (p_zip_code, '([ ])', '')
                          INTO v_removespace_txn
                          FROM DUAL;

                        SELECT REGEXP_REPLACE (v_zip_code, '([ ])', '')
                          INTO v_removespace_cust
                          FROM DUAL;

                        IF v_removespace_txn = v_removespace_cust
                        THEN
                            P_ADDR_VERFY_RESPONSE := 'W';
                        --elsif v_inputzip_length >=3 then --Commented for defect : 13297 on 26/12/13
                        ELSIF LENGTH (v_removespace_txn) >= 3
                        THEN                         --Added for defect : 13297 on 26/12/13
                            --if substr(p_zip_code,1,3) = v_first3_custzip then  --Commented for defect : 13297 on 26/12/13
                            IF SUBSTR (v_removespace_txn, 1, 3) =
                                    SUBSTR (v_removespace_cust, 1, 3)
                            THEN                     --Added for defect : 13297 on 26/12/13
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
                            ELSE
                                P_ADDR_VERFY_RESPONSE := 'N';
                            end if;
                           
                      
                        ELSE                         --Added for defect : 13296 on 26/12/13
                            P_ADDR_VERFY_RESPONSE := 'N'; --Added for defect : 13296 on 26/12/13
                        END IF;
                    END IF;
                ELSE
                    P_ADDR_VERFY_RESPONSE := 'N';
                END IF;
            END IF;
        ELSE
            IF P_ADDRVERIFY_FLAG = 'U'
            THEN
                P_ADDR_VERFY_RESPONSE := V_ADDRVERIFY_RESP; 
            ELSE
                P_ADDR_VERFY_RESPONSE := 'NA';
            END IF;
        END IF;

        --END  MVHOST-300 & 301 ( AVS & ZIP validation changes).

        /* Commented on 23/04/2013 for MVHOST-300 & 301 ( AVS & ZIP validation changes).
        --Sn International Indicator check
        V_ZIP_CODE_IN:= substr(P_ZIP_CODE,0,5);--Added by Deepa to validate 5 digits of ZIP code on OCT-19-2012

        --Sn Address Verificationflag check based on BIN level configuration

        IF V_ADDRVRIFY_FLAG = 'Y' AND P_ADDRVERIFY_FLAG = 'U'
        THEN

             if P_ZIP_CODE is null
             then

                 V_RESP_CDE := '105';
                 V_ERR_MSG    := 'Required Property Not Present : ZIP';
                 RAISE EXP_REJECT_RECORD;

             Elsif trim(P_ZIP_CODE) is null
             then

                 V_RESP_CDE := '49';
                 V_ERR_MSG    := 'Data Element Name ZIP is Invalid';
                 RAISE EXP_REJECT_RECORD;

             end if;

             if P_COUNTRY_CODE is null
             then

                 V_RESP_CDE := '105';
                 V_ERR_MSG    := 'Required Property Not Present : Country Code';
                 RAISE EXP_REJECT_RECORD;

             Elsif trim(P_COUNTRY_CODE) is null
             then

                 V_RESP_CDE := '49';
                 V_ERR_MSG    := 'Data Element Name Country Code is Invalid';
                 RAISE EXP_REJECT_RECORD;

             end if;



                IF trim(p_country_code) =840 -- It Means it is for US , If condition added for FSS-943 on 14-Mar-2013
                THEN

                    --T.Narayanan Changed for Address Verification Indicator Changes. beg
                    BEGIN

                            --IF NVL(P_ZIP_CODE, 0) <> 'N'       -- Commented for FSS-943 since we need to check P_ADDRVERIFY_FLAG = 'U'
                            --THEN

                             --Address verififcation
                             SELECT CAM_PIN_CODE
                                INTO V_ZIP_CODE
                                FROM CMS_ADDR_MAST
                              WHERE CAM_CUST_CODE = V_CAP_CUST_CODE -- Added instead of passing it from subquery for performance during FSS-943 Changes
                              AND CAM_ADDR_FLAG = 'P'; --Modified by Ramkumar.mK, check the addr_flag



                                  IF V_ZIP_CODE_IN = V_ZIP_CODE THEN
                                     P_ADDR_VERFY_RESPONSE := 'W';
                                  ELSE
                                     P_ADDR_VERFY_RESPONSE := 'N';
                                     V_RESP_CDE               := '39';
                                     V_ERR_MSG                  := 'Address Verification Failed';
                                     RAISE EXP_REJECT_RECORD;
                                  END IF;

                         --  ELSE                                         -- Commented for FSS-943

                         --    P_ADDR_VERFY_RESPONSE := 'NA';    -- Commented for FSS-943

                         --  END IF;                                     -- Commented for FSS-943

                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        V_RESP_CDE := '21';
                        V_ERR_MSG  := 'No data found in CMS_ADDR_MAST ' || V_HASH_PAN;
                        RAISE EXP_REJECT_RECORD;
                      WHEN EXP_REJECT_RECORD THEN
                        V_RESP_CDE := '39';
                        RAISE EXP_REJECT_RECORD;
                      WHEN OTHERS THEN
                        V_RESP_CDE := '21';
                        V_ERR_MSG  := 'Error while seelcting CMS_ADDR_MAST ' ||
                                        SUBSTR(SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
                    END;
                    --T.Narayanan Changed for Address Verification Indicator Changes. end



                elsif trim(p_country_code) =124 --It Means it is for Canada,If condition added for FSS-943 on 14-Mar-2013
                then


                     --IF NVL(P_ZIP_CODE, 0) <> 'N' THEN -- Commented for FSS-943

                        BEGIN

                             SELECT CAM_PIN_CODE
                             INTO V_ZIP_CODE
                             FROM CMS_ADDR_MAST
                             WHERE CAM_CUST_CODE = V_CAP_CUST_CODE
                             AND CAM_ADDR_FLAG    = 'P';

                             v_first3_custzip := SUBSTR(V_ZIP_CODE,1,3); --Change name here v_first3_custzip

                        EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                             V_RESP_CDE := '21';
                             V_ERR_MSG    := 'For Canada , No data found in CMS_ADDR_MAST ' ||V_HASH_PAN;
                             RAISE EXP_REJECT_RECORD;

                        WHEN OTHERS THEN
                             V_RESP_CDE := '21';
                             V_ERR_MSG    := 'For Canada ,Error while seelcting CMS_ADDR_MAST ' ||SUBSTR(SQLERRM, 1, 200);
                             RAISE EXP_REJECT_RECORD;
                        END;


                          -- ELSE                                     -- Commented for FSS-943

                          --    p_addr_verfy_response := 'NA'; -- Commented for FSS-943

                          -- END IF;                                 -- Commented for FSS-943

                            v_inputzip_length := length(p_zip_code);

                            if v_inputzip_length = length(v_zip_code)
                            then

                                  if    p_zip_code = v_zip_code
                                  then

                                    P_ADDR_VERFY_RESPONSE := 'W';

                                  ELSE

                                     P_ADDR_VERFY_RESPONSE := 'N';
                                     V_RESP_CDE               := '39';
                                     V_ERR_MSG                  := 'Address Verification Failed for canada for input zip code : '||p_zip_code||'and customer zip code: '||v_zip_code;
                                     RAISE EXP_REJECT_RECORD;

                                  end if;

                            elsif  v_inputzip_length > 3
                            then

                                if substr(p_zip_code,1,3) = v_first3_custzip
                                then

                                 P_ADDR_VERFY_RESPONSE := 'W';

                                ELSE

                                  P_ADDR_VERFY_RESPONSE := 'N';
                                  V_RESP_CDE                := '39';
                                  V_ERR_MSG                 := 'Address Verification Failed for canada when length of input zip code is more than 3 ';
                                  RAISE EXP_REJECT_RECORD;

                                end if;


                            elsif v_inputzip_length = 3
                            then

                              SELECT REGEXP_instr(p_zip_code,'([A-Z,a-z])')
                              into v_nonnumeric_chk
                              FROM dual;

                                if  v_nonnumeric_chk <> '0' -- It Means non-numeric
                                then

                                     if  p_zip_code = v_first3_custzip
                                     then


                                      P_ADDR_VERFY_RESPONSE := 'W';

                                     ELSE

                                        P_ADDR_VERFY_RESPONSE := 'N';
                                        V_RESP_CDE                 := '39';
                                        V_ERR_MSG                 := 'Address Verification Failed for canada when input zip code is nonnumeric and length is 3 ';
                                        RAISE EXP_REJECT_RECORD;


                                     end if;

                                else -- It Means Numeric

                                    SELECT REGEXP_REPLACE(v_zip_code,'([A-Z ,a-z ])', '')
                                    into v_numeric_zip
                                    FROM dual;


                                    if  p_zip_code = substr(v_numeric_zip,1,3)
                                    then

                                        P_ADDR_VERFY_RESPONSE := 'W';

                                    ELSE

                                        P_ADDR_VERFY_RESPONSE := 'N';
                                        V_RESP_CDE                 := '39';
                                        V_ERR_MSG                 := 'Address Verification Failed for canada when input zip code is numeric and length is 3 ';
                                        RAISE EXP_REJECT_RECORD;

                                    end if;


                                end if;

                            elsif v_inputzip_length < 3
                            then

                                        P_ADDR_VERFY_RESPONSE := 'NA';
                                        V_RESP_CDE                 := '39';
                                        V_ERR_MSG                 := 'Address Verification Failed , input zip length is less than 3';
                                        RAISE EXP_REJECT_RECORD;

                            end if;    --If condition to check input zip length ends here



                elsif trim(p_country_code) not in(840,124)
                then

                        BEGIN

                             SELECT CAM_PIN_CODE
                             INTO V_ZIP_CODE
                             FROM CMS_ADDR_MAST
                             WHERE CAM_CUST_CODE = V_CAP_CUST_CODE
                             AND CAM_ADDR_FLAG    = 'P';

                        EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                             V_RESP_CDE := '21';
                             V_ERR_MSG    := 'For other country , No data found in CMS_ADDR_MAST ' ||V_HASH_PAN;
                             RAISE EXP_REJECT_RECORD;

                        WHEN OTHERS THEN
                             V_RESP_CDE := '21';
                             V_ERR_MSG    := 'For other country ,Error while selecting CMS_ADDR_MAST ' ||SUBSTR(SQLERRM, 1, 200);
                             RAISE EXP_REJECT_RECORD;
                        END;


                  IF P_ZIP_CODE = V_ZIP_CODE
                  THEN

                     P_ADDR_VERFY_RESPONSE := 'W';

                  ELSE

                     P_ADDR_VERFY_RESPONSE := 'N';
                     V_RESP_CDE               := '39';
                     V_ERR_MSG                  := 'Address Verification Failed for other country code';
                     RAISE EXP_REJECT_RECORD;
                  END IF;


                end if;-- If condition for Country code check ends here

        ELSE

              IF P_ADDRVERIFY_FLAG = 'U' THEN

                 P_ADDR_VERFY_RESPONSE := 'U'; --If Address verification is disabled and verification flag in request is U.Response will have Address Verification Indicator tag with the value 'U'.

              ELSE

                 P_ADDR_VERFY_RESPONSE := 'NA';

              END IF;


        END IF;

        --En Address Verificationflag check based on BIN level configuration
  */
        --Sn find service tax
        BEGIN
            SELECT CIP_PARAM_VALUE
              INTO V_SERVICETAX_PERCENT
              FROM CMS_INST_PARAM
             WHERE CIP_PARAM_KEY = 'SERVICETAX' AND CIP_INST_CODE = P_INST_CODE;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG := 'Service Tax is  not defined in the system';
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG := 'Error while selecting service tax from system ';
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
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG := 'Cess is not defined in the system';
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG := 'Error while selecting cess from system ';
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
            WHEN NO_DATA_FOUND
            THEN
                V_CUTOFF_TIME := 0;
                V_RESP_CDE := '21';
                V_ERR_MSG := 'Cutoff time is not defined in the system';
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG := 'Error while selecting cutoff  dtl  from system ';
                RAISE EXP_REJECT_RECORD;
        END;

        ---En find cutoff time
        
        BEGIN
           SELECT cam_acct_bal, NVL (cam_redemption_delay_flag, 'N')
             INTO v_acc_bal, v_redemption_delay_flag
             FROM cms_acct_mast
            WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_acct_number;
        EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
              V_RESP_CDE := '14';                            
              V_ERR_MSG := 'Invalid acct ';
              RAISE EXP_REJECT_RECORD;
           WHEN OTHERS
           THEN
              V_RESP_CDE := '21';
              V_ERR_MSG :=
                 'Error while selecting data from acct Master: '|| SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
        END;
        
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
             v_acc_bal := v_acc_bal - v_delayed_amount;
          END IF;
       END IF;

        --Sn find the tran amt
        IF ( (V_TRAN_TYPE = 'F') OR (V_TRAN_PREAUTH_FLAG = 'Y'))
        THEN
            IF (P_TXN_AMT >= 0)
            THEN
                --V_TRAN_AMT := P_TXN_AMT;--Commented by Deepa on Mar-06-2013 to log the amount for AVS declined transactions also.

                BEGIN
                    SP_CONVERT_CURR (P_INST_CODE,
                                          P_CURR_CODE,
                                          P_CARD_NO,
                                          P_TXN_AMT,
                                          V_TRAN_DATE,
                                          V_TRAN_AMT,
                                          V_CARD_CURR,
                                          V_ERR_MSG,
										  V_PROD_CODE,
                                          V_PROD_CATTYPE);

                    IF V_ERR_MSG <> 'OK'
                    THEN
                        V_RESP_CDE := '44';
                        RAISE EXP_REJECT_RECORD;
                    END IF;

                    --Adder srinivasu for Partial Preauth Transaction
                    IF TO_NUMBER (P_PARTIAL_PREAUTH_IND) = 1
                    THEN
--                        BEGIN
--                            SELECT CAM_ACCT_BAL
--                              INTO V_ACC_BAL
--                              FROM CMS_ACCT_MAST
--                             WHERE cam_inst_code = p_inst_code
--                                  AND cam_acct_no = v_acct_number;   
--                             /*CAM_ACCT_ID = (SELECT CAP_ACCT_ID
--                                                            FROM CMS_APPL_PAN
--                                                          WHERE CAP_PAN_CODE = V_HASH_PAN);*/
--                        EXCEPTION
--                            WHEN NO_DATA_FOUND
--                            THEN
--                                V_RESP_CDE := '69';         -- Server Declined -220509
--                                V_ERR_MSG :=
--                                    'DETAILS NOT AVAILABLE IN ACCT MAST FOR PAN'
--                                    || V_HASH_PAN;
--                                RAISE EXP_REJECT_RECORD;
--                            WHEN OTHERS
--                            THEN
--                                V_RESP_CDE := '69';         -- Server Declined -220509
--                                V_ERR_MSG :=
--                                    'ERROR WHILE FETCHING RECORD FROM ACCT MAST'
--                                    || SUBSTR (SQLERRM, 1, 200);
--                                RAISE EXP_REJECT_RECORD;
--                        END;

                        /* Start Added by Dhiraj G on 30112012 for Account Balance Issue    */
                        IF V_ACC_BAL <= 0
                        THEN
                            V_RESP_CDE := '15';
                            V_ERR_MSG := 'Account Balance is Zero or Less Than Zero ';
                            -- || V_HASH_PAN;                                       --Commented on 02-Jan-2013 for Defect 9770
                            RAISE EXP_REJECT_RECORD;
                        END IF;

                        /* End Added by Dhiraj G on 30112012 for Account Balance Issuence   */
                        IF V_TRAN_AMT > V_ACC_BAL
                        THEN
                            V_TRAN_AMT := V_ACC_BAL;
                            P_PARTIALAUTH_AMOUNT := V_TRAN_AMT;
                        --Sn Commented by Pankaj S. for 3 decimal places amount issue
                        --ELSE
                        --V_TRAN_AMT := P_TXN_AMT;
                        --En Commented by Pankaj S. for 3 decimal places amount issue
                        END IF;
                    END IF;
                EXCEPTION
                    WHEN EXP_REJECT_RECORD
                    THEN
                        RAISE;
                    WHEN OTHERS
                    THEN
                        V_RESP_CDE := '69';               -- Server Declined -220509
                        V_ERR_MSG :=
                            'Error from currency conversion '
                            || SUBSTR (SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
                END;
            ELSE
                -- If transaction Amount is zero - Invalid Amount -220509
                V_RESP_CDE := '43';
                V_ERR_MSG := 'INVALID AMOUNT';
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
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '21';                       --only for master setups
                V_ERR_MSG := 'Master set up is not done for Authorization Process';
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';                       --only for master setups
                V_ERR_MSG :=
                    'Error while selecting precheck flag'
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En select authorization process    flag
        --Sn select authorization processe flag
        BEGIN
            SELECT PTP_PARAM_VALUE
              INTO V_PREAUTH_FLAG
              FROM PCMS_TRANAUTH_PARAM
             WHERE PTP_PARAM_NAME = 'PRE AUTH' AND PTP_INST_CODE = P_INST_CODE;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG := 'Master set up is not done for Authorization Process';
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG :=
                    'Error while selecting PCMS_TRANAUTH_PARAM'
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En select authorization process    flag


        --Comment  hardcoded condition for Active-Unregistered card status POS    transaction on 02-Oct-2012 by Ananth Thota
        -- ST Added New card status Active/UnRegistered Card    13(Card Status) 02 (POS txn) 11 (txn code)
        /*if V_APPLPAN_CARDSTAT = '13' and  P_DELIVERY_CHANNEL = 02 and P_TXN_CODE = '11'
     then
     if P_POS_VERFICATION <>'S'  then
      V_RESP_CDE := '10';
            V_ERR_MSG  := 'Invalid Card Status ' || V_HASH_PAN;
            RAISE EXP_REJECT_RECORD;
            end if;
        end if;*/
        -- ET Added New card status Active/UnRegistered Card
        BEGIN
            SP_STATUS_CHECK_GPR (P_INST_CODE,
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

            IF ( (V_RESP_CDE <> '1' AND V_ERR_MSG <> 'OK')
                 OR (V_RESP_CDE <> '0' AND V_ERR_MSG <> 'OK'))
            THEN
                RAISE EXP_REJECT_RECORD;
            ELSE
                V_STATUS_CHK := V_RESP_CDE;
                V_RESP_CDE := '1';
            END IF;
        EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
                RAISE;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG :=
                    'Error from GPR Card Status Check '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En GPR Card status check

        IF V_STATUS_CHK = '1'
        THEN
            -- Expiry Check
            BEGIN
                IF TO_DATE (P_TRAN_DATE, 'YYYYMMDD') >
                        LAST_DAY (TO_CHAR (V_EXPRY_DATE, 'DD-MON-YY'))
                THEN
                    V_RESP_CDE := '13';
                    V_ERR_MSG := 'EXPIRED CARD';
                    RAISE EXP_REJECT_RECORD;
                END IF;
            EXCEPTION
                WHEN EXP_REJECT_RECORD
                THEN
                    RAISE;
                WHEN OTHERS
                THEN
                    V_RESP_CDE := '21';
                    V_ERR_MSG :=
                        'ERROR IN EXPIRY DATE CHECK ' || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
            END;

            -- End Expiry Check

            --Sn check for precheck
            IF V_PRECHECK_FLAG = 1
            THEN
                BEGIN
                    SP_PRECHECK_TXN (P_INST_CODE,
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

                    IF (V_RESP_CDE <> '1' OR V_ERR_MSG <> 'OK')
                    THEN
                        RAISE EXP_REJECT_RECORD;
                    END IF;
                EXCEPTION
                    WHEN EXP_REJECT_RECORD
                    THEN
                        RAISE;
                    WHEN OTHERS
                    THEN
                        V_RESP_CDE := '21';
                        V_ERR_MSG :=
                            'Error from precheck processes '
                            || SUBSTR (SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
                END;
            END IF;
        --En check for Precheck

        END IF;

        --Sn check for Preauth
        IF V_PREAUTH_FLAG = 1
        THEN
            BEGIN
                /* SP_PREAUTHORIZE_TXN(P_CARD_NO,
                 P_MCC_CODE,
                 P_CURR_CODE,
                 V_TRAN_DATE,
                 P_TXN_CODE,
                 P_INST_CODE,
                 P_TRAN_DATE,
                 V_TRAN_AMT,
                 P_DELIVERY_CHANNEL,
                 V_RESP_CDE,
                 V_ERR_MSG);*/
                /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */

                SP_ELAN_PREAUTHORIZE_TXN (P_CARD_NO,
                                                  P_MCC_CODE,
                                                  P_CURR_CODE,
                                                  V_TRAN_DATE,
                                                  P_TXN_CODE,
                                                  P_INST_CODE,
                                                  P_TRAN_DATE,
                                                  V_TRAN_AMT,
                                                  P_DELIVERY_CHANNEL,
                                                  P_MERC_ID,
                                                  P_COUNTRY_CODE,
                                                  V_HOLD_AMNT,
                                                  V_HOLD_DAYS,
                                                  V_RESP_CDE,
                                                  V_ERR_MSG);

                /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                IF (V_RESP_CDE <> '1' OR TRIM (V_ERR_MSG) <> 'OK')
                THEN
                    -- V_RESP_CDE := '21';--Modified by Deepa on Apr-30-2012 for the response code change
                    RAISE EXP_REJECT_RECORD;
                END IF;
            EXCEPTION
                WHEN EXP_REJECT_RECORD
                THEN
                    RAISE;
                WHEN OTHERS
                THEN
                    V_RESP_CDE := '21';
                    V_ERR_MSG :=
                        'Error from pre_auth process ' || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
            END;
        END IF;

        --En check for preauth
        
        --SN - commeneted for fwr-48

        --Sn find function code attached to txn code
    /*    BEGIN
            SELECT CFM_FUNC_CODE
              INTO V_FUNC_CODE
              FROM CMS_FUNC_MAST
             WHERE      CFM_TXN_CODE = P_TXN_CODE
                     AND CFM_TXN_MODE = P_TXN_MODE
                     AND CFM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                     AND CFM_INST_CODE = P_INST_CODE;
        --TXN mode and delivery channel we need to attach
        --bkz txn code may be same for all type of channels
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '69';                       --Ineligible Transaction
                V_ERR_MSG :=
                    'Function code not defined for txn code ' || P_TXN_CODE;
                RAISE EXP_REJECT_RECORD;
            WHEN TOO_MANY_ROWS
            THEN
                V_RESP_CDE := '69';
                V_ERR_MSG :=
                    'More than one function defined for txn code ' || P_TXN_CODE;
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '69';
                V_ERR_MSG :=
                        'Error while selecting CMS_FUNC_MAST'
                    || SUBSTR (SQLERRM, 1, 200)
                    || P_TXN_CODE;
                RAISE EXP_REJECT_RECORD;
        END; */

        --En find function code attached to txn code
        
        --EN - commeneted for fwr-48
        --Sn find prod code and card type and available balance for the card number
        BEGIN
            SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO, cam_type_code --added by Pankaj S. for 10871
              INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO, v_acct_type --added by Pankaj S. for 10871
              FROM CMS_ACCT_MAST
             WHERE CAM_ACCT_NO =v_acct_number
                      /*   (SELECT CAP_ACCT_NO
                             FROM CMS_APPL_PAN
                            WHERE      CAP_PAN_CODE = V_HASH_PAN
                                    AND CAP_MBR_NUMB = P_MBR_NUMB
                                    AND CAP_INST_CODE = P_INST_CODE)*/
                     AND CAM_INST_CODE = P_INST_CODE
            FOR UPDATE;                                           --SN:Added on 18-Jun-2013
        --FOR UPDATE NOWAIT;   --SN:COMMENTED for FSS-Preauth normal transaction details with same RRN - Response 89 instead of 22 - Resource busy on 18-Jun-2013 by Ranveer Meel
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '14';                       --Ineligible Transaction
                V_ERR_MSG := 'Invalid Card ';
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG :=
                    'Error while selecting data from card Master for card number '
                    || SQLERRM;
                RAISE EXP_REJECT_RECORD;
        END;
        
          IF v_delayed_amount > 0 THEN
             v_acct_balance := v_acc_bal;
          END IF;

        --Check for Duplicate rrn for Pre-Auth if pre-auth is expire or valid flag is N
        --checking for inccremental pre-auth
        --added for FSS-Preauth normal transaction details with same RRN - Response 89 instead of 22 - Resource busy on 18-Jun-2013 by Ranveer Meel
        /*  BEGIN
            IF P_INCR_INDICATOR = '0'
            THEN

             --------------------------------------
             --SN:Added for FSS-833 on 02-Jan-2013
             --------------------------------------

                select count(1)
                into     V_PREAUTH_CNT
                from     transactionlog
                where  rrn                    = P_RRN
                and     delivery_channel = P_DELIVERY_CHANNEL
                and     business_date     = P_TRAN_DATE;

             ------------------------------------
             --EN:Added for FSS-833 on 02-Jan-2013
             ------------------------------------

              /*                          Commented on 02-Jan-2013 for FSS-833
                SELECT COUNT(*)
                INTO V_PREAUTH_COUNT
                FROM CMS_PREAUTH_TRANSACTION
                WHERE CPT_CARD_NO = V_HASH_PAN AND CPT_RRN = P_RRN;
              */
        /*
                 IF V_PREAUTH_CNT > 0 THEN
                  V_RESP_CDE := '22';
                  V_ERR_MSG  := 'Duplicate RRN Pre-Auth';
                  RAISE EXP_REJECT_RECORD;
                 END IF;
              ELSE
                 IF P_INCR_INDICATOR = '1' THEN
                  SELECT COUNT(*)
                     INTO V_PREAUTH_CNT
                     FROM CMS_PREAUTH_TRANSACTION
                    WHERE CPT_CARD_NO = V_HASH_PAN AND CPT_RRN = P_RRN AND
                          (CPT_PREAUTH_VALIDFLAG = 'N' OR CPT_EXPIRY_FLAG = 'Y');

                  IF V_PREAUTH_CNT > 0 THEN
                     V_RESP_CDE := '22';
                     V_ERR_MSG    := 'Duplicate RRN Pre-Auth';
                     RAISE EXP_REJECT_RECORD;
                  END IF;
                 ELSE
                  V_RESP_CDE := '22';
                  V_ERR_MSG  := 'Duplicate RRN Pre-Auth';
                  RAISE EXP_REJECT_RECORD;
                 END IF;
              END IF;
             EXCEPTION
              WHEN EXP_REJECT_RECORD THEN
                 RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                 V_RESP_CDE := '22';
                 V_ERR_MSG    := 'ERROR IN PREAUTH RRN CHECK' ||
                                SUBSTR(SQLERRM, 1, 200);
                 RAISE EXP_REJECT_RECORD;
             END;
        */
        -- MODIFIED BY ABDUL HAMEED M.A ON 06-03-2014
        BEGIN
            sp_dup_rrn_check (V_HASH_PAN,
                                    P_RRN,
                                    P_TRAN_DATE,
                                    P_DELIVERY_CHANNEL,
                                    P_MSG,
                                    P_TXN_CODE,
                                    V_ERR_MSG,
                                    P_INCR_INDICATOR);

            IF v_err_msg <> 'OK'
            THEN
                v_resp_cde := '22';
                RAISE exp_reject_record;
            END IF;
        EXCEPTION
            WHEN exp_reject_record
            THEN
                RAISE;
            WHEN OTHERS
            THEN
                v_resp_cde := '22';
                v_err_msg :=
                    'Error while checking RRN' || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;
        END;


        --En find prod code and card type for the card number

        --En Check PreAuth Completion txn
        BEGIN
            SP_TRAN_FEES_CMSAUTH (P_INST_CODE,
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
                                         V_RESP_CDE,    --Added by Deepa for Fees Changes
                                         P_MSG,            --Added by Deepa for Fees Changes
                                         P_RVSL_CODE, --Added by Deepa on June 25 2012 for Reversal txn Fee
                                         P_MCC_CODE, --Added by Trivikram on 05-Sep-2012 for merchant catg code
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
                                         V_CLAWBACK,    --Added by Deepa for Fees Changes
                                         V_FEE_PLAN,    --Added by Deepa for Fees Changes
                                         V_PER_FEES,    --Added by Deepa for Fees Changes
                                         V_FLAT_FEES,    --Added by Deepa for Fees Changes
                                         V_FREETXN_EXCEED, -- Added by Trivikram for logging fee of free transaction
                                         V_DURATION, -- Added by Trivikram for logging fee of free transaction
                                         V_FEEATTACH_TYPE, -- Added by Trivikram on Sep 05 2012
                                         V_FEE_DESC                  -- Added for MVCSD-4471
                                                      );

            IF V_ERROR <> 'OK'
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG := V_ERROR;
                RAISE EXP_REJECT_RECORD;
            END IF;
        EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
                RAISE;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG :=
                    'Error from fee calc process ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        ---En dynamic fee calculation .

        --Sn calculate waiver on the fee
        BEGIN
            SP_CALCULATE_WAIVER (P_INST_CODE,
                                        P_CARD_NO,
                                        '000',
                                        V_PROD_CODE,
                                        V_PROD_CATTYPE,
                                        V_FEE_CODE,
                                        V_FEE_PLAN, -- Added by Trivikram on 21/aug/2012
                                        V_TRAN_DATE, --Added Trivikam on Aug-23-2012 to calculate the waiver based on tran date
                                        V_WAIV_PERCNT,
                                        V_ERR_WAIV);

            IF V_ERR_WAIV <> 'OK'
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG := V_ERR_WAIV;
                RAISE EXP_REJECT_RECORD;
            END IF;
        EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
                RAISE;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG :=
                    'Error from waiver calc process ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En calculate waiver on the fee

        --Sn apply waiver on fee amount
        V_LOG_ACTUAL_FEE := V_FEE_AMT;              --only used to log in log table
        V_FEE_AMT := ROUND (V_FEE_AMT - ( (V_FEE_AMT * V_WAIV_PERCNT) / 100), 2);
        V_LOG_WAIVER_AMT := V_LOG_ACTUAL_FEE - V_FEE_AMT;

        --only used to log in log table

        --En apply waiver on fee amount

        --Sn apply service tax and cess
        IF V_ST_CALC_FLAG = 1
        THEN
            V_SERVICETAX_AMOUNT := (V_FEE_AMT * V_SERVICETAX_PERCENT) / 100;
        ELSE
            V_SERVICETAX_AMOUNT := 0;
        END IF;

        IF V_CESS_CALC_FLAG = 1
        THEN
            V_CESS_AMOUNT := (V_SERVICETAX_AMOUNT * V_CESS_PERCENT) / 100;
        ELSE
            V_CESS_AMOUNT := 0;
        END IF;

        V_TOTAL_FEE :=
            ROUND (V_FEE_AMT + V_SERVICETAX_AMOUNT + V_CESS_AMOUNT, 2);

        --En apply service tax and cess

        --En find fees amount attached to func code, prod code and card type
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        IF P_DELIVERY_CHANNEL IN ('01', '02') AND P_TXN_CODE = '11'
        THEN
            IF V_HOLD_AMNT IS NOT NULL
            THEN
                V_TRAN_AMT := ROUND (V_HOLD_AMNT, 2); --ROUND added for 3 decimal issue
            END IF;
        END IF;

        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */

        --SN Added on 29.10.2013 for 12568
        IF TO_NUMBER (P_PARTIAL_PREAUTH_IND) = 1 AND V_TOTAL_FEE <> 0
        THEN
            IF V_TOTAL_FEE >= v_acct_balance
            THEN
                V_RESP_CDE := '15';
                V_ERR_MSG := 'Insufficient Balance ';
                RAISE EXP_REJECT_RECORD;
            ELSIF V_TRAN_AMT + V_TOTAL_FEE > V_ACC_BAL
            THEN
                V_TRAN_AMT := V_ACC_BAL - V_TOTAL_FEE;
                P_PARTIALAUTH_AMOUNT := V_TRAN_AMT;
            END IF;
        ELSIF TO_NUMBER (P_PARTIAL_PREAUTH_IND) = 1 AND V_HOLD_AMNT IS NOT NULL
        THEN
            IF V_TRAN_AMT > V_ACC_BAL
            THEN
                V_TRAN_AMT := V_ACC_BAL;
                P_PARTIALAUTH_AMOUNT := V_TRAN_AMT;
            END IF;
        END IF;

        --EN Added on 29.10.2013 for 12568

        -- SN added for FSS-837 on 23-06-2014
        
      IF  V_TRAN_AMT = 0 THEN
      
       v_tot_hold_amt := V_TRAN_AMT;
       --v_comp_total_fee :=0; -- commented for mantis id:0015618
       v_comp_fee_hold:=0;  --added for mantis id:0015618
      
      
      ELSE
          
            --sn calculate the  preauth  oompletion fee..
            BEGIN
              
               SELECT cpt_compl_txncode
              INTO v_completion_txn_code
              FROM cms_preauthcomp_txncode
               WHERE cpt_inst_code = p_inst_code AND cpt_preauth_txncode = p_txn_code;
              
            EXCEPTION
                       
             WHEN OTHERS THEN
               V_RESP_CDE := '21';
               V_ERR_MSG  := 'Error while selecting data for Completion transaction code ' ||
                          SQLERRM;
               RAISE EXP_REJECT_RECORD;
               END;
            
            IF P_INCR_INDICATOR = '1' THEN
                            
                BEGIN
                        SELECT CPT_TOTALHOLD_AMT,NVL(CPT_COMPLETION_FEE,'0'),
                        nvl(cpt_complfree_flag,'N') --nvl added for mantis id:0015618
                              INTO V_PREAUTH_AMT,v_completion_fee,
                              v_comlfree_flag
                              FROM VMSCMS.CMS_PREAUTH_TRANSACTION                              --Added for VMS-5739/FSP-991                    
                              WHERE      CPT_CARD_NO = V_HASH_PAN
                                         AND CPT_RRN = P_RRN
                                         AND CPT_PREAUTH_VALIDFLAG = 'Y'
                                         AND CPT_EXPIRY_FLAG = 'N';
						IF SQL%ROWCOUNT = 0 THEN
						 SELECT CPT_TOTALHOLD_AMT,NVL(CPT_COMPLETION_FEE,'0'),
                        nvl(cpt_complfree_flag,'N') --nvl added for mantis id:0015618
                              INTO V_PREAUTH_AMT,v_completion_fee,
                              v_comlfree_flag
                              FROM VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                               --Added for VMS-5739/FSP-991                    
                              WHERE      CPT_CARD_NO = V_HASH_PAN
                                         AND CPT_RRN = P_RRN
                                         AND CPT_PREAUTH_VALIDFLAG = 'Y'
                                         AND CPT_EXPIRY_FLAG = 'N';
						END IF;						
                EXCEPTION
                    WHEN OTHERS
                            THEN
                        V_ERR_MSG :=
                            'Error while selecting  CMS_PREAUTH_TRANSACTION '
                            || SUBSTR (SQLERRM, 1, 300);
                            V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END;
            
                V_TRAN_AMT := V_TRAN_AMT+V_PREAUTH_AMT;
            
            END IF;
            
            
    
            --En Check PreAuth Completion txn
            BEGIN
                SP_TRAN_FEES_CMSAUTH (P_INST_CODE,
                                             P_CARD_NO,
                                             P_DELIVERY_CHANNEL,
                                             '1',
                                             P_TXN_MODE,
                                             v_completion_txn_code,
                                             P_CURR_CODE,
                                             P_CONSODIUM_CODE,
                                             P_PARTNER_CODE,
                                             V_TRAN_AMT,
                                             V_TRAN_DATE,
                                             P_INTERNATIONAL_IND, 
                                             P_POS_VERFICATION, 
                                             V_RESP_CDE,    
                                             '0200',            
                                             P_RVSL_CODE,
                                             P_MCC_CODE, 
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

                IF V_ERROR <> 'OK'
                THEN
                    V_RESP_CDE := '21';
                    V_ERR_MSG := V_ERROR;
                    RAISE EXP_REJECT_RECORD;
                END IF;
            EXCEPTION
                WHEN EXP_REJECT_RECORD
                THEN
                    RAISE;
                WHEN OTHERS
                THEN
                    V_RESP_CDE := '21';
                    V_ERR_MSG :=
                        'Error from fee calc process ' || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
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
            
                IF P_INCR_INDICATOR = '1' THEN
                
                 V_TRAN_AMT := V_TRAN_AMT-V_PREAUTH_AMT;
              
               END IF;
                       
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
                v_err_msg := v_err_waiv;
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
        
           -- en calculate the preauth completion fee..
       
           --Sn apply waiver on fee amount
         
            v_comp_fee_amt := ROUND (v_comp_fee_amt - ((v_comp_fee_amt * v_comp_waiv_percnt) / 100), 2);

          --En apply waiver on fee amount
          
          -- SN  apply service tax and cess
          
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
                        
               v_comp_fee_hold:=v_comp_total_fee;
                                             
               if v_comp_total_fee > '0' then
                  
               
                   if P_INCR_INDICATOR = 1 THEN
                   
                           
                           if  v_comp_total_fee = v_completion_fee then
                           
                           v_comp_hold_fee_diff :=0;
                           
                           elsif  v_comp_total_fee > v_completion_fee then
                           
                            v_comp_hold_fee_diff := v_comp_total_fee -v_completion_fee;
                            
                           elsif  v_comp_total_fee < v_completion_fee then
                           
                            v_comp_hold_fee_diff := v_completion_fee-v_comp_total_fee;
                           
                           end if;
                                             
                           
                        if  v_tran_amt+v_total_fee+v_comp_hold_fee_diff > V_ACCT_BALANCE then
                                                      
                   
                            IF TO_NUMBER (P_PARTIAL_PREAUTH_IND) = '1'   THEN
                            
                                                                  
                                  if v_comp_total_fee = v_completion_fee then   
                                 
                                                                   
                                  v_comp_total_fee := '0';
                                  v_comp_total_fee_log :='Y';
                                  v_tot_hold_amt:=v_tran_amt-v_total_fee;
                                  V_COMPLFEE_INCREMENT_TYPE :='N';
                                 P_PARTIALAUTH_AMOUNT:= V_TRAN_AMT;
                                 
                                 elsif v_comp_total_fee > v_completion_fee then  
                                 
                                                              
                                  v_comp_hold_fee_diff :=  v_comp_total_fee- v_completion_fee;
                                  V_COMPLFEE_INCREMENT_TYPE :='D';
                                  v_comp_total_fee := v_comp_hold_fee_diff;
                                  
                                  v_tot_hold_amt :=V_TRAN_AMT-v_total_fee;
                                  V_TRAN_AMT :=V_TRAN_AMT- v_comp_hold_fee_diff;
                                   P_PARTIALAUTH_AMOUNT:= V_TRAN_AMT;                                               
                                                
                                 
                                 elsif v_comp_total_fee < v_completion_fee then  
                                                                              
                                     v_comp_hold_fee_diff :=  v_completion_fee - v_comp_total_fee;
                                     v_comp_total_fee := v_comp_hold_fee_diff;
                                                                                        
                                      v_comp_hold_cr_flag :='H';                -- if completion fee is less than the  previous preauth completion fee hold amount.this need to be hold 
                                      V_COMPLFEE_INCREMENT_TYPE :='C';
                                      v_tot_hold_amt :=V_TRAN_AMT-v_total_fee;
                                        P_PARTIALAUTH_AMOUNT:= V_TRAN_AMT;
                                                                                                
                                 end if;
                               
                                 
                            else  
                             
                                V_RESP_CDE := '15'; 
                                V_ERR_MSG  := 'Insufficient Balance'; 
                                RAISE EXP_REJECT_RECORD;   
                                                        
                            end if;
                        
                        
                        else
                                                 
                                if v_comp_total_fee = v_completion_fee then
                                 
                                  
                                  v_comp_total_fee := '0';
                                  v_comp_total_fee_log :='Y';
                                  v_tot_hold_amt:=v_tran_amt;
                                  V_COMPLFEE_INCREMENT_TYPE :='N';
                                 
                                elsif v_comp_total_fee > v_completion_fee then
                                                               
                                  v_comp_hold_fee_diff :=  v_comp_total_fee- v_completion_fee;   
                                  
                                  V_COMPLFEE_INCREMENT_TYPE :='D';     -- this will be log_dtl
                                  v_comp_total_fee := v_comp_hold_fee_diff; -- this will be in log_dtl
                                  v_tot_hold_amt := V_TRAN_AMT+v_comp_hold_fee_diff;
                               
                                 elsif v_comp_total_fee < v_completion_fee then  --tested
                                               
                                     v_comp_hold_fee_diff :=  v_completion_fee - v_comp_total_fee;
                                     v_comp_total_fee := v_comp_hold_fee_diff;
                                     V_COMPLFEE_INCREMENT_TYPE :='C';
                                     v_tot_hold_amt :=V_TRAN_AMT-v_comp_hold_fee_diff;
                                                                                                                                    
                                 end if;
                            
                         
                        end if;


                   else -- direct partial preauth transaction.....

                       if  V_tran_amt+v_total_fee+v_comp_total_fee >V_ACCT_BALANCE then



                            IF TO_NUMBER (P_PARTIAL_PREAUTH_IND) = 1    THEN



                                v_tot_hold_amt := V_ACCT_BALANCE -v_total_fee;
                                -- v_tot_hold_amt := V_ACCT_BALANCE ;
                                  V_COMPLFEE_INCREMENT_TYPE :='N';

                                -- v_tran_amt :=v_tot_hold_amt-(v_comp_total_fee+v_total_fee);
                                  v_tran_amt :=v_tot_hold_amt-v_comp_total_fee;
                                  P_PARTIALAUTH_AMOUNT :=v_tran_amt;

                            else

                                V_RESP_CDE := '15';
                                V_ERR_MSG  := 'Insufficient Balance';
                                RAISE EXP_REJECT_RECORD;


                            end if;
                       
                       
                       else   
                            
                           v_tot_hold_amt := V_TRAN_AMT+v_comp_total_fee;
                           V_COMPLFEE_INCREMENT_TYPE :='N';
                       
                       end if;
                                    
                    
                   end if;
                   
               else  
               
                    v_tot_hold_amt:=v_tran_amt;
               
               
               end if;
               
                  
       END IF;
     --EN added for FSS-837 on 23-06-2014
         
     
        --Sn Added by Pankaj S. for enabling limit validation
        IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y'
        THEN
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
                                                             v_err_msg);

                IF v_err_msg <> 'OK'
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
                        'Error from Limit Check Process '
                        || SUBSTR (SQLERRM, 1, 200);
                    RAISE exp_reject_record;
            END;
        END IF;

        --En Added by Pankaj S. for enabling limit validation


        --Sn find total transaction     amount
        IF V_DR_CR_FLAG = 'CR'
        THEN
            V_TOTAL_AMT := V_TRAN_AMT - V_TOTAL_FEE;
            V_UPD_AMT := V_ACCT_BALANCE + V_TOTAL_AMT;
            V_UPD_LEDGER_AMT := V_LEDGER_BAL + V_TOTAL_AMT;
        ELSIF V_DR_CR_FLAG = 'DR'
        THEN
            V_TOTAL_AMT := V_TRAN_AMT + V_TOTAL_FEE;
            V_UPD_AMT := V_ACCT_BALANCE - V_TOTAL_AMT;
            V_UPD_LEDGER_AMT := V_LEDGER_BAL - V_TOTAL_AMT;
        ELSIF V_DR_CR_FLAG = 'NA'
        THEN
            IF V_TRAN_PREAUTH_FLAG = 'Y'
            THEN
                V_TOTAL_AMT := V_TRAN_AMT + V_TOTAL_FEE;
            ELSE
                V_TOTAL_AMT := V_TOTAL_FEE;
            END IF;

            V_UPD_AMT := V_ACCT_BALANCE - V_TOTAL_AMT;
            V_UPD_LEDGER_AMT := V_LEDGER_BAL - V_TOTAL_AMT;
        ELSE
            V_RESP_CDE := '12';                          --Ineligible Transaction
            V_ERR_MSG := 'Invalid transflag    txn code ' || P_TXN_CODE;
            RAISE EXP_REJECT_RECORD;
        END IF;

        --En find total transaction     amout

        /* Commented For Clawback (MVHOST - 346) Changes on 25/04/2013
        --Sn check balance

        IF V_UPD_AMT < 0 THEN
         V_RESP_CDE := '15'; --Ineligible Transaction
         V_ERR_MSG    := 'Insufficient Balance '; -- modified by Ravi N for Mantis ID 0011282
         RAISE EXP_REJECT_RECORD;

        END IF;

        --En check balance*/
        
         if v_comp_total_fee_log ='Y' then
                        
          v_comp_total_fee:=v_completion_fee;
                        
         end if;

        --Start Clawback Changes (MVHOST - 346)  on 20/04/2013
        IF v_upd_amt < 0
        THEN
            IF v_total_fee <> 0 AND v_clawback = 'Y' AND v_clawback_txn = 'Y'
            THEN
                IF v_acct_balance >= v_tran_amt
                THEN
                    v_actual_fee_amnt := v_total_fee;
                    v_acct_bal_fee := v_acct_balance - v_tran_amt;
                    v_clawback_amnt := v_total_fee - v_acct_bal_fee;
                    v_fee_amt := v_acct_bal_fee;
                    v_upd_amt := v_acct_bal_fee - v_fee_amt;

                    IF v_clawback_amnt > 0
                    THEN
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
                                         AND ccd_acct_no = v_card_acct_no
                     and ccd_clawback ='Y';
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    V_RESP_CDE := '21';
                                    V_ERR_MSG :=
                                        'Error occured while fetching count from cms_charge_dtl'
                                        || SUBSTR (SQLERRM, 1, 100);
                                    RAISE EXP_REJECT_RECORD;
                            END;  
            -- Added for FWR 64 --
                
                        BEGIN
                            BEGIN
                                SELECT COUNT (*)
                                  INTO v_clawback_count
                                  FROM cms_acctclawback_dtl
                                 WHERE      cad_inst_code = p_inst_code
                                         AND cad_delivery_channel = p_delivery_channel
                                         AND cad_txn_code = p_txn_code
                                         AND cad_pan_code = v_hash_pan
                                         AND cad_acct_no = v_card_acct_no;
                            EXCEPTION
                                WHEN OTHERS --SN Exception Block added as per review observations for FSS-1246
                                THEN
                                    V_RESP_CDE := '21';
                                    V_ERR_MSG :=
                                        'Error occured while fetching clawback count '
                                        || SUBSTR (SQLERRM, 1, 100);
                                    RAISE EXP_REJECT_RECORD;
                            END; --EN Exception Block added as per review observations for FSS-1246

                            IF v_clawback_count = 0
                            THEN
                                BEGIN
                                    INSERT
                                      INTO cms_acctclawback_dtl (cad_inst_code,
                                                                          cad_acct_no,
                                                                          cad_pan_code,
                                                                          cad_pan_code_encr,
                                                                          cad_clawback_amnt,
                                                                          cad_recovery_flag,
                                                                          cad_ins_date,
                                                                          cad_lupd_date,
                                                                          cad_delivery_channel,
                                                                          cad_txn_code,
                                                                          cad_ins_user,
                                                                          cad_lupd_user)
                                    VALUES (p_inst_code,
                                              v_card_acct_no,
                                              v_hash_pan,
                                              v_encr_pan,
                                              ROUND (v_clawback_amnt, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                              'N',
                                              SYSDATE,
                                              SYSDATE,
                                              p_delivery_channel,
                                              p_txn_code,
                                              '1',
                                              '1');
                                EXCEPTION
                                    WHEN OTHERS --SN Exception Block added as per review observations for FSS-1246
                                    THEN
                                        V_RESP_CDE := '21';
                                        V_ERR_MSG :=
                                            'Error occured while inserting into acct clawback detl'
                                            || SUBSTR (SQLERRM, 1, 100);
                                        RAISE EXP_REJECT_RECORD;
                                END; --EN Exception Block added as per review observations for FSS-1246
                        
              ELSIF v_chrg_dtl_cnt < v_tot_clwbck_count then  -- Modified for fwr 64
                    BEGIN
                                    UPDATE cms_acctclawback_dtl
                                        SET cad_clawback_amnt =
                                                 ROUND (
                                                     cad_clawback_amnt + v_clawback_amnt,
                                                     2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                             cad_recovery_flag = 'N',
                                             cad_lupd_date = SYSDATE
                                     WHERE      cad_inst_code = p_inst_code
                                             AND cad_acct_no = v_card_acct_no
                                             AND cad_pan_code = v_hash_pan
                                             AND cad_delivery_channel =
                                                      p_delivery_channel
                                             AND cad_txn_code = p_txn_code;


                                    IF SQL%ROWCOUNT = 0 --SN If condition added as per review observations for FSS-1246
                                    THEN
                                        V_RESP_CDE := '21';
                                        V_ERR_MSG :=
                                            'No records found to update into acct clawback detl';
                                        RAISE EXP_REJECT_RECORD;
                                    END IF; --EN If condition added as per review observations for FSS-1246
                                EXCEPTION
                                    WHEN EXP_REJECT_RECORD --SN Exception Block added as per review observations for FSS-1246
                                    THEN
                                        RAISE;
                                    WHEN OTHERS
                                    THEN
                                        V_RESP_CDE := '21';
                                        V_ERR_MSG :=
                                            'Error occured while updating into acct clawback detl '
                                            || SUBSTR (SQLERRM, 1, 100);
                                        RAISE EXP_REJECT_RECORD;
                                END; --EN Exception Block added as per review observations for FSS-1246
                            END IF;
                        EXCEPTION
                            WHEN EXP_REJECT_RECORD --Exception EXP_REJECT_RECORD added as per review observations for FSS-1246
                            THEN
                                RAISE;
                            WHEN OTHERS
                            THEN
                                v_resp_cde := '21';
                                v_err_msg :=
                                    'Error while inserting Account ClawBack details'
                                    || SUBSTR (SQLERRM, 1, 200);
                                RAISE exp_reject_record;
                        END;
                    END IF;
                ELSE
                    v_resp_cde := '15';
                    v_err_msg := 'Insufficient Balance '; -- modified by Ravi N for Mantis ID 0011282
                    RAISE exp_reject_record;
                END IF;

                V_TOTAL_AMT := V_TRAN_AMT + V_FEE_AMT; -- Added for the total amount logging issue on Apr-02-14
            ELSE
                v_resp_cde := '15';
                v_err_msg := 'Insufficient Balance '; -- modified by Ravi N for Mantis ID 0011282
                RAISE exp_reject_record;
            END IF;
        END IF;

        --End  Clawback Changes (MVHOST - 346) on 20/04/2013

        /* -- Commented since same is not required to check as per defect 10406

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
                V_ERR_MSG  := 'CARD BALANCE CONFIGURATION NOT AVAILABLE  FOR THE PRODUCT PROFILE ' ||
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
             V_ERR_MSG    := 'EXCEEDING MAXIMUM CARD BALANCE';
             RAISE EXP_REJECT_RECORD;
            END IF;
            --En check balance

        */
        -- Commented since same is not required to check as per defect 10406


        --Sn create gl entries and acct update
        BEGIN
            SP_UPD_TRANSACTION_ACCNT_AUTH (P_INST_CODE,
                                                     V_TRAN_DATE,
                                                     V_PROD_CODE,
                                                     V_PROD_CATTYPE,
                                                     --V_TRAN_AMT,
                                                     v_tot_hold_amt,
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

            IF (V_RESP_CDE <> '1' OR V_ERR_MSG <> 'OK')
            THEN
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
            END IF;
        EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
                RAISE;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG :=
                    'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En create gl entries and acct update

        --Sn find narration
        BEGIN
            SELECT CTM_TRAN_DESC
              INTO V_TRANS_DESC
              FROM CMS_TRANSACTION_MAST
             WHERE      CTM_TRAN_CODE = P_TXN_CODE
                     AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                     AND CTM_INST_CODE = P_INST_CODE;

            IF TRIM (V_TRANS_DESC) IS NOT NULL
            THEN
                V_NARRATION := V_TRANS_DESC || '/';
            END IF;

            IF TRIM (P_MERCHANT_NAME) IS NOT NULL
            THEN
                V_NARRATION := V_NARRATION || P_MERCHANT_NAME || '/';
            END IF;

            IF TRIM (P_MERCHANT_CITY) IS NOT NULL
            THEN
                V_NARRATION := V_NARRATION || P_MERCHANT_CITY || '/';
            END IF;

            IF TRIM (P_TRAN_DATE) IS NOT NULL
            THEN
                V_NARRATION := V_NARRATION || P_TRAN_DATE || '/';
            END IF;

            IF TRIM (V_AUTH_ID) IS NOT NULL
            THEN
                V_NARRATION := V_NARRATION || V_AUTH_ID;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_TRANS_DESC := 'Transaction type ' || P_TXN_CODE;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG :=
                    'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En find narration

        v_timestamp := SYSTIMESTAMP;                    --added by Pankaj S. for 10871
        
               
         if v_comp_hold_cr_flag ='H' then
         
         V_TRAN_AMT := v_tot_hold_amt+v_comp_hold_fee_diff;
         V_TOTAL_AMT :=V_TRAN_AMT;
         
         end if;
         
      --Sn create a entry in statement log
        IF V_DR_CR_FLAG <> 'NA'
        THEN
            BEGIN
                INSERT INTO CMS_STATEMENTS_LOG (CSL_PAN_NO,
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
                                                          csl_time_stamp--En added by Pankaj S. for 10871
                                                          )
                      VALUES (
                                    V_HASH_PAN,
                                    ROUND (v_ledger_bal, 2), --V_ACCT_BALANCE replaced by Pankaj S. with v_ledger_bal for 10871 --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                    ROUND (V_TRAN_AMT, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                    V_DR_CR_FLAG,
                                    V_TRAN_DATE,
                                    ROUND (
                                        DECODE (V_DR_CR_FLAG,
                                                  'DR', v_ledger_bal - V_TRAN_AMT, --V_ACCT_BALANCE replaced by Pankaj S. with v_ledger_bal for 10871
                                                  'CR', v_ledger_bal + V_TRAN_AMT, --V_ACCT_BALANCE replaced by Pankaj S. with v_ledger_bal for 10871
                                                  'NA', v_ledger_bal),
                                        2), --V_ACCT_BALANCE replaced by Pankaj S. with v_ledger_bal for 10871 --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
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
                                    (SUBSTR (P_CARD_NO,
                                                LENGTH (P_CARD_NO) - 3,
                                                LENGTH (P_CARD_NO))), --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
                                    --Sn added by Pankaj S. for 10871
                                    v_prod_code,v_prod_cattype,
                                    v_acct_type,
                                    v_timestamp--En added by Pankaj S. for 10871
                                    );
            EXCEPTION
                WHEN OTHERS
                THEN
                    V_RESP_CDE := '21';
                    V_ERR_MSG :=
                        'Problem while inserting into statement log for tran amt '
                        || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
            END;
        END IF;

        --En create a entry in statement log

        --Sn find fee opening balance
        IF V_TOTAL_FEE <> 0 OR V_FREETXN_EXCEED = 'N'
        THEN -- Modified by Trivikram on 26-July-2012 for logging fee of free transaction
            BEGIN
                SELECT DECODE (V_DR_CR_FLAG,    'DR', v_ledger_bal - V_TRAN_AMT, --V_ACCT_BALANCE replaced by Pankaj S. with v_ledger_bal for 10871
                                                                                                  'CR', v_ledger_bal + V_TRAN_AMT, --V_ACCT_BALANCE replaced by Pankaj S. with v_ledger_bal for 10871
                                                                                                                                             'NA', v_ledger_bal) --V_ACCT_BALANCE replaced by Pankaj S. with v_ledger_bal for 10871
                  INTO V_FEE_OPENING_BAL
                  FROM DUAL;
            EXCEPTION
                WHEN OTHERS
                THEN
                    V_RESP_CDE := '12';
                    V_ERR_MSG :=
                        'Error in acct balance calculation based on transflag'
                        || V_DR_CR_FLAG;
                    RAISE EXP_REJECT_RECORD;
            END;

            -- Added by Trivikram on 27-July-2012 for logging complementary transaction
            IF V_FREETXN_EXCEED = 'N'
            THEN
                BEGIN
                    INSERT INTO CMS_STATEMENTS_LOG (CSL_PAN_NO,
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
                                                              csl_time_stamp--En added by Pankaj S. for 10871
                                                              )
                          VALUES (
                                        V_HASH_PAN,
                                        ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                        ROUND (V_TOTAL_FEE, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                        'DR',
                                        V_TRAN_DATE,
                                        ROUND (V_FEE_OPENING_BAL - V_TOTAL_FEE, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                        -- 'Complimentary ' || V_DURATION ||' '|| V_NARRATION, -- Commented for MVCSD-4471 -- Modified by Trivikram  on 27-July-2012
                                        V_FEE_DESC,                   --Added for MVCSD-4471
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
                                        (SUBSTR (P_CARD_NO,
                                                    LENGTH (P_CARD_NO) - 3,
                                                    LENGTH (P_CARD_NO))), --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                                        --Sn added by Pankaj S. for 10871
                                        v_prod_code,
                                        v_acct_type,
                                        v_timestamp--En added by Pankaj S. for 10871
                                        );
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        V_RESP_CDE := '21';
                        V_ERR_MSG :=
                            'Problem while inserting into statement log for tran fee '
                            || SUBSTR (SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
                END;
            ELSE
                BEGIN
                    --En find fee opening balance
                    IF V_FEEAMNT_TYPE = 'A'
                    THEN
                        -- Added by Trivikram on 23/aug/2012 for logged fixed fee and percentage fee with waiver

                        V_FLAT_FEES :=
                            ROUND (
                                V_FLAT_FEES - ( (V_FLAT_FEES * V_WAIV_PERCNT) / 100),
                                2);


                        V_PER_FEES :=
                            ROUND (
                                V_PER_FEES - ( (V_PER_FEES * V_WAIV_PERCNT) / 100),
                                2);

                        --En Entry for Fixed Fee
                        INSERT INTO CMS_STATEMENTS_LOG (CSL_PAN_NO,
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
                                                                  csl_time_stamp--En added by Pankaj S. for 10871
                                                                  )
                              VALUES (
                                            V_HASH_PAN,
                                            ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                            ROUND (V_FLAT_FEES, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                            'DR',
                                            V_TRAN_DATE,
                                            ROUND (V_FEE_OPENING_BAL - V_FLAT_FEES, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                            --'Fixed Fee debited for ' || V_NARRATION, --Commented for MVCSD-4471
                                            'Fixed Fee debited for ' || V_FEE_DESC, --Added for MVCSD-4471
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
                                            (SUBSTR (P_CARD_NO,
                                                        LENGTH (P_CARD_NO) - 3,
                                                        LENGTH (P_CARD_NO))),
                                            --Sn added by Pankaj S. for 10871
                                            v_prod_code,
                                            v_acct_type,
                                            v_timestamp--En added by Pankaj S. for 10871
                                            );

                        --En Entry for Fixed Fee
                        V_FEE_OPENING_BAL := V_FEE_OPENING_BAL - V_FLAT_FEES;

                        --Sn Entry for Percentage Fee

                        INSERT INTO CMS_STATEMENTS_LOG (CSL_PAN_NO,
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
                                                                  csl_time_stamp--En added by Pankaj S. for 10871
                                                                  )
                              VALUES (
                                            V_HASH_PAN,
                                            ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                            ROUND (V_PER_FEES, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                            'DR',
                                            V_TRAN_DATE,
                                            ROUND (V_FEE_OPENING_BAL - V_PER_FEES, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                            -- 'Percetage Fee debited for ' || V_NARRATION, --Commented for MVCSD-4471
                                            'Percentage Fee debited for ' || V_FEE_DESC, --Added for MVCSD-4471
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
                                            (SUBSTR (P_CARD_NO,
                                                        LENGTH (P_CARD_NO) - 3,
                                                        LENGTH (P_CARD_NO))),
                                            --Sn added by Pankaj S. for 10871
                                            v_prod_code,
                                            v_acct_type,
                                            v_timestamp--En added by Pankaj S. for 10871
                                            );
                    --En Entry for Percentage Fee

                    ELSE
                        --Sn create entries for FEES attached

                        INSERT INTO CMS_STATEMENTS_LOG (CSL_PAN_NO,
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
                                                                  csl_time_stamp--En added by Pankaj S. for 10871
                                                                  )
                              VALUES (
                                            V_HASH_PAN,
                                            ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                            ROUND (v_fee_amt, 2), -- Modifed for MVHOST-346 --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                            'DR',
                                            V_TRAN_DATE,
                                            ROUND (V_FEE_OPENING_BAL - v_fee_amt, 2), -- Modifed for MVHOST-346 --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                            --'Fee debited for ' || V_NARRATION, --Commented for MVCSD-4471
                                            V_FEE_DESC,               --Added for MVCSD-4471
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
                                            (SUBSTR (P_CARD_NO,
                                                        LENGTH (P_CARD_NO) - 3,
                                                        LENGTH (P_CARD_NO))), --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                                            --Sn added by Pankaj S. for 10871
                                            v_prod_code,
                                            v_acct_type,
                                            v_timestamp--En added by Pankaj S. for 10871
                                            );

                        --Start    Clawback Changes    (MVHOST - 346) on 20/04/2013
           
                        IF v_clawback_txn = 'Y' AND V_CLAWBACK_AMNT > 0 and v_chrg_dtl_cnt < v_tot_clwbck_count  -- Modified for fwr 64
                        THEN
                            BEGIN
                                INSERT INTO cms_charge_dtl (ccd_pan_code,
                                                                     ccd_acct_no,
                                                                     ccd_clawback_amnt,
                                                                     ccd_gl_acct_no,
                                                                     ccd_pan_code_encr,
                                                                     ccd_rrn,
                                                                     ccd_calc_date,
                                                                     ccd_fee_freq,
                                                                     ccd_file_status,
                                                                     ccd_clawback,
                                                                     ccd_inst_code,
                                                                     ccd_fee_code,
                                                                     ccd_calc_amt,
                                                                     ccd_fee_plan,
                                                                     ccd_delivery_channel,
                                                                     ccd_txn_code,
                                                                     ccd_debited_amnt,
                                                                     ccd_mbr_numb,
                                                                     ccd_process_msg,
                                                                     ccd_feeattachtype)
                                      VALUES (v_hash_pan,
                                                 v_card_acct_no,
                                                 ROUND (v_clawback_amnt, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                                 v_fee_cracct_no,
                                                 v_encr_pan,
                                                 p_rrn,
                                                 v_tran_date,
                                                 'T',
                                                 'C',
                                                 v_clawback,
                                                 p_inst_code,
                                                 v_fee_code,
                                                 ROUND (v_actual_fee_amnt, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                                 v_fee_plan,
                                                 p_delivery_channel,
                                                 p_txn_code,
                                                 ROUND (v_fee_amt, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                                 p_mbr_numb,
                                                 DECODE (v_err_msg, 'OK', 'SUCCESS'),
                                                 v_feeattach_type);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    v_resp_cde := '21';
                                    v_err_msg :=
                                        'Problem while inserting into CMS_CHARGE_DTL '
                                        || SUBSTR (SQLERRM, 1, 200);
                                    RAISE exp_reject_record;
                            END;
                        END IF;
                    --End  Clawback Changes (MVHOST - 346) on 20/04/2013

                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        V_RESP_CDE := '21';
                        V_ERR_MSG :=
                            'Problem while inserting into statement log for tran fee '
                            || SUBSTR (SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
                END;
            END IF;
        END IF;

        --En create entries for FEES attached
        --Sn create a entry for successful
        BEGIN
            INSERT INTO CMS_TRANSACTION_LOG_DTL (CTD_DELIVERY_CHANNEL,
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
                                                             CTD_ZIP_CODE,/* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes    */
                                                             ctd_completion_fee,
                                                             CTD_COMPLFEE_INCREMENT_TYPE,
                                                             CTD_COMPFEE_CODE ,
                                                             CTD_COMPFEEATTACH_TYPE,
                                                             CTD_COMPFEEPLAN_ID
                                                                             )
                  VALUES (
                                P_DELIVERY_CHANNEL,
                                P_TXN_CODE,
                                V_TXN_TYPE,
                                P_MSG,
                                P_TXN_MODE,
                                P_TRAN_DATE,
                                P_TRAN_TIME,
                                V_HASH_PAN,
                                p_txn_amt, --v_tran_amt,                    --p_txn_amt modified for 10871 modified for defect id:12166
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
                                P_ADDR_VERFY_RESPONSE,
                                P_INTERNATIONAL_IND,
                                /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                P_NETWORK_ID,
                                P_INTERCHANGE_FEEAMT,
                                P_MERCHANT_ZIP,
                                P_MERC_ID,
                                P_COUNTRY_CODE,
                                --DECODE(V_ZIP_CODE_IN, 'N', '', V_ZIP_CODE_IN) --Modified by Deepa to validate 5 digits of ZIP code on OCT-19-2012
                                DECODE (P_ZIP_CODE, 'N', '', P_ZIP_CODE), -- Added for FSS-943 on 14-Mar-2013
                                                                                     /* End    Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                 decode(v_comp_total_fee_log,'Y','0',v_comp_total_fee),
                                 V_COMPLFEE_INCREMENT_TYPE,
                                 v_comp_fee_code,
                                 v_comp_feeattach_type,
                                 v_comp_fee_plan                                                     );
        --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
        EXCEPTION
            WHEN OTHERS
            THEN
                V_ERR_MSG :=
                    'Problem while selecting data from response master '
                    || SUBSTR (SQLERRM, 1, 300);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
        END;

        --En create a entry for successful

        /*                                                                         --SN commented as per review observation for FSS-1246
         ---Sn update daily and weekly transcounter    and amount
         BEGIN
         --      SELECT CAT_PAN_CODE
         --         INTO V_AVAIL_PAN
         --         FROM CMS_AVAIL_TRANS
         --        WHERE CAT_PAN_CODE = V_HASH_PAN P_card_no
         --              AND CAT_TRAN_CODE = P_TXN_CODE AND
         --              CAT_TRAN_MODE = P_TXN_MODE;
          UPDATE CMS_AVAIL_TRANS
              SET CAT_MAXDAILY_TRANCNT  = DECODE(CAT_MAXDAILY_TRANCNT,
                                                    0,
                                                    CAT_MAXDAILY_TRANCNT,
                                                    CAT_MAXDAILY_TRANCNT - 1),
                  CAT_MAXDAILY_TRANAMT    = DECODE(V_DR_CR_FLAG,
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


         --        IF SQL%ROWCOUNT = 0 THEN
         --          V_ERR_MSG  := 'Problem while updating data in avail trans ' ||
         --                         SUBSTR(SQLERRM, 1, 300);
         --          V_RESP_CDE := '21';
         --          RAISE EXP_REJECT_RECORD;
         --        END IF;
         --
         EXCEPTION
          WHEN EXP_REJECT_RECORD THEN
             RAISE;
          WHEN NO_DATA_FOUND THEN
             NULL;
          WHEN OTHERS THEN
             V_ERR_MSG    := 'Problem while selecting data from avail trans ' ||
                            SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
         END;

         --En update daily and weekly transaction counter and amount
         */
        --EN commented as per review observation for FSS-1246

        --Sn create detail for response message
        IF V_OUTPUT_TYPE = 'B'
        THEN
            --Balance Inquiry
            P_RESP_MSG := TO_CHAR (V_UPD_AMT+v_delayed_amount);
        END IF;

        --En create detail fro response message
        --Sn mini statement
        IF V_OUTPUT_TYPE = 'M'
        THEN
            --Mini statement
            BEGIN
                SP_GEN_MINI_STMT (P_INST_CODE,
                                        P_CARD_NO,
                                        V_MINI_TOTREC,
                                        V_MINISTMT_OUTPUT,
                                        V_MINISTMT_ERRMSG);

                IF V_MINISTMT_ERRMSG <> 'OK'
                THEN
                    V_ERR_MSG := V_MINISTMT_ERRMSG;
                    V_RESP_CDE := '21';
                    RAISE EXP_REJECT_RECORD;
                END IF;

                P_RESP_MSG :=
                    LPAD (TO_CHAR (V_MINI_TOTREC), 2, '0') || V_MINISTMT_OUTPUT;
            EXCEPTION
                WHEN EXP_REJECT_RECORD
                THEN
                    RAISE;
                WHEN OTHERS
                THEN
                    V_ERR_MSG :=
                        'Problem while selecting data for mini statement '
                        || SUBSTR (SQLERRM, 1, 300);
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
                IF V_TRAN_PREAUTH_FLAG = 'Y'
                THEN
                    /*
                    Commented on 06112012 Dhiraj Gaikwad

                    IF P_PREAUTH_EXPPERIOD IS NULL THEN
                      BEGIN
                         SELECT CPM_PRE_AUTH_EXP_DATE
                          INTO V_PREAUTH_EXP_PERIOD
                          FROM CMS_PROD_MAST
                         WHERE CPM_PROD_CODE = V_PROD_CODE;
                      EXCEPTION
                         WHEN NO_DATA_FOUND THEN
                          V_ERR_MSG  := 'NO DATA IN CMS_PROD_MAST FOR PRODUCT ' ||
                                         V_PROD_CODE;
                          V_RESP_CDE := '21';
                          RAISE EXP_REJECT_RECORD;
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
                          WHEN NO_DATA_FOUND THEN
                             V_ERR_MSG    := 'NO DATA IN CMS_INST_PARAM FOR EXPIRY PERIOD ' ||
                                            P_INST_CODE;
                             V_RESP_CDE := '21';
                             RAISE EXP_REJECT_RECORD;
                          WHEN OTHERS THEN
                             V_ERR_MSG    := 'Error while selecting  CMS_INST_PARAM ' ||
                                            SUBSTR(SQLERRM, 1, 300);
                             V_RESP_CDE := '21';
                             RAISE EXP_REJECT_RECORD;
                         END;

                         V_PREAUTH_HOLD    := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
                         V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
                      ELSE
                         V_PREAUTH_HOLD    := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
                         V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
                      END IF;
                    ELSE
                      V_PREAUTH_HOLD     := SUBSTR(TRIM(P_PREAUTH_EXPPERIOD), 1, 1);
                      V_PREAUTH_PERIOD := SUBSTR(TRIM(P_PREAUTH_EXPPERIOD), 2, 2);

                      IF V_PREAUTH_PERIOD = '00' THEN
                         BEGIN
                          SELECT CPM_PRE_AUTH_EXP_DATE
                             INTO V_PREAUTH_EXP_PERIOD
                             FROM CMS_PROD_MAST
                            WHERE CPM_PROD_CODE = V_PROD_CODE;
                         EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                             V_ERR_MSG    := 'NO DATA IN CMS_PROD_MAST1 FOR EXPIRY PRODUCT ' ||
                                            V_PROD_CODE;
                             V_RESP_CDE := '21';
                             RAISE EXP_REJECT_RECORD;

                          WHEN OTHERS THEN
                             V_ERR_MSG    := 'Error while selecting  CMS_PROD_MAST1 ' ||
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
                             WHEN NO_DATA_FOUND THEN
                              V_ERR_MSG  := 'NO DATA IN CMS_INST_PARAM1 FOR EXPIRY PERIOD ' ||
                                              P_INST_CODE;
                              V_RESP_CDE := '21';
                              RAISE EXP_REJECT_RECORD;
                             WHEN OTHERS THEN
                              V_ERR_MSG  := 'Error while selecting  CMS_INST_PARAM1 ' ||
                                              SUBSTR(SQLERRM, 1, 300);
                              V_RESP_CDE := '21';
                              RAISE EXP_REJECT_RECORD;
                          END;

                          V_PREAUTH_HOLD     := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
                          V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
                         ELSE
                          V_PREAUTH_HOLD     := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 1, 1);
                          V_PREAUTH_PERIOD := SUBSTR(TRIM(V_PREAUTH_EXP_PERIOD), 2, 2);
                         END IF;
                      ELSE
                         V_PREAUTH_HOLD    := V_PREAUTH_HOLD;
                         V_PREAUTH_PERIOD := V_PREAUTH_PERIOD;
                      END IF;
                    END IF; */

                    -------------------------
                    --SN- Added for FSS-1246
                    -------------------------

                    IF     TRIM (p_preauth_expperiod) IS NULL
                        OR LENGTH (TRIM (p_preauth_expperiod)) < 2
                        OR LENGTH (TRIM (p_preauth_expperiod)) > 5
                        OR SUBSTR (TRIM (p_preauth_expperiod), 1, 1) NOT IN
                                ('0', '1', '2')
                    THEN
                        v_preauth_expperiod := '000';
                    ELSE
                        v_preauth_expperiod := TRIM (p_preauth_expperiod);
                    END IF;

                    -------------------------
                    --SN- Added for FSS-1246
                    -------------------------


                    /* Start Added by Dhiraj G on 06112012  for Pre -Auth Hold days changes */
                    vt_preauth_hold :=
                        TO_NUMBER (
                            SUBSTR (TRIM (NVL (v_preauth_expperiod, '000')), 1, 1)); -- Changed from p_preauth_expperiod to v_preauth_expperiod FSS-1246
                    vt_preauth_period :=
                        TO_NUMBER (
                            SUBSTR (TRIM (NVL (v_preauth_expperiod, '000')), 2, 2)); -- Changed from p_preauth_expperiod to v_preauth_expperiod FSS-1246

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

                    vp_preauth_hold :=
                        TO_NUMBER (SUBSTR (TRIM (vp_preauth_exp_period), 1, 1));
                    vp_preauth_period :=
                        TO_NUMBER (SUBSTR (TRIM (vp_preauth_exp_period), 2, 2));

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

                    vi_preauth_hold :=
                        TO_NUMBER (SUBSTR (TRIM (vi_preauth_exp_period), 1, 1)); --01122012
                    vi_preauth_period :=
                        TO_NUMBER (SUBSTR (TRIM (vi_preauth_exp_period), 2, 2)); --01122012

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

                    /* End  Added by Dhiraj G on 27112012    for Pre -Auth Hold days changes */

                    /*
                        preauth period will be added with transaction date based on preauth_hold
                        IF v_preauth_hold is '0'--'Minute'
                        '1'--'Hour'
                        '2'--'Day'
                      */
                    /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */

                    /* Commented on 21092012 Dhiraj Gaikwad

                      IF P_DELIVERY_CHANNEL IN ('01', '02') AND P_TXN_CODE = '11' THEN
                        IF V_HOLD_DAYS IS NOT NULL THEN
                          IF V_HOLD_DAYS > V_PREAUTH_PERIOD THEN
                            V_PREAUTH_PERIOD := V_HOLD_DAYS;
                          END IF;
                        END IF;
                     END IF;*/

                    /*Comparing greatest from    institution peroid ,Txn Peroid , product peroid  with rule peroid  */

                    IF P_DELIVERY_CHANNEL IN ('01', '02') AND P_TXN_CODE = '11'
                    THEN
                        IF V_HOLD_DAYS IS NOT NULL AND V_HOLD_DAYS <> '0' -- Added on 26-Feb-2013 during FSS-781 changes
                        THEN
                            IF V_PREAUTH_HOLD IN ('0', '1')
                            THEN
                                V_PREAUTH_PERIOD := V_HOLD_DAYS;
                                V_PREAUTH_HOLD := '2';
                            ELSIF V_PREAUTH_HOLD = '2'
                            THEN
                                IF V_HOLD_DAYS > V_PREAUTH_PERIOD
                                THEN
                                    V_PREAUTH_PERIOD := V_HOLD_DAYS;
                                    V_PREAUTH_HOLD := '2';
                                END IF;
                            END IF;
                        END IF;
                    END IF;

                    /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */

                    IF V_PREAUTH_HOLD = '0'
                    THEN
                        V_PREAUTH_DATE :=
                            V_TRAN_DATE + (V_PREAUTH_PERIOD * (1 / 1440));
                    END IF;

                    IF V_PREAUTH_HOLD = '1'
                    THEN
                        V_PREAUTH_DATE :=
                            V_TRAN_DATE + (V_PREAUTH_PERIOD * (1 / 24));
                    END IF;

                    IF V_PREAUTH_HOLD = '2'
                    THEN
                        V_PREAUTH_DATE := V_TRAN_DATE + V_PREAUTH_PERIOD;
                    END IF;

                    BEGIN
                        SELECT COUNT (*)
                          INTO V_PREAUTH_COUNT
                          FROM VMSCMS.CMS_PREAUTH_TRANSACTION                  --Added for VMS-5739/FSP-991
                         WHERE      CPT_CARD_NO = V_HASH_PAN
                                 AND CPT_RRN = P_RRN
                                 AND CPT_PREAUTH_VALIDFLAG = 'Y'
                                 AND CPT_EXPIRY_FLAG = 'N';
						IF SQL%ROWCOUNT = 0 THEN
						 SELECT COUNT (*)
                          INTO V_PREAUTH_COUNT
                          FROM VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                  --Added for VMS-5739/FSP-991
                         WHERE      CPT_CARD_NO = V_HASH_PAN
                                 AND CPT_RRN = P_RRN
                                 AND CPT_PREAUTH_VALIDFLAG = 'Y'
                                 AND CPT_EXPIRY_FLAG = 'N';
						END IF;

                        IF V_PREAUTH_COUNT > 0
                        THEN
                            IF P_INCR_INDICATOR = '1'
                            THEN
                                V_TRANTYPE := 'I';

                                BEGIN
                                    SELECT CPT_TOTALHOLD_AMT                                --,
                                      --CPT_EXPIRY_DATE          --Commented on 24-Jan-2013 so that expiry date calculated above will be updated in CMS_PREAUTH_TRANSACTION
                                      INTO V_PREAUTH_COUNT                                    --,
                                      --V_PREAUTH_DATE             -- Comented for defect 10121
                                      FROM VMSCMS.CMS_PREAUTH_TRANSACTION                    --Added for VMS-5739/FSP-991
                                     WHERE      CPT_CARD_NO = V_HASH_PAN
                                             AND CPT_RRN = P_RRN
                                             AND CPT_PREAUTH_VALIDFLAG = 'Y'
                                             AND CPT_EXPIRY_FLAG = 'N';
									IF SQL%ROWCOUNT = 0 THEN
									                                    SELECT CPT_TOTALHOLD_AMT                                --,
                                      --CPT_EXPIRY_DATE          --Commented on 24-Jan-2013 so that expiry date calculated above will be updated in CMS_PREAUTH_TRANSACTION
                                      INTO V_PREAUTH_COUNT                                    --,
                                      --V_PREAUTH_DATE             -- Comented for defect 10121
                                      FROM VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                  --Added for VMS-5739/FSP-991
                                     WHERE      CPT_CARD_NO = V_HASH_PAN
                                             AND CPT_RRN = P_RRN
                                             AND CPT_PREAUTH_VALIDFLAG = 'Y'
                                             AND CPT_EXPIRY_FLAG = 'N';
									END IF;									
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        V_ERR_MSG :=
                                            'Error while selecting  CMS_PREAUTH_TRANSACTION '
                                            || SUBSTR (SQLERRM, 1, 300);
                                        V_RESP_CDE := '21';
                                        RAISE EXP_REJECT_RECORD;
                                END;

                                --For Incremental
                                /*
                             Commented by Dhiraj Gaikwad on 28112012    as
                              --we need to add hold days in incrimental pre auth from transaction date
                              V_PREAUTH_HOLD     := SUBSTR(TRIM(P_PREAUTH_EXPPERIOD), 1, 1);
                                V_PREAUTH_PERIOD := SUBSTR(TRIM(P_PREAUTH_EXPPERIOD), 2, 2);

                                IF V_PREAUTH_HOLD = '0' THEN
                                  V_PREAUTH_DATE := V_PREAUTH_DATE +
                                                     V_PREAUTH_PERIOD / (24 * 60);
                                END IF;

                                IF V_PREAUTH_HOLD = '1' THEN
                                  V_PREAUTH_DATE := V_PREAUTH_DATE + V_PREAUTH_PERIOD / 24;
                                END IF;

                                IF V_PREAUTH_HOLD = '2' THEN
                                  V_PREAUTH_DATE := V_PREAUTH_DATE + V_PREAUTH_PERIOD;
                                END IF;
                                */
                                BEGIN
                                    UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION            --Added for VMS-5739/FSP-991
                                        SET CPT_TOTALHOLD_AMT =
                                                 ROUND (V_PREAUTH_COUNT + V_TRAN_AMT, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                             CPT_TRANSACTION_FLAG = 'I',
                                             CPT_TXN_AMNT = ROUND (v_tran_amt, 2), --p_txn_amt modified for 10871 --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                             CPT_EXPIRY_DATE = V_PREAUTH_DATE,
                                             cpt_completion_fee=v_comp_fee_hold
                                     WHERE      CPT_CARD_NO = V_HASH_PAN
                                             AND CPT_RRN = P_RRN
                                             AND CPT_PREAUTH_VALIDFLAG = 'Y'
                                             AND CPT_EXPIRY_FLAG = 'N'
                                             AND CPT_INST_CODE = P_INST_CODE;
											 
										IF SQL%ROWCOUNT = 0
                                        THEN
											   UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST            --Added for VMS-5739/FSP-991
											SET CPT_TOTALHOLD_AMT =
													 ROUND (V_PREAUTH_COUNT + V_TRAN_AMT, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
												 CPT_TRANSACTION_FLAG = 'I',
												 CPT_TXN_AMNT = ROUND (v_tran_amt, 2), --p_txn_amt modified for 10871 --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
												 CPT_EXPIRY_DATE = V_PREAUTH_DATE,
												 cpt_completion_fee=v_comp_fee_hold
										 WHERE      CPT_CARD_NO = V_HASH_PAN
												 AND CPT_RRN = P_RRN
												 AND CPT_PREAUTH_VALIDFLAG = 'Y'
												 AND CPT_EXPIRY_FLAG = 'N'
												 AND CPT_INST_CODE = P_INST_CODE;

										IF SQL%ROWCOUNT = 0
										THEN
											V_ERR_MSG :=
												'Problem while updating data in CMS_PREAUTH_TRANSACTION';
											V_RESP_CDE := '21';
											RAISE EXP_REJECT_RECORD;
										END IF;
									  END IF;	
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        V_ERR_MSG :=
                                            'Error while updating  CMS_PREAUTH_TRANSACTION '
                                            || SUBSTR (SQLERRM, 1, 300);
                                        V_RESP_CDE := '21';
                                        RAISE EXP_REJECT_RECORD;
                                END;
                            ELSE
                                V_RESP_CDE := '56';                 -- Server Declione
                                V_ERR_MSG :=
                                    'Not aValid Pre-Auth' || SUBSTR (SQLERRM, 1, 300);
                                RAISE EXP_REJECT_RECORD;
                            END IF;
                        ELSE
                            V_TRANTYPE := 'N';

                            BEGIN
                                INSERT
                                  INTO CMS_PREAUTH_TRANSACTION (
                                             CPT_CARD_NO,
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
                                             CPT_ACCT_NO, --Added by Deepa on 26-Nov-2012 to log the Account number of preauth transactions
                                             CPT_MCC_CODE,                 -- Added for FSS-781
                                             cpt_completion_fee,
                                             --Sn Added for Transactionlog Functional Removal Phase-II changes
                                             cpt_delivery_channel,
                                             cpt_txn_code,
                                             cpt_merchant_id,
                                             cpt_merchant_name, 
                                             cpt_merchant_city,
                                             cpt_merchant_state, 
                                             cpt_merchant_zip, 
                                             cpt_pos_verification, 
                                             cpt_internation_ind_response,
                                             --En Added for Transactionlog Functional Removal Phase-II changes
                                             cpt_complfree_flag
                                                             )
                                VALUES (
                                             V_HASH_PAN,
                                             ROUND (NVL (v_tran_amt, 0), 2), --modified for 10871 --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                             V_PREAUTH_DATE,
                                             P_PREAUTH_SEQNO,
                                             'Y',
                                             P_INST_CODE,
                                             P_MBR_NUMB,
                                             V_ENCR_PAN,
                                             'N',
                                             TRIM (
                                                 TO_CHAR (NVL (v_tran_amt, 0),
                                                             '999999999999999990.99')), --formatted for 10871
                                             P_RRN,
                                             P_TRAN_DATE,
                                             P_TRAN_TIME,
                                             P_TERM_ID,
                                             'N',
                                             TRIM (
                                                 TO_CHAR (NVL (v_tran_amt, 0),
                                                             '999999999999999990.99')), --formatted for 10871
                                             'N',
                                             V_ACCT_NUMBER, --Added by Deepa on 26-Nov-2012 to log the Account number of preauth transactions
                                             P_MCC_CODE,                  -- Added for FSS-781
                                             v_comp_fee_hold,
                                              --Sn Added for Transactionlog Functional Removal Phase-II changes
                                             p_delivery_channel,
                                             p_txn_code,
                                             p_merc_id,
                                             p_merchant_name,
                                             p_merchant_city,
                                             p_atmname_loc,
                                             p_merchant_zip,
                                             p_pos_verfication,
                                             p_international_ind,
                                             --En Added for Transactionlog Functional Removal Phase-II changes
                                             CASE WHEN v_comp_freetxn_exceed='N' THEN 'Y' END
                                                          );
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    V_ERR_MSG :=
                                        'Error while inserting  CMS_PREAUTH_TRANSACTION '
                                        || SUBSTR (SQLERRM, 1, 300);
                                    V_RESP_CDE := '21';
                                    RAISE EXP_REJECT_RECORD;
                            END;
                        END IF;

                        BEGIN
                            INSERT
                              INTO CMS_PREAUTH_TRANS_HIST (CPH_CARD_NO,
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
                                                                     CPH_MERCHANT_NAME, --Added by Deepa on May-09-2012 for statement changes
                                                                     CPH_MERCHANT_CITY,
                                                                     CPH_MERCHANT_STATE,
                                                                     CPH_DELIVERY_CHANNEL,
                                                                     CPH_TRAN_CODE,
                                                                     CPH_PANNO_LAST4DIGIT,
                                                                     CPH_ACCT_NO,
                                                                     cph_completion_fee) --Added by Deepa on 26-Nov-2012 to log the Account number of preauth transactions
                            VALUES (
                                         V_HASH_PAN,
                                         NVL (v_tran_amt, 0), --p_txn_amt modified for 10871          -- Added on 24-Jan-2013 to pass transaction amount and ignore toatal amount ,Defect 10122
                                         --V_TOTAL_AMT,    -- commented on 24-Jan-2013 to pass transaction amount and ignore toatal amount ,Defect 10122
                                         V_PREAUTH_DATE,
                                         P_PREAUTH_SEQNO,
                                         'Y',
                                         P_INST_CODE,
                                         P_MBR_NUMB,
                                         V_ENCR_PAN,
                                         'N',
                                         -- TRIM (TO_CHAR (NVL (v_total_amt, 0),'999999999999999990.99')), --modified for 10871
                                         --Commented and modified on 24.07.2013 for 11692
                                         TRIM (
                                             TO_CHAR (NVL (v_tran_amt, 0),
                                                         '999999999999999990.99')),
                                         P_RRN,
                                         P_TRAN_DATE,
                                         P_TERM_ID,
                                         'N',
                                         V_TRANTYPE,
                                         TRIM (
                                             TO_CHAR (NVL (v_tran_amt, 0),
                                                         '999999999999999990.99')), --modified for 10871
                                         P_RRN,
                                         P_MERCHANT_NAME, --Added by Deepa on May-09-2012 for statement changes
                                         P_MERCHANT_CITY,
                                         P_ATMNAME_LOC,
                                         P_DELIVERY_CHANNEL,
                                         P_TXN_CODE,
                                         (SUBSTR (P_CARD_NO,
                                                     LENGTH (P_CARD_NO) - 3,
                                                     LENGTH (P_CARD_NO))), --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
                                         V_ACCT_NUMBER,
                                        v_comp_fee_hold); --Added by Deepa on 26-Nov-2012 to log the Account number of preauth transactions
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while inserting  CMS_PREAUTH_TRANS_HIST '
                                    || SUBSTR (SQLERRM, 1, 300);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    EXCEPTION
                        WHEN EXP_REJECT_RECORD
                        THEN
                            RAISE;
                        WHEN OTHERS
                        THEN
                            V_RESP_CDE := '21';                    -- Server Declione
                            V_ERR_MSG :=
                                'Problem while inserting preauth transaction details'
                                || SUBSTR (SQLERRM, 1, 300);
                            RAISE EXP_REJECT_RECORD;
                    END;
                END IF;
            EXCEPTION
                WHEN EXP_REJECT_RECORD
                THEN
                    RAISE;
                WHEN OTHERS
                THEN
                    V_RESP_CDE := '21';                          -- Server Declione
                    V_ERR_MSG :=
                        'Problem while inserting preauth transaction details'
                        || SUBSTR (SQLERRM, 1, 300);
                    RAISE EXP_REJECT_RECORD;
            END;
        /*                                                       --SN commented as per review observation for FSS-1246
         ---Sn Updation of Usage limit and amount
         BEGIN
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
             V_ERR_MSG    := 'Cannot get the Transaction Limit Details of the Card' ||
                             V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
             V_ERR_MSG    := 'Error while selecting CMS_TRANSLIMIT_CHECK' ||
                             V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
         END;
        */
        --EN commented as per review observation for FSS-1246

        /*                                                       --SN commented as per review observation for FSS-1246
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
                          SET CTC_ATMUSAGE_AMT          = V_ATM_USAGEAMNT,
                              CTC_ATMUSAGE_LIMIT      = V_ATM_USAGELIMIT,
                              CTC_POSUSAGE_AMT         = 0,
                              CTC_POSUSAGE_LIMIT      = 0,
                              CTC_PREAUTHUSAGE_LIMIT = 0,
                              CTC_BUSINESS_DATE         = TO_DATE(P_TRAN_DATE ||
                                                                  '23:59:59',
                                                                  'yymmdd' ||
                                                                  'hh24:mi:ss'),
                              CTC_MMPOSUSAGE_AMT      = 0,
                              CTC_MMPOSUSAGE_LIMIT     = 0
                        WHERE CTC_INST_CODE = P_INST_CODE AND
                              CTC_PAN_CODE = V_HASH_PAN AND
                              CTC_MBR_NUMB = P_MBR_NUMB;

                        IF SQL%ROWCOUNT = 0 THEN
                         V_ERR_MSG    := 'Problem while updating data in CMS_TRANSLIMIT_CHECK';
                         V_RESP_CDE := '21';
                         RAISE EXP_REJECT_RECORD;
                        END IF;

                     EXCEPTION
                        WHEN OTHERS THEN
                         V_ERR_MSG    := 'Error while updating CMS_TRANSLIMIT_CHECK' ||
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
                          SET CTC_ATMUSAGE_AMT     = V_ATM_USAGEAMNT,
                              CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
                        WHERE CTC_INST_CODE = P_INST_CODE AND
                              CTC_PAN_CODE = V_HASH_PAN AND
                              CTC_MBR_NUMB = P_MBR_NUMB;

                        IF SQL%ROWCOUNT = 0 THEN
                         V_ERR_MSG    := 'Problem while updating data in CMS_TRANSLIMIT_CHECK';
                         V_RESP_CDE := '21';
                         RAISE EXP_REJECT_RECORD;
                        END IF;

                     EXCEPTION
                        WHEN OTHERS THEN
                         V_ERR_MSG    := 'Error while updating CMS_TRANSLIMIT_CHECK1' ||
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
                  V_POS_USAGEAMNT         := 0;
                ELSE
                  V_PREAUTH_USAGE_LIMIT := 0;
                END IF;



                     BEGIN
                        UPDATE CMS_TRANSLIMIT_CHECK
                          SET CTC_POSUSAGE_AMT          = V_POS_USAGEAMNT,
                              CTC_POSUSAGE_LIMIT      = V_POS_USAGELIMIT,
                              CTC_ATMUSAGE_AMT         = 0,
                              CTC_ATMUSAGE_LIMIT      = 0,
                              CTC_BUSINESS_DATE         = TO_DATE(P_TRAN_DATE ||
                                                                  '23:59:59',
                                                                  'yymmdd' ||
                                                                  'hh24:mi:ss'),
                              CTC_MMPOSUSAGE_AMT      = 0,
                              CTC_MMPOSUSAGE_LIMIT     = 0,
                              CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
                        WHERE CTC_INST_CODE = P_INST_CODE AND
                              CTC_PAN_CODE = V_HASH_PAN AND
                              CTC_MBR_NUMB = P_MBR_NUMB;

                        IF SQL%ROWCOUNT = 0 THEN
                         V_ERR_MSG    := 'Problem while updating data in CMS_TRANSLIMIT_CHECK';
                         V_RESP_CDE := '21';
                         RAISE EXP_REJECT_RECORD;
                        END IF;

                     EXCEPTION
                        WHEN OTHERS THEN
                         V_ERR_MSG    := 'Error while updating CMS_TRANSLIMIT_CHECK2' ||
                                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
                         V_RESP_CDE := '21';
                         RAISE EXP_REJECT_RECORD;
                     END;


             ELSE
                V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;

                IF V_TRAN_PREAUTH_FLAG = 'Y' THEN
                  V_PREAUTH_USAGE_LIMIT := V_PREAUTH_USAGE_LIMIT + 1;
                  V_POS_USAGEAMNT         := V_POS_USAGEAMNT +
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
                          SET CTC_POSUSAGE_AMT          = V_POS_USAGEAMNT,
                              CTC_POSUSAGE_LIMIT      = V_POS_USAGELIMIT,
                              CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
                        WHERE CTC_INST_CODE = P_INST_CODE AND
                              CTC_PAN_CODE = V_HASH_PAN AND
                              CTC_MBR_NUMB = P_MBR_NUMB;

                        IF SQL%ROWCOUNT = 0 THEN
                         V_ERR_MSG    := 'Problem while updating data in CMS_TRANSLIMIT_CHECK';
                         V_RESP_CDE := '21';
                         RAISE EXP_REJECT_RECORD;
                        END IF;

                     EXCEPTION
                        WHEN OTHERS THEN
                         V_ERR_MSG    := 'Error while updating CMS_TRANSLIMIT_CHECK3' ||
                                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
                         V_RESP_CDE := '21';
                         RAISE EXP_REJECT_RECORD;
                     END;


             END IF;
            END IF;
         END;
         */
        --EN commented as per review observation for FSS-1246
        EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';                             -- Server Declione
                V_ERR_MSG :=
                    'ERROR WHILE CREATING ENTRIES FOR PRE AUTH TXN'
                    || SUBSTR (SQLERRM, 1, 300);
                RAISE EXP_REJECT_RECORD;
        END;



        ---En Updation of Usage limit and amount
        P_RESP_ID := V_RESP_CDE; --Added for VMS-8018
        BEGIN
            SELECT CMS_ISO_RESPCDE
              INTO P_RESP_CODE
              FROM CMS_RESPONSE_MAST
             WHERE      CMS_INST_CODE = P_INST_CODE
                     AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                     AND CMS_RESPONSE_ID = TO_NUMBER (V_RESP_CDE);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_ERR_MSG :=
                    'NO DATA IN  response master for respose code' || V_RESP_CDE;
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_ERR_MSG :=
                    'Problem while selecting data from response master for respose code'
                    || V_RESP_CDE
                    || SUBSTR (SQLERRM, 1, 300);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
        END;

        --En Added by Pankaj S. for enabling limit validation
        IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y'
        THEN
            BEGIN
                pkg_limits_check.sp_limitcnt_reset (p_inst_code,
                                                                v_hash_pan,
                                                                v_tran_amt,
                                                                v_comb_hash,
                                                                v_resp_cde,
                                                                v_err_msg);

                IF v_err_msg <> 'OK'
                THEN
                    v_err_msg := 'From Procedure sp_limitcnt_reset' || v_err_msg;
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
                        'Error from Limit Reset Count Process '
                        || SUBSTR (SQLERRM, 1, 200);
                    RAISE exp_reject_record;
            END;
        END IF;
    --En Added by Pankaj S. for enabling limit validation

    EXCEPTION
        --<< MAIN EXCEPTION >>
        WHEN EXP_REJECT_RECORD
        THEN
            ROLLBACK TO V_AUTH_SAVEPOINT;

            BEGIN
                SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
                  INTO V_ACCT_BALANCE, V_LEDGER_BAL
                  FROM CMS_ACCT_MAST
                 WHERE CAM_ACCT_NO =
                             (SELECT CAP_ACCT_NO
                                 FROM CMS_APPL_PAN
                                WHERE CAP_PAN_CODE = V_HASH_PAN
                                        AND CAP_INST_CODE = P_INST_CODE)
                         AND CAM_INST_CODE = P_INST_CODE;
            EXCEPTION
                WHEN OTHERS
                THEN
                    V_ACCT_BALANCE := 0;
                    V_LEDGER_BAL := 0;
            END;

            /*                                                       --SN commented as per review observation for FSS-1246
             BEGIN
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
                 V_ERR_MSG    := 'Cannot get the Transaction Limit Details of the Card' ||
                                 V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
                 V_RESP_CDE := '21';
                 RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                 V_ERR_MSG    := 'Error while selecting CMS_TRANSLIMIT_CHECK3' ||
                                 V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
                 V_RESP_CDE := '21';
                 RAISE EXP_REJECT_RECORD;
             END;
            */
            --EN commented as per review observation for FSS-1246


            /*                                                       --SN commented as per review observation for FSS-1246
             BEGIN

                IF P_DELIVERY_CHANNEL = '02' THEN
                 IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
                    V_POS_USAGEAMNT         := 0;
                    V_POS_USAGELIMIT         := 1;
                    V_PREAUTH_USAGE_LIMIT := 0;


                         BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                              SET CTC_POSUSAGE_AMT          = V_POS_USAGEAMNT,
                                  CTC_POSUSAGE_LIMIT      = V_POS_USAGELIMIT,
                                  CTC_ATMUSAGE_AMT         = 0,
                                  CTC_ATMUSAGE_LIMIT      = 0,
                                  CTC_BUSINESS_DATE         = TO_DATE(P_TRAN_DATE ||
                                                                      '23:59:59',
                                                                      'yymmdd' ||
                                                                      'hh24:mi:ss'),
                                  CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT,
                                  CTC_MMPOSUSAGE_AMT      = 0,
                                  CTC_MMPOSUSAGE_LIMIT     = 0
                            WHERE CTC_INST_CODE = P_INST_CODE AND
                                  CTC_PAN_CODE = V_HASH_PAN AND
                                  CTC_MBR_NUMB = P_MBR_NUMB;
                         EXCEPTION
                            WHEN OTHERS THEN
                             V_ERR_MSG    := 'Error while updating CMS_TRANSLIMIT_CHECK4' ||
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

                            IF SQL%ROWCOUNT = 0 THEN
                             V_ERR_MSG    := 'Problem while updating data in CMS_TRANSLIMIT_CHECK';
                             V_RESP_CDE := '21';
                             RAISE EXP_REJECT_RECORD;
                            END IF;

                         EXCEPTION
                            WHEN OTHERS THEN
                             V_ERR_MSG    := 'Error while updating CMS_TRANSLIMIT_CHECK5' ||
                                            V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
                             V_RESP_CDE := '21';
                             RAISE EXP_REJECT_RECORD;
                         END;


                 END IF;
                END IF;

             END;
          */
            --EN commented as per review observation for FSS-1246

            --Sn select response code and insert record into txn log dtl
            BEGIN
                P_RESP_MSG := V_ERR_MSG;
                P_RESP_CODE := V_RESP_CDE;
                
                IF v_delayed_amount>0 AND v_resp_cde='15' THEN
                     v_resp_cde:='1000';
                END IF;                

                P_RESP_ID := V_RESP_CDE; --Added for VMS-8018
                -- Assign the response code to the out parameter
                SELECT CMS_ISO_RESPCDE
                  INTO P_RESP_CODE
                  FROM CMS_RESPONSE_MAST
                 WHERE      CMS_INST_CODE = P_INST_CODE
                         AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                         AND CMS_RESPONSE_ID = V_RESP_CDE;
            EXCEPTION
                WHEN OTHERS
                THEN
                    P_RESP_MSG :=
                            'Problem while selecting data from response master '
                        || V_RESP_CDE
                        || SUBSTR (SQLERRM, 1, 300);
                    P_RESP_CODE := '69';
                    ---ISO MESSAGE FOR DATABASE ERROR Server Declined
                    P_RESP_ID := '69'; --Added for VMS-8018
                    ROLLBACK;
            END;

            BEGIN
                INSERT
                  INTO CMS_TRANSACTION_LOG_DTL (CTD_DELIVERY_CHANNEL,
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
                                                          /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes    */
                                                          CTD_NETWORK_ID,
                                                          CTD_INTERCHANGE_FEEAMT,
                                                          CTD_MERCHANT_ZIP,
                                                          CTD_MERCHANT_ID,
                                                          CTD_COUNTRY_CODE,
                                                          CTD_ZIP_CODE,/* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                                           ctd_completion_fee,
                                                             CTD_COMPLFEE_INCREMENT_TYPE,
                                                             CTD_COMPFEE_CODE ,
                                                             CTD_COMPFEEATTACH_TYPE,
                                                             CTD_COMPFEEPLAN_ID
                                                                          )
                VALUES (
                             P_DELIVERY_CHANNEL,
                             P_TXN_CODE,
                             V_TXN_TYPE,
                             P_MSG,
                             P_TXN_MODE,
                             P_TRAN_DATE,
                             P_TRAN_TIME,
                             V_HASH_PAN,
                             p_txn_amt, --v_tran_amt,                 --p_txn_amt modified for 10871 modified for defect id:12166
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
                             P_ADDR_VERFY_RESPONSE,
                             P_INTERNATIONAL_IND,
                             /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                             P_NETWORK_ID,
                             P_INTERCHANGE_FEEAMT,
                             P_MERCHANT_ZIP,
                             P_MERC_ID,
                             P_COUNTRY_CODE,
                             --DECODE(V_ZIP_CODE_IN, 'N', '', V_ZIP_CODE_IN) --Modified by Deepa to validate 5 digits of ZIP code on OCT-19-2012
                             DECODE (P_ZIP_CODE, 'N', '', P_ZIP_CODE), -- Added for FSS-943 on 14-Mar-2013
                                                                                  /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                             decode(v_comp_total_fee_log,'Y','0',v_comp_total_fee),
                                 V_COMPLFEE_INCREMENT_TYPE,
                                 v_comp_fee_code,
                                 v_comp_feeattach_type,
                                 v_comp_fee_plan
                                                                                  );

                P_RESP_MSG := V_ERR_MSG;
            EXCEPTION
                WHEN OTHERS
                THEN
                    P_RESP_MSG :=
                        'Problem while inserting data into transaction log  dtl'
                        || SUBSTR (SQLERRM, 1, 300);
                    P_RESP_CODE := '69';                         -- Server Declined
                    P_RESP_ID := '69'; --Added for VMS-8018
                    ROLLBACK;
                    RETURN;
            END;
        WHEN OTHERS
        THEN
            ROLLBACK TO V_AUTH_SAVEPOINT;

            /*                                                       --SN commented as per review observation for FSS-1246
             BEGIN
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
                 V_ERR_MSG    := 'Cannot get the Transaction Limit Details of the Card' ||
                                 V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
                 V_RESP_CDE := '21';
                 RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                 V_ERR_MSG    := 'Error while selecting CMS_TRANSLIMIT_CHECK4' ||
                                 V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
                 V_RESP_CDE := '21';
                 RAISE EXP_REJECT_RECORD;
             END;



             BEGIN

                IF P_DELIVERY_CHANNEL = '02' THEN
                 IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
                    V_POS_USAGEAMNT         := 0;
                    V_POS_USAGELIMIT         := 1;
                    V_PREAUTH_USAGE_LIMIT := 0;
                    BEGIN
                      UPDATE CMS_TRANSLIMIT_CHECK
                         SET CTC_POSUSAGE_AMT         = V_POS_USAGEAMNT,
                             CTC_POSUSAGE_LIMIT        = V_POS_USAGELIMIT,
                             CTC_ATMUSAGE_AMT         = 0,
                             CTC_ATMUSAGE_LIMIT        = 0,
                             CTC_BUSINESS_DATE        = TO_DATE(P_TRAN_DATE ||
                                                                 '23:59:59',
                                                                 'yymmdd' ||
                                                                 'hh24:mi:ss'),
                             CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT,
                             CTC_MMPOSUSAGE_AMT        = 0,
                             CTC_MMPOSUSAGE_LIMIT    = 0
                      WHERE CTC_INST_CODE = P_INST_CODE AND
                             CTC_PAN_CODE = V_HASH_PAN AND
                             CTC_MBR_NUMB = P_MBR_NUMB;

                      IF SQL%ROWCOUNT = 0 THEN
                        V_ERR_MSG  := 'Problem while updating data in CMS_TRANSLIMIT_CHECK';
                        V_RESP_CDE := '21';
                        RAISE EXP_REJECT_RECORD;
                      END IF;

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

                      IF SQL%ROWCOUNT = 0 THEN
                        V_ERR_MSG  := 'Problem while updating data in CMS_TRANSLIMIT_CHECK';
                        V_RESP_CDE := '21';
                        RAISE EXP_REJECT_RECORD;
                      END IF;

                    EXCEPTION
                      WHEN OTHERS THEN
                        V_ERR_MSG  := 'Error while updating CMS_TRANSLIMIT_CHECK7' ||
                                      V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
                        V_RESP_CDE := '21';
                        RAISE EXP_REJECT_RECORD;
                    END;
                 END IF;
                END IF;
             END;
          */
            --SN commented as per review observation for FSS-1246

            --Sn select response code and insert record into txn log dtl
            BEGIN
                SELECT CMS_ISO_RESPCDE
                  INTO P_RESP_CODE
                  FROM CMS_RESPONSE_MAST
                 WHERE      CMS_INST_CODE = P_INST_CODE
                         AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                         AND CMS_RESPONSE_ID = V_RESP_CDE;

                P_RESP_MSG := V_ERR_MSG;
                P_RESP_ID := V_RESP_CDE; --Added for VMS-8018
            EXCEPTION
                WHEN OTHERS
                THEN
                    P_RESP_MSG :=
                            'Problem while selecting data from response master '
                        || V_RESP_CDE
                        || SUBSTR (SQLERRM, 1, 300);
                    P_RESP_CODE := '69';                         -- Server Declined
                    P_RESP_ID := '69'; --Added for VMS-8018
                    ROLLBACK;
            END;

            BEGIN
                INSERT
                  INTO CMS_TRANSACTION_LOG_DTL (CTD_DELIVERY_CHANNEL,
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
                                                          /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes    */
                                                          CTD_NETWORK_ID,
                                                          CTD_INTERCHANGE_FEEAMT,
                                                          CTD_MERCHANT_ZIP,
                                                          CTD_MERCHANT_ID,
                                                          CTD_COUNTRY_CODE,
                                                          CTD_ZIP_CODE,/* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                                           ctd_completion_fee,
                                                             CTD_COMPLFEE_INCREMENT_TYPE,
                                                             CTD_COMPFEE_CODE ,
                                                             CTD_COMPFEEATTACH_TYPE,
                                                             CTD_COMPFEEPLAN_ID
                                                                          )
                VALUES (
                             P_DELIVERY_CHANNEL,
                             P_TXN_CODE,
                             V_TXN_TYPE,
                             P_MSG,
                             P_TXN_MODE,
                             P_TRAN_DATE,
                             P_TRAN_TIME,
                             V_HASH_PAN,
                             p_txn_amt, --v_tran_amt,                 --p_txn_amt modified for 10871 modified for defect id:12166
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
                             P_ADDR_VERFY_RESPONSE,
                             P_INTERNATIONAL_IND,
                             /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                             P_NETWORK_ID,
                             P_INTERCHANGE_FEEAMT,
                             P_MERCHANT_ZIP,
                             P_MERC_ID,
                             P_COUNTRY_CODE,
                             --DECODE(V_ZIP_CODE_IN, 'N', '', V_ZIP_CODE_IN) --Modified by Deepa to validate 5 digits of ZIP code on OCT-19-2012
                             DECODE (P_ZIP_CODE, 'N', '', P_ZIP_CODE), -- Added for FSS-943 on 14-Mar-2013
                                                                                  /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                             decode(v_comp_total_fee_log,'Y','0',v_comp_total_fee),
                                 V_COMPLFEE_INCREMENT_TYPE,
                                 v_comp_fee_code,
                                 v_comp_feeattach_type,
                                 v_comp_fee_plan
                                                                                  );
            EXCEPTION
                WHEN OTHERS
                THEN
                    P_RESP_MSG :=
                        'Problem while inserting data into transaction log  dtl'
                        || SUBSTR (SQLERRM, 1, 300);
                    P_RESP_CODE := '69';          -- Server Decline Response 220509
                    P_RESP_ID := '69'; --Added for VMS-8018
                    ROLLBACK;
                    RETURN;
            END;
    --En select response code and insert record into txn log dtl
    END;

    --- Sn create GL ENTRIES
    IF V_RESP_CDE = '1'
    THEN
        SAVEPOINT V_SAVEPOINT;
        --Sn find business date
        V_BUSINESS_TIME := TO_CHAR (V_TRAN_DATE, 'HH24:MI');

        IF V_BUSINESS_TIME > V_CUTOFF_TIME
        THEN
            V_BUSINESS_DATE := TRUNC (V_TRAN_DATE) + 1;
        ELSE
            V_BUSINESS_DATE := TRUNC (V_TRAN_DATE);
        END IF;

        --En find businesses date

        --Sn find prod code and card type and available balance for the card number
        BEGIN
            SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL   --Added on 29.10.2013 for 12087
              INTO V_ACCT_BALANCE, V_LEDGER_BAL   --Added on 29.10.2013 for 12087
              FROM CMS_ACCT_MAST
             WHERE CAM_ACCT_NO =
                         (SELECT CAP_ACCT_NO
                             FROM CMS_APPL_PAN
                            WHERE      CAP_PAN_CODE = V_HASH_PAN
                                    AND CAP_MBR_NUMB = P_MBR_NUMB
                                    AND CAP_INST_CODE = P_INST_CODE)
                     AND CAM_INST_CODE = P_INST_CODE;
        -- FOR UPDATE NOWAIT;--SN: Commented for Concurrent Processsing Issue  on 25-FEB-2014 By Revathi
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '14';                       --Ineligible Transaction
                V_ERR_MSG := 'Invalid Card ';
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG :=
                    'Error while selecting data from card Master for card number '
                    || SQLERRM;
                RAISE EXP_REJECT_RECORD;
        END;

        --En find prod code and card type for the card number
         IF V_OUTPUT_TYPE = 'N' and p_delivery_channel='02' and  p_txn_code ='11'
        THEN
           
            P_RESP_MSG := TO_CHAR (V_ACCT_BALANCE);
        elsif V_OUTPUT_TYPE = 'N'
        THEN
            --Balance Inquiry
            P_RESP_MSG := TO_CHAR (V_UPD_AMT);
        END IF;
    END IF;

    --En create GL ENTRIES

    --Sn added by Pankaj S. for 10871
    IF v_dr_cr_flag IS NULL
    THEN
        BEGIN
            SELECT ctm_credit_debit_flag, TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')), ctm_tran_type
              INTO v_dr_cr_flag, v_txn_type, v_tran_type
              FROM cms_transaction_mast
             WHERE      ctm_tran_code = p_txn_code
                     AND ctm_delivery_channel = p_delivery_channel
                     AND ctm_inst_code = p_inst_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;
    END IF;

    IF v_prod_code IS NULL
    THEN
        BEGIN
            SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
              INTO v_prod_code, v_prod_cattype, v_applpan_cardstat, v_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code
                     AND cap_pan_code = gethash (p_card_no);
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;
    END IF;

    IF v_acct_type IS NULL
    THEN
        BEGIN
            SELECT cam_type_code
              INTO v_acct_type
              FROM cms_acct_mast
             WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_acct_number;
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;
    END IF;

    --En added by Pankaj S. for 10871

    --Sn create a entry in txn log
    BEGIN
        INSERT INTO TRANSACTIONLOG (MSGTYPE,
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
                                             /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes    */
                                             FEE_PLAN,
                                             POS_VERIFICATION, --Added by Deepa on July 03 2012 to log the verification of POS
                                             ZIP_CODE,
                                             PARTIAL_PREAUTH_IND, --Added by Deepa on Sep 05 to log the Partial Preauth Indicator
                                             FEEATTACHTYPE, -- Added by Trivikram on 05-Sep-2012
                                             MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                                             MERCHANT_CITY, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                                             MERCHANT_STATE, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                                             ADDR_VERIFY_INDICATOR, --Added by Deepa on Sep-12-2012 to log the Address Verification Indicator from request for CSR,
                                             NETWORK_SETTL_DATE, -- Added on 201112 for logging N/W settlement date in transactionlog
                                             ERROR_MSG, --Added on 23/04/2013 for errorMessage not logged
                                             --Sn added by Pankaj S. for 10871
                                             acct_type,
                                             time_stamp,
                                             --En added by Pankaj S. for 10871
                                             NETWORKID_SWITCH, --Added on 20130626 for the Mantis ID 11344
                                             remark --Added for error msg need to display in CSR(declined by rule)
                                                                  )
              VALUES (
                            P_MSG,
                            P_RRN,
                            P_DELIVERY_CHANNEL,
                            P_TERM_ID,
                            V_BUSINESS_DATE,
                            P_TXN_CODE,
                            V_TXN_TYPE,
                            P_TXN_MODE,
                            DECODE (P_RESP_CODE, '00', 'C', 'F'),
                            P_RESP_CODE,
                            P_TRAN_DATE,
                            P_TRAN_TIME,
                            V_HASH_PAN,
                            NULL,
                            NULL,                                         --P_topup_acctno      ,
                            NULL,                                           --P_topup_accttype,
                            P_BANK_CODE,
                            TRIM (
                                TO_CHAR (NVL (v_total_amt, 0),
                                            '999999999999999990.99')), --modified for 10871
                            NULL,
                            NULL,
                            P_MCC_CODE,
                            P_CURR_CODE,
                            NULL,                                               -- P_add_charge,
                            V_PROD_CODE,
                            V_PROD_CATTYPE,
                            NVL (p_tip_amt, '0.00'), --formatted by Pankaj S. for 10871
                            P_DECLINE_RULEID,
                            P_ATMNAME_LOC,
                            V_AUTH_ID,
                            V_TRANS_DESC,
                            TRIM (
                                TO_CHAR (NVL (v_tran_amt, 0),
                                            '999999999999999990.99')), --modified for 10871
                            '0.00',                 --modified by Pankaj S. for 10871
                            '0.00', --modified by Pankaj S. for 10871  -- Partial amount (will be given for partial txn)
                            P_MCCCODE_GROUPID,
                            P_CURRCODE_GROUPID,
                            P_TRANSCODE_GROUPID,
                            P_RULES,
                            P_PREAUTH_DATE,
                            V_GL_UPD_FLAG,
                            P_STAN,
                            P_INST_CODE,
                            V_FEE_CODE,
                            NVL (V_FEE_AMT, 0),                         --modified for 10871
                            NVL (V_SERVICETAX_AMOUNT, 0),          --modified for 10871
                            NVL (V_CESS_AMOUNT, 0),                  --modified for 10871
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
                            P_ADDR_VERFY_RESPONSE,
                            V_PROXUNUMBER,
                            P_RVSL_CODE,
                            V_ACCT_NUMBER,
                            ROUND (V_ACCT_BALANCE, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                            ROUND (V_LEDGER_BAL, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                            P_INTERNATIONAL_IND,
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
                            --DECODE(V_ZIP_CODE_IN, 'N', '', V_ZIP_CODE_IN),--Modified by Deepa to validate 5 digits of ZIP code on OCT-19-2012 -- Commented for FSS-943 on 14-Mar-2013
                            DECODE (P_ZIP_CODE, 'N', '', P_ZIP_CODE), -- Added for FSS-943 on 14-Mar-2013
                            P_PARTIAL_PREAUTH_IND, --Added by Deepa on Sep 05 to log the Partial Preauth Indicator
                            V_FEEATTACH_TYPE,     -- Added by Trivikram on 05-Sep-2012
                            P_MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                            P_MERCHANT_CITY, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                            P_ATMNAME_LOC, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                            P_ADDRVERIFY_FLAG, --Added by Deepa on Sep-12-2012 to log the Address Verification Indicator from request for CSR
                            P_NETWORK_SETL_DATE, -- Added on 201112 for logging N/W settlement date in transactionlog
                            V_ERR_MSG, --Added on 23/04/2013 for errorMessage not logged
                            --Sn added by Pankaj S. for 10871
                            v_acct_type,
                            NVL (v_timestamp, SYSTIMESTAMP),
                            --En added by Pankaj S. for 10871
                            P_NETWORKID_SWITCH, --Added on 20130626 for the Mantis ID 11344
                            DECODE(v_resp_cde,'1000','Decline due to redemption delay',V_ERR_MSG) --Added for error msg need to display in CSR(declined by rule)
                                                    );

        P_CAPTURE_DATE := V_BUSINESS_DATE;
        P_AUTH_ID := V_AUTH_ID;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            P_RESP_CODE := '69';                               -- Server Declione
            P_RESP_ID := '69'; --Added for VMS-8018
            P_RESP_MSG :=
                'Problem while inserting data into transaction log  '
                || SUBSTR (SQLERRM, 1, 300);
    END;
--En create a entry in txn log
EXCEPTION
    WHEN OTHERS
    THEN
        ROLLBACK;
        P_RESP_CODE := '69';                                  -- Server Declined
        P_RESP_ID := '69'; --Added for VMS-8018
        P_RESP_MSG :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END;
/

show error;