set define off;
CREATE OR REPLACE PROCEDURE VMSCMS.SP_CHW_RECENT_STATEMENT ( 
    P_INST_CODE IN NUMBER,
    P_MSG       IN VARCHAR2,
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
    P_RULE_INDICATOR    VARCHAR2,
    P_RULEGRP_ID        VARCHAR2,
    P_MCC_CODE          VARCHAR2,
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
    P_PREAUTH_DATE         DATE,
    P_CONSODIUM_CODE    IN VARCHAR2,
    P_PARTNER_CODE      IN VARCHAR2,
    P_EXPRY_DATE        IN VARCHAR2,
    P_STAN              IN VARCHAR2,
    P_MBR_NUMB          IN VARCHAR2,
    P_PREAUTH_EXPPERIOD IN VARCHAR2,
    P_INTERNATIONAL_IND IN VARCHAR2,
    P_RVSL_CODE         IN NUMBER,
    P_TRAN_CNT          IN NUMBER,
    P_MONTH_YEAR        IN VARCHAR2,
    P_ANI               IN VARCHAR2,
    P_DNI               IN VARCHAR2,
    P_IPADDRESS         IN VARCHAR2,
    P_MERCHANT_NAME     IN VARCHAR2, --  Added by Besky on 20/12/12 for defect id : 9709
    P_MERCHANT_CITY     IN VARCHAR2, --  Added by Besky on 20/12/12 for defect id : 9709
    P_Trans_Type        IN VARCHAR2, -- added for fwr-67
    P_FROMDATE          IN VARCHAR2, -- added for fwr-67
    P_TODATE            IN VARCHAR2, -- added for fwr-67
    P_FROMAMNT          IN VARCHAR2, -- added for fwr-67
    P_TOAMNT            IN VARCHAR2, -- added for fwr-67
    P_AUTH_ID OUT VARCHAR2,
    P_RESP_CODE OUT VARCHAR2,
    P_RESP_MSG OUT CLOB,
    P_TOT_DR_AMT OUT VARCHAR2, --Updated by SivaKumar M on 11/10/2012 -- changed from number to varchar2 for MVHOST-346
    P_TOT_CR_AMT OUT VARCHAR2, --Updated by SivaKumar M on 11/10/2012 -- changed from number to varchar2 for MVHOST-346
    P_PRE_AUTH_HOLD_AMT OUT VARCHAR2,
    P_LED_BAL_AMT OUT VARCHAR2,
    P_AVAIL_BAL_AMT OUT VARCHAR2,
    p_posting_cnt OUT NUMBER,
    p_pending_cnt OUT NUMBER,
    P_PRE_AUTH_DET OUT CLOB,
    P_CAPTURE_DATE OUT DATE,
    P_ROUT_NUMBER OUT VARCHAR2, -- Added by siva kumar on 03/07/12
    --P_DDRPRXY_FLAG                OUT  VARCHAR2,  -- Added for FSS-4120
    P_DDAPRXY_NUMBER OUT VARCHAR2, -- Added for FSS-4120
    p_begining_bal OUT VARCHAR2,
    p_ending_bal OUT VARCHAR2,
    P_medagateref_id IN VARCHAR2 DEFAULT NULL, -- Added for MVHOSt-388 on 13/06/13
    p_mailaddress1 OUT VARCHAR2, --Added for FSS-5137
    p_mailaddress2 OUT VARCHAR2, --Added for FSS-5137
    p_mailcity OUT VARCHAR2,--Added for FSS-5137
    p_mailstate OUT VARCHAR2,--Added for FSS-5137
    p_mailcountry OUT VARCHAR2,--Added for FSS-5137
    p_mailzip OUT VARCHAR2,--Added for FSS-5137
    p_currency OUT VARCHAR2,--Added for FSS-5137
    p_prod_desc OUT VARCHAR2,--Added for FSS-5137
    p_prod_cattype_desc  OUT VARCHAR2,--Added for FSS-5137
    p_total_fees OUT VARCHAR2,--Added for FSS-5137
    p_ytd OUT VARCHAR2--Added for FSS-5137
  )
IS
  /********************************************************************************************************
  * Created By   : NA
  * Created Date : NA
  * Modified by  : B.Besky Anand.
  * Modified Reason : Modified for logging Merchant name and Merchant city in to transactionlog table
  * Modified Date  : 20-12-2012
  * Reviewer : Dhiraj
  * Reviewed Date  : 27-Dec-2012
  * Build Number : CMS3.5.1_RI0023_B0003
  * Modified by  : Sagar M.
  * Modified Date  : 11-Feb-13
  * Modified reason : To display fromcard account number and last 4 digits of fromcard number
  in response message for Card to Card transfer transaction
  * Modified for : FSS-482
  * Reviewer : Dhiarj
  * Build Number : CMS3.5.1_RI0023.2_B0002
  * Modified by  : Saravanakumar
  * Modified Reason : Defect 10261
  * Modified Date  : 22-Feb-2013
  * Reviewer : Sachin
  * Reviewed Date  : 22-Feb-2013
  * Build Number : CMS3.5.1_RI0023.2_B0006
  * Modified by   : Pankaj S.
  * Modified Reason : DFCCHW-194
  * Modified Date  : 08-APR-2013
  * Reviewer : Dhiraj
  * Reviewed Date  :
  * Build Number : CMS3.5.1_RI0024.1_B0003
  * Modified by  : Dhinakaran B
  * Modified Reason : MVHOST - 346
  * Modified Date  : 20-APR-2013
  * Reviewer :
  * Reviewed Date  :
  * Build Number :
  * Modified By  : Sagar M.
  * Modified Date  : 20-Apr-2013
  * Modified Reason : Logging of below details handled in tranasctionlog and statementlog table
  1) ledger balance in statementlog
  2) Product code,Product category code,Card status,Acct Type,drcr flag
  3) Timestamp and Amount values logging correction
  * Reviewer : Dhiraj
  * Reviewed Date  : 20-Apr-2013
  * Build Number : RI0024.1_B0010
  * Modified By  : Sagar M.
  * Modified Date  : 20-Apr-2013
  * Modified For : MVHOST-346
  * Modified Reason : Datatype changed for input variables from Number to Varchar2
  P_TOT_DR_AMT,P_TOT_CR_AMT
  Exception handled while select first name and mid name
  * Reviewer : Dhiraj
  * Reviewed Date  : 20-Apr-2013
  * Build Number : RI0024.1_B0020
  * Modified By  : Sai Prasad.
  * Modified Date  : 13-May-2013
  * Modified For : MVHOST-346
  * Modified Reason : Transaction Description will have 'CLAWBACK' in  CLAWBACK transactions description
  * Reviewer :
  * Reviewed Date  :
  * Build Number : RI0024.1_B0023
  * Modified By  : Muralidharan
  * Modified Date  : 06-June-2013
  * Modified For : MVHOST-388 Medagate Transaction History API
  * Modified Reason : Modified for Medagate Transaction History ApI to get recent transactions for CR and DR transactions.
  * Build Number : RI0024.2_B0004
  * Modified by  : Ranveer Meel.
  * Modified Reason : Preauth normal transaction details with same RRN - Response 89 instead of 22 - Resource busy
  * Modified Date  : 18-JUN-2013
  * Reviewer : Saravana kumar
  * Reviewed Date  : 18-JUN-2013
  * Build Number : RI0024.2_B0004
  * Modified by  : Ravi N
  * Modified for     : Mantis ID 0011282
  * Modified Reason : Correction of Insufficient balance spelling mistake
  * Modified Date  : 20-Jun-2013
  * Reviewer : Dhiraj
  * Reviewed Date  : 20-Jun-2013
  * Build Number : RI0024.2_B0006
  * Modified by  : Ramesh A
  * Modified for     : MVHOST-388
  * Modified Reason : Added new cursor for getting statement details in medagate
  * Modified Date  : 20-Jun-2013
  * Reviewer :
  * Reviewed Date  :
  * Build Number : RI0024.2_B0006
  * Modified by  : Anil Kumar
  * Modified for : JIRA MVCHW-454
  * Modified Reason : Insufficient Balance for Non-financial Transactions.
  * Modified Date  : 16-07-2013
  * Reviewer :
  * Reviewed Date  :
  * Build Number : RI0024.3_B0005
  * Modified by  : RAVI N
  * Modified for : 0012744
  * Modified Reason : Waiver Description shows on response belongs to Recent transaction
  * Modified Date  : 21-11-2013
  * Reviewer : Dhiraj
  * Reviewed Date  : 05/DEC/2013
  * Build Number : RI0024.7_B0001
  * Modified by  : Pankaj S.
  * Modified Reason : FWR-42
  * Modified Date  : 10-Jan-2014
  * Reviewer : Dhiraj
  * Reviewed Date  : 10-Jan-2014
  * Build Number : RI0027_B0003
  * Modified by  : Sai Prasad
  * Modified Reason : FWR-42
  * Modified Date  : 23-Jan-2014
  * Reviewer : Dhiraj
  * Reviewed Date  :
  * Build Number : RI0027_B0004
  * Modified by  : MageshKumar S
  * Modified Reason : Mantis Id:0013528
  * Modified Date  : 24-Jan-2014
  * Reviewer : Dhiraj
  * Reviewed Date  : 24-Jan-2014
  * Build Number : RI0027_B0004
  * modified by : Sai Prasad
  * modified Date   :  27-Jan-14
  * modified reason : Non-Financical Transactions with fee is not shown in statement
  * modified reason : Mantis Id:0013572
  * Reviewer  :  Dhiraj
  * Reviewed Date   :
  * Build Number    : RI0027_B0005
  * modified by : MageshKumar S
  * modified Date   :  31-Jan-14
  * modified reason : FWR-42 Removal
  * modified reason : FWR-42
  * Reviewer  :  Dhiraj
  * Reviewed Date   :
  * Build Number    :    RI0027_B0005
  * modified by : MageshKumar S
  * modified Date   :  11-Feb-14
  * modified reason : Mantis Id: 13643
  * modified reason : IVR Pending Transaction should not be considered in profile level count .
  * Reviewer  :  Dhiraj
  * Reviewed Date   :
  * Build Number    :    RI0027_B0007
  * modified by : RAVI N
  * modified Date   : FEB-05-14
  * modified reason : MVCSD-4471
  * modified reason : logging fee_description for fee entry in statemenst_log
  * Reviewer  : DHIRAJ
  * Reviewed Date   :
  * Build Number    : RI0027.1_B0001
  * modified by : RAVI N
  * modified Date   : 14-02-14
  * modified reason : MVHOST-848
  * modified reason : Merchant name changes [if merchane name null display Delchannel_Desc]
  * Reviewer  : Dhiraj
  * Reviewed Date   : 14-02-2014
  * Build Number    : RI0027.1_B0002
  * modified by : MageshKumar S
  * modified Date   : 06-03-14
  * modified reason : JH-2611
  * Reviewer  : Dhiraj
  * Reviewed Date   : 06-03-14
  * Build Number    : RI0027.2_B0001
  * Modified by  : Abdul Hameed M.A
  * Modified for  : Mantis ID 13893
  * Modified Reason : Added card number for duplicate RRN check
  * Modified Date    : 06-Mar-2014
  * Reviewer   : Dhiraj
  * Reviewed Date    : 10-Mar-2014
  * Build Number  : RI0027.2_B0002
  * Modified By       : Sankar S
  * Modified Date : 08-APR-2014
  * Modified for      :
  * Modified Reason  : 1.Round functions added upto 2nd decimal for amount columns in CMS_CHARGE_DTL,CMS_ACCTCLAWBACK_DTL,
  CMS_STATEMENTS_LOG,TRANSACTIONLOG.
  2.V_TRAN_AMT initial value assigned as zero.
  * Reviewer       : Pankaj S.
  * Reviewed Date : 08-APR-2014
  * Build Number      : CMS3.5.1_RI0027.2_B0005
  * modified by       : Amudhan S
  * modified Date     : 23-may-14
  * modified for      : FWR 64
  * modified reason   : To restrict clawback fee entries as per the configuration done by user.
  * Reviewer          : Spankaj
  * Build Number      : RI0027.3_B0001
  * Modified by       : Abdul Hameed M.A
  * Modified Date     : 10-July-14
  * Modified for      : FSS 837
  * Modified reason   : To return the sum of completion fee and hold amt in the preauth hold amount
  * Reviewer          : spankaj
  * Build Number      : RI0027.3_B0003
  * Modified by       : MageshKumar S.
  * Modified Date     : 25-July-14
  * Modified For      : FWR-48
  * Modified reason   : GL Mapping removal changes
  * Reviewer          : Spankaj
  * Build Number      : RI0027.3.1_B0001
  * Modified by       : Siva Kumar M.
  * Modified Date     : 08-Aug-14
  * Modified For      : FWR-67
  * Modified reason   : Transaction history filter
  * Reviewer          : Spankaj
  * Build Number      : RI0027.3.1_B0002
  * Modified by       : Abdul Hameed M.A
  * Modified Date     : 25-Sep-14
  * Modified For      : MVHOST 987
  * Reviewer          :
  * Build Number      : RI0027.4_B0001
  * Modified by       : Sai Prasad
  * Modified Date     : 01-Mar-15
  * Modified For      : DFCTNM-3
  * Reviewer          : Spankaj
  * Build Number      : RI0027.5_B0011
  * Modified by       : Ramesh A
  * Modified Date     : 02-Mar-15
  * Modified For      : DFCTNM-26
  * Reviewer          : Saravanakumar
  * Reviewed Date     : 06/03/15
  * Build Number      : 3.0_B0001
  * Modified by       : MAGESHKUMAR S
  * Modified Date     : 20-Mar-15
  * Modified For      : DFCTNM-2 && MANTIS:0016055
  * Reviewer          : PANKAJ S
  * Build Number      : VMSGPRHOST3.0_B0002
  * Modified by       : Saravanakumar
  * Modified Date     : 06-May-2015
  * Modified For      : DFCTNM-78
  * Reviewer          : PANKAJ S
  * Build Number      : VMSGPRHOST3.0.1
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
  * Modified by      : A.Sivakaminathan
  * Modified for     : 3.2 Person to Person (P2P) ACH Correction
  * Modified Date    : 15-Sep-2015
  * Reviewer         : Saravanankumar
  * Build Number     : VMSGPRHOST_3.2
  * Modified by       : Abdul Hameed M.A.
  * Modified Date     : 21-Sep-2015
  * Modified For      : Display Transaction Flex  Descriptions in statements
  * Reviewer          : Saravanankumar
  * Build Number      : VMSGPRHOST_3.2
  * Modified by      : Ramesh A
  * Modified Date    : 27-Jan-2016
  * PURPOSE          : RDC
  * Review           : Saravana
  * Build Number     : 3.3.1
  * Modified by      : Ramesh A
  * Modified Date    : 08-Feb-2016
  * PURPOSE          : DFCTNM-108(Integration of 3.2.4)
  * Review           : Saravana
  * Build Number     : 3.3.2
  * Modified by      : Siva Kumar M
  * Modified Date    : 15-Mar-2016
  * PURPOSE          : FSS-4120
  * Review           : Saravana
  * Build Number     : VMSGPRHOST_4.0
  * Modified by      : Sai Prasad
  * Modified Date    : 23-Mar-2016
  * PURPOSE          : Mantis - 0016327
  * Review           : Saravana
  * Build Number     : VMSGPRHOST_4.0
  * Modified by      : Pankaj S.
  * Modified Date    : 12/Sep/2016
  * PURPOSE          : MVHOST-1345
  * Review           : Saravana
  * Build Number     : VMSGPRHOST_4.9
  * Modified by       : Ramesh A
  * Modified Date     : 20-Sep-2016
  * Modified For      : FSS-4353 NACHA Compliance Issue for ACH Description
  * Reviewer          : Saravanankumar
  * Build Number      : VMSGPRHOSTCSD_4.9
  * Modified by      : Pankaj S.
  * Modified Date    : 07/Oct/2016
  * PURPOSE          : FSS-4755
  * Review           : Saravana
  * Build Number     : VMSGPRHOST_4.10
  * Modified by      : Pankaj S.
  * Modified Date    : 06/Feb/2017
  * PURPOSE          : FSS-5065
  * Review                : Saravana
  * Build Number     : VMSGPRHOST_17.02
  * Modified by      : Saravana
  * Modified Date    : 27/Feb/2017
  * PURPOSE          : FSS-4366
  * Review            : Pankaj S
  * Build Number     : VMSGPRHOST_17.02


  	 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07

  * Modified by      : Saravana
  * Modified Date    : 04/Sep/2017
  * PURPOSE          : FSS-5224
  * Review            : Pankaj S
  * Build Number     : VMSGPRHOST_17.08.B0002

  * Modified by      : Ramesh A
  * Modified Date    : 22/Sep/2017
  * PURPOSE          : FSS-5137
  * Review           : Saravanakumar A
  * Build Number     : VMSGPRHOST_17.09.B0002

        * Modified by       :Vini
       * Modified Date    : 10-Jan-2018
       * Modified For     : VMS-162
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD_17.12.1

	   	 * Modified By      : Sreeja D
     * Modified Date    : 25/01/2018
     * Purpose          : VMS-162
     * Reviewer         : SaravanaKumar A/Vini Pushkaran
     * Release Number   : VMSGPRHOST18.01

     * Modified By      : Ubaidur Rahman.H
     * Modified Date    : 22/10/2021
     * Purpose          : VMS-4097 - Remove RECENT TRANSACTION logging into TRANSACTIONLOG
     * Reviewer         : SaravanaKumar A
     * Release Number   : VMSGPRHOST_R53_B2
     
    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991

  ************************************************************************************************************/
  V_ERR_MSG      VARCHAR2 (900) := 'OK';
  V_ACCT_BALANCE NUMBER;
  V_LEDGER_BAL   NUMBER;
  V_TRAN_AMT     NUMBER := 0; --Modified by Sankar S on 08-Apr-2014
  V_AUTH_ID TRANSACTIONLOG.AUTH_ID%TYPE;
  V_TOTAL_AMT NUMBER;
  V_TRAN_DATE DATE;
  V_FUNC_CODE CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_PROD_CODE CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_FEE_AMT         NUMBER;
  V_TOTAL_FEE       NUMBER;
  V_UPD_AMT         NUMBER;
  V_UPD_LEDGER_AMT  NUMBER;
  V_NARRATION       VARCHAR2 (50);
  V_FEE_OPENING_BAL NUMBER;
  V_RESP_CDE        VARCHAR2 (5);
  V_EXPRY_DATE DATE;
  V_DR_CR_FLAG  VARCHAR2 (2);
  V_OUTPUT_TYPE VARCHAR2 (2);
  V_APPLPAN_CARDSTAT CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_ATMONLINE_LIMIT CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  V_POSONLINE_LIMIT CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  V_PRECHECK_FLAG PCMS_TRANAUTH_PARAM.PTP_PARAM_VALUE%TYPE;
  V_PREAUTH_FLAG PCMS_TRANAUTH_PARAM.PTP_PARAM_VALUE%TYPE;
  V_GL_UPD_FLAG TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
  V_GL_ERR_MSG VARCHAR2 (500);
  V_SAVEPOINT  NUMBER := 0;
  V_TRAN_FEE   NUMBER;
  V_ERROR      VARCHAR2 (500);
  V_BUSINESS_DATE_TRAN DATE;
  V_BUSINESS_TIME VARCHAR2 (5);
  V_CUTOFF_TIME   VARCHAR2 (5);
  V_CARD_CURR     VARCHAR2 (5);
  V_FEE_CODE CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  V_FEE_CRGL_CATG CMS_PRODCATTYPE_FEES.CPF_CRGL_CATG%TYPE;
  V_FEE_CRGL_CODE CMS_PRODCATTYPE_FEES.CPF_CRGL_CODE%TYPE;
  V_FEE_CRSUBGL_CODE CMS_PRODCATTYPE_FEES.CPF_CRSUBGL_CODE%TYPE;
  V_FEE_CRACCT_NO CMS_PRODCATTYPE_FEES.CPF_CRACCT_NO%TYPE;
  V_FEE_DRGL_CATG CMS_PRODCATTYPE_FEES.CPF_DRGL_CATG%TYPE;
  V_FEE_DRGL_CODE CMS_PRODCATTYPE_FEES.CPF_DRGL_CODE%TYPE;
  V_FEE_DRSUBGL_CODE CMS_PRODCATTYPE_FEES.CPF_DRSUBGL_CODE%TYPE;
  V_FEE_DRACCT_NO CMS_PRODCATTYPE_FEES.CPF_DRACCT_NO%TYPE;
  --st AND cess
  V_SERVICETAX_PERCENT CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_CESS_PERCENT CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_SERVICETAX_AMOUNT NUMBER;
  V_CESS_AMOUNT       NUMBER;
  V_ST_CALC_FLAG CMS_PRODCATTYPE_FEES.CPF_ST_CALC_FLAG%TYPE;
  V_CESS_CALC_FLAG CMS_PRODCATTYPE_FEES.CPF_CESS_CALC_FLAG%TYPE;
  V_ST_CRACCT_NO CMS_PRODCATTYPE_FEES.CPF_ST_CRACCT_NO%TYPE;
  V_ST_DRACCT_NO CMS_PRODCATTYPE_FEES.CPF_ST_DRACCT_NO%TYPE;
  V_CESS_CRACCT_NO CMS_PRODCATTYPE_FEES.CPF_CESS_CRACCT_NO%TYPE;
  V_CESS_DRACCT_NO CMS_PRODCATTYPE_FEES.CPF_CESS_DRACCT_NO%TYPE;
  --
  V_WAIV_PERCNT CMS_PRODCATTYPE_WAIV.CPW_WAIV_PRCNT%TYPE;
  V_ERR_WAIV       VARCHAR2 (300);
  V_LOG_ACTUAL_FEE NUMBER;
  V_LOG_WAIVER_AMT NUMBER;
  V_AUTH_SAVEPOINT NUMBER DEFAULT 0;
  V_ACTUAL_EXPRYDATE DATE;
  V_BUSINESS_DATE DATE;
  V_TXN_TYPE        NUMBER (1);
  V_MINI_TOTREC     NUMBER (2);
  V_MINISTMT_ERRMSG VARCHAR2 (500);
  V_MINISTMT_OUTPUT VARCHAR2 (900);
  EXP_REJECT_RECORD EXCEPTION;
  V_ATM_USAGEAMNT CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_AMT%TYPE;
  V_POS_USAGEAMNT CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_AMT%TYPE;
  V_ATM_USAGELIMIT CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_LIMIT%TYPE;
  V_POS_USAGELIMIT CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_LIMIT%TYPE;
  V_MMPOS_USAGEAMNT CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
  V_MMPOS_USAGELIMIT CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_LIMIT%TYPE;
  V_PREAUTH_DATE DATE;
  V_PREAUTH_HOLD        VARCHAR2 (1);
  V_PREAUTH_PERIOD      NUMBER;
  V_PREAUTH_USAGE_LIMIT NUMBER;
  V_CARD_ACCT_NO        VARCHAR2 (20);
  V_HOLD_AMOUNT         NUMBER;
  V_HASH_PAN CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_RRN_COUNT NUMBER;
  V_TRAN_TYPE VARCHAR2 (2);
  V_DATE DATE;
  V_TIME         VARCHAR2 (10);
  V_MAX_CARD_BAL NUMBER;
  V_CURR_DATE DATE;
  V_PREAUTH_EXP_PERIOD VARCHAR2 (10);
  V_MINI_STAT_RES CLOB;
  V_MINI_STAT_VAL CLOB;
  V_PRE_AUTH_DET CLOB;
  V_PRE_AUTH_DET_VAL CLOB;
  V_INTERNATIONAL_FLAG CHARACTER (1);
  V_TRAN_CNT NUMBER;
  V_PROXUNUMBER CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_MONTH_YEAR DATE;
  V_MON_YEAR_TEMP VARCHAR2 (6);
  V_MONTH_DET CLOB;
  V_STATUS_CHK NUMBER;
  --Added by Deepa On June 19 2012 for Fees Changes
  V_FEEAMNT_TYPE CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
  V_PER_FEES CMS_FEE_MAST.CFM_PER_FEES%TYPE;
  V_FLAT_FEES CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_CLAWBACK CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
  V_FEE_PLAN CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;
  -- V_ROUTING_NUMBER            CMS_PROD_MAST.CPM_ROUT_NUM%TYPE; -- Added by siva kumar on 03/07/12 --_Commented for DFCTNM-26
  v_freetxn_exceed VARCHAR2 (1);                          -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_DURATION       VARCHAR2 (20);                         -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_FEEATTACH_TYPE VARCHAR2 (2);                          -- Added by Trivikram on 5th Sept 2012
  v_tran_amount cms_statements_log.csl_trans_amount%TYPE; --Added by SivaKumar M on 11/10/2012
  V_LOGIN_TXN CMS_TRANSACTION_MAST.CTM_LOGIN_TXN%TYPE;    --Added For Clawback Changes (MVHOST - 346) on 20/04/2013
  V_ACTUAL_FEE_AMNT NUMBER;                               --Added For Clawback Changes (MVHOST - 346)  on 20/04/2013
  V_CLAWBACK_AMNT CMS_FEE_MAST.CFM_FEE_AMT%TYPE;          --Added For Clawback Changes (MVHOST - 346)  on 20/04/2013
  V_CLAWBACK_COUNT NUMBER;                                --Added For Clawback Changes (MVHOST - 346) on 20/04/2013
  v_cam_type_code cms_acct_mast.cam_type_code%TYPE;       -- Added on 20-apr-2013 for defect 10871
  v_timestamp TIMESTAMP;                                  -- Added on 20-Apr-2013 for defect 10871
  V_FEE_DESC CMS_FEE_MAST.CFM_FEE_DESC%TYPE;              -- Added on 05/02/14 for defect MVCSD-4471
  v_response_code transactionlog.response_code%TYPE;
  v_tot_clwbck_count CMS_FEE_MAST.cfm_clawback_count%TYPE; -- Added for FWR 64
  v_chrg_dtl_cnt   NUMBER;                                   -- Added for FWR 64
  v_trans_type     VARCHAR2(3);                              -- added for fwr-67
  V_ROUTING_NUMBER VARCHAR2(50);                             --Added for DFCTNM-26
  V_RUTING_NUM CMS_PROD_CATTYPE.CPC_ROUT_NUM%TYPE;
  V_ENCRYPT_ENABLE  CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
  v_rnum    NUMBER;
  v_balance VARCHAR2(30);
  V_CUST_CODE CMS_APPL_PAN.CAP_CUST_CODE%TYPE; --Added for FSS-5137
  v_feeFlag VARCHAR2(1); --Added for FSS-5137 changes
  v_txnamount VARCHAR2(30); --Added for FSS-5137 changes
  v_totalFees NUMBER; --Added for FSS-5137 changes
  V_MON_YEAR_TMP VARCHAR2 (6); --Added for FSS-5137 changes
  v_encr_addr_lineone cms_addr_mast.CAM_ADD_ONE%type;
  V_ENCR_ADDR_LINETWO CMS_ADDR_MAST.CAM_ADD_TWO%TYPE;
  v_encr_city         cms_addr_mast.CAM_CITY_NAME%type;
  v_encr_email        cms_addr_mast.CAM_EMAIL%type;
  v_encr_phone_no     cms_addr_mast.CAM_PHONE_ONE%type;
  v_encr_mob_one      cms_addr_mast.CAM_MOBL_ONE%type;
  v_encr_zip          cms_addr_mast.CAM_PIN_CODE%type;
  v_audit_flag		    cms_transaction_mast.ctm_txn_log_flag%TYPE;
  v_resp_out          TRANSACTIONLOG.ERROR_MSG%TYPE;
  v_Retperiod  date; --Added for VMS-5733/FSP-991
  v_Retdate  date; --Added for VMS-5733/FSP-991

 -- v_prod_cattype           CMS_APPL_PAN.cap_card_type%TYPE;
  --Sn Added for FWR-42
  /* CURSOR C_MINI_TRAN_1 (p_month_year VARCHAR2) is
  WITH txnlog AS
  (SELECT *
  FROM (SELECT rrn, add_ins_date, response_code,
  TRIM (TO_CHAR (NVL (amount, 0), '99999999999999990.99')
  ) amount,
  txn_code, delivery_channel, customer_card_no, auth_id,
  cr_dr_flag, instcode, mccode, trans_desc,
  clawback_indicator, reversal_code, cms_resp_desc error_msg, customer_acct_no -- Added for Mantis ID:0013572
  FROM transactionlog,cms_response_mast
  WHERE instcode = p_inst_code
  AND cms_inst_code = p_inst_code
  AND cms_delivery_channel = delivery_channel
  AND cms_response_id = to_number(response_id)
  AND response_code NOT IN ('22', '43', '49', '89', '102')
  AND ((cr_dr_flag<>'NA')  OR ((response_code ='00' and tranfee_amt > 0) or -- Added for Mantis ID:0013572
  (delivery_channel='03' AND txn_code IN('38','40'))OR
  (delivery_channel='07' AND txn_code ='12')OR
  (delivery_channel='10' AND txn_code='21')))
  AND customer_card_no = gethash (p_card_no)
  ORDER BY add_ins_date DESC)
  WHERE (((p_month_year IS NOT NULL AND
  TO_CHAR(add_ins_date, 'MMYYYY') = p_month_year)) OR
  (p_month_year IS NULL AND ROWNUM <= v_tran_cnt))) -- added = in rownum
  SELECT t.response_code,CASE
  WHEN t.response_code <> '00'
  THEN t.amount
  ELSE TRIM (TO_CHAR (csl_trans_amount, '99999999999999990.99'))
  END amt,
  CASE
  WHEN t.response_code <> '00'
  THEN t.cr_dr_flag
  ELSE csl_trans_type
  END crdr_flag,
  CASE
  WHEN t.response_code <> '00'
  THEN TO_CHAR (t.add_ins_date, 'MM/DD/YYYY')
  || ' ~ '
  || t.cr_dr_flag
  || ' ~ '
  || t.amount
  || ' ~ '
  || t.trans_desc
  || ' ~ '
  || t.error_msg
  || ' ~ '
  || t.mccode
  || ' ~ '
  || t.delivery_channel
  ELSE    TO_CHAR (nvl(csl_trans_date,t.add_ins_date), 'MM/DD/YYYY')
  || ' ~ '
  || nvl(csl_trans_type,t.cr_dr_flag)
  || ' ~ '
  || TRIM (TO_CHAR (nvl(csl_trans_amount,t.amount), '99999999999999990.99'))
  || ' ~ '
  || DECODE (NVL (reversal_code, '0'),'0',  DECODE (TRIM (UPPER(t.trans_desc)),'WAIVED ' || tm.ctm_tran_desc ,TRIM (UPPER(t.trans_desc)),tm.ctm_tran_desc),'RVSL-' || tm.ctm_tran_desc)
  || (CASE
  WHEN clawback_indicator = 'Y'
  THEN ' - CLAWBACK FEE'
  ELSE DECODE (sl.txn_fee_flag,'Y', ' - FEE')
  END
  )
  || ' ~ '
  || ' '
  || ' ~ '
  || t.mccode
  || ' ~ '
  || nvl(sl.csl_delivery_channel, t.delivery_channel)
  END
  FROM cms_statements_log sl, cms_transaction_mast tm, txnlog t
  WHERE /*csl_acct_no =
  (SELECT cap_acct_no
  FROM cms_appl_pan
  WHERE cap_pan_code = gethash ('4567890001550343')
  AND cap_mbr_numb = '000'
  AND cap_inst_code = 1)*/
  /*   CSL_ACCT_NO =
  (SELECT CAP_ACCT_NO
  FROM CMS_APPL_PAN
  WHERE CAP_PAN_CODE = GETHASH(P_CARD_NO) AND
  CAP_MBR_NUMB = P_MBR_NUMB    AND CAP_INST_CODE=P_INST_CODE) AND --Added on 24-01-2014 for Mantis Id:0013528*/
  /*  tm.ctm_delivery_channel = t.delivery_channel
  AND tm.ctm_tran_code = t.txn_code
  --AND csl_trans_date IS NOT NULL
  AND tm.ctm_inst_code = t.instcode
  AND instcode = p_inst_code
  AND sl.CSL_ACCT_NO(+) = t.customer_acct_no -- Added fgr Mantis ID:0013572
  AND sl.csl_delivery_channel(+) = t.delivery_channel
  AND sl.csl_txn_code(+) = t.txn_code
  AND sl.csl_rrn(+) = t.rrn
  AND sl.csl_pan_no(+) = t.customer_card_no
  AND sl.csl_auth_id(+) = t.auth_id
  AND sl.csl_inst_code(+) = t.instcode;*/
  --CURSOR C_PRE_AUTH_DET_1 (P_MONTH_YEAR VARCHAR2)
  CURSOR C_PRE_AUTH_DET_1 (P_MONTH_YEAR VARCHAR2,P_ACC_NUM cms_acct_mast.cam_acct_no%TYPE)
  IS
    SELECT x.*
    FROM
      (SELECT TO_CHAR (TO_DATE (cph_txn_date, 'YYYY/MM/DD'), 'MM/DD/YYYY')
        || ' ~ '
        || DECODE(CPT_PREAUTH_TYPE,'C', 'CR','DR')
        || ' ~ '
        || TRIM (TO_CHAR (ph.cph_txn_amnt, '99999999999999990.99'))
        || ' ~ '
        ||
        CASE
          WHEN EXISTS
            (SELECT 1
            FROM CMS_BIN_LEVEL_CONFIG
            WHERE CBL_INST_BIN = SUBSTR(p_card_no,1,6)
            AND CBL_INST_CODE  = p_inst_code
            AND CBL_FUND_MCC   = pm.cpt_mcc_code
            )
        AND CPT_PREAUTH_TYPE = 'D'
        THEN 'MoneySend Funding Auth'
        ELSE --tm.ctm_tran_desc
          tm.ctm_display_txndesc
      END
      || ' ~ '
      || pm.cpt_mcc_code
      || ' ~ '
      || ph.cph_delivery_channel
    FROM cms_preauth_trans_hist ph,
      cms_transaction_mast tm,
      CMS_PREAUTH_TRANSACTION_VW pm
    WHERE
      /*cph_card_no IN
      (SELECT cap_pan_code
      FROM cms_appl_pan
      WHERE cap_acct_no =
      (SELECT cap_acct_no
      FROM cms_appl_pan
      WHERE cap_pan_code = gethash (p_card_no)
      AND cap_mbr_numb = p_mbr_numb
      AND cap_inst_code = p_inst_code))*/
      pm.CPT_ACCT_NO             = P_ACC_NUM
    AND tm.ctm_delivery_channel  = ph.cph_delivery_channel
    AND tm.ctm_tran_code         = ph.cph_tran_code
    AND ph.cph_inst_code         = tm.ctm_inst_code
    AND ph.cph_inst_code         = pm.cpt_inst_code
    AND ph.cph_inst_code         = p_inst_code
    AND ph.cph_card_no           = pm.cpt_card_no
    AND pm.cpt_totalhold_amt     > 0
    AND pm.cpt_expiry_flag       = 'N'
    AND pm.cpt_preauth_validflag = 'Y'
    AND ph.cph_rrn               = pm.cpt_rrn
    ORDER BY cph_txn_date DESC
      ) x
    WHERE (p_month_year IS NULL
      /*AND ROWNUM <= v_tran_cnt*/
      ) --Modified for Mantis Id : 13643
    OR p_month_year IS NOT NULL;
    --En Added for FWR-42
    CURSOR C_MINI_TRAN ( P_MONTH_YEAR VARCHAR2 ,P_ACC_NUM cms_acct_mast.cam_acct_no%TYPE)
    IS --Updated by Ramesh.A on 11/07/2012
      --SN: 06/06/2016~Modified for MVHOST-1345 //to display the fixed fee and percentage fee on a transaction as a single line item.
      SELECT NVL(TRIM(SUBSTR(TXNAMT,1,INSTR(TXNAMT,'~')-1)),0),
        TXNTYPE,
        DATA1
        || TXNAMT
        ||DATA2,
        closing_bal,
        opening_bal,
        feeFlag, --Added for FSS-5137 changes
        txnamount --Added for FSS-5137 changes
        --Z.*
      FROM
        (SELECT --TRIM (
          -- TO_CHAR (csl_trans_amount, '99999999999999990.99')),
          CASE
            WHEN INSTR(UPPER(sl.CSL_TRANS_NARRRATION),'FIXED')>0
            THEN
              (SELECT TRIM(TO_CHAR (SUM(CSL_TRANS_AMOUNT),'99999999999999990.99'))
                ||' ~ '
                ||TRIM(TO_CHAR (MIN(CSL_CLOSING_BALANCE),'99999999999999990.99'))
              FROM CMS_STATEMENTS_LOG_VW
              WHERE CSL_RRN     = sl.CSL_RRN
              AND CSL_AUTH_ID   = sl.CSL_AUTH_ID
              AND CSL_ACCT_NO   = sl.CSL_ACCT_NO
              AND CSL_INST_CODE = sl.CSL_INST_CODE
              AND TXN_FEE_FLAG  ='Y'
              )
          ELSE TRIM(TO_CHAR (sl.CSL_TRANS_AMOUNT, '99999999999999990.99'))
            ||' ~ '
            ||TRIM (TO_CHAR (sl.CSL_CLOSING_BALANCE, '99999999999999990.99'))
        END TXNAMT,
        CASE
          WHEN INSTR(UPPER(sl.CSL_TRANS_NARRRATION),'PERCENTAGE')>0
          THEN 1
          ELSE 0
        END RNUM,
        csl_trans_type TXNTYPE, --Added by Ramesh.A on 11/10/2012
        TO_CHAR (CSL_TRANS_DATE, 'MM/DD/YYYY hh24:mi:ss') --Added for FSS-5137 changes
        || ' ~ '
        || CSL_TRANS_TYPE
        || ' ~ '
        || sl.CSL_DELIVERY_CHANNEL
        || ' ~ '
        || --TM.CTM_TRAN_DESC
	CASE
        WHEN csl_delivery_channel IN ('01','02') AND TXN_FEE_FLAG = 'N'
			   THEN DECODE(nvl(regexp_instr(csl_trans_narrration,'RVSL-',1,1,0,'i'),0),0,TRANS_DESC,
                          'RVSL-'||TRANS_DESC)
			  ||'/'||DECODE(nvl(merchant_name,CSL_MERCHANT_NAME), NULL, DECODE(delivery_channel, '01', 'ATM', '02', 'Retail Merchant'), nvl(merchant_name,CSL_MERCHANT_NAME)
                                                                                                             || '/'
                                                                                                             || terminal_id
                                                                                                             || '/'
                                                                                                             || merchant_street
                                                                                                             || '/'
                                                                                                             || merchant_city
                                                                                                             || '/'
                                                                                                             || merchant_state
                                                                                                             || '/'
                                                                                                             || preauthamount
                                                                                                             || '/'
                                                                                                             ||business_date
                                                                                                             ||'/'
                                                                                                             ||auth_id)
        ELSE
        DECODE ( NVL (REVERSAL_CODE, '0'), '0', DECODE ( sl.TXN_FEE_FLAG, 'Y',
        --TRIM(UPPER(SL.CSL_TRANS_NARRRATION)), --Commented for DFCTNM-108 on 08/02/16 (3.2.4)
        REPLACE(TRIM(UPPER(SUBSTR(SL.CSL_TRANS_NARRRATION,0,DECODE(instr(SL.CSL_TRANS_NARRRATION,' - ',-1),0,LENGTH(SL.CSL_TRANS_NARRRATION),instr(SL.CSL_TRANS_NARRRATION,' - ',-1))))),'CLAWBACK-',''), --Added for DFCTNM-108 on 08/02/16 (3.2.4)
        /* case when trans_desc like 'MoneySend%' then trans_desc else tm./*ctm_tran_desc ctm_display_txndesc end */
        DECODE(upper(trim(NVL(trans_desc,tm.CTM_TRAN_DESC))),upper(trim(tm.CTM_TRAN_DESC)),tm.ctm_display_txndesc,trans_desc))
        /*TM.CTM_TRAN_DESC*/
        , DECODE ( SL.TXN_FEE_FLAG, 'Y', REPLACE(TRIM(UPPER(SUBSTR(SL.CSL_TRANS_NARRRATION,0,DECODE(instr(SL.CSL_TRANS_NARRRATION,' - ',-1),0,LENGTH(SL.CSL_TRANS_NARRRATION),instr(SL.CSL_TRANS_NARRRATION,' - ',-1))))),'CLAWBACK-',''), 'RVSL-'
        ||
        /*case when trans_desc like 'MoneySend%' then trans_desc else TM.CTM_TRAN_DESC end */
        DECODE(upper(trim(NVL(trans_desc,tm.CTM_TRAN_DESC))),upper(trim(tm.CTM_TRAN_DESC)),tm.ctm_display_txndesc,trans_desc))) --Modified for defect 10261
        || (
        CASE
          WHEN clawback_indicator = 'Y'
          THEN
            -- ' - CLAWBACK FEE' --Commented for DFCTNM-108 on 08/02/16 (3.2.4)
            (
            SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '
              || CPC_CLAWBACK_DESC))
              ||rtrim(SUBSTR(SL.CSL_TRANS_NARRRATION,instr(SL.CSL_TRANS_NARRRATION,' - ',-1)))
            FROM CMS_PROD_CATTYPE
           WHERE CPC_PROD_CODE=V_PROD_CODE
				AND CPC_CARD_TYPE= V_PROD_CATTYPE
				AND CPC_INST_CODE=p_inst_code
            ) --Added for DFCTNM-108 on 08/02/16 (3.2.4)
          ELSE DECODE (sl.TXN_FEE_FLAG, 'Y', ' - FEE')
        END) END -- Modified by Sai for MVHOSt-346--Modified for Mantis:0012744
        || ' ~ '
        || --Modified by Ramesh.A on 23/07/2012
        SL.CSL_RRN
        || ' ~ '
        || (
        CASE
          WHEN ( csl_delivery_channel = '11' )
          THEN REGEXP_REPLACE(NVL((DECODE(NVL(COMPANYNAME,''),'','','/'
            ||'From '||COMPANYNAME)
            || DECODE(NVL(COMPENTRYDESC,''),'','','/'
            ||COMPENTRYDESC)
            || DECODE(NVL(INDNAME,''),'','','/'
            ||INDIDNUM
            ||' to '
            ||INDNAME)),'Direct Deposit'),'/','',1,1)
          ELSE NVL ( SL.CSL_MERCHANT_NAME, DECODE (TRIM (DM.CDM_CHANNEL_DESC), 'ATM', 'ATM', 'POS', 'Retail Merchant', 'IVR', 'IVR Transfer', 'CHW', 'Card Holder website', 'ACH', 'Direct Deposit', 'MOB', 'Mobile Transfer', 'CSR', 'Customer Service', 'System'))||'/'||merchant_street||'/'||merchant_id --Modified on 14/02/14 for regarding MVHOST-848  --Modified for MVHOST 987
        END)
        || ' ~ '
        || SL.CSL_MERCHANT_CITY
        || ' ~ '
        || SL.CSL_MERCHANT_STATE
        || ' ~ ' DATA1,
        /*|| TRIM (
        TO_CHAR (CSL_TRANS_AMOUNT, '99999999999999990.99'))
        ||
        ' ~ '
        || TRIM (
        TO_CHAR (SL.CSL_CLOSING_BALANCE,
        '99999999999999990.99'))
        ||*/
        ' ~ '
        || --Sn Modified & added by Pankaj s for DFCCHW-194 changes
        -- SL.CSL_ACCT_NO
        CASE
          WHEN ( (csl_delivery_channel IN ('07', '13')
          AND csl_txn_code              = '11')
          OR (csl_delivery_channel      = '10'
          AND csl_txn_code              = '20'))
          AND csl_trans_type            = 'CR'
          THEN
            (SELECT csl_acct_no
            FROM CMS_STATEMENTS_LOG_VW
            WHERE csl_trans_type = 'DR'
            AND csl_rrn          = sl.csl_rrn
            AND csl_auth_id      = sl.csl_auth_id
            AND csl_to_acctno    = sl.csl_acct_no
            AND csl_inst_code    = sl.csl_inst_code
            )
          ELSE sl.csl_acct_no
        END
        --En Modified & added by Pankaj s for DFCCHW-194 changes
        || ' ~ '
        || --Added by Ramesh.A on 06/07/2012
        CASE
          WHEN ( -- SN Added on 11-Feb-2013 for FSS-482
            (csl_delivery_channel IN ('10', '07')
          AND csl_txn_code         = '07')
          OR (csl_delivery_channel = '13'
          AND csl_txn_code         = '13')
          OR (csl_delivery_channel = '03'
          AND csl_txn_code         = '39'))
          AND csl_trans_type       = 'DR'  -- to acct name
          THEN SL.CSL_TO_ACCTNO||'/'|| case when  CUSTOMER_CARD_NO is not null and TXN_FEE_FLAG ='N' then
            (select vmscms.fn_dmaps_main(ccm_first_name)||' '||vmscms.fn_dmaps_main(ccm_last_name) from vmscms.cms_cust_mast
                                  where ccm_inst_code=csl_inst_code
                                  and ccm_cust_code=(select cap_cust_code from vmscms.cms_appl_pan
                                                      where cap_inst_code=csl_inst_code
                                                            and cap_mbr_numb='000'
                                                            and cap_pan_code= TOPUP_CARD_NO))end
               WHEN csl_delivery_channel='02' and csl_txn_code='37'  THEN
                                  (select cpi_payer_id  from vmscms.cms_payment_info where
                                  CPI_INST_CODE=csl_inst_code
                                  and cpi_RRN=csl_RRN
                                  and CPI_PAN_CODE=csl_PAN_no)
          WHEN ( -- SN Added on 11-Feb-2013 for FSS-482
            (csl_delivery_channel IN ('10', '07')
          AND csl_txn_code         = '07')
          OR (csl_delivery_channel = '13'
          AND csl_txn_code         = '13')
          OR (csl_delivery_channel = '03'
          AND csl_txn_code         = '39'))
          AND csl_trans_type       = 'CR'
          THEN
            (SELECT CSL_ACCT_NO
            FROM CMS_STATEMENTS_LOG_VW
            WHERE CSL_TRANS_TYPE = 'DR'
            AND CSL_RRN          = SL.CSL_RRN
            AND CSL_AUTH_ID      = SL.CSL_AUTH_ID
            AND CSL_TO_ACCTNO    = SL.CSL_ACCT_NO
            AND CSL_INST_CODE    = SL.CSL_INST_CODE
            )||'/'||case when CUSTOMER_CARD_NO is null and TXN_FEE_FLAG ='N' then
              (select vmscms.fn_dmaps_main(ccm_first_name)||' '||vmscms.fn_dmaps_main(ccm_last_name) from vmscms.cms_cust_mast
                                  where ccm_inst_code=csl_inst_code
                                  and ccm_cust_code=(select cap_cust_code from vmscms.cms_appl_pan
                                                      where cap_inst_code=csl_inst_code
                                                            and cap_mbr_numb='000'
                                                            and cap_pan_code=  (select CUSTOMER_CARD_NO from vmscms.TRANSACTIONLOG_VW
                                                                      where   CSL_DELIVERY_CHANNEL = DELIVERY_CHANNEL
                                                                      AND CSL_TXN_CODE       = TXN_CODE
                                                                      AND CSL_RRN            = RRN
                                                                      AND CSL_AUTH_ID        = AUTH_ID
                                                                      AND CSL_INST_CODE      = INSTCODE and response_code='00' ))) end
              WHEN csl_delivery_channel='02'  and csl_txn_code='12' THEN
                            (select cpi_spu_id  from vmscms.cms_payment_info where
                                  CPI_INST_CODE=csl_inst_code
                                  and cpi_RRN=csl_RRN
                                  and CPI_PAN_CODE=csl_PAN_no)-- to from acct name
            --Sn Added by Pankaj s for DFCCHW-194 changes
          WHEN ( (csl_delivery_channel IN ('07', '13')
          AND csl_txn_code              = '11')
          OR (csl_delivery_channel      = '10'
          AND csl_txn_code              = '20'))
          AND csl_trans_type            = 'CR'
          THEN sl.csl_acct_no
          ELSE sl.csl_to_acctno
            --En Added by Pankaj s for DFCCHW-194 changes
        END -- EN Added on 11-Feb-2013 for FSS-482
        --SL.CSL_TO_ACCTNO --Added by Ramesh.A on 06/07/2012
        --commented by Ramesh.A on 06/07/2012 || decode(tm.ctm_amnt_transfer_flag,'Y',(nvl2(sl.csl_to_acctno,' ~ ' || sl.csl_to_acctno,''))) -- Modified by Trivikram on 10-05-12, Changes in fetching depend upon amount transfer flag.
        || ' ~ '
        || SL.CSL_PANNO_LAST4DIGIT --Modifed by Srinivasu on 15-May-2012 for displayion Last 4 Digit of the card number
        --Begin Added for CR-30 C2C Transfer history
        || ' ~ '
        ||
        CASE
          WHEN ( -- SN Added on 11-Feb-2013 for FSS-482
            (csl_delivery_channel IN ('10', '07')
          AND csl_txn_code         = '07')
          OR (csl_delivery_channel = '03'
          AND csl_txn_code         = '39'))
          AND csl_trans_type       = 'DR'
          THEN
            (SELECT CSL_PANNO_LAST4DIGIT
            FROM CMS_STATEMENTS_LOG_VW
            WHERE CSL_TRANS_TYPE = 'CR'
            AND CSL_RRN          = SL.CSL_RRN
            AND CSL_AUTH_ID      = SL.CSL_AUTH_ID
            AND CSL_ACCT_NO      = SL.CSL_TO_ACCTNO
            AND CSL_INST_CODE    = SL.CSL_INST_CODE
            )
          WHEN ( -- SN Added on 11-Feb-2013 for FSS-482
            (csl_delivery_channel IN ('10', '07')
          AND csl_txn_code         = '07')
          OR (csl_delivery_channel = '03'
          AND csl_txn_code         = '39'))
          AND csl_trans_type       = 'CR'
          THEN
            (SELECT CSL_PANNO_LAST4DIGIT
            FROM CMS_STATEMENTS_LOG_VW
            WHERE CSL_TRANS_TYPE = 'DR'
            AND CSL_RRN          = SL.CSL_RRN
            AND CSL_AUTH_ID      = SL.CSL_AUTH_ID
            AND CSL_TO_ACCTNO    = SL.CSL_ACCT_NO
            AND CSL_INST_CODE    = SL.CSL_INST_CODE
            )
        END -- EN Added on 11-Feb-2013 for FSS-482
        || ' ~ '
        ||
        CASE
          WHEN (CSL_DELIVERY_CHANNEL = '13'
          AND csl_txn_code          IN ('28','55')
          AND sl.TXN_FEE_FLAG       <> 'Y')
          THEN
            (SELECT NVL(cct_check_desc,'')
              || ' ~ '
              || NVL(cct_check_no,'')
              || ' ~ '
              || NVL(cct_routing_no,'')
              || ' ~ '
              || NVL(cct_acct_no,'')
            FROM cms_checkdeposit_transaction
            WHERE cct_rrn     =csl_rrn
            AND cct_inst_code = CSL_INST_CODE
            )
          ELSE (' ~ '
            || ' ~ '
            || ' ~ '
            || ' ~ ')
        END DATA2,
        TRIM(TO_CHAR (sl.csl_closing_balance, '99999999999999990.99')) closing_bal,
        TRIM(TO_CHAR ( sl.csl_opening_bal, '99999999999999990.99')) opening_bal,
        sl.TXN_FEE_FLAG feeFlag,
        TRIM(TO_CHAR (sl.CSL_TRANS_AMOUNT, '99999999999999990.99')) txnamount
      FROM CMS_STATEMENTS_LOG_VW SL,
        CMS_TRANSACTION_MAST TM,
        CMS_DELCHANNEL_MAST DM, --Added on 14/02/14 for regarding  MVHOST-848
        TRANSACTIONLOG_VW          --Added for defect 10261
      WHERE                     --CSL_PAN_NO = GETHASH(P_CARD_NO) AND --Commented by Ramesh.A on 10/09/2012
        CSL_ACCT_NO = P_ACC_NUM
        /*(SELECT CAP_ACCT_NO
        FROM CMS_APPL_PAN --Modified by Besky on 20/12/12 for defect id : 9709
        WHERE      CAP_PAN_CODE = GETHASH (P_CARD_NO)
        AND CAP_MBR_NUMB = P_MBR_NUMB
        AND CAP_INST_CODE = P_INST_CODE)*/
      AND DM.CDM_CHANNEL_CODE = SL.CSL_DELIVERY_CHANNEL
      AND --Added on 14/02/14 for regarding  MVHOST-848
        DM.CDM_INST_CODE          = SL.CSL_INST_CODE
      AND TM.CTM_DELIVERY_CHANNEL = SL.CSL_DELIVERY_CHANNEL
      AND TM.CTM_TRAN_CODE        = SL.CSL_TXN_CODE
      AND CSL_TRANS_DATE         IS NOT NULL
      AND --Updated by Ramesh.A on 23/07/2012
        TM.CTM_INST_CODE = SL.CSL_INST_CODE
      AND -- Added by siva kumar m as on Oct-11-12
        SL.CSL_INST_CODE = P_INST_CODE
      AND -- Added by siva kumar m as on Oct-11-12
        --Sn Added for defect 10261
        SL.CSL_DELIVERY_CHANNEL = DELIVERY_CHANNEL(+)
      AND SL.CSL_TXN_CODE       = TXN_CODE(+)
      AND SL.CSL_RRN            = RRN(+)
      AND SL.CSL_PAN_NO         = CUSTOMER_CARD_NO(+)
      AND SL.CSL_AUTH_ID        = AUTH_ID(+)
      AND SL.CSL_INST_CODE      = INSTCODE(+)
      AND --En Added for defect 10261
        ( (P_MONTH_YEAR                     IS NOT NULL
      AND TO_CHAR (CSL_TRANS_DATE, 'MMYYYY') = P_MONTH_YEAR)
      OR P_MONTH_YEAR                       IS NULL) --Updated by Ramesh.A on 11/07/2012
      AND ((v_Trans_Type                     ='B'
      AND sl.CSL_TRANS_TYPE                 IN ('CR','DR'))
      OR sl.CSL_TRANS_TYPE                   = v_Trans_Type) -- added for fwr-67
      AND ((P_FROMDATE                      IS NOT NULL
      AND sl.CSL_BUSINESS_DATE BETWEEN TO_CHAR (TO_DATE (p_fromdate, 'MMDDYYYY'),'YYYYMMDD') AND TO_CHAR (TO_DATE (p_todate, 'MMDDYYYY'),'YYYYMMDD'))
      OR P_FROMDATE    IS NULL )
      AND ((P_FROMAMNT IS NOT NULL
      AND sl.csl_trans_amount BETWEEN P_FROMAMNT AND P_TOAMNT)
      OR P_FROMAMNT IS NULL )
      ORDER BY CSL_INS_DATE
        ) Z -- Modified by Ramesh.A on 13/09/12,sort by ins date
      WHERE ((P_MONTH_YEAR IS NULL
      AND P_FROMDATE       IS NULL
      AND ROWNUM           <= V_TRAN_CNT)
      OR P_MONTH_YEAR      IS NOT NULL
      OR P_FROMDATE        IS NOT NULL)
      AND RNUM              =0; --Updated by Ramesh.A on 11/07/2012
      --EN: 06/06/2016~Modified for MVHOST-1345 //to display the fixed fee and percentage fee on a transaction as a single line item.
      --Added for MVHOST-388 on 20/06/2013
      CURSOR C_MINI_TRAN_FOR_MEDAGATE ( P_MONTH_YEAR VARCHAR2, P_ACCT_NUM cms_acct_mast.cam_acct_no%TYPE)
      IS --Updated by Ramesh.A on 11/07/2012
        SELECT Z.*
        FROM
          (SELECT TRIM (TO_CHAR (csl_trans_amount, '99999999999999990.99')),
            csl_trans_type, --Added by Ramesh.A on 11/10/2012
            TO_CHAR (CSL_TRANS_DATE, 'MM/DD/YYYY')
            || ' ~ '
            || CSL_TRANS_TYPE
            || ' ~ '
            || SL.CSL_DELIVERY_CHANNEL
            || ' ~ '
            || --TM.CTM_TRAN_DESC
	    CASE
	        WHEN csl_delivery_channel IN ('01','02') AND TXN_FEE_FLAG = 'N'
			   THEN DECODE(nvl(regexp_instr(csl_trans_narrration,'RVSL-',1,1,0,'i'),0),0,TRANS_DESC,
                          'RVSL-'||TRANS_DESC)
			  ||'/'||DECODE(nvl(merchant_name,CSL_MERCHANT_NAME), NULL, DECODE(delivery_channel, '01', 'ATM', '02', 'Retail Merchant'), nvl(merchant_name,CSL_MERCHANT_NAME)
                                                                                                             || '/'
                                                                                                             || terminal_id
                                                                                                             || '/'
                                                                                                             || merchant_street
                                                                                                             || '/'
                                                                                                             || merchant_city
                                                                                                             || '/'
                                                                                                             || merchant_state
                                                                                                             || '/'
                                                                                                             || preauthamount
                                                                                                             || '/'
                                                                                                             ||business_date
                                                                                                             ||'/'
                                                                                                             ||auth_id)
            ELSE
            -- decode(nvl(REVERSAL_CODE,'0'),'0',TM.CTM_TRAN_DESC,'RVSL-'||TM.CTM_TRAN_DESC)--Modified for defect 10261
            DECODE (NVL (REVERSAL_CODE, '0'), '0', DECODE (sl.TXN_FEE_FLAG, 'Y',
            --TRIM(UPPER(SL.CSL_TRANS_NARRRATION)), --Commented for DFCTNM-108 on 08/02/16 (3.2.4)
            REPLACE(TRIM(UPPER(SUBSTR(SL.CSL_TRANS_NARRRATION,0,DECODE(instr(SL.CSL_TRANS_NARRRATION,' - ',-1),0,LENGTH(SL.CSL_TRANS_NARRRATION),instr(SL.CSL_TRANS_NARRRATION,' - ',-1))))),'CLAWBACK-',''), --Added for DFCTNM-108 on 08/02/16 (3.2.4)
            /* case when trans_desc like 'MoneySend%' then trans_desc else tm.ctm_display_txndesc end*/
            DECODE(UPPER(TRIM(NVL(TRANS_DESC,TM.CTM_TRAN_DESC))),UPPER(TRIM(TM.CTM_TRAN_DESC)),TM.CTM_DISPLAY_TXNDESC,TRANS_DESC)), DECODE (sl.TXN_FEE_FLAG, 'Y', REPLACE(TRIM(UPPER(SUBSTR(SL.CSL_TRANS_NARRRATION,0,DECODE(instr(SL.CSL_TRANS_NARRRATION,' - ',-1),0,LENGTH(SL.CSL_TRANS_NARRRATION),instr(SL.CSL_TRANS_NARRRATION,' - ',-1))))),'CLAWBACK-',''), 'RVSL-'
            ||
            /*case when trans_desc like 'MoneySend%' then trans_desc else tm.ctm_display_txndesc end */
            DECODE(upper(trim(NVL(trans_desc,tm.CTM_TRAN_DESC))),upper(trim(tm.CTM_TRAN_DESC)),tm.ctm_display_txndesc,trans_desc)))
            || (
            CASE
              WHEN clawback_indicator = 'Y'
              THEN
                -- ' - CLAWBACK FEE' --Commented for DFCTNM-108 on 08/02/16 (3.2.4)
                (
                SELECT UPPER(DECODE(CPC_CLAWBACK_DESC,NULL,'',' - '
                  || CPC_CLAWBACK_DESC))
                  ||rtrim(SUBSTR(SL.CSL_TRANS_NARRRATION,instr(SL.CSL_TRANS_NARRRATION,' - ',-1)))
                FROM CMS_PROD_CATTYPE
                WHERE CPC_PROD_CODE=V_PROD_CODE
				AND CPC_CARD_TYPE= V_PROD_CATTYPE
				AND CPC_INST_CODE=p_inst_code
                ) --Added for DFCTNM-108 on 08/02/16 (3.2.4)
            ELSE DECODE (sl.TXN_FEE_FLAG, 'Y', ' - FEE')
          END) END -- Modified by Sai for MVHOSt-346
            || ' ~ '
            || --Modified by Ramesh.A on 23/07/2012
            SL.CSL_RRN
            || ' ~ '
            || (
            CASE
              WHEN ( csl_delivery_channel = '11' )
              THEN REGEXP_REPLACE(NVL((DECODE(NVL(COMPANYNAME,''),'','','/'
                ||COMPANYNAME)
                || DECODE(NVL(COMPENTRYDESC,''),'','','/'
                ||COMPENTRYDESC)
                || DECODE(NVL(INDNAME,''),'','','/'
                ||INDIDNUM
                ||' to '
                ||INDNAME)),'Direct Deposit'),'/','',1,1)
              ELSE NVL (SL.CSL_MERCHANT_NAME, DECODE (TRIM (DM.CDM_CHANNEL_DESC), 'ATM', 'ATM', 'POS', 'Retail Merchant', 'IVR', 'IVR Transfer', 'CHW', 'Card Holder website', 'ACH', 'Direct Deposit', 'MOB', 'Mobile Transfer', 'CSR', 'Customer Service', 'System')) --Added on 14/02/14 for regarding  MVHOST-848  --Modified for MVHOST 987
            END)
            || ' ~ '
            || SL.CSL_MERCHANT_CITY
            || ' ~ '
            || SL.CSL_MERCHANT_STATE
            || ' ~ '
            || TRIM (TO_CHAR (CSL_TRANS_AMOUNT, '99999999999999990.99'))
            || ' ~ '
            || TRIM (TO_CHAR (SL.CSL_CLOSING_BALANCE, '99999999999999990.99'))
            || ' ~ '
            || SL.CSL_ACCT_NO
            || ' ~ '
            || SL.CSL_PANNO_LAST4DIGIT --Modifed by Srinivasu on 15-May-2012 for displayion Last 4 Digit of the card number
            -- EN Added on 11-Feb-2013 for FSS-482
          FROM CMS_STATEMENTS_LOG_VW SL,
            CMS_TRANSACTION_MAST TM,
            CMS_DELCHANNEL_MAST DM, --Added on 14/02/14 for regarding  MVHOST-848
            TRANSACTIONLOG_VW          --Added for defect 10261
          WHERE                     --CSL_PAN_NO = GETHASH(P_CARD_NO) AND --Commented by Ramesh.A on 10/09/2012
            CSL_ACCT_NO = P_ACCT_NUM
            /* (SELECT CAP_ACCT_NO
            FROM CMS_APPL_PAN --Modified by Besky on 20/12/12 for defect id : 9709
            WHERE      CAP_PAN_CODE = GETHASH (P_CARD_NO)
            AND CAP_MBR_NUMB = P_MBR_NUMB
            AND CAP_INST_CODE = P_INST_CODE)*/
          AND DM.CDM_CHANNEL_CODE = SL.CSL_DELIVERY_CHANNEL
          AND --Added on 14/02/14 for regarding  MVHOST-848
            DM.CDM_INST_CODE = SL.CSL_INST_CODE
          AND --Added on 14/02/14 for regarding  MVHOST-848
            TM.CTM_DELIVERY_CHANNEL = SL.CSL_DELIVERY_CHANNEL
          AND TM.CTM_TRAN_CODE      = SL.CSL_TXN_CODE
          AND CSL_TRANS_DATE       IS NOT NULL
          AND --Updated by Ramesh.A on 23/07/2012
            TM.CTM_INST_CODE = SL.CSL_INST_CODE
          AND -- Added by siva kumar m as on Oct-11-12
            SL.CSL_INST_CODE = P_INST_CODE
          AND -- Added by siva kumar m as on Oct-11-12
            --Sn Added for defect 10261
            SL.CSL_DELIVERY_CHANNEL = DELIVERY_CHANNEL(+)
          AND SL.CSL_TXN_CODE       = TXN_CODE(+)
          AND SL.CSL_RRN            = RRN(+)
          AND SL.CSL_PAN_NO         = CUSTOMER_CARD_NO(+)
          AND SL.CSL_AUTH_ID        = AUTH_ID(+)
          AND SL.CSL_INST_CODE      = INSTCODE(+)
          AND --En Added for defect 10261
            ( (P_MONTH_YEAR                     IS NOT NULL
          AND TO_CHAR (CSL_TRANS_DATE, 'MMYYYY') = P_MONTH_YEAR)
          OR P_MONTH_YEAR                       IS NULL) --Updated by Ramesh.A on 11/07/2012
          ORDER BY CSL_INS_DATE DESC
          ) Z -- Modified by Ramesh.A on 13/09/12,sort by ins date
        WHERE (P_MONTH_YEAR IS NULL
        AND ROWNUM          <= V_TRAN_CNT)
        OR P_MONTH_YEAR     IS NOT NULL;
        /*
        MOdified by Trivikram on 09-May-2012
        Reason:: Format of statements for IVR and CHW recent transaction changed.
        */
        CURSOR C_PRE_AUTH_DET ( P_MONTH_YEAR VARCHAR2, P_ACCT_NO cms_acct_mast.cam_acct_no%TYPE)
        IS --Updated by Ramesh.A on 11/07/2012
          SELECT X.*
          FROM
            (SELECT TO_CHAR (TO_DATE (CPH_TXN_DATE, 'YYYY/MM/DD'), 'MM/DD/YYYY')
              || ' ~ '
              || PH.CPH_DELIVERY_CHANNEL
              || ' ~ '
              ||
              CASE
                WHEN EXISTS
                  (SELECT 1
                  FROM CMS_BIN_LEVEL_CONFIG
                  WHERE CBL_INST_BIN = SUBSTR(p_card_no,1,6)
                  AND CBL_INST_CODE  = p_inst_code
                  AND CBL_FUND_MCC   = pm.cpt_mcc_code
                  )
              AND CPT_PREAUTH_TYPE = 'D'
              THEN 'MoneySend Funding Auth'
              ELSE TM.
                /*CTM_TRAN_DESC*/
                ctm_display_txndesc
            END
            || --   ' ~ ' || PH.CPH_RRN || ' ~ ' || PH.CPH_MERCHANT_NAME || ' ~ ' ||-- Commented for -- MVHOST-848
            ' ~ '
            || PH.CPH_RRN
            || ' ~ '
            || NVL (ph.cph_merchant_name, DECODE (TRIM (DM.CDM_CHANNEL_DESC), 'ATM', 'ATM', 'POS', 'Retail Merchant', 'IVR', 'IVR Transfer', 'CHW', 'Card Holder website', 'ACH', 'Direct Deposit', 'MOB', 'Mobile Transfer', 'CSR', 'Customer Service', 'System')) --Added on 14/02/14 for regarding  MVHOST-848  --Modified for MVHOST 987
            || ' ~ '
            || PH.CPH_MERCHANT_CITY
            || ' ~ '
            || PH.CPH_MERCHANT_STATE
            || ' ~ '
            || TRIM (TO_CHAR (PH.CPH_TXN_AMNT, '99999999999999990.99'))
            || ' ~ '
            || PH.CPH_PANNO_LAST4DIGIT --Modifed by Srinivasu on 15-May-2012 for displayion Last 4 Digit of the card number
          FROM CMS_PREAUTH_TRANS_HIST PH,
            CMS_TRANSACTION_MAST TM,
            CMS_PREAUTH_TRANSACTION_VW PM,
            CMS_DELCHANNEL_MAST DM
          WHERE PM.CPT_ACCT_NO = P_ACCT_NO
            /*CPH_CARD_NO IN
            (SELECT CAP_PAN_CODE
            FROM cms_appl_pan
            WHERE CAP_ACCT_NO = --Modified by Besky on 20/12/12 for defect id : 9709
            (SELECT CAP_ACCT_NO
            FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = GETHASH (P_CARD_NO)
            AND CAP_MBR_NUMB = P_MBR_NUMB
            AND CAP_INST_CODE = P_INST_CODE))*/
          AND --Updated by Ramesh.A on 10/09/2012
            TM.CTM_DELIVERY_CHANNEL = PH.CPH_DELIVERY_CHANNEL
          AND TM.CTM_TRAN_CODE      = PH.CPH_TRAN_CODE
          AND PH.CPH_INST_CODE      = TM.CTM_INST_CODE
          AND -- Added by siva kumar m as on Oct-11-12
            PH.CPH_INST_CODE = PM.CPT_INST_CODE
          AND -- Added by siva kumar m as on Oct-11-12
            PH.CPH_INST_CODE = P_INST_CODE
          AND -- Added by siva kumar m as on Oct-11-12
            PH.CPH_CARD_NO     = PM.CPT_CARD_NO
          AND DM.CDM_INST_CODE = P_INST_CODE
          AND --Added on 14/02/13 for regarding  MVHOST-848
            DM.CDM_CHANNEL_CODE = PH.CPH_DELIVERY_CHANNEL
          AND --Added on 14/02/13 for regarding  MVHOST-848
            PM.CPT_TOTALHOLD_AMT       > 0
          AND PM.cpt_expiry_flag       = 'N'
          AND pm.cpt_preauth_validflag = 'Y'
          AND --Added by Ramesh.A  on 24/07/2012
            ph.cph_rrn = pm.cpt_rrn
            --Commended by Saravanakumar on 07-Nov-2012 for defect id FSS782
            /*and
            ((P_MONTH_YEAR IS NOT NULL AND
            TO_CHAR(TO_DATE(CPH_TXN_DATE, 'YYYY/MM/DD'), 'MMYYYY') =
            P_MONTH_YEAR) OR P_MONTH_YEAR IS NULL) */
            --Updated by Ramesh.A on 11/07/2012
          ORDER BY CPH_TXN_DATE DESC
            ) X
          WHERE (P_MONTH_YEAR IS NULL
          AND ROWNUM          <= V_TRAN_CNT)
          OR P_MONTH_YEAR     IS NOT NULL; --Updated by Ramesh.A on 11/07/2012
          CURSOR C_PRE_AUTH__MONTH_DET
          IS
            SELECT X.*
            FROM
              (SELECT TO_CHAR (TO_DATE (CPH_TXN_DATE, 'YYYY/MM/DD'), 'MM/DD/YYYY')
                || ' ~ '
                || CPH_TXN_AMNT
              FROM CMS_PREAUTH_TRANS_HIST
              WHERE CPH_CARD_NO                                            = GETHASH (P_CARD_NO)
              AND TO_CHAR (TO_DATE (CPH_TXN_DATE, 'YYYY/MM/DD'), 'MMYYYY') = V_MON_YEAR_TEMP
              AND CPH_INST_CODE                                            = P_INST_CODE -- Added by siva kumar m as on Oct-11-12
              ORDER BY CPH_TXN_DATE DESC
              ) X;
          CURSOR C_ACC_STAT
          IS
            --SN: 06/06/2016~Modified for MVHOST-1345 //to display the fixed fee and percentage fee on a transaction as a single line item.
            SELECT DATA1
              ||NVL(TRIM(SUBSTR(TXNAMT,1,INSTR(TXNAMT,'~')-1)),0)
              ||DATA2
              ||SUBSTR(TXNAMT,INSTR(TXNAMT,'~'))
            FROM
              (SELECT TO_CHAR (sl.CSL_TRANS_DATE, 'MM/DD/YYYY')
                || ' ~ '
                || sl.CSL_TRANS_TYPE
                || ' ~ ' DATA1,
                --|| TRIM (TO_CHAR (sl.CSL_TRANS_AMOUNT, '99999999999999990.99')) ||
                ' ~ '
                ||
				CASE
		   WHEN sl.csl_delivery_channel IN ('01','02') AND sl.TXN_FEE_FLAG = 'N'
            THEN
              ( SELECT DECODE(nvl(regexp_instr(sl.csl_trans_narrration,'RVSL-',1,1,0,'i'),0),0,A.TRANS_DESC,'RVSL-'||A.TRANS_DESC)
               ||'/'||DECODE(nvl(A.merchant_name,sl.CSL_MERCHANT_NAME), NULL, DECODE(A.delivery_channel, '01', 'ATM', '02', 'Retail Merchant'), nvl(A.merchant_name,sl.CSL_MERCHANT_NAME)
               || '/'
                                                                                                             || A.terminal_id
                                                                                                             || '/'
                                                                                                             || A.merchant_street
                                                                                                             || '/'
                                                                                                             || A.merchant_city
                                                                                                             || '/'
                                                                                                             || A.merchant_state
                                                                                                             || '/'
                                                                                                             || A.preauthamount
                                                                                                             || '/'
                                                                                                             || A.business_date
                                                                                                             ||'/'
                                                                                                           || A.auth_id)
                  FROM TRANSACTIONLOG_VW A where customer_card_no = sl.CSL_PAN_NO and rrn = sl.csl_rrn and A.auth_id = sl.csl_auth_id
                  and a.business_date = csl_business_date AND a.business_time = csl_business_time)
                  ELSE
                  sl.CSL_TRANS_NARRRATION
	   END DATA2, --|| ' ~ ' || TRIM (TO_CHAR (sl.CSL_CLOSING_BALANCE, '99999999999999990.99'))
                CASE
                  WHEN INSTR(UPPER(sl.CSL_TRANS_NARRRATION),'FIXED')>0
                  THEN
                    (SELECT TRIM(TO_CHAR (SUM(CSL_TRANS_AMOUNT),'99999999999999990.99'))
                      ||'~ '
                      ||TRIM(TO_CHAR (MIN(CSL_CLOSING_BALANCE),'99999999999999990.99'))
                    FROM CMS_STATEMENTS_LOG_VW
                    WHERE CSL_RRN     = sl.CSL_RRN
                    AND CSL_AUTH_ID   = sl.CSL_AUTH_ID
                    AND CSL_ACCT_NO   = sl.CSL_ACCT_NO
                    AND CSL_INST_CODE = sl.CSL_INST_CODE
                    AND TXN_FEE_FLAG  ='Y'
                    )
                ELSE TRIM(TO_CHAR (sl.CSL_TRANS_AMOUNT, '99999999999999990.99'))
                  ||'~ '
                  ||TRIM (TO_CHAR (sl.CSL_CLOSING_BALANCE, '99999999999999990.99'))
              END TXNAMT,
              CASE
                WHEN INSTR(UPPER(sl.CSL_TRANS_NARRRATION),'PERCENTAGE')>0
                THEN 1
                ELSE 0
              END RNUM
            FROM CMS_STATEMENTS_LOG_VW sl
            WHERE sl.CSL_PAN_NO = GETHASH (P_CARD_NO)
            AND sl.CSL_ACCT_NO  =
              (SELECT CAP_ACCT_NO
              FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = GETHASH (P_CARD_NO)
              AND CAP_MBR_NUMB   = P_MBR_NUMB
              )
            AND TO_CHAR (sl.CSL_TRANS_DATE, 'MMYYYY') = V_MON_YEAR_TEMP
            AND sl.CSL_INST_CODE                      = P_INST_CODE -- Added by siva kumar m as on Oct-11-12
            ORDER BY sl.CSL_INS_DATE DESC
              )
            WHERE RNUM=0; -- Modified by Ramesh.A on 13/09/12,sort by ins date
            --EN: 06/06/2016~Modified for MVHOST-1345 //to display the fixed fee and percentage fee on a transaction as a single line item.
            CURSOR C_IVR_MINI_TRAN (P_ACCT_NUM cms_acct_mast.cam_acct_no%TYPE)
            IS
              --SN: 06/06/2016~Modified for MVHOST-1345 //to display the fixed fee and percentage fee on a transaction as a single line item.
              SELECT DATA1
                ||NVL(TRIM(TXNAMT),0)
                ||DATA2 --Z.*
              FROM
                (SELECT TO_CHAR (sl.CSL_TRANS_DATE, 'MM/DD/YYYY')
                  || ' '
                  || sl.CSL_TRANS_TYPE
                  || ' ' DATA1,
                  --|| TRIM (TO_CHAR (sl.CSL_TRANS_AMOUNT, '99999999999999990.99'))
                  --||
                  TRIM(
                  CASE
                    WHEN INSTR(upper(sl.csl_trans_narrration),'FIXED')>0
                    THEN TO_CHAR (
                      (SELECT SUM(csl_trans_amount)
                      FROM CMS_STATEMENTS_LOG_VW
                      WHERE csl_rrn     = sl.csl_rrn
                      AND csl_auth_id   = sl.csl_auth_id
                      AND csl_acct_no   = sl.csl_acct_no
                      AND csl_inst_code = sl.csl_inst_code
                      AND txn_fee_flag  ='Y'
                      ),'99999999999999990.99')
                    ELSE TO_CHAR (sl.CSL_TRANS_AMOUNT, '99999999999999990.99')
                  END)TXNAMT,
                  CASE
                    WHEN INSTR(upper(sl.csl_trans_narrration),'PERCENTAGE')>0
                    THEN 1
                    ELSE 0
                  END rnum,
                  ' '
                  ||
                  CASE
                    WHEN (sl.CSL_DELIVERY_CHANNEL = '13'
                    AND sl.csl_txn_code          IN ('28','55')
                    AND sl.TXN_FEE_FLAG          <> 'Y')
                    THEN
                      (SELECT NVL(cct_check_no,'')
                        || ' '
                        || NVL(CCT_ROUTING_NO,'')
                        || ' '
                        || NVL(CCT_ACCT_NO,'')
                      FROM CMS_CHECKDEPOSIT_TRANSACTION
                      WHERE cct_rrn     =sl.csl_rrn
                      AND cct_inst_code = sl.CSL_INST_CODE
                      )
                    ELSE ( ' '
                      || ' '
                      || ' ')
                  END DATA2
                FROM CMS_STATEMENTS_LOG_VW sl
                WHERE --CSL_PAN_NO = GETHASH(P_CARD_NO) AND --Commented on 06-06-03-2014 for JH-2611
                  sl.CSL_ACCT_NO = P_ACCT_NUM
                  /*   (SELECT CAP_ACCT_NO
                  FROM CMS_APPL_PAN
                  WHERE CAP_PAN_CODE = GETHASH (P_CARD_NO)
                  AND CAP_MBR_NUMB = P_MBR_NUMB)*/
                AND sl.CSL_INST_CODE   = P_INST_CODE -- Added by siva kumar m as on Oct-11-12
                AND ((V_TRANS_TYPE     ='B'
                AND sl.CSL_TRANS_TYPE IN ('CR','DR'))
                OR sl.CSL_TRANS_TYPE   = V_TRANS_TYPE) -- added for fwr-67
                AND ((P_FROMDATE      IS NOT NULL
                AND sl.CSL_BUSINESS_DATE BETWEEN TO_CHAR (TO_DATE (P_FROMDATE, 'MMDDYYYY'),'YYYYMMDD') AND TO_CHAR (TO_DATE (P_TODATE, 'MMDDYYYY'),'YYYYMMDD'))
                OR P_FROMDATE    IS NULL )
                AND ((P_FROMAMNT IS NOT NULL
                AND sl.CSL_TRANS_AMOUNT BETWEEN P_FROMAMNT AND P_TOAMNT)
                OR P_FROMAMNT IS NULL )
                ORDER BY sl.CSL_INS_DATE DESC
                ) Z -- Modified by Ramesh.A on 13/09/12,sort by ins date
              WHERE RNUM  =0
              AND ROWNUM <= V_TRAN_CNT;
              --EN: 06/06/2016~Modified for MVHOST-1345 //to display the fixed fee and percentage fee on a transaction as a single line item.
            BEGIN
              SAVEPOINT V_AUTH_SAVEPOINT;
              V_RESP_CDE    := '1';
              P_RESP_MSG    := 'OK';
              P_TOT_DR_AMT  := 0; --Added by SivaKumar M on 11/10/2012
              P_TOT_CR_AMT  := 0; --Added by SivaKumar M on 11/10/2012
              p_posting_cnt := 0; --Added for FWR-42
              p_pending_cnt := 0; --Added for FWR-42
              BEGIN
                --SN CREATE HASH PAN
                --Gethash is used to hash the original Pan no
                BEGIN
                  V_HASH_PAN := GETHASH (P_CARD_NO);
                EXCEPTION
                WHEN OTHERS THEN
                  V_ERR_MSG := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
                END;
                --EN CREATE HASH PAN
                --SN create encr pan
                --Fn_Emaps_Main is used for Encrypt the original Pan no
                BEGIN
                  V_ENCR_PAN := FN_EMAPS_MAIN (P_CARD_NO);
                EXCEPTION
                WHEN OTHERS THEN
                  V_ERR_MSG := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
                END;
                --EN create encr pan
                --Sn find narration     -- Modified for VMS-4097 - Remove RECENT TRANSACTION logging into TRANSACTIONLOG
                BEGIN
                  SELECT CTM_TRAN_DESC,nvl(CTM_TXN_LOG_FLAG,'T')
                  INTO V_NARRATION,V_AUDIT_FLAG
                  FROM CMS_TRANSACTION_MAST
                  WHERE CTM_TRAN_CODE      = P_TXN_CODE
                  AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                  AND CTM_INST_CODE        = P_INST_CODE;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  V_NARRATION := 'Transaction type ' || P_TXN_CODE;
                WHEN OTHERS THEN
                  V_NARRATION := 'Transaction type ' || P_TXN_CODE;
                END;
                --En find narration
                IF p_trans_type IS NULL THEN
                  v_trans_type  :='B';
                ELSE
                  v_trans_type:= p_trans_type;
                END IF;
                --IF P_DELIVERY_CHANNEL IN ('07', '12') AND P_TXN_CODE = '04' THEN
                IF P_DELIVERY_CHANNEL IN ('07', '12', '10', '04', '14') AND --Modified for MVHOSt-388 on 13/06/13
                  P_TXN_CODE          IN ('04', '10', '12', '17', '95', '96', '14'
                  /*,'28'*/
                  ) THEN --Modified for Mantis Id:13643  --Modified for MVHOSt-388 on 13/06/13
                  ----Updated by Ramesh.A on 12/07/2012
                  IF ( (P_TRAN_CNT IS NULL) OR (P_DELIVERY_CHANNEL = '14' AND P_TRAN_CNT = '0')) THEN --Modified for MVHOSt-388 on 13/06/13
                    BEGIN
                      SELECT CAP_PROD_CODE,cap_card_type
                      INTO V_PROD_CODE,v_prod_cattype
                      FROM CMS_APPL_PAN
                      WHERE CAP_PAN_CODE = V_HASH_PAN
                      AND CAP_INST_CODE  = P_INST_CODE;
                      SELECT TO_NUMBER (CBP_PARAM_VALUE)
                      INTO V_TRAN_CNT
                      FROM CMS_BIN_PARAM
                      WHERE CBP_INST_CODE   = P_INST_CODE
                      AND CBP_PARAM_NAME    = 'TranCount_For_RecentStmt'
                      AND CBP_PROFILE_CODE IN
                        (SELECT CPC_PROFILE_CODE FROM CMS_PROD_CATTYPE WHERE CPC_PROD_CODE = V_PROD_CODE AND CPC_CARD_TYPE=v_prod_cattype AND CPC_INST_CODE=P_INST_CODE);
                      -- Added by siva kumar on 03/07/12
                      SELECT NVL (CPC_ROUT_NUM, CPC_INSTITUTION_ID
                        ||'-'
                        || CPC_TRANSIT_NUMBER),
                        CPC_ROUT_NUM --Modified for DFCTNM-26
                      INTO V_ROUTING_NUMBER,
                        V_RUTING_NUM
                      FROM CMS_PROD_CATTYPE
                      WHERE CPC_PROD_CODE = V_PROD_CODE
                     AND CPC_CARD_TYPE= v_prod_cattype
                      AND CPC_INST_CODE   = P_INST_CODE;
                    EXCEPTION
                    WHEN OTHERS THEN
                      V_TRAN_CNT := 10;
                    END;
                  ELSE
                    V_TRAN_CNT := P_TRAN_CNT;
                  END IF;
                  -- ELSIF P_DELIVERY_CHANNEL = '10' AND P_TXN_CODE IN ('04','12','17') THEN  --Updated by Ramesh.A on 22/06/2012  -- commented by Ramesh.A on 12/07/2012
                  -- V_TRAN_CNT := 10;
                END IF;
                --sN CHECK INST CODE
                BEGIN
                  IF P_INST_CODE IS NULL THEN
                    V_RESP_CDE   := '12'; -- Invalid Transaction
                    V_ERR_MSG    := 'Institute code cannot be null ' || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
                  END IF;
                EXCEPTION
                WHEN EXP_REJECT_RECORD THEN
                  RAISE;
                WHEN OTHERS THEN
                  V_RESP_CDE := '12'; -- Invalid Transaction
                  V_ERR_MSG  := 'Institute code cannot be null ' || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
                END;
                --eN CHECK INST CODE
                BEGIN
                  V_DATE := TO_DATE (SUBSTR (TRIM (P_TRAN_DATE), 1, 8), 'yyyymmdd');
                EXCEPTION
                WHEN OTHERS THEN
                  V_RESP_CDE := '45';                       -- Server Declined -220509
                  V_ERR_MSG  := 'INVALID TRANSACTION DATE'; -- Updated by Ramesh.A on 01/08/2012
                  RAISE EXP_REJECT_RECORD;
                END;
                BEGIN
                  V_TRAN_DATE := TO_DATE ( SUBSTR (TRIM (P_TRAN_DATE), 1, 8) || ' ' || SUBSTR (TRIM (P_TRAN_TIME), 1, 10), 'yyyymmdd hh24:mi:ss');
                EXCEPTION
                WHEN OTHERS THEN
                  V_RESP_CDE := '32';                       -- Server Declined -220509
                  V_ERR_MSG  := 'INVALID TRANSACTION TIME'; -- Updated by Ramesh.A on 01/08/2012
                  RAISE EXP_REJECT_RECORD;
                END;
                IF P_DELIVERY_CHANNEL IN ('04', '10') AND P_TXN_CODE IN ('12', '95') THEN --Modified by Ramesh.A on 13/07/2012
                  BEGIN
                    V_MONTH_YEAR    := TO_DATE (P_MONTH_YEAR, 'MMYYYY');
                    V_MON_YEAR_TEMP := P_MONTH_YEAR;
                  EXCEPTION
                  WHEN OTHERS THEN
                    V_RESP_CDE := '49';                     -- Server Declined -220509
                    V_ERR_MSG  := 'Invalid Month and Year'; -- Updated by Ramesh.A on 01/08/2012
                    RAISE EXP_REJECT_RECORD;
                  END;
                  --SN Modified for DFCTNM-2
                ELSIF P_DELIVERY_CHANNEL ='10' AND P_TXN_CODE = '17' THEN
                  SELECT TO_CHAR (TO_DATE (P_TRAN_DATE, 'YYYY/MM/DD'), 'MMYYYY')
                  INTO V_MON_YEAR_TEMP
                  FROM DUAL;
                ELSIF P_DELIVERY_CHANNEL = '04' AND P_TXN_CODE ='96' AND (P_FROMDATE IS NOT NULL OR P_FROMAMNT IS NOT NULL) THEN
                  V_MON_YEAR_TEMP       := NULL;--Modified by saravanakumar on 06-May-2015 for defect DFCTNM-78
                ELSIF P_DELIVERY_CHANNEL = '04' AND P_TXN_CODE ='96' AND (P_FROMDATE IS NULL AND P_FROMAMNT IS NULL) THEN
                  V_MON_YEAR_TEMP       := TO_CHAR (TO_DATE (P_TRAN_DATE, 'YYYY/MM/DD'), 'MMYYYY'); --Modified by saravanakumar on 06-May-2015 for defect DFCTNM-78
                END IF;
                --En Modified for DFCTNM-2
                -- END IF;
                --En get date
                --Sn find debit and credit flag
                BEGIN
                  SELECT CTM_CREDIT_DEBIT_FLAG,
                    CTM_OUTPUT_TYPE,
                    TO_NUMBER (DECODE (CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
                    CTM_TRAN_TYPE,
                    CTM_LOGIN_TXN, --Added For Clawback changes on 200413
                    nvl(CTM_TXN_LOG_FLAG,'T')	-- Modified for VMS-4097 - Remove RECENT TRANSACTION
                  INTO V_DR_CR_FLAG,
                    V_OUTPUT_TYPE,
                    V_TXN_TYPE,
                    V_TRAN_TYPE,
                    V_LOGIN_TXN,
                    V_AUDIT_FLAG
                  FROM CMS_TRANSACTION_MAST
                  WHERE CTM_TRAN_CODE      = P_TXN_CODE
                  AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                  AND CTM_INST_CODE        = P_INST_CODE;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  V_RESP_CDE := '12'; --Ineligible Transaction
                  V_ERR_MSG  := 'Transflag  not defined for txn code ' || P_TXN_CODE || ' and delivery channel ' || P_DELIVERY_CHANNEL;
                  RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                  V_RESP_CDE := '21'; --Ineligible Transaction
                  V_ERR_MSG  := 'Error while selecting transaction details';
                  RAISE EXP_REJECT_RECORD;
                END;

                dbms_output.put_line ('V_AUDIT_FLAG -' ||V_AUDIT_FLAG);
                --En find debit and credit flag
                --Sn Duplicate RRN Check
                /* BEGIN
                SELECT COUNT(1)
                INTO V_RRN_COUNT
                FROM TRANSACTIONLOG
                WHERE RRN = P_RRN AND --Changed for admin dr cr.
                BUSINESS_DATE = P_TRAN_DATE AND
                DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; --Added by ramkumar.Mk on 25 march 2012
                IF V_RRN_COUNT > 0 THEN
                V_RESP_CDE := '22';
                V_ERR_MSG := 'Duplicate RRN from the Terminal ' || P_TERM_ID ||
                ' on ' || P_TRAN_DATE;
                RAISE EXP_REJECT_RECORD;
                END IF;
                END;
                */
                -- MODIFIED BY ABDUL HAMEED M.A ON 06-03-2014
		IF V_AUDIT_FLAG = 'T'			-- Modified for VMS-4097 - Remove RECENT TRANSACTION logging into TRANSACTIONLOG
                THEN
                BEGIN
                  sp_dup_rrn_check (v_hash_pan, p_rrn, p_tran_date, p_delivery_channel, p_msg, p_txn_code, v_err_msg);
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
                END;
                --En Duplicate RRN Check
		END IF;
                --Sn find service tax
                BEGIN
                  SELECT CIP_PARAM_VALUE
                  INTO V_SERVICETAX_PERCENT
                  FROM CMS_INST_PARAM
                  WHERE CIP_PARAM_KEY = 'SERVICETAX'
                  AND CIP_INST_CODE   = P_INST_CODE;
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
                BEGIN
                  IF P_TXN_CODE               = '04' AND P_DELIVERY_CHANNEL IN ('07', '12') THEN
                    IF TO_NUMBER (P_TRAN_CNT) = '0' THEN
                      V_RESP_CDE             := '90';
                      V_ERR_MSG              := 'Minimum Transaction Count should be greater than 0 ';
                      RAISE EXP_REJECT_RECORD;
                    ELSIF TO_NUMBER (P_TRAN_CNT) > '10' THEN
                      V_RESP_CDE                := '90';
                      V_ERR_MSG                 := 'Maximum Transaction Count should not be greater than 10 ';
                      RAISE EXP_REJECT_RECORD;
                    END IF;
                  END IF;
                EXCEPTION
                WHEN EXP_REJECT_RECORD THEN
                  RAISE;
                WHEN OTHERS THEN
                  V_RESP_CDE := '21';
                  V_ERR_MSG  := 'Error while selecting transaction count from system ';
                  RAISE EXP_REJECT_RECORD;
                END;
                --Sn find cess
                BEGIN
                  SELECT CIP_PARAM_VALUE
                  INTO V_CESS_PERCENT
                  FROM CMS_INST_PARAM
                  WHERE CIP_PARAM_KEY = 'CESS'
                  AND CIP_INST_CODE   = P_INST_CODE;
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
                  WHERE CIP_PARAM_KEY = 'CUTOFF'
                  AND CIP_INST_CODE   = P_INST_CODE;
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
                IF ( (V_TRAN_TYPE = 'F') OR (P_MSG = '0100')) THEN
                  IF (P_TXN_AMT  >= 0) THEN
                    V_TRAN_AMT   := P_TXN_AMT;
                    BEGIN
                      SP_CONVERT_CURR (P_INST_CODE, P_CURR_CODE, P_CARD_NO, P_TXN_AMT, V_TRAN_DATE, V_TRAN_AMT, V_CARD_CURR, V_ERR_MSG,V_PROD_CODE,v_prod_cattype);
                      IF V_ERR_MSG <> 'OK' THEN
                        V_RESP_CDE := '44';
                        RAISE EXP_REJECT_RECORD;
                      END IF;
                    EXCEPTION
                    WHEN EXP_REJECT_RECORD THEN
                      RAISE;
                    WHEN OTHERS THEN
                      V_RESP_CDE := '69'; -- Server Declined -220509
                      V_ERR_MSG  := 'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
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
                  WHERE PTP_PARAM_NAME = 'PRE CHECK'
                  AND PTP_INST_CODE    = P_INST_CODE;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  V_RESP_CDE := '21'; --only for master setups
                  V_ERR_MSG  := 'Master set up is not done for Authorization Process';
                  RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                  V_RESP_CDE := '21'; --only for master setups
                  V_ERR_MSG  := 'Error while selecting precheck flag' || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
                END;
                --En select authorization process flag
                --Sn select authorization processe flag
                BEGIN
                  SELECT PTP_PARAM_VALUE
                  INTO V_PREAUTH_FLAG
                  FROM PCMS_TRANAUTH_PARAM
                  WHERE PTP_PARAM_NAME = 'PRE AUTH'
                  AND PTP_INST_CODE    = P_INST_CODE;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  V_RESP_CDE := '21';
                  V_ERR_MSG  := 'Master set up is not done for Authorization Process';
                  RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                  V_RESP_CDE := '21';
                  V_ERR_MSG  := 'Error while selecting PCMS_TRANAUTH_PARAM' || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
                END;
                --En select authorization process flag
                --Sn find card detail
                BEGIN
                  SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_EXPRY_DATE,
                    CAP_CARD_STAT,
                    CAP_ATM_ONLINE_LIMIT ,
                    CAP_POS_ONLINE_LIMIT,
                    CAP_PROXY_NUMBER,
                    CAP_ACCT_NO,
                    CAP_CUST_CODE --Added for FSS-5137
                  INTO V_PROD_CODE,
                    V_PROD_CATTYPE,
                    V_EXPRY_DATE,
                    V_APPLPAN_CARDSTAT,
                    V_ATMONLINE_LIMIT ,
                    V_ATMONLINE_LIMIT,
                    V_PROXUNUMBER,
                    V_ACCT_NUMBER,
                    V_CUST_CODE --Added for FSS-5137
                  FROM CMS_APPL_PAN
                  WHERE CAP_PAN_CODE = V_HASH_PAN
                  AND CAP_INST_CODE  = P_INST_CODE;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  V_RESP_CDE := '14';
                  V_ERR_MSG  := 'CARD NOT FOUND ' || V_HASH_PAN;
                  RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                  V_RESP_CDE := '21';
                  V_ERR_MSG  := 'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
                END;
                --En find card detail
                IF P_DELIVERY_CHANNEL ='10' AND P_TXN_CODE IN ('12', '17' ) THEN
                  IF V_RUTING_NUM    IS NOT NULL THEN
                    --P_DDRPRXY_FLAG :='R';  -- R means routing number is configured at product level.
                    P_DDAPRXY_NUMBER :=V_ACCT_NUMBER;
                  ELSE
                    --P_DDRPRXY_FLAG := 'I';  -- I means intitution and transait number is configured at product level
                    P_DDAPRXY_NUMBER :=V_PROXUNUMBER;
                  END IF;
                END IF;
                --Sn GPR Card status check
                BEGIN
                  SP_STATUS_CHECK_GPR (P_INST_CODE, P_CARD_NO, P_DELIVERY_CHANNEL, V_EXPRY_DATE, V_APPLPAN_CARDSTAT, P_TXN_CODE, P_TXN_MODE, V_PROD_CODE, V_PROD_CATTYPE, P_MSG, P_TRAN_DATE, P_TRAN_TIME, P_INTERNATIONAL_IND, NULL, P_MCC_CODE, V_RESP_CDE, V_ERR_MSG);
                  IF ( (V_RESP_CDE <> '1' AND V_ERR_MSG <> 'OK') OR (V_RESP_CDE <> '0' AND V_ERR_MSG <> 'OK')) THEN
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
                  V_ERR_MSG  := 'Error from GPR Card Status Check ' || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
                END;
                --En GPR Card status check
                IF V_STATUS_CHK = '1' THEN
                  -- Expiry Check
                  BEGIN
                    IF TO_DATE (P_TRAN_DATE, 'YYYYMMDD') > LAST_DAY (TO_CHAR (V_EXPRY_DATE, 'DD-MON-YY')) THEN
                      V_RESP_CDE                        := '13';
                      V_ERR_MSG                         := 'EXPIRED CARD';
                      RAISE EXP_REJECT_RECORD;
                    END IF;
                  EXCEPTION
                  WHEN EXP_REJECT_RECORD THEN
                    RAISE;
                  WHEN OTHERS THEN
                    V_RESP_CDE := '21';
                    V_ERR_MSG  := 'ERROR IN EXPIRY DATE CHECK ' || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
                  END;
                  -- End Expiry Check
                  --Sn check for precheck
                  IF V_PRECHECK_FLAG = 1 THEN
                    BEGIN
                      SP_PRECHECK_TXN (P_INST_CODE, P_CARD_NO, P_DELIVERY_CHANNEL, V_EXPRY_DATE, V_APPLPAN_CARDSTAT, P_TXN_CODE, P_TXN_MODE, P_TRAN_DATE, P_TRAN_TIME, V_TRAN_AMT, V_ATMONLINE_LIMIT, V_POSONLINE_LIMIT, V_RESP_CDE, V_ERR_MSG);
                      IF (V_RESP_CDE <> '1' OR V_ERR_MSG <> 'OK') THEN
                        RAISE EXP_REJECT_RECORD;
                      END IF;
                    EXCEPTION
                    WHEN EXP_REJECT_RECORD THEN
                      RAISE;
                    WHEN OTHERS THEN
                      V_RESP_CDE := '21';
                      V_ERR_MSG  := 'Error from precheck processes ' || SUBSTR (SQLERRM, 1, 200);
                      RAISE EXP_REJECT_RECORD;
                    END;
                  END IF;
                  --En check for Precheck
                END IF;
                --Sn check for Preauth
                IF V_PREAUTH_FLAG = 1 THEN
                  BEGIN
                    SP_PREAUTHORIZE_TXN (P_CARD_NO, P_MCC_CODE, P_CURR_CODE, V_TRAN_DATE, P_TXN_CODE, P_INST_CODE, P_TRAN_DATE, V_TRAN_AMT, P_DELIVERY_CHANNEL, V_RESP_CDE, V_ERR_MSG);
                    IF (V_RESP_CDE <> '1' OR TRIM (V_ERR_MSG) <> 'OK') THEN
                      RAISE EXP_REJECT_RECORD; --Modified by Deepa on Apr-30-2012 for the response code change
                    END IF;
                  EXCEPTION
                  WHEN EXP_REJECT_RECORD THEN
                    RAISE;
                  WHEN OTHERS THEN
                    V_RESP_CDE := '21';
                    V_ERR_MSG  := 'Error from pre_auth process ' || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
                  END;
                END IF;
                --En check for preauth
                --Sn-commented for fwr-48
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
                'Error while selecting CMS_FUNC_MAST '
                || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
                END;*/
                --En find function code attached to txn code
                --En-commented for fwr-48
                --Sn find prod code and card type and available balance for the card number
                BEGIN
                  SELECT CAM_ACCT_BAL,
                    CAM_LEDGER_BAL,
                    CAM_ACCT_NO,
                    CAM_TYPE_CODE --Added for defect 10871
                  INTO V_ACCT_BALANCE,
                    V_LEDGER_BAL,
                    V_CARD_ACCT_NO,
                    V_CAM_TYPE_CODE --Added for defect 10871
                  FROM CMS_ACCT_MAST
                  WHERE CAM_ACCT_NO =
                    (SELECT CAP_ACCT_NO
                    FROM CMS_APPL_PAN
                    WHERE CAP_PAN_CODE = V_HASH_PAN
                    AND CAP_MBR_NUMB   = P_MBR_NUMB
                    AND CAP_INST_CODE  = P_INST_CODE
                    )
                  AND CAM_INST_CODE = P_INST_CODE;
                  -- FOR UPDATE NOWAIT; --SN:COMMENTED for FSS-Preauth normal transaction details with same RRN - Response 89 instead of 22 - Resource busy on 18-Jun-2013 by Ranveer Meel
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  V_RESP_CDE := '14'; --Ineligible Transaction
                  V_ERR_MSG  := 'Invalid Card ';
                  RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                  V_RESP_CDE := '12';
                  V_ERR_MSG  := 'Error while selecting data from card Master for card number ' || SQLERRM;
                  RAISE EXP_REJECT_RECORD;
                END;
                --En find prod code and card type for the card number
                --Commented by deepa on Apr-04-12 as this check is not required and the value is passed as null for the transaction
                --Sn Internation Flag check
                BEGIN
                  SP_TRAN_FEES_CMSAUTH (P_INST_CODE, P_CARD_NO, P_DELIVERY_CHANNEL, V_TXN_TYPE, P_TXN_MODE, P_TXN_CODE, P_CURR_CODE, P_CONSODIUM_CODE, P_PARTNER_CODE, V_TRAN_AMT, V_TRAN_DATE, NULL, NULL, V_RESP_CDE, P_MSG, P_RVSL_CODE,                                                                                                                                              --Added by Deepa on June 25 2012 for Reversal txn Fee
                  P_MCC_CODE,                                                                                                                                                                                                                                                                                                                                                            --Added by Trivikram on 05-Sep-2012 for merchant catg code
                  V_FEE_AMT, V_ERROR, V_FEE_CODE, V_FEE_CRGL_CATG, V_FEE_CRGL_CODE, V_FEE_CRSUBGL_CODE, V_FEE_CRACCT_NO, V_FEE_DRGL_CATG, V_FEE_DRGL_CODE, V_FEE_DRSUBGL_CODE, V_FEE_DRACCT_NO, V_ST_CALC_FLAG, V_CESS_CALC_FLAG, V_ST_CRACCT_NO, V_ST_DRACCT_NO, V_CESS_CRACCT_NO, V_CESS_DRACCT_NO, V_FEEAMNT_TYPE, V_CLAWBACK, V_FEE_PLAN, V_PER_FEES, V_FLAT_FEES, v_freetxn_exceed, -- Added by Trivikram for logging fee of free transaction
                  V_DURATION,                                                                                                                                                                                                                                                                                                                                                            -- Added by Trivikram for logging fee of free transaction
                  V_FEEATTACH_TYPE,                                                                                                                                                                                                                                                                                                                                                      -- Added by Trivikram on Sep 05 2012
                  V_FEE_DESC);
                  IF V_ERROR   <> 'OK' THEN
                    V_RESP_CDE := '21';
                    V_ERR_MSG  := V_ERROR;
                    RAISE EXP_REJECT_RECORD;
                  END IF;
                EXCEPTION
                WHEN EXP_REJECT_RECORD THEN
                  RAISE;
                WHEN OTHERS THEN
                  V_RESP_CDE := '21';
                  V_ERR_MSG  := 'Error from fee calc process ' || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
                END;
                ---En dynamic fee calculation .
                --Sn calculate waiver on the fee
                BEGIN
                  SP_CALCULATE_WAIVER (P_INST_CODE, P_CARD_NO, '000', V_PROD_CODE, V_PROD_CATTYPE, V_FEE_CODE, V_FEE_PLAN, -- Added by Trivikram on 21/aug/2012
                  V_TRAN_DATE,                                                                                             --Added Trivikam on Aug-23-2012 to calculate the waiver based on tran date
                  V_WAIV_PERCNT, V_ERR_WAIV);
                  IF V_ERR_WAIV <> 'OK' THEN
                    V_RESP_CDE  := '21';
                    V_ERR_MSG   := V_ERR_WAIV;
                    RAISE EXP_REJECT_RECORD;
                  END IF;
                EXCEPTION
                WHEN EXP_REJECT_RECORD THEN
                  RAISE;
                WHEN OTHERS THEN
                  V_RESP_CDE := '21';
                  V_ERR_MSG  := 'Error from waiver calc process ' || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
                END;
                --En calculate waiver on the fee
                --Sn apply waiver on fee amount
                V_LOG_ACTUAL_FEE := V_FEE_AMT; --only used to log in log table
                V_FEE_AMT        := ROUND (V_FEE_AMT - ( (V_FEE_AMT * V_WAIV_PERCNT) / 100), 2);
                V_LOG_WAIVER_AMT := V_LOG_ACTUAL_FEE - V_FEE_AMT;
                --only used to log in log table
                --En apply waiver on fee amount
                --Sn apply service tax and cess
                IF V_ST_CALC_FLAG      = 1 THEN
                  V_SERVICETAX_AMOUNT := (V_FEE_AMT * V_SERVICETAX_PERCENT) / 100;
                ELSE
                  V_SERVICETAX_AMOUNT := 0;
                END IF;
                IF V_CESS_CALC_FLAG = 1 THEN
                  V_CESS_AMOUNT    := (V_SERVICETAX_AMOUNT * V_CESS_PERCENT) / 100;
                ELSE
                  V_CESS_AMOUNT := 0;
                END IF;
                V_TOTAL_FEE := ROUND (V_FEE_AMT + V_SERVICETAX_AMOUNT + V_CESS_AMOUNT, 2);
                --En apply service tax and cess
                --En find fees amount attached to func code, prod code and card type
                --Sn find total transaction  amount
                IF V_DR_CR_FLAG       = 'CR' THEN
                  V_TOTAL_AMT        := V_TRAN_AMT     - V_TOTAL_FEE;
                  V_UPD_AMT          := V_ACCT_BALANCE + V_TOTAL_AMT;
                  V_UPD_LEDGER_AMT   := V_LEDGER_BAL   + V_TOTAL_AMT;
                ELSIF V_DR_CR_FLAG    = 'DR' THEN
                  V_TOTAL_AMT        := V_TRAN_AMT     + V_TOTAL_FEE;
                  V_UPD_AMT          := V_ACCT_BALANCE - V_TOTAL_AMT;
                  V_UPD_LEDGER_AMT   := V_LEDGER_BAL   - V_TOTAL_AMT;
                ELSIF V_DR_CR_FLAG    = 'NA' THEN
                  IF P_TXN_CODE       = '11' AND P_MSG = '0100' THEN
                    V_TOTAL_AMT      := V_TRAN_AMT     + V_TOTAL_FEE;
                    V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
                    V_UPD_LEDGER_AMT := V_LEDGER_BAL   - V_TOTAL_AMT;
                  ELSE
                    IF V_TOTAL_FEE = 0 THEN
                      V_TOTAL_AMT := 0;
                    ELSE
                      V_TOTAL_AMT := V_TOTAL_FEE;
                    END IF;
                    V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
                    V_UPD_LEDGER_AMT := V_LEDGER_BAL   - V_TOTAL_AMT;
                  END IF;
                ELSE
                  V_RESP_CDE := '12'; --Ineligible Transaction
                  V_ERR_MSG  := 'Invalid transflag    txn code ' || P_TXN_CODE;
                  RAISE EXP_REJECT_RECORD;
                END IF;
                --En find total transaction  amout
                /*   Commented For Clawback (MVHOST - 346) Changes on 20/04/2013
                --Sn check balance
                --IF (V_DR_CR_FLAG NOT IN ('NA', 'CR')  AND P_TXN_CODE <> '93') OR (V_TOTAL_FEE <> 0)-- For credit transaction or Non-Financial transaction Insufficient Balance Check is not required. -- 29th June 2011
                IF (V_DR_CR_FLAG NOT IN ('NA', 'CR') AND P_TXN_CODE <> '93') OR
                V_TOTAL_FEE <> 0 --Modified for As it needs to check insufficient balance for fee
                THEN
                IF V_UPD_AMT < 0 THEN
                V_RESP_CDE := '15'; --Ineligible Transaction
                V_ERR_MSG := 'Insufficent Balance ';
                RAISE EXP_REJECT_RECORD;
                END IF;
                END IF;
                --En check balance*/
                --Start Clawback Changes (MVHOST - 346)  on 20/04/2013
                IF (V_DR_CR_FLAG NOT IN ('NA', 'CR') OR (V_TOTAL_FEE <> 0)) THEN --ADDED FOR JIRA MVCHW - 454
                  IF V_UPD_AMT        < 0 THEN
                    --Sn IVR ClawBack amount updation
                    --IF V_LOGIN_TXN = 'Y' AND V_CLAWBACK = 'Y' V_DR_CR_FLAG NOT IN ('NA', 'CR') OR (V_TOTAL_FEE <> 0) THEN  --commented for JIRA MVCHW - 454
                    IF V_LOGIN_TXN       = 'Y' AND V_CLAWBACK = 'Y' THEN --ADDED FOR JIRA MVCHW - 454
                      V_ACTUAL_FEE_AMNT := V_TOTAL_FEE;
                      --V_CLAWBACK_AMNT   := V_TOTAL_FEE - V_ACCT_BALANCE; --commented for JIRA MVCHW - 454
                      --   V_FEE_AMT   := V_ACCT_BALANCE; --commented for JIRA MVCHW - 454
                      --Start ADDED FOR JIRA MVCHW - 454
                      IF (V_ACCT_BALANCE > 0) THEN
                        V_CLAWBACK_AMNT := V_TOTAL_FEE - V_ACCT_BALANCE;
                        V_FEE_AMT       := V_ACCT_BALANCE;
                      ELSE
                        V_CLAWBACK_AMNT := V_TOTAL_FEE;
                        V_FEE_AMT       := 0;
                      END IF;
                      --END FOR JIRA MVCHW - 454
                      IF V_CLAWBACK_AMNT > 0 THEN
                        -- Added for FWR 64 --
                        BEGIN
                          SELECT cfm_clawback_count
                          INTO v_tot_clwbck_count
                          FROM cms_fee_mast
                          WHERE cfm_fee_code=V_FEE_CODE;
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
                          WHERE ccd_inst_code      = p_inst_code
                          AND ccd_delivery_channel = p_delivery_channel
                          AND ccd_txn_code         = p_txn_code
                            --AND ccd_pan_code = v_hash_pan  --Commented for FSS-4755
                          AND ccd_acct_no  = v_card_acct_no
                          AND CCD_FEE_CODE =V_FEE_CODE
                          AND ccd_clawback ='Y';
                        EXCEPTION
                        WHEN OTHERS THEN
                          V_RESP_CDE := '21';
                          V_ERR_MSG  := 'Error occured while fetching count from cms_charge_dtl' || SUBSTR (SQLERRM, 1, 100);
                          RAISE EXP_REJECT_RECORD;
                        END;
                        -- Added for FWR 64 --
                        BEGIN
                          SELECT COUNT (*)
                          INTO V_CLAWBACK_COUNT
                          FROM CMS_ACCTCLAWBACK_DTL
                          WHERE CAD_INST_CODE      = P_INST_CODE
                          AND CAD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                          AND CAD_TXN_CODE         = P_TXN_CODE
                          AND CAD_PAN_CODE         = V_HASH_PAN
                          AND CAD_ACCT_NO          = V_CARD_ACCT_NO;
                          IF V_CLAWBACK_COUNT      = 0 THEN
                            INSERT
                            INTO CMS_ACCTCLAWBACK_DTL
                              (
                                CAD_INST_CODE,
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
                                CAD_LUPD_USER
                              )
                              VALUES
                              (
                                P_INST_CODE,
                                V_CARD_ACCT_NO,
                                V_HASH_PAN,
                                V_ENCR_PAN,
                                ROUND (V_CLAWBACK_AMNT, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                'N',
                                SYSDATE,
                                SYSDATE,
                                P_DELIVERY_CHANNEL,
                                P_TXN_CODE,
                                '1',
                                '1'
                              );
                          ELSIF v_chrg_dtl_cnt < v_tot_clwbck_count THEN -- Modified for fwr 64
                            UPDATE CMS_ACCTCLAWBACK_DTL
                            SET CAD_CLAWBACK_AMNT    = ROUND (CAD_CLAWBACK_AMNT + V_CLAWBACK_AMNT, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                              CAD_RECOVERY_FLAG      = 'N',
                              CAD_LUPD_DATE          = SYSDATE
                            WHERE CAD_INST_CODE      = P_INST_CODE
                            AND CAD_ACCT_NO          = V_CARD_ACCT_NO
                            AND CAD_PAN_CODE         = V_HASH_PAN
                            AND CAD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                            AND CAD_TXN_CODE         = P_TXN_CODE;
                          END IF;
                        EXCEPTION
                        WHEN OTHERS THEN
                          V_RESP_CDE := '21';
                          V_ERR_MSG  := 'Error while inserting Account ClawBack details' || SUBSTR (SQLERRM, 1, 200);
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
                    V_TOTAL_AMT      := V_TRAN_AMT + V_FEE_AMT;
                  END IF;
                END IF; --for JIRA MVCHW - 454
                --End  Clawback Changes (MVHOST - 346) on 20/04/2013
                --Commented by deepa on Apr-04-12 as the Maximum card balance check is not required for Recent transaction statement
                -- Check for maximum card balance configured for the product profile.
                --En check balance
                --Sn create gl entries and acct update
                BEGIN
                  SP_UPD_TRANSACTION_ACCNT_AUTH (P_INST_CODE, V_TRAN_DATE, V_PROD_CODE, V_PROD_CATTYPE, V_TRAN_AMT, V_FUNC_CODE, P_TXN_CODE, V_DR_CR_FLAG, P_RRN, P_TERM_ID, P_DELIVERY_CHANNEL, P_TXN_MODE, P_CARD_NO, V_FEE_CODE, V_FEE_AMT, V_FEE_CRACCT_NO, V_FEE_DRACCT_NO, V_ST_CALC_FLAG, V_CESS_CALC_FLAG, V_SERVICETAX_AMOUNT, V_ST_CRACCT_NO, V_ST_DRACCT_NO, V_CESS_AMOUNT, V_CESS_CRACCT_NO, V_CESS_DRACCT_NO, V_CARD_ACCT_NO,
                  ---Card's account no has been passed instead of card no(For Debit card acct_no will be different)
                  V_HOLD_AMOUNT, --For PreAuth Completion transaction
                  P_MSG, V_RESP_CDE, V_ERR_MSG);
                  IF (V_RESP_CDE <> '1' OR V_ERR_MSG <> 'OK') THEN
                    V_RESP_CDE   := '21';
                    RAISE EXP_REJECT_RECORD;
                  END IF;
                EXCEPTION
                WHEN EXP_REJECT_RECORD THEN
                  RAISE;
                WHEN OTHERS THEN
                  V_RESP_CDE := '21';
                  V_ERR_MSG  := 'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
                END;
                --En create gl entries and acct update
                v_timestamp := SYSTIMESTAMP; -- Added on 20-Apr-2013 for defect 10871
                --Sn create a entry in statement log
                IF V_DR_CR_FLAG <> 'NA' THEN
                  BEGIN
                    INSERT
                    INTO CMS_STATEMENTS_LOG
                      (
                        CSL_PAN_NO,
                        CSL_OPENING_BAL,
                        CSL_TRANS_AMOUNT,
                        CSL_TRANS_TYPE,
                        CSL_TRANS_DATE,
                        CSL_CLOSING_BALANCE,
                        CSL_TRANS_NARRRATION,
                        CSL_INST_CODE,
                        CSL_PAN_NO_ENCR,
                        csl_acct_type,  -- Added on 20-Apr-2013 for defect 10871
                        csl_time_stamp, -- Added on 20-Apr-2013 for defect 10871
                        csl_prod_code   -- Added on 20-Apr-2013 for defect 10871
                      )
                      VALUES
                      (
                        V_HASH_PAN,
                        ROUND (V_LEDGER_BAL, 2), -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871,--Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                        ROUND (V_TRAN_AMT, 2),   --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                        V_DR_CR_FLAG,
                        V_TRAN_DATE,
                        ROUND ( DECODE (V_DR_CR_FLAG, 'DR', V_LEDGER_BAL - V_TRAN_AMT, -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871,
                        'CR', V_LEDGER_BAL                               + V_TRAN_AMT, -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871,
                        'NA', V_LEDGER_BAL), 2),                                       -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871,--Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                        V_NARRATION,
                        P_INST_CODE,
                        V_ENCR_PAN,
                        v_cam_type_code, -- Added on 20-Apr-2013 for defect 10871
                        v_timestamp,     -- Added on 20-Apr-2013 for defect 10871
                        v_prod_code      -- Added on 20-Apr-2013 for defect 10871
                      );
                  EXCEPTION
                  WHEN OTHERS THEN
                    V_RESP_CDE := '21';
                    V_ERR_MSG  := 'Problem while inserting into statement log for tran amt ' || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
                  END;
                END IF;
                --En create a entry in statement log
                --Sn find fee opening balance
                IF V_TOTAL_FEE <> 0 OR V_FREETXN_EXCEED = 'N' THEN
                  BEGIN
                    SELECT DECODE (V_DR_CR_FLAG, 'DR', V_LEDGER_BAL - V_TRAN_AMT, 'CR', V_LEDGER_BAL + V_TRAN_AMT, 'NA', V_LEDGER_BAL)
                    INTO V_FEE_OPENING_BAL
                    FROM DUAL;
                  EXCEPTION
                  WHEN OTHERS THEN
                    V_RESP_CDE := '12';
                    V_ERR_MSG  := 'Error while selecting data from card Master for card number ' || P_CARD_NO;
                    RAISE EXP_REJECT_RECORD;
                  END;
                  -- Added by Trivikram on 27-July-2012 for logging complementary transaction
                  IF V_FREETXN_EXCEED = 'N' THEN
                    BEGIN
                      INSERT
                      INTO CMS_STATEMENTS_LOG
                        (
                          CSL_PAN_NO,
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
                          CSL_PANNO_LAST4DIGIT,
                          csl_acct_type,  -- Added on 20-Apr-2013 for defect 10871
                          csl_time_stamp, -- Added on 20-Apr-2013 for defect 10871
                          csl_prod_code   -- Added on 20-Apr-2013 for defect 10871
                        )
                        VALUES
                        (
                          V_HASH_PAN,
                          ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                          ROUND (V_TOTAL_FEE, 2),       --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                          'DR',
                          V_TRAN_DATE,
                          ROUND (V_FEE_OPENING_BAL - V_TOTAL_FEE, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                          --   'Complimentary ' || V_DURATION ||' '|| V_NARRATION, -- Modified by Trivikram  on 27-July-2012 --Added on 05/02/14 for regarding MVCSD-4471
                          V_FEE_DESC, --Added on 05/02/14 for regarding MVCSD-4471
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
                          (SUBSTR (P_CARD_NO, LENGTH (P_CARD_NO) - 3, LENGTH (P_CARD_NO))),
                          v_cam_type_code, -- Added on 20-Apr-2013 for defect 10871
                          v_timestamp,     -- Added on 20-Apr-2013 for defect 10871
                          v_prod_code      -- Added on 20-Apr-2013 for defect 10871
                        );
                    EXCEPTION
                    WHEN OTHERS THEN
                      V_RESP_CDE := '21';
                      V_ERR_MSG  := 'Problem while inserting into statement log for tran fee ' || SUBSTR (SQLERRM, 1, 200);
                      RAISE EXP_REJECT_RECORD;
                    END;
                  ELSE
                    BEGIN
                      --En find fee opening balance
                      IF V_FEEAMNT_TYPE = 'A' THEN
                        -- Added by Trivikram on 23/aug/2012 for logged fixed fee and percentage fee with waiver
                        V_FLAT_FEES := ROUND ( V_FLAT_FEES - ( (V_FLAT_FEES * V_WAIV_PERCNT) / 100), 2);
                        V_PER_FEES  := ROUND ( V_PER_FEES  - ( (V_PER_FEES * V_WAIV_PERCNT) / 100), 2);
                        --En Entry for Fixed Fee
                        INSERT
                        INTO CMS_STATEMENTS_LOG
                          (
                            CSL_PAN_NO,
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
                            CSL_PANNO_LAST4DIGIT,
                            csl_acct_type,  -- Added on 20-Apr-2013 for defect 10871
                            csl_time_stamp, -- Added on 20-Apr-2013 for defect 10871
                            csl_prod_code   -- Added on 20-Apr-2013 for defect 10871
                          )
                          VALUES
                          (
                            V_HASH_PAN,
                            ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                            ROUND (V_FLAT_FEES, 2),       --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                            'DR',
                            V_TRAN_DATE,
                            ROUND (V_FEE_OPENING_BAL - V_FLAT_FEES, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                            -- 'Fixed Fee debited for ' || V_NARRATION, --Commented on 05/02/14 for regarding MVCSD-4471
                            'Fixed Fee debited for '
                            || V_FEE_DESC, --Added on 05/02/14 for regarding MVCSD-4471
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
                            (SUBSTR (P_CARD_NO, LENGTH (P_CARD_NO) - 3, LENGTH (P_CARD_NO))),
                            v_cam_type_code, -- Added on 20-Apr-2013 for defect 10871
                            v_timestamp,     -- Added on 20-Apr-2013 for defect 10871
                            v_prod_code      -- Added on 20-Apr-2013 for defect 10871
                          );
                        --En Entry for Fixed Fee
                        V_FEE_OPENING_BAL := V_FEE_OPENING_BAL - V_FLAT_FEES;
                        --Sn Entry for Percentage Fee
                        INSERT
                        INTO CMS_STATEMENTS_LOG
                          (
                            CSL_PAN_NO,
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
                            CSL_PANNO_LAST4DIGIT, --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                            csl_acct_type,        -- Added on 20-Apr-2013 for defect 10871
                            csl_time_stamp,       -- Added on 20-Apr-2013 for defect 10871
                            csl_prod_code         -- Added on 20-Apr-2013 for defect 10871
                          )
                          VALUES
                          (
                            V_HASH_PAN,
                            ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                            ROUND (V_PER_FEES, 2),        --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                            'DR',
                            V_TRAN_DATE,
                            ROUND (V_FEE_OPENING_BAL - V_PER_FEES, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                            -- 'Percetage Fee debited for ' || V_NARRATION, --Commented on 05/02/14 for regarding MVCSD-4471
                            'Percentage Fee debited for '
                            || V_FEE_DESC, --Added on 05/02/14 for regarding MVCSD-4471
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
                            (SUBSTR (P_CARD_NO, LENGTH (P_CARD_NO) - 3, LENGTH (P_CARD_NO))),
                            v_cam_type_code, -- Added on 20-Apr-2013 for defect 10871
                            v_timestamp,     -- Added on 20-Apr-2013 for defect 10871
                            v_prod_code      -- Added on 20-Apr-2013 for defect 10871
                          );
                        --En Entry for Percentage Fee
                      ELSE
                        --Sn create entries for FEES attached
                        INSERT
                        INTO CMS_STATEMENTS_LOG
                          (
                            CSL_PAN_NO,
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
                            CSL_PANNO_LAST4DIGIT,
                            csl_acct_type,  -- Added on 20-Apr-2013 for defect 10871
                            csl_time_stamp, -- Added on 20-Apr-2013 for defect 10871
                            csl_prod_code   -- Added on 20-Apr-2013 for defect 10871
                          )
                          VALUES
                          (
                            V_HASH_PAN,
                            ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                            ROUND (V_FEE_AMT, 2),         --modified for MVHOST-346 --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                            'DR',
                            V_TRAN_DATE,
                            ROUND (V_FEE_OPENING_BAL - V_FEE_AMT, 2), --modified for MVHOST-346 --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                            --'Fee debited for ' || V_NARRATION,-Commented on 05/02/14 for regarding MVCSD-4471
                            V_FEE_DESC, --Added on 05/02/14 for regarding MVCSD-4471
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
                            (SUBSTR (P_CARD_NO, LENGTH (P_CARD_NO) - 3, LENGTH (P_CARD_NO))),
                            v_cam_type_code, -- Added on 20-Apr-2013 for defect 10871
                            v_timestamp,     -- Added on 20-Apr-2013 for defect 10871
                            v_prod_code      -- Added on 20-Apr-2013 for defect 10871
                          );
                        --Start Clawback Changes (MVHOST - 346) on 20/04/2013
                        IF V_LOGIN_TXN = 'Y' AND V_CLAWBACK_AMNT > 0 AND v_chrg_dtl_cnt < v_tot_clwbck_count THEN -- Modified for fwr 64
                          BEGIN
                            INSERT
                            INTO CMS_CHARGE_DTL
                              (
                                CCD_PAN_CODE,
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
                              (
                                V_HASH_PAN,
                                V_CARD_ACCT_NO,
                                ROUND (V_CLAWBACK_AMNT, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                V_FEE_CRACCT_NO,
                                V_ENCR_PAN,
                                P_RRN,
                                V_TRAN_DATE,
                                'T',
                                'C',
                                V_CLAWBACK,
                                P_INST_CODE,
                                V_FEE_CODE,
                                ROUND (V_ACTUAL_FEE_AMNT, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                V_FEE_PLAN,
                                P_DELIVERY_CHANNEL,
                                P_TXN_CODE,
                                ROUND (V_FEE_AMT, 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                                P_MBR_NUMB,
                                DECODE (V_ERR_MSG, 'OK', 'SUCCESS'),
                                V_FEEATTACH_TYPE
                              );
                          EXCEPTION
                          WHEN OTHERS THEN
                            V_RESP_CDE := '21';
                            V_ERR_MSG  := 'Problem while inserting into CMS_CHARGE_DTL ' || SUBSTR (SQLERRM, 1, 200);
                            RAISE EXP_REJECT_RECORD;
                          END;
                        END IF;
                        --End  Clawback Changes (MVHOST - 346) on 20/04/2013
                      END IF;
                    EXCEPTION
                    WHEN OTHERS THEN
                      V_RESP_CDE := '21';
                      V_ERR_MSG  := 'Problem while inserting into statement log for tran fee ' || SUBSTR (SQLERRM, 1, 200);
                      RAISE EXP_REJECT_RECORD;
                    END;
                  END IF;
                END IF;
                --En create entries for FEES attached
                --Sn create a entry for successful

                IF V_AUDIT_FLAG = 'T'		-- Modified for VMS-4097 - Remove RECENT TRANSACTION logging into TRANSACTIONLOG
                THEN

                BEGIN
                  INSERT
                  INTO CMS_TRANSACTION_LOG_DTL
                    (
                      CTD_DELIVERY_CHANNEL,
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
                      CTD_CUST_ACCT_NUMBER
                    )
                    VALUES
                    (
                      P_DELIVERY_CHANNEL,
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
                      V_ACCT_NUMBER
                    );
                  --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
                EXCEPTION
                WHEN OTHERS THEN
                  V_ERR_MSG  := 'Problem while selecting data from response master ' || SUBSTR (SQLERRM, 1, 300);
                  V_RESP_CDE := '21';
                  RAISE EXP_REJECT_RECORD;
                END;

                END IF;
                --En create a entry for successful
                ---Sn update daily and weekly transcounter  and amount
                BEGIN
                  UPDATE CMS_AVAIL_TRANS
                  SET CAT_MAXDAILY_TRANCNT = DECODE (CAT_MAXDAILY_TRANCNT, 0, CAT_MAXDAILY_TRANCNT, CAT_MAXDAILY_TRANCNT   - 1),
                    CAT_MAXDAILY_TRANAMT   = DECODE (V_DR_CR_FLAG, 'DR', CAT_MAXDAILY_TRANAMT                              - V_TRAN_AMT, CAT_MAXDAILY_TRANAMT),
                    CAT_MAXWEEKLY_TRANCNT  = DECODE (CAT_MAXWEEKLY_TRANCNT, 0, CAT_MAXWEEKLY_TRANCNT, CAT_MAXDAILY_TRANCNT - 1),
                    CAT_MAXWEEKLY_TRANAMT  = DECODE (V_DR_CR_FLAG, 'DR', CAT_MAXWEEKLY_TRANAMT                             - V_TRAN_AMT, CAT_MAXWEEKLY_TRANAMT)
                  WHERE CAT_INST_CODE      = P_INST_CODE
                  AND CAT_PAN_CODE         = V_HASH_PAN
                  AND CAT_TRAN_CODE        = P_TXN_CODE
                  AND CAT_TRAN_MODE        = P_TXN_MODE;
                EXCEPTION
                WHEN EXP_REJECT_RECORD THEN
                  RAISE;
                WHEN OTHERS THEN
                  V_ERR_MSG  := 'Problem while selecting data from avail trans ' || SUBSTR (SQLERRM, 1, 300);
                  V_RESP_CDE := '21';
                  RAISE EXP_REJECT_RECORD;
                END;
                --En update daily and weekly transaction counter and amount
                --Sn create detail for response message
                -- added for mini statement
                IF V_OUTPUT_TYPE = 'B' THEN
                  --Balance Inquiry
                  IF P_TXN_CODE IN ('04', '12', '17', '95', '96') AND P_DELIVERY_CHANNEL IN ('04', '10') THEN --Condition modified for FWR-42
                    BEGIN
                      P_LED_BAL_AMT   := NVL (V_LEDGER_BAL, '0');   --Added by Ramesh.A on 11/10/2012
                      P_AVAIL_BAL_AMT := NVL (V_ACCT_BALANCE, '0'); --Added by Ramesh.A on 11/10/2012
                      p_begining_bal  :='0.00';
                      p_ending_bal    :='0.00';
                      v_rnum          :=0;
                      v_totalFees:=0;

                      OPEN C_MINI_TRAN (V_MON_YEAR_TEMP, V_ACCT_NUMBER);
                      LOOP
                        FETCH C_MINI_TRAN
                        INTO v_tran_amount,
                          v_tran_type,
                          V_MINI_STAT_VAL,
                          v_balance,
                          p_begining_bal, --Updated by Ramesh.A on 11/10/2012
                          v_feeFlag, --Added for FSS-5137 changes
                          v_txnamount; --Added for FSS-5137 changes
                        EXIT
                      WHEN C_MINI_TRAN%NOTFOUND;
                        V_MINI_STAT_RES := V_MINI_STAT_RES || ' || ' || V_MINI_STAT_VAL;
                        --Added by Ramesh.A on 11/10/2012
                        IF v_tran_type    = 'DR' THEN
                          P_TOT_DR_AMT   := P_TOT_DR_AMT + v_tran_amount;
                        ELSIF v_tran_type = 'CR' THEN
                          P_TOT_CR_AMT   := P_TOT_CR_AMT + v_tran_amount;
                        END IF;

                        IF v_feeFlag = 'Y' and v_tran_type    = 'DR' THEN
                            v_totalFees:=v_totalFees + v_txnamount;
                          END IF;
                           IF v_feeFlag = 'Y' and v_tran_type    = 'CR' THEN
                            v_totalFees:=v_totalFees - v_txnamount;
                          END IF;

                        IF v_rnum      =0 THEN
                          p_ending_bal:=v_balance;
                          v_rnum      :=v_rnum+1;
                        END IF;
                        --End
                      END LOOP;
                      CLOSE C_MINI_TRAN;
                    EXCEPTION
                    WHEN OTHERS THEN
                      V_ERR_MSG  := 'Problem while selecting data from C_MINI_TRAN cursor' || SUBSTR (SQLERRM, 1, 300);
                      V_RESP_CDE := '21';
                      RAISE EXP_REJECT_RECORD;
                    END;
                    IF (V_MINI_STAT_RES IS NULL) THEN
                      V_MINI_STAT_RES   := ' ';
                    ELSE
                      V_MINI_STAT_RES := SUBSTR (V_MINI_STAT_RES, 5, LENGTH (V_MINI_STAT_RES));
                    END IF;
                    --St Added by Ramesh.A on 13/07/2012
                    /* commented by Ramesh.A on 10/11/2012
                    BEGIN
                    SELECT NVL(SUM(Y.CSL_TRANS_AMOUNT), '0')
                    INTO P_TOT_CR_AMT
                    FROM (SELECT Z.*
                    FROM (SELECT CSL_TRANS_AMOUNT, CSL_TRANS_TYPE
                    FROM CMS_STATEMENTS_LOG
                    WHERE CSL_PAN_NO = GETHASH(P_CARD_NO) AND
                    CSL_TRANS_TYPE = 'CR' AND
                    ((V_MON_YEAR_TEMP IS NOT NULL AND
                    TO_CHAR(CSL_TRANS_DATE, 'MMYYYY') =
                    V_MON_YEAR_TEMP) OR V_MON_YEAR_TEMP IS NULL)
                    ORDER BY CSL_INS_DATE DESC) Z -- Modified by Ramesh.A on 13/09/12,sort by ins date
                    WHERE (V_MON_YEAR_TEMP IS NULL AND ROWNUM <= V_TRAN_CNT) OR
                    V_MON_YEAR_TEMP IS NOT NULL) Y;
                    SELECT NVL(SUM(Y.CSL_TRANS_AMOUNT), '0')
                    INTO P_TOT_DR_AMT
                    FROM (SELECT Z.*
                    FROM (SELECT CSL_TRANS_AMOUNT, CSL_TRANS_TYPE
                    FROM CMS_STATEMENTS_LOG
                    WHERE CSL_PAN_NO = GETHASH(P_CARD_NO) AND
                    CSL_TRANS_TYPE = 'DR' AND
                    ((V_MON_YEAR_TEMP IS NOT NULL AND
                    TO_CHAR(CSL_TRANS_DATE, 'MMYYYY') =
                    V_MON_YEAR_TEMP) OR V_MON_YEAR_TEMP IS NULL)
                    ORDER BY CSL_INS_DATE DESC) Z -- Modified by Ramesh.A on 13/09/12,sort by ins date
                    WHERE (V_MON_YEAR_TEMP IS NULL AND ROWNUM <= V_TRAN_CNT) OR
                    V_MON_YEAR_TEMP IS NOT NULL) Y;
                    P_LED_BAL_AMT := NVL(V_LEDGER_BAL, '0');
                    P_AVAIL_BAL_AMT := NVL(V_ACCT_BALANCE, '0');
                    EXCEPTION
                    WHEN OTHERS THEN
                    V_ERR_MSG  := 'Problem while selecting totdebit,credit for mini statement ' ||
                    SUBSTR(SQLERRM, 1, 200);
                    V_RESP_CDE := '21';
                    RAISE EXP_REJECT_RECORD;
                    END;
                    */
                    --End
                    --ST :FSS-5137 changes

					BEGIN

                      select cpm_prod_desc,cpc_cardtype_desc, cpc_encrypt_enable into p_prod_desc,p_prod_cattype_desc, v_encrypt_enable
                      from cms_prod_mast,cms_prod_cattype
                      where cpm_prod_code=V_PROD_CODE
                      and cpc_card_type=V_PROD_CATTYPE
                      and cpm_inst_code=P_INST_CODE
                      and cpm_prod_code=cpc_prod_code
                      and cpm_inst_code=CPC_INST_CODE;

                     EXCEPTION
                          WHEN OTHERS THEN
                            V_RESP_CDE := '21';
                            V_ERR_MSG  := 'Problem while selecting prod details ' || SUBSTR (SQLERRM, 1, 200);
                            RAISE EXP_REJECT_RECORD;
                    END;

					BEGIN

                     select decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_add_one),cam_add_one),
					        decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_add_two),cam_add_two),
							decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_city_name),cam_city_name),
                           (SELECT UPPER (gsm_state_name)
						    FROM gen_state_mast
							WHERE gsm_inst_code = cam_inst_code
                            AND gsm_state_code = cam_state_code
							AND gsm_cntry_code = cam_cntry_code),
						   (SELECT UPPER (gcm_cntry_name)
							FROM gen_cntry_mast
							WHERE gcm_inst_code = cam_inst_code
							AND gcm_cntry_code = cam_cntry_code),
							decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(CAM_PIN_CODE),CAM_PIN_CODE),
						   (select GCM_CURR_NAME
						   from gen_curr_mast
						   where gcm_inst_code = P_INST_CODE
						   and GCM_CURR_CODE = P_CURR_CODE)
				   into p_mailaddress1,p_mailaddress2,p_mailcity,p_mailstate,p_mailcountry,p_mailzip,p_currency
				   from cms_addr_mast
				   where cam_cust_code=V_CUST_CODE AND CAM_ADDR_FLAG = 'P';

                    EXCEPTION
                          WHEN OTHERS THEN
                            V_RESP_CDE := '21';
                            V_ERR_MSG  := 'Problem while selecting addr details ' || SUBSTR (SQLERRM, 1, 200);
                            RAISE EXP_REJECT_RECORD;
                    END;

                    BEGIN

                     IF P_DELIVERY_CHANNEL ='10' AND P_TXN_CODE = '04' and V_MON_YEAR_TEMP is null THEN
                     SELECT TO_CHAR (SYSDATE, 'MMYYYY')
                      INTO V_MON_YEAR_TMP
                      FROM DUAL;
                    else
                      V_MON_YEAR_TMP := V_MON_YEAR_TEMP;
                     END IF;

                      select trim(ytd) into p_ytd from (
                      select to_char(sum(decode(CSL_TRANS_TYPE,'DR',1,-1)*NVL (CSL_TRANS_AMOUNT, 0)), '9,999,999,990.99')  ytd
                      from CMS_STATEMENTS_LOG_VW
                      WHERE  csl_acct_no=V_ACCT_NUMBER
                      AND txn_fee_flag='Y'
                      AND CSL_INST_CODE= P_INST_CODE
                      and ((V_MON_YEAR_TMP is not null AND  TO_CHAR(CSL_TRANS_DATE,'MMYYYY') between '01'||SUBSTR(V_MON_YEAR_TMP,3,5) and V_MON_YEAR_TMP)
                      or V_MON_YEAR_TMP is null )
                      and  ((P_FROMDATE  IS NOT NULL
                      AND CSL_BUSINESS_DATE BETWEEN TO_CHAR (TO_DATE ('0101'||SUBSTR(P_FROMDATE,5,8), 'MMDDYYYY'),'YYYYMMDD') AND TO_CHAR (TO_DATE (P_TODATE, 'MMDDYYYY'),'YYYYMMDD'))
                      OR P_FROMDATE IS NULL )
                      )z
                      where ((V_MON_YEAR_TMP IS NULL
                            AND P_FROMDATE  IS NULL
                            AND ROWNUM           <= v_tran_cnt)
                            OR V_MON_YEAR_TMP IS NOT NULL
                            OR P_FROMDATE IS NOT NULL);

                      if p_ytd is null then
                      p_ytd := '0.00';
                      end if;

                      if P_FROMDATE IS NOT NULL AND P_TODATE IS NOT NULL AND SUBSTR(P_FROMDATE,5,8) <> SUBSTR(P_TODATE,5,8) THEN

                       p_ytd := ' ';

                      END IF;

                      P_TOTAL_FEES:= trim(to_char(NVL(v_totalFees,0),'99999999999999990.99'));
                     EXCEPTION
                          WHEN OTHERS THEN
                            V_RESP_CDE := '21';
                            V_ERR_MSG  := 'Problem while selecting ytd details ' || SUBSTR (SQLERRM, 1, 200);
                            RAISE EXP_REJECT_RECORD;
                    END;

                    --END :FSS-5137 changes

                  ELSE
                    P_RESP_MSG := TO_CHAR (V_UPD_AMT);
                  END IF;
                  --Sn Added for FWR-42
                  /*  IF p_txn_code IN ('04','12', '17')
                  AND p_delivery_channel IN ('07', '10')
                  THEN
                  BEGIN
                  p_led_bal_amt := NVL (v_ledger_bal, '0');
                  p_avail_bal_amt := NVL (v_acct_balance, '0');
                  OPEN c_mini_tran_1 (v_mon_year_temp);
                  LOOP
                  FETCH c_mini_tran_1
                  INTO v_response_code,v_tran_amount, v_tran_type, v_mini_stat_val;
                  EXIT WHEN c_mini_tran_1%NOTFOUND;
                  v_mini_stat_res := v_mini_stat_res || ' || ' || v_mini_stat_val;
                  IF v_tran_type = 'DR' AND v_response_code='00'
                  THEN
                  p_tot_dr_amt := p_tot_dr_amt + v_tran_amount;
                  p_posting_cnt :=p_posting_cnt+1;
                  ELSIF v_tran_type = 'CR' AND v_response_code='00'
                  THEN
                  p_tot_cr_amt := p_tot_cr_amt + v_tran_amount;
                  p_posting_cnt :=p_posting_cnt+1;
                  END IF;
                  END LOOP;
                  CLOSE c_mini_tran_1;
                  EXCEPTION
                  WHEN OTHERS THEN
                  v_err_msg :='Problem while selecting data from C_MINI_TRAN cursor'|| SUBSTR (SQLERRM, 1, 300);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
                  END;
                  IF (v_mini_stat_res IS NULL)THEN
                  v_mini_stat_res := ' ';
                  ELSE
                  v_mini_stat_res :=SUBSTR (v_mini_stat_res, 5, LENGTH (v_mini_stat_res));
                  END IF;
                  ELSE
                  p_resp_msg := TO_CHAR (v_upd_amt);
                  END IF;*/
                  --En Added for FWR-42
                  IF P_TXN_CODE IN ('04', '17', '96') AND P_DELIVERY_CHANNEL IN ('04', '10') THEN --Modified by Ramesh.A on 13/07/2012
                    BEGIN
                      OPEN C_PRE_AUTH_DET (V_MON_YEAR_TEMP, V_ACCT_NUMBER);
                      LOOP
                        FETCH C_PRE_AUTH_DET INTO V_PRE_AUTH_DET_VAL;
                        EXIT
                      WHEN C_PRE_AUTH_DET%NOTFOUND;
                        V_PRE_AUTH_DET := V_PRE_AUTH_DET || ' || ' || V_PRE_AUTH_DET_VAL;
                      END LOOP;
                      CLOSE C_PRE_AUTH_DET;
                    EXCEPTION
                    WHEN OTHERS THEN
                      V_ERR_MSG  := 'Problem while selecting data from C_PRE_AUTH_DET cursor' || SUBSTR (SQLERRM, 1, 300);
                      V_RESP_CDE := '21';
                      RAISE EXP_REJECT_RECORD;
                    END;
                    IF (V_PRE_AUTH_DET IS NULL) THEN
                      V_PRE_AUTH_DET   := '  ';
                    ELSE
                      V_PRE_AUTH_DET := SUBSTR (V_PRE_AUTH_DET, 5, LENGTH (V_PRE_AUTH_DET));
                    END IF;
                    P_PRE_AUTH_DET := NVL (V_PRE_AUTH_DET, ' ');
                    SELECT                                                  --NVL (SUM (CPT_TOTALHOLD_AMT), '0')
                      NVL (SUM (CPT_TOTALHOLD_AMT+CPT_COMPLETION_FEE), '0') --Modified for FSS 837
                    INTO P_PRE_AUTH_HOLD_AMT
                    FROM CMS_PREAUTH_TRANSACTION_VW
                    WHERE CPT_CARD_NO --= GETHASH(P_CARD_NO)
                      IN
                      (SELECT CAP_PAN_CODE
                      FROM cms_appl_pan
                      WHERE CAP_ACCT_NO =
                        (SELECT CAP_ACCT_NO
                        FROM CMS_APPL_PAN
                        WHERE CAP_PAN_CODE = GETHASH (P_CARD_NO) --Added by Ramesh.A on 11/10/2012
                        AND CAP_MBR_NUMB   = P_MBR_NUMB
                        )
                      )
                    AND CPT_EXPIRY_FLAG       = 'N' --Modified by Ramesh.A  on 24/07/2012
                    AND cpt_totalhold_amt     > 0   --Modified for FSS 837
                    AND CPT_PREAUTH_VALIDFLAG = 'Y';
                  END IF;
                  --Sn Added for FWR-42
                  IF p_txn_code IN (
                    /*'04','12','17',*/
                    '28') AND p_delivery_channel IN ('07'
                    /*, '10'*/
                    ) -- condition modified for FWR-removal
                    THEN
                    BEGIN
                      OPEN c_pre_auth_det_1 (v_mon_year_temp,V_ACCT_NUMBER);
                      LOOP
                        FETCH c_pre_auth_det_1 INTO v_pre_auth_det_val;
                        DBMS_OUTPUT.PUT_LINE ( 'v_pre_auth_det_val = ' || v_pre_auth_det_val);
                        EXIT
                      WHEN c_pre_auth_det_1%NOTFOUND;
                        v_pre_auth_det := v_pre_auth_det || ' || ' || v_pre_auth_det_val;
                        p_pending_cnt  := p_pending_cnt + 1;
                        DBMS_OUTPUT.PUT_LINE ('p_pending_cnt = ' || p_pending_cnt);
                      END LOOP;
                      CLOSE c_pre_auth_det_1;
                    EXCEPTION
                    WHEN OTHERS THEN
                      v_err_msg  := 'Problem while selecting data from C_PRE_AUTH_DET cursor' || SUBSTR (SQLERRM, 1, 300);
                      v_resp_cde := '21';
                      RAISE exp_reject_record;
                    END;
                    IF (v_pre_auth_det IS NULL) THEN
                      v_pre_auth_det   := '  ';
                    ELSE
                      v_pre_auth_det := SUBSTR (v_pre_auth_det, 5, LENGTH (v_pre_auth_det));
                    END IF;
                    p_pre_auth_det := NVL (v_pre_auth_det, ' ');
                    SELECT                                                  --NVL (SUM (cpt_totalhold_amt), '0')
                      NVL (SUM (CPT_TOTALHOLD_AMT+CPT_completion_fee), '0') --Modified for FSS 837
                    INTO p_pre_auth_hold_amt
                    FROM CMS_PREAUTH_TRANSACTION_VW
                    WHERE cpt_card_no IN
                      (SELECT cap_pan_code
                      FROM cms_appl_pan
                      WHERE cap_acct_no =
                        (SELECT cap_acct_no
                        FROM cms_appl_pan
                        WHERE cap_pan_code = gethash (p_card_no)
                        AND cap_mbr_numb   = p_mbr_numb
                        )
                      )
                    AND CPT_EXPIRY_FLAG       = 'N'
                    AND cpt_totalhold_amt     > 0 --Modified for FSS 837
                    AND cpt_preauth_validflag = 'Y';
                  END IF;
                  --En Added for FWR-42
                  --Modified for MVHOSt-388 on 13/06/13
                  IF P_TXN_CODE = '04' AND P_DELIVERY_CHANNEL IN ('07', '12') THEN --Condition modified for FWR-42
                    BEGIN
                      OPEN C_IVR_MINI_TRAN(V_ACCT_NUMBER);
                      LOOP
                        FETCH C_IVR_MINI_TRAN INTO V_MINI_STAT_VAL;
                        EXIT
                      WHEN C_IVR_MINI_TRAN%NOTFOUND;
                        V_MINI_STAT_RES := V_MINI_STAT_RES || ' | ' || V_MINI_STAT_VAL;
                      END LOOP;
                      CLOSE C_IVR_MINI_TRAN;
                    EXCEPTION
                    WHEN OTHERS THEN
                      V_ERR_MSG  := 'Problem while selecting data from C_IVR_MINI_TRAN cursor' || SUBSTR (SQLERRM, 1, 300);
                      V_RESP_CDE := '21';
                      RAISE EXP_REJECT_RECORD;
                    END;
                    IF (V_MINI_STAT_RES IS NULL) THEN
                      V_MINI_STAT_RES   := ' ';
                    ELSE
                      V_MINI_STAT_RES := SUBSTR (V_MINI_STAT_RES, 3, LENGTH (V_MINI_STAT_RES));
                    END IF;
                  END IF;
                  --ST :Added for MVHOST-388 on 20/06/2013
                  IF P_TXN_CODE IN ('14') AND P_DELIVERY_CHANNEL IN ('14') THEN
                    BEGIN
                      P_LED_BAL_AMT   := NVL (V_LEDGER_BAL, '0');   --Added by Ramesh.A on 11/10/2012
                      P_AVAIL_BAL_AMT := NVL (V_ACCT_BALANCE, '0'); --Added by Ramesh.A on 11/10/2012
                      OPEN C_MINI_TRAN_FOR_MEDAGATE (V_MON_YEAR_TEMP, V_ACCT_NUMBER);
                      LOOP
                        FETCH C_MINI_TRAN_FOR_MEDAGATE
                        INTO v_tran_amount,
                          v_tran_type,
                          V_MINI_STAT_VAL; --Updated by Ramesh.A on 11/10/2012
                        EXIT
                      WHEN C_MINI_TRAN_FOR_MEDAGATE%NOTFOUND;
                        V_MINI_STAT_RES := V_MINI_STAT_RES || ' || ' || V_MINI_STAT_VAL;
                        --Added by Ramesh.A on 11/10/2012
                        IF v_tran_type    = 'DR' THEN
                          P_TOT_DR_AMT   := P_TOT_DR_AMT + v_tran_amount;
                        ELSIF v_tran_type = 'CR' THEN
                          P_TOT_CR_AMT   := P_TOT_CR_AMT + v_tran_amount;
                        END IF;
                        --End
                      END LOOP;
                      CLOSE C_MINI_TRAN_FOR_MEDAGATE;
                    EXCEPTION
                    WHEN OTHERS THEN
                      V_ERR_MSG  := 'Problem while selecting data from C_MINI_TRAN_FOR_MEDAGATE cursor' || SUBSTR (SQLERRM, 1, 300);
                      V_RESP_CDE := '21';
                      RAISE EXP_REJECT_RECORD;
                    END;
                    IF (V_MINI_STAT_RES IS NULL) THEN
                      V_MINI_STAT_RES   := ' ';
                    ELSE
                      V_MINI_STAT_RES := SUBSTR (V_MINI_STAT_RES, 5, LENGTH (V_MINI_STAT_RES));
                    END IF;
                  ELSE
                    P_RESP_MSG := TO_CHAR (V_UPD_AMT);
                  END IF;
                  --END: Added for MVHOST-388 on 20/06/2013
                END IF;
                -- added for mini statement
                --En create detail fro response message
                --Sn mini statement
                IF V_OUTPUT_TYPE = 'M' THEN
                  --Mini statement
                  BEGIN
                    SP_GEN_MINI_STMT (P_INST_CODE, P_CARD_NO, V_MINI_TOTREC, V_MINISTMT_OUTPUT, V_MINISTMT_ERRMSG);
                    IF V_MINISTMT_ERRMSG <> 'OK' THEN
                      V_ERR_MSG          := V_MINISTMT_ERRMSG;
                      V_RESP_CDE         := '21';
                      RAISE EXP_REJECT_RECORD;
                    END IF;
                    P_RESP_MSG := LPAD (TO_CHAR (V_MINI_TOTREC), 2, '0') || V_MINISTMT_OUTPUT;
                  EXCEPTION
                  WHEN EXP_REJECT_RECORD THEN
                    RAISE;
                  WHEN OTHERS THEN
                    V_ERR_MSG  := 'Problem while selecting data for mini statement ' || SUBSTR (SQLERRM, 1, 300);
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
                    IF P_TXN_CODE             = '11' AND P_MSG = '0100' THEN
                      IF P_PREAUTH_EXPPERIOD IS NULL THEN
                        SELECT CPM_PRE_AUTH_EXP_DATE
                        INTO V_PREAUTH_EXP_PERIOD
                        FROM CMS_PROD_MAST
                        WHERE CPM_PROD_CODE      = V_PROD_CODE;
                        IF V_PREAUTH_EXP_PERIOD IS NULL THEN
                          SELECT CIP_PARAM_VALUE
                          INTO V_PREAUTH_EXP_PERIOD
                          FROM CMS_INST_PARAM
                          WHERE CIP_INST_CODE = P_INST_CODE
                          AND CIP_PARAM_KEY   = 'PRE-AUTH EXP PERIOD';
                          V_PREAUTH_HOLD     := SUBSTR (TRIM (V_PREAUTH_EXP_PERIOD), 1, 1);
                          V_PREAUTH_PERIOD   := SUBSTR (TRIM (V_PREAUTH_EXP_PERIOD), 2, 2);
                        ELSE
                          V_PREAUTH_HOLD   := SUBSTR (TRIM (V_PREAUTH_EXP_PERIOD), 1, 1);
                          V_PREAUTH_PERIOD := SUBSTR (TRIM (V_PREAUTH_EXP_PERIOD), 2, 2);
                        END IF;
                      ELSE
                        V_PREAUTH_HOLD     := SUBSTR (TRIM (P_PREAUTH_EXPPERIOD), 1, 1);
                        V_PREAUTH_PERIOD   := SUBSTR (TRIM (P_PREAUTH_EXPPERIOD), 2, 2);
                        IF V_PREAUTH_PERIOD = '00' THEN
                          SELECT CPM_PRE_AUTH_EXP_DATE
                          INTO V_PREAUTH_EXP_PERIOD
                          FROM CMS_PROD_MAST
                          WHERE CPM_PROD_CODE      = V_PROD_CODE;
                          IF V_PREAUTH_EXP_PERIOD IS NULL THEN
                            SELECT CIP_PARAM_VALUE
                            INTO V_PREAUTH_EXP_PERIOD
                            FROM CMS_INST_PARAM
                            WHERE CIP_INST_CODE = P_INST_CODE
                            AND CIP_PARAM_KEY   = 'PRE-AUTH EXP PERIOD';
                            V_PREAUTH_HOLD     := SUBSTR (TRIM (V_PREAUTH_EXP_PERIOD), 1, 1);
                            V_PREAUTH_PERIOD   := SUBSTR (TRIM (V_PREAUTH_EXP_PERIOD), 2, 2);
                          ELSE
                            V_PREAUTH_HOLD   := SUBSTR (TRIM (V_PREAUTH_EXP_PERIOD), 1, 1);
                            V_PREAUTH_PERIOD := SUBSTR (TRIM (V_PREAUTH_EXP_PERIOD), 2, 2);
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
                      */
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
                    V_ERR_MSG  := 'Problem while inserting preauth transaction details' || SUBSTR (SQLERRM, 1, 300);
                    RAISE EXP_REJECT_RECORD;
                  END;
                  IF V_RESP_CDE = '1' THEN
                    --Sn find business date
                    V_BUSINESS_TIME   := TO_CHAR (V_TRAN_DATE, 'HH24:MI');
                    IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
                      V_BUSINESS_DATE := TRUNC (V_TRAN_DATE) + 1;
                    ELSE
                      V_BUSINESS_DATE := TRUNC (V_TRAN_DATE);
                    END IF;
                    --En find businesses date
                    --Sn-commented for fwr-48
                    /*        BEGIN
                    SP_CREATE_GL_ENTRIES_CMSAUTH (P_INST_CODE,
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
                    IF V_GL_ERR_MSG <> 'OK' OR V_GL_UPD_FLAG <> 'Y'
                    THEN
                    V_GL_UPD_FLAG := 'N';
                    P_RESP_CODE := V_RESP_CDE;
                    V_ERR_MSG := V_GL_ERR_MSG;
                    RAISE EXP_REJECT_RECORD;
                    END IF;
                    EXCEPTION
                    WHEN OTHERS
                    THEN
                    V_GL_UPD_FLAG := 'N';
                    P_RESP_CODE := V_RESP_CDE;
                    V_ERR_MSG := V_GL_ERR_MSG;
                    RAISE EXP_REJECT_RECORD;
                    END;*/
                    --En-commented for fwr-48
                    --Sn find prod code and card type and available balance for the card number

                    BEGIN
                      SELECT CAM_ACCT_BAL,
                        CAM_LEDGER_BAL --Added by Ramesh.A on 23/07/2012
                      INTO V_ACCT_BALANCE,
                        V_LEDGER_BAL --Added by Ramesh.A on 23/07/2012
                      FROM CMS_ACCT_MAST
                      WHERE CAM_ACCT_NO =
                        (SELECT CAP_ACCT_NO
                        FROM CMS_APPL_PAN
                        WHERE CAP_PAN_CODE = V_HASH_PAN
                        AND CAP_MBR_NUMB   = P_MBR_NUMB
                        AND CAP_INST_CODE  = P_INST_CODE
                        )
                      AND CAM_INST_CODE = P_INST_CODE ;  -- FOR UPDATE NOWAIT    Removed 'FOR UPDATE' for JIRA FSS-5224;
                    EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      V_RESP_CDE := '14'; --Ineligible Transaction
                      V_ERR_MSG  := 'Invalid Card ';
                      RAISE EXP_REJECT_RECORD;
                    WHEN OTHERS THEN
                      V_RESP_CDE := '12';
                      V_ERR_MSG  := 'Error while selecting data from card Master for card number ' || SQLERRM;
                      RAISE EXP_REJECT_RECORD;
                    END;
                    --En find prod code and card type for the card number
                    IF V_OUTPUT_TYPE = 'N' THEN
                      --Balance Inquiry
                      IF P_TXN_CODE = '10' AND P_DELIVERY_CHANNEL = '10' THEN
                        BEGIN -- SN: Begin block added with exception handling for defect MVHOST-346
                          SELECT DECODE(V_ENCRYPT_ENABLE,'Y', FN_DMAPS_MAIN(CCM.CCM_FIRST_NAME),CCM.CCM_FIRST_NAME),
                                 NVL (DECODE(V_ENCRYPT_ENABLE,'Y', FN_DMAPS_MAIN(CCM.CCM_MID_NAME),CCM.CCM_MID_NAME), ' '),
                                 DECODE(V_ENCRYPT_ENABLE,'Y', FN_DMAPS_MAIN(CCM.CCM_LAST_NAME),CCM.CCM_LAST_NAME),
                                 CAP.CAP_ACCT_NO,
                                 ' ' ,
                                 ' '
                          INTO P_TOT_DR_AMT,
                            P_TOT_CR_AMT,
                            P_PRE_AUTH_HOLD_AMT,
                            P_LED_BAL_AMT,
                            P_AVAIL_BAL_AMT ,
                            P_PRE_AUTH_DET
                          FROM CMS_APPL_PAN CAP,
                            CMS_CUST_MAST CCM
                          WHERE CAP.CAP_INST_CODE = CCM.CCM_INST_CODE
                          AND CAP.CAP_CUST_CODE   = CCM.CCM_CUST_CODE
                          AND CAP.CAP_PAN_CODE    = V_HASH_PAN;
                        EXCEPTION
                        WHEN OTHERS THEN
                          V_RESP_CDE := '12';
                          V_ERR_MSG  := 'Error while selecting data from cust master and card Master ' || SUBSTR (SQLERRM, 1, 100);
                          RAISE EXP_REJECT_RECORD;
                        END; -- EN : Begin block added with exception handling for defect MVHOST-346
                      ELSIF P_TXN_CODE IN ('12', '17') AND P_DELIVERY_CHANNEL = '10' THEN
                        BEGIN
                          BEGIN
                            OPEN C_ACC_STAT;
                            LOOP
                              FETCH C_ACC_STAT INTO V_PRE_AUTH_DET_VAL;
                              EXIT
                            WHEN C_ACC_STAT%NOTFOUND;
                              V_PRE_AUTH_DET := V_PRE_AUTH_DET || ' || ' || V_PRE_AUTH_DET_VAL;
                            END LOOP;
                            CLOSE C_ACC_STAT;
                          EXCEPTION
                          WHEN OTHERS THEN
                            V_ERR_MSG  := 'Problem while selecting data from C_ACC_STAT cursor' || SUBSTR (SQLERRM, 1, 300);
                            V_RESP_CDE := '21';
                            RAISE EXP_REJECT_RECORD;
                          END;
                          IF (V_PRE_AUTH_DET IS NULL) THEN
                            V_PRE_AUTH_DET   := '  ';
                          ELSE
                            V_PRE_AUTH_DET := SUBSTR (V_PRE_AUTH_DET, 5, LENGTH (V_PRE_AUTH_DET));
                          END IF;
                          P_RESP_MSG         := NVL (V_PRE_AUTH_DET, ' ');
                          V_MONTH_DET        := NVL (V_PRE_AUTH_DET, ' ');
                          V_PRE_AUTH_DET     := '';
                          V_PRE_AUTH_DET_VAL := '';
                          SELECT NVL (SUM (CSL_TRANS_AMOUNT), 0)
                          INTO P_TOT_CR_AMT
                          FROM CMS_STATEMENTS_LOG_VW
                          WHERE CSL_PAN_NO                       = V_HASH_PAN
                          AND TO_CHAR (CSL_TRANS_DATE, 'MMYYYY') = V_MON_YEAR_TEMP
                          AND CSL_TRANS_TYPE                     = 'CR';
                          SELECT NVL (SUM (CSL_TRANS_AMOUNT), 0)
                          INTO P_TOT_DR_AMT
                          FROM CMS_STATEMENTS_LOG_VW
                          WHERE CSL_PAN_NO                       = V_HASH_PAN
                          AND TO_CHAR (CSL_TRANS_DATE, 'MMYYYY') = V_MON_YEAR_TEMP
                          AND CSL_TRANS_TYPE                     = 'DR';
                          P_LED_BAL_AMT                         := NVL (V_LEDGER_BAL, '0');
                          P_AVAIL_BAL_AMT                       := NVL (V_ACCT_BALANCE, '0');
                          IF P_TXN_CODE                          = '17' AND P_DELIVERY_CHANNEL = '10' THEN
                            BEGIN
                              OPEN C_PRE_AUTH__MONTH_DET;
                              LOOP
                                FETCH C_PRE_AUTH__MONTH_DET INTO V_PRE_AUTH_DET_VAL;
                                EXIT
                              WHEN C_PRE_AUTH__MONTH_DET%NOTFOUND;
                                V_PRE_AUTH_DET := V_PRE_AUTH_DET || ' || ' || V_PRE_AUTH_DET_VAL;
                              END LOOP;
                              CLOSE C_PRE_AUTH__MONTH_DET;
                            EXCEPTION
                            WHEN OTHERS THEN
                              V_ERR_MSG  := 'Problem while selecting data from C_PRE_AUTH__MONTH_DET cursor' || SUBSTR (SQLERRM, 1, 300);
                              V_RESP_CDE := '21';
                              RAISE EXP_REJECT_RECORD;
                            END;
                            IF (V_PRE_AUTH_DET IS NULL) THEN
                              V_PRE_AUTH_DET   := '  ';
                            ELSE
                              V_PRE_AUTH_DET := SUBSTR (V_PRE_AUTH_DET, 5, LENGTH (V_PRE_AUTH_DET));
                            END IF;
                            P_PRE_AUTH_DET := NVL (V_PRE_AUTH_DET, ' ');
                            SELECT                                                 --NVL (SUM (CPT_TOTALHOLD_AMT), '0')
                              NVL (SUM (CPT_TOTALHOLD_AMT+CPT_completion_fee), '0')--Modified for FSS 837
                            INTO P_PRE_AUTH_HOLD_AMT
                            FROM CMS_PREAUTH_TRANSACTION_VW
                            WHERE CPT_CARD_NO     = GETHASH (P_CARD_NO)
                            AND cpt_totalhold_amt > 0 --Modified for FSS 837
                            AND CPT_EXPIRY_FLAG   = 'N';
                          END IF;
                        EXCEPTION
                        WHEN OTHERS THEN
                          P_RESP_MSG := 'Error occured  ' || SQLERRM;
                        END;
                      END IF;
                    ELSE
                      P_RESP_MSG := TO_CHAR (V_UPD_AMT);
                    END IF;
                  END IF;
                  --En create GL ENTRIES
                  /*  ---Sn Updation of Usage limit and amount   Commented  by Besky on 20/12/12 for defect id : 9709
                  BEGIN
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
                  V_ERR_MSG    := 'Cannot get the Transaction Limit Details of the Card' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
                  V_RESP_CDE := '21';
                  RAISE EXP_REJECT_RECORD;
                  WHEN OTHERS THEN
                  V_ERR_MSG    := 'Error while selecting 1 CMS_TRANSLIMIT_CHECK' ||
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
                  SET CTC_ATMUSAGE_AMT   = V_ATM_USAGEAMNT,
                  CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT,
                  CTC_POSUSAGE_AMT  = 0,
                  CTC_POSUSAGE_LIMIT = 0,
                  CTC_PREAUTHUSAGE_LIMIT = 0,
                  CTC_BUSINESS_DATE     = TO_DATE(P_TRAN_DATE ||
                  '23:59:59',
                  'yymmdd' ||
                  'hh24:mi:ss'),
                  CTC_MMPOSUSAGE_AMT = 0,
                  CTC_MMPOSUSAGE_LIMIT    = 0
                  WHERE CTC_INST_CODE = P_INST_CODE AND
                  CTC_PAN_CODE = V_HASH_PAN AND
                  CTC_MBR_NUMB = P_MBR_NUMB;
                  IF SQL%ROWCOUNT = 0 THEN
                  V_ERR_MSG := 'Error while updating 1 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
                  V_RESP_CDE := '21';
                  RAISE EXP_REJECT_RECORD;
                  END IF;
                  EXCEPTION
                  WHEN OTHERS THEN
                  V_ERR_MSG := 'Error while updating 1 CMS_TRANSLIMIT_CHECK' ||
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
                  SET CTC_ATMUSAGE_AMT = V_ATM_USAGEAMNT,
                  CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
                  WHERE CTC_INST_CODE = P_INST_CODE AND
                  CTC_PAN_CODE = V_HASH_PAN AND
                  CTC_MBR_NUMB = P_MBR_NUMB;
                  IF SQL%ROWCOUNT = 0 THEN
                  V_ERR_MSG := 'Error while updating 2 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
                  V_RESP_CDE := '21';
                  RAISE EXP_REJECT_RECORD;
                  END IF;
                  EXCEPTION
                  WHEN OTHERS THEN
                  V_ERR_MSG := 'Error while updating 2 CMS_TRANSLIMIT_CHECK' ||
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
                  V_POS_USAGEAMNT := 0;
                  ELSE
                  V_PREAUTH_USAGE_LIMIT := 0;
                  END IF;
                  BEGIN
                  UPDATE CMS_TRANSLIMIT_CHECK
                  SET CTC_POSUSAGE_AMT   = V_POS_USAGEAMNT,
                  CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT,
                  CTC_ATMUSAGE_AMT  = 0,
                  CTC_ATMUSAGE_LIMIT = 0,
                  CTC_BUSINESS_DATE     = TO_DATE(P_TRAN_DATE ||
                  '23:59:59',
                  'yymmdd' ||
                  'hh24:mi:ss'),
                  CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT,
                  CTC_MMPOSUSAGE_AMT = 0,
                  CTC_MMPOSUSAGE_LIMIT    = 0
                  WHERE CTC_INST_CODE = P_INST_CODE AND
                  CTC_PAN_CODE = V_HASH_PAN AND
                  CTC_MBR_NUMB = P_MBR_NUMB;
                  IF SQL%ROWCOUNT = 0 THEN
                  V_ERR_MSG := 'Error while updating 3 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
                  V_RESP_CDE := '21';
                  RAISE EXP_REJECT_RECORD;
                  END IF;
                  EXCEPTION
                  WHEN OTHERS THEN
                  V_ERR_MSG := 'Error while updating 3 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
                  V_RESP_CDE := '21';
                  RAISE EXP_REJECT_RECORD;
                  END;
                  ELSE
                  V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;
                  IF P_TXN_CODE = '11' AND P_MSG = '0100' THEN
                  V_PREAUTH_USAGE_LIMIT := V_PREAUTH_USAGE_LIMIT + 1;
                  V_POS_USAGEAMNT := V_POS_USAGEAMNT;
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
                  SET CTC_POSUSAGE_AMT   = V_POS_USAGEAMNT,
                  CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT,
                  CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
                  WHERE CTC_INST_CODE = P_INST_CODE AND
                  CTC_PAN_CODE = V_HASH_PAN AND
                  CTC_MBR_NUMB = P_MBR_NUMB;
                  IF SQL%ROWCOUNT = 0 THEN
                  V_ERR_MSG := 'Error while updating 4 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
                  V_RESP_CDE := '21';
                  RAISE EXP_REJECT_RECORD;
                  END IF;
                  EXCEPTION
                  WHEN OTHERS THEN
                  V_ERR_MSG := 'Error while updating 4 CMS_TRANSLIMIT_CHECK' ||
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
                  SET CTC_MMPOSUSAGE_AMT = V_MMPOS_USAGEAMNT,
                  CTC_MMPOSUSAGE_LIMIT    = V_MMPOS_USAGELIMIT,
                  CTC_ATMUSAGE_AMT  = 0,
                  CTC_ATMUSAGE_LIMIT = 0,
                  CTC_BUSINESS_DATE     = TO_DATE(P_TRAN_DATE ||
                  '23:59:59',
                  'yymmdd' ||
                  'hh24:mi:ss'),
                  CTC_PREAUTHUSAGE_LIMIT = 0,
                  CTC_POSUSAGE_AMT  = 0,
                  CTC_POSUSAGE_LIMIT = 0
                  WHERE CTC_INST_CODE = P_INST_CODE AND
                  CTC_PAN_CODE = V_HASH_PAN AND
                  CTC_MBR_NUMB = P_MBR_NUMB;
                  IF SQL%ROWCOUNT = 0 THEN
                  V_ERR_MSG := 'Error while updating 5 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
                  V_RESP_CDE := '21';
                  RAISE EXP_REJECT_RECORD;
                  END IF;
                  EXCEPTION
                  WHEN OTHERS THEN
                  V_ERR_MSG := 'Error while updating 5 CMS_TRANSLIMIT_CHECK' ||
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
                  SET CTC_MMPOSUSAGE_AMT = V_MMPOS_USAGEAMNT,
                  CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
                  WHERE CTC_INST_CODE = P_INST_CODE AND
                  CTC_PAN_CODE = V_HASH_PAN AND
                  CTC_MBR_NUMB = P_MBR_NUMB;
                  IF SQL%ROWCOUNT = 0 THEN
                  V_ERR_MSG := 'Error while updating 6 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
                  V_RESP_CDE := '21';
                  RAISE EXP_REJECT_RECORD;
                  END IF;
                  EXCEPTION
                  WHEN OTHERS THEN
                  V_ERR_MSG := 'Error while updating 6 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
                  V_RESP_CDE := '21';
                  RAISE EXP_REJECT_RECORD;
                  END;
                  END IF;
                  END IF;
                  --En Usage limit and amount updation for MMPOS
                  END;*/
                  --Commented  by Besky on 20/12/12 for defect id : 9709
                END;
                ---En Updation of Usage limit and amount
                BEGIN
                  SELECT CMS_ISO_RESPCDE
                  INTO P_RESP_CODE
                  FROM CMS_RESPONSE_MAST
                  WHERE CMS_INST_CODE      = P_INST_CODE
                  AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                  AND CMS_RESPONSE_ID      = TO_NUMBER (V_RESP_CDE);
                EXCEPTION
                WHEN OTHERS THEN
                  V_ERR_MSG  := 'Problem while selecting data from response master for respose code' || V_RESP_CDE || SUBSTR (SQLERRM, 1, 300);
                  V_RESP_CDE := '21';
                  RAISE EXP_REJECT_RECORD;
                END;

                IF V_AUDIT_FLAG = 'T'		-- Modified for VMS-4097 - Remove RECENT TRANSACTION logging into TRANSACTIONLOG
                THEN
                    BEGIN
                      --Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

IF (v_Retdate>v_Retperiod)
    THEN
                      --Query modified for MVHOSt-388 on 13/06/13
                      UPDATE TRANSACTIONLOG
                      SET ANI              = P_ANI,
                        DNI                = P_DNI,
                        IPADDRESS          = P_IPADDRESS,
                        medagateref_id     = p_medagateref_id
                      WHERE RRN            = P_RRN
                      AND BUSINESS_DATE    = P_TRAN_DATE
                      AND TXN_CODE         = P_TXN_CODE
                      AND MSGTYPE          = P_MSG
                      AND BUSINESS_TIME    = P_TRAN_TIME
                      AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
             else        
               UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
                      SET ANI              = P_ANI,
                        DNI                = P_DNI,
                        IPADDRESS          = P_IPADDRESS,
                        medagateref_id     = p_medagateref_id
                      WHERE RRN            = P_RRN
                      AND BUSINESS_DATE    = P_TRAN_DATE
                      AND TXN_CODE         = P_TXN_CODE
                      AND MSGTYPE          = P_MSG
                      AND BUSINESS_TIME    = P_TRAN_TIME
                      AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; 
                end if;      

                      dbms_output.put_line ('count -' ||sql%rowcount);
                    EXCEPTION
                    WHEN OTHERS THEN
                      P_RESP_CODE := '69';
                      P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 300);
                    END;

                END IF;

                --Added by dhina for integrating sathya changes on 290712
                IF P_TXN_CODE     <> '10' AND P_DELIVERY_CHANNEL = '10' THEN
                  P_LED_BAL_AMT   := NVL (V_LEDGER_BAL, '0');   --Added by Ramesh.A on 23/07/2012
                  P_AVAIL_BAL_AMT := NVL (V_ACCT_BALANCE, '0'); --Added by Ramesh.A on 23/07/2012
                END IF;
              EXCEPTION

                --<< MAIN EXCEPTION >>
              WHEN EXP_REJECT_RECORD THEN
                ROLLBACK TO V_AUTH_SAVEPOINT;
                BEGIN
                  SELECT CAM_ACCT_BAL,
                    CAM_LEDGER_BAL,
                    CAM_ACCT_NO,
                    cam_type_code --Added for defect 10871
                  INTO V_ACCT_BALANCE,
                    V_LEDGER_BAL,
                    V_CARD_ACCT_NO,
                    v_cam_type_code --Added for defect 10871
                  FROM CMS_ACCT_MAST
                  WHERE CAM_ACCT_NO =
                    (SELECT CAP_ACCT_NO
                    FROM CMS_APPL_PAN
                    WHERE CAP_PAN_CODE = V_HASH_PAN
                    AND CAP_MBR_NUMB   = P_MBR_NUMB
                    AND CAP_INST_CODE  = P_INST_CODE
                    )
                  AND CAM_INST_CODE = P_INST_CODE;
                EXCEPTION
                WHEN OTHERS THEN
                  V_ACCT_BALANCE := 0;
                  V_LEDGER_BAL   := 0;
                END;
                /*BEGIN    Commented by Besky on 20/12/12 for defect id : 9709
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
                V_ERR_MSG := 'Cannot get the Transaction Limit Details of the Card' ||
                V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                V_ERR_MSG := 'Error while selecting 2 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END;
                BEGIN
                IF P_DELIVERY_CHANNEL = '01' THEN
                IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
                V_ATM_USAGEAMNT    := 0;
                V_ATM_USAGELIMIT := 1;
                BEGIN
                UPDATE CMS_TRANSLIMIT_CHECK
                SET CTC_ATMUSAGE_AMT    = V_ATM_USAGEAMNT,
                CTC_ATMUSAGE_LIMIT  = V_ATM_USAGELIMIT,
                CTC_POSUSAGE_AMT  = 0,
                CTC_POSUSAGE_LIMIT  = 0,
                CTC_PREAUTHUSAGE_LIMIT = 0,
                CTC_MMPOSUSAGE_AMT  = 0,
                CTC_MMPOSUSAGE_LIMIT = 0,
                CTC_BUSINESS_DATE    = TO_DATE(P_TRAN_DATE ||
                '23:59:59',
                'yymmdd' ||
                'hh24:mi:ss')
                WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN AND
                CTC_MBR_NUMB = P_MBR_NUMB;
                IF SQL%ROWCOUNT = 0 THEN
                V_ERR_MSG := 'Error while updating 7 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END IF;
                EXCEPTION
                WHEN OTHERS THEN
                V_ERR_MSG := 'Error while updating 7 CMS_TRANSLIMIT_CHECK' ||
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
                V_ERR_MSG := 'Error while updating 8 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END IF;
                EXCEPTION
                WHEN OTHERS THEN
                V_ERR_MSG := 'Error while updating 8 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END;
                END IF;
                END IF;
                IF P_DELIVERY_CHANNEL = '02' THEN
                IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
                V_POS_USAGEAMNT := 0;
                V_POS_USAGELIMIT := 1;
                V_PREAUTH_USAGE_LIMIT := 0;
                BEGIN
                UPDATE CMS_TRANSLIMIT_CHECK
                SET CTC_POSUSAGE_AMT    = V_POS_USAGEAMNT,
                CTC_POSUSAGE_LIMIT  = V_POS_USAGELIMIT,
                CTC_ATMUSAGE_AMT  = 0,
                CTC_ATMUSAGE_LIMIT  = 0,
                CTC_MMPOSUSAGE_AMT  = 0,
                CTC_MMPOSUSAGE_LIMIT = 0,
                CTC_BUSINESS_DATE    = TO_DATE(P_TRAN_DATE ||
                '23:59:59',
                'yymmdd' ||
                'hh24:mi:ss'),
                CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
                WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN AND
                CTC_MBR_NUMB = P_MBR_NUMB;
                IF SQL%ROWCOUNT = 0 THEN
                V_ERR_MSG := 'Error while updating 9 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END IF;
                EXCEPTION
                WHEN OTHERS THEN
                V_ERR_MSG := 'Error while updating 9 CMS_TRANSLIMIT_CHECK' ||
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
                V_ERR_MSG := 'Error while updating 10 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END IF;
                EXCEPTION
                WHEN OTHERS THEN
                V_ERR_MSG := 'Error while updating 10 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END;
                END IF;
                END IF;
                --Sn Usage limit updation for MMPOS
                IF P_DELIVERY_CHANNEL = '04' THEN
                IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
                V_MMPOS_USAGEAMNT := 0;
                V_MMPOS_USAGELIMIT := 1;
                BEGIN
                UPDATE CMS_TRANSLIMIT_CHECK
                SET CTC_POSUSAGE_AMT    = 0,
                CTC_POSUSAGE_LIMIT  = 0,
                CTC_ATMUSAGE_AMT  = 0,
                CTC_ATMUSAGE_LIMIT  = 0,
                CTC_MMPOSUSAGE_AMT  = V_MMPOS_USAGEAMNT,
                CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT,
                CTC_BUSINESS_DATE    = TO_DATE(P_TRAN_DATE ||
                '23:59:59',
                'yymmdd' ||
                'hh24:mi:ss'),
                CTC_PREAUTHUSAGE_LIMIT = 0
                WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN AND
                CTC_MBR_NUMB = P_MBR_NUMB;
                IF SQL%ROWCOUNT = 0 THEN
                V_ERR_MSG := 'Error while updating 11 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END IF;
                EXCEPTION
                WHEN OTHERS THEN
                V_ERR_MSG := 'Error while updating 11 CMS_TRANSLIMIT_CHECK' ||
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
                V_ERR_MSG := 'Error while updating 12 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END IF;
                EXCEPTION
                WHEN OTHERS THEN
                V_ERR_MSG := 'Error while updating 12 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END;
                END IF;
                END IF;
                --En Usage limit updation for MMPOS
                END;*/
                --Commented  by Besky on 20/12/12 for defect id : 9709
                --Sn select response code and insert record into txn log dtl
                BEGIN
                  P_RESP_CODE := V_RESP_CDE;
                  P_RESP_MSG  := V_ERR_MSG;
                  -- Assign the response code to the out parameter
                  SELECT CMS_ISO_RESPCDE
                  INTO P_RESP_CODE
                  FROM CMS_RESPONSE_MAST
                  WHERE CMS_INST_CODE      = P_INST_CODE
                  AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                  AND CMS_RESPONSE_ID      = V_RESP_CDE;
                EXCEPTION
                WHEN OTHERS THEN
                  P_RESP_MSG  := 'Problem while selecting data from response master ' || V_RESP_CDE || SUBSTR (SQLERRM, 1, 300);
                  P_RESP_CODE := '69';
                  ---ISO MESSAGE FOR DATABASE ERROR Server Declined
                  ROLLBACK;
                END;
                --Sn Commented for Transactionlog Functional Removal Phase-II changes
                /* BEGIN
                IF V_RRN_COUNT > 0
                THEN
                IF TO_NUMBER (P_DELIVERY_CHANNEL) = 8
                THEN
                BEGIN
                SELECT RESPONSE_CODE
                INTO V_RESP_CDE
                FROM TRANSACTIONLOG A,
                (SELECT MIN (ADD_INS_DATE) MINDATE
                FROM TRANSACTIONLOG
                WHERE RRN = P_RRN) B
                WHERE A.ADD_INS_DATE = MINDATE AND RRN = P_RRN;
                P_RESP_CODE := V_RESP_CDE;
                SELECT CAM_ACCT_BAL
                INTO V_ACCT_BALANCE
                FROM CMS_ACCT_MAST
                WHERE CAM_ACCT_NO =
                (SELECT CAP_ACCT_NO
                FROM CMS_APPL_PAN
                WHERE      CAP_PAN_CODE = V_HASH_PAN
                AND CAP_MBR_NUMB = P_MBR_NUMB
                AND CAP_INST_CODE = P_INST_CODE)
                AND CAM_INST_CODE = P_INST_CODE
                FOR UPDATE NOWAIT;
                V_ERR_MSG := TO_CHAR (V_ACCT_BALANCE);
                EXCEPTION
                WHEN OTHERS
                THEN
                V_ERR_MSG :=
                'Problem in selecting the response detail of Original transaction'
                || SUBSTR (SQLERRM, 1, 300);
                P_RESP_CODE := '89';                -- Server Declined
                ROLLBACK;
                --RETURN; Commented by Besky on 20/12/12 for defect id : 9709
                END;
                END IF;
                END IF;
                END;*/
                --En Commented for Transactionlog Functional Removal Phase-II changes
                IF V_AUDIT_FLAG = 'T'
                THEN

                BEGIN
                  INSERT
                  INTO CMS_TRANSACTION_LOG_DTL
                    (
                      CTD_DELIVERY_CHANNEL,
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
                      CTD_CUST_ACCT_NUMBER
                    )
                    VALUES
                    (
                      P_DELIVERY_CHANNEL,
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
                      V_ACCT_NUMBER
                    );
                  P_RESP_MSG := V_ERR_MSG;
                EXCEPTION
                WHEN OTHERS THEN
                  P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 300);
                  P_RESP_CODE := '69'; -- Server Declined
                  ROLLBACK;
                  --RETURN;
                END;

                 END IF;
                -----------------------------------------------
                --SN: Added on 20-Apr-2013 for defect 10871
                -----------------------------------------------
                IF V_PROD_CODE IS NULL THEN
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
                    WHERE CAP_INST_CODE = P_INST_CODE
                    AND CAP_PAN_CODE    = V_HASH_PAN; --P_card_no;
                  EXCEPTION
                  WHEN OTHERS THEN
                    NULL;
                  END;
                END IF;
                IF V_DR_CR_FLAG IS NULL THEN
                  BEGIN
                    SELECT CTM_CREDIT_DEBIT_FLAG,nvl(CTM_TXN_LOG_FLAG,'T')
                    INTO V_DR_CR_FLAG,V_AUDIT_FLAG
                    FROM CMS_TRANSACTION_MAST
                    WHERE CTM_TRAN_CODE      = P_TXN_CODE
                    AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                    AND CTM_INST_CODE        = P_INST_CODE;
                  EXCEPTION
                  WHEN OTHERS THEN
                    NULL;
                  END;
                END IF;
                IF v_timestamp IS NULL THEN
                  v_timestamp  := SYSTIMESTAMP; -- Added on 20-Apr-2013 for defect 10871
                END IF;
                -----------------------------------------------
                --EN: Added on 20-Apr-2013 for defect 10871
                -----------------------------------------------
              WHEN OTHERS THEN
                ROLLBACK TO V_AUTH_SAVEPOINT;
                /* BEGIN     Commented  by Besky on 20/12/12 for defect id : 9709
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
                V_ERR_MSG := 'Cannot get the Transaction Limit Details of the Card' ||
                V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                V_ERR_MSG := 'Error while selecting 3 CMS_TRANSLIMIT_CHECK' ||
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
                SET CTC_ATMUSAGE_AMT = V_ATM_USAGEAMNT,
                CTC_ATMUSAGE_LIMIT  = V_ATM_USAGELIMIT,
                CTC_POSUSAGE_AMT = 0,
                CTC_POSUSAGE_LIMIT  = 0,
                CTC_PREAUTHUSAGE_LIMIT = 0,
                CTC_MMPOSUSAGE_AMT  = 0,
                CTC_MMPOSUSAGE_LIMIT = 0,
                CTC_BUSINESS_DATE = TO_DATE(P_TRAN_DATE ||
                '23:59:59',
                'yymmdd' ||
                'hh24:mi:ss')
                WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN AND
                CTC_MBR_NUMB = P_MBR_NUMB;
                IF SQL%ROWCOUNT = 0 THEN
                V_ERR_MSG    := 'Error while updating 13 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END IF;
                EXCEPTION
                WHEN OTHERS THEN
                V_ERR_MSG    := 'Error while updating 13 CMS_TRANSLIMIT_CHECK' ||
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
                V_ERR_MSG    := 'Error while updating 14 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END IF;
                EXCEPTION
                WHEN OTHERS THEN
                V_ERR_MSG    := 'Error while updating 14 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END;
                END IF;
                END IF;
                IF P_DELIVERY_CHANNEL = '02' THEN
                IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
                V_POS_USAGEAMNT   := 0;
                V_POS_USAGELIMIT := 1;
                V_PREAUTH_USAGE_LIMIT := 0;
                BEGIN
                UPDATE CMS_TRANSLIMIT_CHECK
                SET CTC_POSUSAGE_AMT = V_POS_USAGEAMNT,
                CTC_POSUSAGE_LIMIT  = V_POS_USAGELIMIT,
                CTC_ATMUSAGE_AMT = 0,
                CTC_ATMUSAGE_LIMIT  = 0,
                CTC_MMPOSUSAGE_AMT  = 0,
                CTC_MMPOSUSAGE_LIMIT = 0,
                CTC_BUSINESS_DATE = TO_DATE(P_TRAN_DATE ||
                '23:59:59',
                'yymmdd' ||
                'hh24:mi:ss'),
                CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
                WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN AND
                CTC_MBR_NUMB = P_MBR_NUMB;
                IF SQL%ROWCOUNT = 0 THEN
                V_ERR_MSG    := 'Error while updating 15 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END IF;
                EXCEPTION
                WHEN OTHERS THEN
                V_ERR_MSG    := 'Error while updating 15 CMS_TRANSLIMIT_CHECK' ||
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
                V_ERR_MSG    := 'Error while updating 16 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END IF;
                EXCEPTION
                WHEN OTHERS THEN
                V_ERR_MSG    := 'Error while updating 16 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END;
                END IF;
                END IF;
                --Sn Usage limit updation for MMPOS
                IF P_DELIVERY_CHANNEL = '04' THEN
                IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
                V_MMPOS_USAGEAMNT := 0;
                V_MMPOS_USAGELIMIT := 1;
                BEGIN
                UPDATE CMS_TRANSLIMIT_CHECK
                SET CTC_POSUSAGE_AMT = 0,
                CTC_POSUSAGE_LIMIT  = 0,
                CTC_ATMUSAGE_AMT = 0,
                CTC_ATMUSAGE_LIMIT  = 0,
                CTC_MMPOSUSAGE_AMT  = V_MMPOS_USAGEAMNT,
                CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT,
                CTC_BUSINESS_DATE = TO_DATE(P_TRAN_DATE ||
                '23:59:59',
                'yymmdd' ||
                'hh24:mi:ss'),
                CTC_PREAUTHUSAGE_LIMIT = 0
                WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN AND
                CTC_MBR_NUMB = P_MBR_NUMB;
                IF SQL%ROWCOUNT = 0 THEN
                V_ERR_MSG    := 'Error while updating 17 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END IF;
                EXCEPTION
                WHEN OTHERS THEN
                V_ERR_MSG    := 'Error while updating 17 CMS_TRANSLIMIT_CHECK' ||
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
                V_ERR_MSG    := 'Error while updating 18 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END IF;
                EXCEPTION
                WHEN OTHERS THEN
                V_ERR_MSG    := 'Error while updating 18 CMS_TRANSLIMIT_CHECK' ||
                SUBSTR(SQLERRM, 1, 200);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
                END;
                END IF;
                END IF;
                --En Usage limit updation for MMPOS  Commented by Besky on 20/12/12 for defect id : 9709
                END;*/
                --Sn select response code and insert record into txn log dtl
                BEGIN
                  SELECT CMS_ISO_RESPCDE
                  INTO P_RESP_CODE
                  FROM CMS_RESPONSE_MAST
                  WHERE CMS_INST_CODE      = P_INST_CODE
                  AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                  AND CMS_RESPONSE_ID      = V_RESP_CDE;
                  P_RESP_MSG              := V_ERR_MSG;
                EXCEPTION
                WHEN OTHERS THEN
                  P_RESP_MSG  := 'Problem while selecting data from response master ' || V_RESP_CDE || SUBSTR (SQLERRM, 1, 300);
                  P_RESP_CODE := '69'; -- Server Declined
                  ROLLBACK;
                END;

                IF V_AUDIT_FLAG = 'T'
                THEN

                BEGIN
                  INSERT
                  INTO CMS_TRANSACTION_LOG_DTL
                    (
                      CTD_DELIVERY_CHANNEL,
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
                      CTD_CUST_ACCT_NUMBER
                    )
                    VALUES
                    (
                      P_DELIVERY_CHANNEL,
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
                      V_ACCT_NUMBER
                    );
                EXCEPTION
                WHEN OTHERS THEN
                  P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 300);
                  P_RESP_CODE := '69'; -- Server Decline Response 220509
                  ROLLBACK;
                  --RETURN; Commented by Besky on 20/12/12 for defect id : 9709
                END;

                END IF;
                --En select response code and insert record into txn log dtl
                -----------------------------------------------
                --SN: Added on 20-Apr-2013 for defect 10871
                -----------------------------------------------
                IF V_ACCT_BALANCE IS NULL THEN
                  BEGIN
                    SELECT CAM_ACCT_BAL,
                      CAM_LEDGER_BAL,
                      CAM_ACCT_NO,
                      cam_type_code --Added for defect 10871
                    INTO V_ACCT_BALANCE,
                      V_LEDGER_BAL,
                      V_CARD_ACCT_NO,
                      v_cam_type_code --Added for defect 10871
                    FROM CMS_ACCT_MAST
                    WHERE CAM_ACCT_NO =
                      (SELECT CAP_ACCT_NO
                      FROM CMS_APPL_PAN
                      WHERE CAP_PAN_CODE = V_HASH_PAN
                      AND CAP_MBR_NUMB   = P_MBR_NUMB
                      AND CAP_INST_CODE  = P_INST_CODE
                      )
                    AND CAM_INST_CODE = P_INST_CODE;
                  EXCEPTION
                  WHEN OTHERS THEN
                    V_ACCT_BALANCE := 0;
                    V_LEDGER_BAL   := 0;
                  END;
                END IF;
                IF V_PROD_CODE IS NULL THEN
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
                    WHERE CAP_INST_CODE = P_INST_CODE
                    AND CAP_PAN_CODE    = V_HASH_PAN; --P_card_no;
                  EXCEPTION
                  WHEN OTHERS THEN
                    NULL;
                  END;
                END IF;
                IF V_DR_CR_FLAG IS NULL THEN
                  BEGIN
                    SELECT CTM_CREDIT_DEBIT_FLAG,nvl(CTM_TXN_LOG_FLAG,'T')
                    INTO V_DR_CR_FLAG,V_AUDIT_FLAG
                    FROM CMS_TRANSACTION_MAST
                    WHERE CTM_TRAN_CODE      = P_TXN_CODE
                    AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                    AND CTM_INST_CODE        = P_INST_CODE;
                  EXCEPTION
                  WHEN OTHERS THEN
                    NULL;
                  END;
                END IF;
                IF v_timestamp IS NULL THEN
                  v_timestamp  := SYSTIMESTAMP; -- Added on 20-Apr-2013 for defect 10871
                END IF;
                -----------------------------------------------
                --EN: Added on 20-Apr-2013 for defect 10871
                -----------------------------------------------
              END;
              --- Sn create GL ENTRIES
              --Sn generate auth id
              BEGIN
                --  SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
                SELECT LPAD (SEQ_AUTH_ID.NEXTVAL, 6, '0')
                INTO V_AUTH_ID
                FROM DUAL;
              EXCEPTION
              WHEN OTHERS THEN
                P_RESP_MSG  := 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
                P_RESP_CODE := '21'; -- Server Declined
                ROLLBACK;
              END;
              --En generate auth id
              --Sn create a entry in txn log
              -- Modified for VMS-4097 - Remove RECENT TRANSACTION logging into TRANSACTIONLOG
              IF V_AUDIT_FLAG = 'T'
              THEN

              BEGIN
                INSERT
                INTO TRANSACTIONLOG
                  (
                    MSGTYPE,
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
                    ANI,
                    DNI,
                    IPADDRESS,
                    CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
                    FEE_PLAN,
                    FEEATTACHTYPE,  -- Added by Trivikram on 05-Sep-2012
                    MERCHANT_NAME,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                    MERCHANT_CITY,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                    MERCHANT_STATE, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                    ERROR_MSG,      -- Added by Besky on 20/12/12 for defect id : 9709
                    acct_type,      --Added for degect 10871
                    time_stamp,     --Added for degect 10871
                    medagateref_id, --Added for MVHOSt-388 on 13/06/13
                    remark --Added for error msg need to display in CSR(declined by rule)
                  )
                  VALUES
                  (
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
                    SUBSTR (P_TRAN_TIME, 1, 10),
                    V_HASH_PAN,
                    NULL,
                    NULL, --P_topup_acctno   ,
                    NULL, --P_topup_accttype,
                    P_BANK_CODE,
                    TRIM ( TO_CHAR (NVL (V_TOTAL_AMT, 0), '99999999999999990.99')), --NVL added for defect 10871
                    P_RULE_INDICATOR,
                    P_RULEGRP_ID,
                    P_MCC_CODE,
                    P_CURR_CODE,
                    NULL, -- P_add_charge,
                    V_PROD_CODE,
                    V_PROD_CATTYPE,
                    TRIM ( TO_CHAR (NVL (P_TIP_AMT, 0), '99999999999999990.99')), --NVL added for defect 10871
                    P_DECLINE_RULEID,
                    P_ATMNAME_LOC,
                    V_AUTH_ID,
                    V_NARRATION,
                    TRIM ( TO_CHAR (NVL (V_TRAN_AMT, 0), '99999999999999990.99')), --NVL added for defect 10871
                    '0.00',                                                        -- NULL replaced by 0.00 , on 20-Apr-2013 for defect 10871
                    '0.00',                                                        -- Partial amount (will be given for partial txn)  -- NULL replaced by 0.00 , on 20-Apr-2013 for defect 10871
                    P_MCCCODE_GROUPID,
                    P_CURRCODE_GROUPID,
                    P_TRANSCODE_GROUPID,
                    P_RULES,
                    P_PREAUTH_DATE,
                    V_GL_UPD_FLAG,
                    P_STAN,
                    P_INST_CODE,
                    V_FEE_CODE,
                    V_FEE_AMT,
                    NVL (V_SERVICETAX_AMOUNT, 0), --NVL added for defect 10871
                    NVL (V_CESS_AMOUNT, 0),       --NVL added for defect 10871
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
                    ROUND (NVL (V_ACCT_BALANCE, 0), 2), --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                    ROUND (NVL (V_LEDGER_BAL, 0), 2),   --Modified by Sankar S on 08-Apr-2014 for 3decimal place issue
                    V_RESP_CDE,
                    P_ANI,
                    P_DNI,
                    P_IPADDRESS,
                    V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
                    V_FEE_PLAN,         --Added by Deepa for Fee Plan on June 10 2012
                    V_FEEATTACH_TYPE,   -- Added by Trivikram on 05-Sep-2012
                    P_MERCHANT_NAME,    -- Added by Besky on 20/12/12 for defect id : 9709
                    P_MERCHANT_CITY,    -- Added by Besky on 20/12/12 for defect id : 9709
                    P_ATMNAME_LOC,      -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                    V_ERR_MSG,          -- Added by Besky on 20/12/12 for defect id : 9709
                    v_cam_type_code,    --Added for defect 10871
                    v_timestamp,        --Added for defect 10871
                    P_medagateref_id ,  --Added for MVHOSt-388 on 13/06/13
                    V_ERR_MSG           --Added for error msg need to display in CSR(declined by rule)
                  );
                P_CAPTURE_DATE := V_BUSINESS_DATE;
                P_AUTH_ID      := V_AUTH_ID;
              EXCEPTION
              WHEN OTHERS THEN
                ROLLBACK;
                P_RESP_CODE := '69'; -- Server Declione
                P_RESP_MSG  := 'Problem while inserting data into transaction log  ' || SUBSTR (SQLERRM, 1, 300);
              END;

              ELSIF V_AUDIT_FLAG = 'A'
              THEN


              	  BEGIN

                         VMSCMS.VMS_LOG.LOG_TRANSACTIONLOG_AUDIT(P_MSG,
                                                                 P_RRN,
                                                                 P_DELIVERY_CHANNEL,
                                                                 P_TXN_CODE,
                                                                 '0',
                                                                 P_TRAN_DATE,
                                                                 P_TRAN_TIME,
                                                                 '00',
                                                                 P_CARD_NO,
                                                                 V_ERR_MSG,
                                                                 V_TRAN_AMT,
                                                                 V_TOTAL_AMT,
                                                                 V_RESP_CDE,
                                                                 P_CURR_CODE,
                                                                 NULL,
                                                                 NULL,
                                                                 v_resp_out,
                                                                 NULL,
                                                                 P_IPADDRESS,
                                                                 NULL,
                                                                 CASE WHEN V_RESP_CDE = '1' THEN  'C' ELSE 'F' END,
                                                                 P_ANI,
                                                                 P_DNI,
                                                                 P_TERM_ID,
                                                                 P_BANK_CODE,
                                                                 P_ATMNAME_LOC,
                                                                 P_STAN,
                                                                 P_MERCHANT_NAME,
                                                                 P_MERCHANT_CITY,
                                                                 P_ATMNAME_LOC);



                        IF v_resp_out <> 'OK'
                        THEN
                            P_RESP_CODE := '69';
                            P_RESP_MSG := v_resp_out;

                        END IF;

                      EXCEPTION
                         WHEN OTHERS
                         THEN
							ROLLBACK;
                            P_RESP_CODE := '69';
                            P_RESP_MSG :=
                                  'Erorr while inserting to audit transaction log '
                               || SUBSTR (SQLERRM, 1, 300);

                      END;

              END IF;
              --En create a entry in txn log
              IF P_TXN_CODE     IN ('04', '12', '17', '95', '96', '14') AND P_DELIVERY_CHANNEL IN ('10', '07', '12', '04', '14') AND --Modified for MVHOSt-388 on 13/06/13
                V_MINI_STAT_RES IS NOT NULL THEN                                                                                     --Modified by Ramesh.A on 13/07/2012
                P_RESP_MSG      := V_MINI_STAT_RES;
                P_AVAIL_BAL_AMT := V_ACCT_BALANCE;
                /*
                ELSIF P_TXN_CODE IN ('12','17') AND P_DELIVERY_CHANNEL = '10' AND --Commented by Ramesh.A on 22/06/2012
                V_MINI_STAT_RES IS NOT NULL THEN
                P_RESP_MSG := V_MINI_STAT_RES;
                P_AVAIL_BAL_AMT := V_ACCT_BALANCE;
                */
                /* --Commented by Ramesh.A on 22/06/2012
                ELSIF P_TXN_CODE = '12' AND P_DELIVERY_CHANNEL IN ('10') AND
                V_MONTH_DET IS NOT NULL THEN
                P_RESP_MSG := V_MONTH_DET;
                */
              ELSIF P_TXN_CODE       = '10' AND P_DELIVERY_CHANNEL = '10' THEN
                P_RESP_MSG          := V_PROXUNUMBER; --Added for DFCTNM-26
                IF V_ROUTING_NUMBER IS NULL THEN
                  --  st Added by siva kumar on 03/07/12
                  P_ROUT_NUMBER := ' ';
                ELSE
                  P_ROUT_NUMBER := V_ROUTING_NUMBER;
                END IF; --  en Added by siva kumar on 03/07/12
              ELSIF P_RESP_MSG = 'OK' THEN
                P_RESP_MSG    := P_TXN_CODE || ':' || P_DELIVERY_CHANNEL || ' == ' || V_MINI_STAT_RES; --TO_CHAR(V_UPD_AMT); --added for response data
              END IF;
            END;
/
show error