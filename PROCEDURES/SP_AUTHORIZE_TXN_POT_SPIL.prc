CREATE OR REPLACE PROCEDURE VMSCMS.SP_AUTHORIZE_TXN_POT_SPIL (
                                             P_INST_CODE         IN NUMBER,
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
                                             P_MERCHANT_NAME     VARCHAR2,
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
                                             P_PREAUTH_DATE      DATE,
                                             P_CONSODIUM_CODE    IN VARCHAR2,
                                             P_PARTNER_CODE      IN VARCHAR2,
                                             P_EXPRY_DATE        IN VARCHAR2,
                                             P_STAN              IN VARCHAR2,
                                             P_MBR_NUMB          IN VARCHAR2,
                                             P_PREAUTH_EXPPERIOD IN VARCHAR2,
                                             P_International_Ind In Varchar2,
                                             P_RVSL_CODE         IN NUMBER,
                                             P_Tran_Cnt          In Number,
                                             P_STORE_ID          In Varchar2,--SantoshP 15 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
                                             P_AUTH_ID           OUT VARCHAR2,
                                             P_RESP_CODE         OUT VARCHAR2,
                                             P_RESP_MSG          OUT VARCHAR2,
                                             P_CAPTURE_DATE      OUT DATE) IS
  /*************************************************
     * modified by      : B.Besky
     * modified Date    : 08-OCT-12
     * modified reason  : Added IN Parameters in SP_STATUS_CHECK_GPR
     * Modified Reason  : SPIL Decline Transaction Reason displayed as 'Database Error'
     
    
     * Modified By      :  Pankaj S.
     * Modified Date    :  26-Feb-2013
     * Modified Reason  : Modified for SPIL RRN Check changes
     * Reviewer         : Dhiraj 
     * Reviewed Date    : 
     * Build Number     :  
     
     * modified by      : Sagar
     * modified Date    : 27-FEB-13
     * modified for     : Defect 10406
     * modified reason  : To ignore max card balance check 10406
     * Reviewer         : Dhiarj
     * Reviewed Date    : 27-FEB-13
     * Build Number     : CMS3.5.1_RI0023.2_B0011     
     
     * Modified By      :  Saravanakumar
     * Modified Date    :  04-Mar-2013
     * Modified Reason  : Removeed txn code from duplicate rrn check
     * Reviewer         : Dhiarj
     * Reviewed Date    : 07-Mar-2013
     * Build Number     : CMS3.5.1_RI0023.2_B0016
     
    * Modified by      : Dhinakaran B
    * Modified Reason  :  MVHOST - 346
    * Modified Date    : 20-APR-2013
    * Reviewer         :  
    * Reviewed Date    : 
    * Build Number     :  
   
    * Modified By      : Sagar M.
    * Modified Date    : 20-Apr-2013
    * Modified Reason  : Logging of below details in tranasctionlog and statementlog table
                          1) ledger balance in statementlog
                          2) Product code,Product category code,Card status,Acct Type,drcr flag
                          3) Timestamp and Amount values logging correction 
    * Reviewer         : Dhiraj
    * Reviewed Date    : 20-Apr-2013
    * Build Number     : RI0024.1_B0013

    * Modified By      : Sagar M.
    * Modified Date    : 20-Apr-2013
    * Modified Reason  : Commented exception raised while comparig card status
    * Modified for     : MVHOST-346                          
    * Reviewer         : Dhiraj
    * Reviewed Date    : 10-MAy-2013
    * Build Number     : RI0024.1_B0018

    * Modified By      : Sagar M.
    * Modified Date    : 11-May-2013
    * Modified Reason  : Below card status codes comapred to return response as "Invalid Request"
                         4  - RESTRICTED
                         5  - MONITORED
                         6  - ON HOLD
                         8  - PASSIVE
                         11 -  HOT CARDED
                         12 - SUSPENDED CREDIT
                         
    * Modified for     : Defect 0011034                          
    * Reviewer         : Dhiraj
    * Reviewed Date    : 11-MAy-2013
    * Build Number     : RI0024.1_B0023
    
     * Modified by      : Ravi N
     * Modified for        : Mantis ID 0011282
     * Modified Reason  : Correction of Insufficient balance spelling mistake 
     * Modified Date    : 20-Jun-2013
     * Reviewer         : 
     * Reviewed Date    : 
     * Build Number     : RI0024.2_B0006
     
      * Modified By      : Santosh P
      * Modified Date    : 15-Jul-2013
      * Modified Reason  : Capture StoreId in transactionlog table
      * Modified for     : FSS-1146 
      * Reviewer         : 
      * Reviewed Date    : 
      * Build Number     :  RI0024.3_B0005  
     
      * Modified by      : Anil Kumar 
      * Modified for     : JIRA ID MVCHW-454
      * Modified Reason  : Insufficient Balance for Non-financial Transactions. 
      * Modified Date    : 18-07-2013
      * Reviewer         : 
      * Reviewed Date    : 
      * Build Number     :  RI0024.3_B0005    
      
    * modified by       : Ramesh A
    * modified Date     : FEB-05-14
    * modified reason   : MVCSD-4471
    * modified reason   : 
    * Reviewer          : Dhiraj 
    * Reviewed Date     :  
    * Build Number      : RI0027.1_B0001  
    
     * Modified By      : Revathi D
     * Modified Date    : 02-APR-2014
     * Modified for     : 
     * Modified Reason  : 1.Round functions added upto 2nd decimal for amount columns in CMS_CHARGE_DTL,CMS_ACCTCLAWBACK_DTL,
                          CMS_STATEMENTS_LOG,TRANSACTIONLOG.
                          2.V_TRAN_AMT initial value assigned as zero.
     * Reviewer         : Pankaj S.
     * Reviewed Date    : 06-APR-2014
     * Build Number     : CMS3.5.1_RI0027.2_B0004
     
    * modified by       : Amudhan S
    * modified Date     : 23-may-14
    * modified for      : FWR 64 
    * modified reason   : To restrict clawback fee entries as per the configuration done by user.
    * Reviewer          : Spankaj
    * Build Number      : RI0027.3_B0001 
    
    * Modified by       : Dhinakaran B
    * Modified for      : MANTIS ID-12422(To Log the Account Type code in txnlog table)
    * Modified Date     : 08-JUL-2014
    * Reviewer          : Spankaj
    * Reviewed Date     : RI0027.3_B0003  
    
    * Modified by       : MageshKumar S.
    * Modified Date     : 25-July-14    
    * Modified For      : FWR-48
    * Modified reason   : GL Mapping removal changes
    * Reviewer          : Spankaj
    * Build Number      : RI0027.3.1_B0001
    
    * Modified by       : Siva Kumar M
    * Modified Date     : 05-Aug-15
    * Modified For      : FSS-2320
    * Reviewer          : Pankaj S
    * Build Number      : RVMSGPRHOSTCSD_3.1_B0001
    
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
	
	* Modified By      : Vini Pushkaran
    * Modified Date    : 24/11/2017
    * Purpose          : VMS-64
    * Reviewer         : Saravanankumar A
    * Release Number   : VMSGPRHOST17.12	
	
	* Modified By      : Karthick/Jey
    * Modified Date    : 05-17-2022
    * Purpose          : Archival changes.
    * Reviewer         : Venkat Singamaneni
    * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991
  *************************************************/
  V_ERR_MSG            VARCHAR2(900) := 'OK';
  V_ACCT_BALANCE       NUMBER;
  V_LEDGER_BAL         NUMBER;
  V_TRAN_AMT           NUMBER:=0;
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
  --P_ERR_MSG            VARCHAR2(500);--Commented duplicate rrn check
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
  V_PREAUTH_AMOUNT      NUMBER;
  V_PREAUTH_TXNAMOUNT   NUMBER;
  V_PREAUTH_DATE        DATE;
  V_PREAUTH_HOLD        VARCHAR2(1);
  V_PREAUTH_PERIOD      NUMBER;
  V_PREAUTH_USAGE_LIMIT NUMBER;
  V_CARD_ACCT_NO        VARCHAR2(20);
  V_HOLD_AMOUNT         NUMBER;
  V_HASH_PAN            CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN            CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  --V_RRN_COUNT           NUMBER;--Commented duplicate rrn check
  V_TRAN_TYPE           VARCHAR2(2);
  V_DATE                DATE;
  V_TIME                VARCHAR2(10);
  V_MAX_CARD_BAL        NUMBER;
  V_CURR_DATE           DATE;
  V_PREAUTH_EXP_PERIOD  VARCHAR2(10);
  V_MINI_STAT_RES       VARCHAR2(600);
  V_MINI_STAT_VAL       VARCHAR2(100);
  V_INTERNATIONAL_FLAG  cms_prod_cattype.cpc_international_check%TYPE;
  --V_TRAN_CNT            NUMBER;
  V_PROXUNUMBER         CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER         CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_AUTHID_DATE         VARCHAR2(8);
  V_STATUS_CHK          NUMBER;

  --V_MINRRNDATE      varchar2(20);--TRANSACTIONLOG.BUSINESS_DATE%TYPE;--Commented duplicate rrn check
  --V_MAXRRNDATE      varchar2(20);--TRANSACTIONLOG.BUSINESS_DATE%TYPE;--Commented duplicate rrn check
  V_DUPCHK_CARDSTAT TRANSACTIONLOG.CARDSTATUS%TYPE;
  V_DUPCHK_ACCTBAL  TRANSACTIONLOG.ACCT_BALANCE%TYPE;
  V_DUPCHK_COUNT    NUMBER;
  --Added by Deepa On June 19 2012 for Fees Changes
  V_FEEAMNT_TYPE CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
  V_PER_FEES     CMS_FEE_MAST.CFM_PER_FEES%TYPE;
  V_FLAT_FEES    CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_CLAWBACK     CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
  V_FEE_PLAN     CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;
  V_FREETXN_EXCEED VARCHAR2(1); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_DURATION VARCHAR2(20); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_FEEATTACH_TYPE  VARCHAR2(2); -- Added by Trivikram on 5th Sept 2012
  V_DUPRRN_RESP_CODE  VARCHAR2(5); --added by Pankaj S. on 26_feb_2013 for changes of SPIL RRN checks
  
  V_LOGIN_TXN       CMS_TRANSACTION_MAST.CTM_LOGIN_TXN%TYPE;  --Added For Clawback Changes (MVHOST - 346)  on 20/04/2013
  V_ACTUAL_FEE_AMNT NUMBER;                                   --Added For Clawback Changes (MVHOST - 346)  on 20/04/2013
  V_CLAWBACK_AMNT   CMS_FEE_MAST.CFM_FEE_AMT%TYPE;            --Added For Clawback Changes (MVHOST - 346)  on 20/04/2013
  V_CLAWBACK_COUNT  NUMBER;     
                                --Added For Clawback Changes (MVHOST - 346)  on 20/04/2013
  v_cam_type_code   cms_acct_mast.cam_type_code%type; -- added on 20-apr-2013 for defect 10871
  v_timestamp       timestamp;                         -- Added on 20-Apr-2013 for defect 10871      
  
  V_DUPRRN_RESP_ID  TRANSACTIONLOG.RESPONSE_ID%type;  --Added For SPIL RRN checks on 14/05/2013                        
  v_fee_desc        cms_fee_mast.cfm_fee_desc%TYPE;  -- Added for MVCSD-4471
   v_tot_clwbck_count CMS_FEE_MAST.cfm_clawback_count%TYPE; -- Added for FWR 64
  v_chrg_dtl_cnt    NUMBER;     -- Added for FWR 64
  --Sn Getting  RRN DETAILS
--Commented duplicate rrn check
  /*CURSOR C(CP_RRN IN VARCHAR2, CP_DELIV_CHNL IN VARCHAR2, --CP_TXN_CODE IN VARCHAR2, --Removeed txn code from duplicate rrn check
            CP_FRMDATE IN VARCHAR2, CP_ENDDATE IN VARCHAR2, CP_HASH_PAN IN CMS_APPL_PAN.CAP_PAN_CODE%TYPE) IS
    SELECT CARDSTATUS, ACCT_BALANCE
     FROM TRANSACTIONLOG
    WHERE RRN = CP_RRN AND CUSTOMER_CARD_NO = CP_HASH_PAN AND
         DELIVERY_CHANNEL = CP_DELIV_CHNL AND 
         --Sn Modified for Removeed txn code from duplicate rrn check
         --TXN_CODE = CP_TXN_CODE AND 
         TO_DATE(BUSINESS_DATE|| BUSINESS_TIME, 'YYYYMMDDHH24MISS') >
         TO_DATE(CP_FRMDATE, 'YYYYMMDDHH24MISS') AND
         TO_DATE(BUSINESS_DATE|| BUSINESS_TIME, 'YYYYMMDDHH24MISS') <=
         TO_DATE(CP_ENDDATE, 'YYYYMMDDHH24MISS') AND 
         --En Modified for Removeed txn code from duplicate rrn check
         BUSINESS_DATE IS NOT NULL AND
         ACCT_BALANCE IS NOT NULL;*/
/*  CURSOR C_MINI_TRAN IS
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
  --P_ERR_MSG  := 'OK';
  P_RESP_MSG := 'Success';
  

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

    --EN create encr pan


     --Sn find narration
 /*   BEGIN
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

    END; */

    --En find narration

    --Sn generate auth id
    BEGIN
     --     SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
     SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;

    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Error while generating authid ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21'; -- Server Declined
       RAISE EXP_REJECT_RECORD;
    END;

    --En generate auth id

  /*  IF P_DELIVERY_CHANNEL = '07' THEN
     IF P_TRAN_CNT IS NULL THEN

       BEGIN

        SELECT CAP_PROD_CODE
          INTO V_PROD_CODE
          FROM CMS_APPL_PAN
         WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;

        SELECT TO_NUMBER(CBP_PARAM_VALUE)
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
    BEGIN
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
    END;

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

    --Sn Duplicate RRN Check
    /* BEGIN
     SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM TRANSACTIONLOG
      WHERE RRN = P_RRN AND --Changed for admin dr cr.
           BUSINESS_DATE = P_TRAN_DATE
          and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;--Added by ramkumar.Mk on 25 march 2012
     IF V_RRN_COUNT > 0 THEN
       V_RESP_CDE := '22';
       V_ERR_MSG  := 'Duplicate RRN from the Treminal' || P_TERM_ID || 'on' ||
                  P_TRAN_DATE;
       RAISE EXP_REJECT_RECORD;
     END IF;
    END;*/
--Commented duplicate rrn check
/*
    BEGIN
     SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM TRANSACTIONLOG
      WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           --TXN_CODE = P_TXN_CODE AND --Removeed txn code from duplicate rrn check
           BUSINESS_DATE IS NOT NULL AND
           ACCT_BALANCE IS NOT NULL;

     IF V_RRN_COUNT >= 1 THEN
       BEGIN
        SELECT MIN(BUSINESS_DATE || BUSINESS_TIME),
              MAX(BUSINESS_DATE || BUSINESS_TIME)
          INTO V_MINRRNDATE, V_MAXRRNDATE
          FROM TRANSACTIONLOG
         WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
              DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
              --TXN_CODE = P_TXN_CODE AND --Removeed txn code from duplicate rrn check
              BUSINESS_DATE IS NOT NULL AND
              ACCT_BALANCE IS NOT NULL;
       EXCEPTION
        WHEN OTHERS THEN
          V_RESP_CDE := '22';
          --Sn modified by Pankaj S. on 26_Feb_2013
          --V_ERR_MSG  := 'Duplicate Incomm Reference Number:' || P_RRN;
          V_ERR_MSG  := 'Error While Fetching Business date Details for RRN:' || P_RRN;
          --En modified by Pankaj S. on 26_Feb_2013
          RAISE EXP_REJECT_RECORD;
       END;

       BEGIN
        SELECT CARDSTATUS, ACCT_BALANCE
          INTO V_DUPCHK_CARDSTAT, V_DUPCHK_ACCTBAL
          FROM TRANSACTIONLOG
         WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
              DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
              --TXN_CODE = P_TXN_CODE AND --Removeed txn code from duplicate rrn check
              TO_DATE(BUSINESS_DATE || BUSINESS_TIME, 'YYYYMMDDhh24miss') =
              TO_DATE(V_MINRRNDATE, 'YYYYMMDDhh24miss') AND
              BUSINESS_DATE IS NOT NULL AND ACCT_BALANCE IS NOT NULL;
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_RESP_CDE := '22';
          V_ERR_MSG  := 'Error While Fetchin the RRN Details-No data found:' ||
                     P_RRN;
          RAISE EXP_REJECT_RECORD;
        WHEN TOO_MANY_ROWS THEN
          V_RESP_CDE := '22';
          V_ERR_MSG  := 'Error While Fetchin the RRN Details-More than one row return:' ||
                     P_RRN;
          RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          V_RESP_CDE := '22';
          V_ERR_MSG  := 'Error While Fetchin the RRN Details-More than one row return:' ||
                     P_RRN;
          RAISE EXP_REJECT_RECORD;
       END;

       IF V_ERR_MSG = 'OK' THEN
        BEGIN
          V_DUPCHK_COUNT := 0;

          FOR I IN C(P_RRN,
                   P_DELIVERY_CHANNEL,
                   --P_TXN_CODE, --Removeed txn code from duplicate rrn check
                   V_MINRRNDATE,
                   V_MAXRRNDATE,
                   V_HASH_PAN) LOOP
            BEGIN
             IF V_DUPCHK_CARDSTAT <> I.CARDSTATUS OR
                V_DUPCHK_ACCTBAL <> I.ACCT_BALANCE THEN
               V_DUPCHK_COUNT := 2;
               EXIT WHEN V_DUPCHK_COUNT = 2;

             END IF;
            EXCEPTION
             WHEN OTHERS THEN
               V_RESP_CDE := '22';
               V_ERR_MSG  := 'Error in RRN duplicate Verification:' ||
                          P_RRN;
               RAISE EXP_REJECT_RECORD;
            END;
          END LOOP;

          IF V_ERR_MSG = 'OK' AND V_DUPCHK_COUNT = 0 THEN
            V_DUPCHK_COUNT := 1;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            V_RESP_CDE := '22';
            V_ERR_MSG  := 'Error in RRN in CURSOR selection:' || P_RRN;
            RAISE EXP_REJECT_RECORD;
        END;
       END IF;
     END IF;
    END;

    --Duplicate RRN Check
    BEGIN

     IF V_DUPCHK_COUNT = 1 THEN
       --Sn modified by Pankaj S. on 26_Feb_2013
       --V_RESP_CDE := '22';
       --V_ERR_MSG  := 'Error in RRN in CURSOR selection:' || P_RRN;
       V_RESP_CDE := '10085';
       V_ERR_MSG  := 'Duplicate Incomm Reference Number:' || P_RRN;
       --En modified by Pankaj S. on 26_Feb_2013
       RAISE EXP_REJECT_RECORD;
       --normal
     END IF;
    END;
*/
    /*elsif v_dupchk_count =2 then
    --mismatch
    end if;
     */
    --En Duplicate RRN Check

    --Sn find card detail
    BEGIN
     SELECT CAP_PROD_CODE,
           CAP_CARD_TYPE,
           CAP_EXPRY_DATE,
           CAP_CARD_STAT,
           CAP_ATM_ONLINE_LIMIT,
           CAP_POS_ONLINE_LIMIT,
           CAP_PROXY_NUMBER,
           CAP_ACCT_NO
       INTO V_PROD_CODE,
           V_PROD_CATTYPE,
           V_EXPRY_DATE,
           V_APPLPAN_CARDSTAT,
           V_ATMONLINE_LIMIT,
           V_ATMONLINE_LIMIT,
           V_PROXUNUMBER,
           V_ACCT_NUMBER
       FROM CMS_APPL_PAN
      WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
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

--Sn added duplicate rrn check.
    begin
        SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
        INTO V_DUPCHK_CARDSTAT, V_DUPCHK_ACCTBAL 
        from(SELECT CARDSTATUS, ACCT_BALANCE  FROM VMSCMS.TRANSACTIONLOG               --Added for VMS-5739/FSP-991
                WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
                DELIVERY_CHANNEL = P_DELIVERY_CHANNEL 
                and ACCT_BALANCE is not null
                order by add_ins_date desc) 
        where rownum=1;
		
		IF SQL%ROWCOUNT = 0 THEN
		SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
        INTO V_DUPCHK_CARDSTAT, V_DUPCHK_ACCTBAL 
        from(SELECT CARDSTATUS, ACCT_BALANCE  FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST             --Added for VMS-5739/FSP-991
                WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
                DELIVERY_CHANNEL = P_DELIVERY_CHANNEL 
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
            V_ERR_MSG   := 'Error while selecting card status and acct balance ' || substr(sqlerrm,1,200);
            RAISE EXP_REJECT_RECORD;
    end;

    if V_DUPCHK_COUNT =1 then
        BEGIN
            SELECT CAM_ACCT_BAL
            INTO V_ACCT_BALANCE
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO = (SELECT CAP_ACCT_NO  FROM CMS_APPL_PAN
                                WHERE CAP_PAN_CODE = V_HASH_PAN 
                                AND CAP_MBR_NUMB = P_MBR_NUMB 
                                AND CAP_INST_CODE = P_INST_CODE) AND
            CAM_INST_CODE = P_INST_CODE;
        EXCEPTION
            WHEN OTHERS THEN
                V_RESP_CDE := '12';
                V_ERR_MSG   := 'Error while selecting acct balance ' ||substr(sqlerrm,1,200);
                RAISE EXP_REJECT_RECORD;
        END;

        V_DUPCHK_COUNT:=0;

        if V_DUPCHK_CARDSTAT= V_APPLPAN_CARDSTAT and V_DUPCHK_ACCTBAL=V_ACCT_BALANCE then
            V_DUPCHK_COUNT:=1;
            V_RESP_CDE := '22';
            V_ERR_MSG   := 'Duplicate Incomm Reference Number' ||P_RRN;
            RAISE EXP_REJECT_RECORD;    
        end if;
    end if;
--En added duplicate rrn check.   

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
       RAISE;

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

    --Sn find debit and credit flag
    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,CTM_LOGIN_TXN,CTM_TRAN_DESC  --Added For Clawback changes (MVHOST - 346)  on 200413
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE, V_LOGIN_TXN,V_TRANS_DESC
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
                     V_PROD_CATTYPE
                     );

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

    BEGIN
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
                                         P_INTERNATIONAL_IND, --Added IN Parameters in SP_STATUS_CHECK_GPR for pos sign indicator,international indicator,mcccode by Besky on 08-oct-12
                                         NULL,
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
     END;

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
    END IF;

    --Sn check for Preauth
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
                       V_ERR_MSG);

       IF (V_RESP_CDE <> '1' OR TRIM(V_ERR_MSG) <> 'OK') THEN
        /*IF (V_RESP_CDE = '70' OR TRIM(V_ERR_MSG) <> 'OK') THEN
            V_RESP_CDE := '70';
            RAISE EXP_REJECT_RECORD;
          ELSE
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
          END IF;*/
        RAISE EXP_REJECT_RECORD; --Modified by Deepa on Apr-30-2012 for the response code change
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
    --Sn commented for fwr-48
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
    END;*/

    --En find function code attached to txn code
    --En commented for fwr-48
    --Sn find prod code and card type and available balance for the card number
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO,cam_type_code
       INTO V_ACCT_BALANCE,V_LEDGER_BAL, V_CARD_ACCT_NO ,v_cam_type_code
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN --P_card_no
                 AND CAP_MBR_NUMB = P_MBR_NUMB AND
                 CAP_INST_CODE = P_INST_CODE) AND
           CAM_INST_CODE = P_INST_CODE
        FOR UPDATE NOWAIT;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '14'; --Ineligible Transaction
       V_ERR_MSG  := 'Invalid Card '|| SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '12';
       V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                  SQLERRM;
       RAISE EXP_REJECT_RECORD;
    END;

    --En find prod code and card type for the card number

    --Sn Internation Flag check
    IF P_INTERNATIONAL_IND = '1' THEN
     BEGIN
       SELECT cpc_international_check
        INTO V_INTERNATIONAL_FLAG
        FROM cms_prod_cattype         
--Modified to retrieve from cms_prod_cattype instead of cms_bin_level_config since international transactions will be tied to product category henceforth
        WHERE cpc_inst_code = p_inst_code
          AND cpc_prod_code = v_prod_code
          AND cpc_card_type = v_prod_cattype;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_INTERNATIONAL_FLAG := 'Y';
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Error while selecting Product Category level Configuration' || SUBSTR(SQLERRM,1,200);
        RAISE EXP_REJECT_RECORD;
     END;

     IF V_INTERNATIONAL_FLAG <> 'Y' THEN
       V_RESP_CDE := '38';
       V_ERR_MSG  := 'International Transaction Not supported';
       RAISE EXP_REJECT_RECORD;
     END IF;
    END IF;

    --En Internation Flag check

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
                      NULL, --Added by Deepa for Fees Changes
                      NULL, --Added by Deepa for Fees Changes
                      V_RESP_CDE, --Added by Deepa for Fees Changes
                      P_MSG, --Added by Deepa for Fees Changes
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
                      V_CLAWBACK, --Added by Deepa for Fees Changes
                      V_FEE_PLAN, --Added by Deepa for Fees Changes
                      V_PER_FEES, --Added by Deepa for Fees Changes
                      V_FLAT_FEES, --Added by Deepa for Fees Changes
                      V_FREETXN_EXCEED, -- Added by Trivikram for logging fee of free transaction
                      V_DURATION, -- Added by Trivikram for logging fee of free transaction
                      V_FEEATTACH_TYPE, -- Added by Trivikram on Sep 05 2012
                      v_fee_desc -- Added for MVCSD-4471
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
     IF P_TXN_CODE = '11' AND P_MSG = '0100' THEN
       V_TOTAL_AMT      := V_TRAN_AMT + V_TOTAL_FEE;
       V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
       V_UPD_LEDGER_AMT := V_LEDGER_BAL - V_TOTAL_AMT;
     ELSE
       IF V_TOTAL_FEE = 0 THEN
        V_TOTAL_AMT := 0;
       ELSE
        V_TOTAL_AMT := V_TOTAL_FEE;
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
    /*   Commented For Clawback Changes (MVHOST - 346)  on 20/04/2013
    --Sn check balance
    IF V_DR_CR_FLAG NOT IN ('NA', 'CR') AND P_TXN_CODE <> '93' -- For credit transaction or Non-Financial transaction Insufficient Balance Check is not required. -- 29th June 2011
    THEN
     IF V_UPD_AMT < 0 THEN
       V_RESP_CDE := '15'; --Ineligible Transaction
       V_ERR_MSG  := 'Insufficient Balance '; -- modified by Ravi N for Mantis ID 0011282
       RAISE EXP_REJECT_RECORD;
     END IF;
    END IF;

    --En check balance   */
    
    
    --Start Clawback Changes (MVHOST - 346)  on 20/04/2013
      IF (V_DR_CR_FLAG NOT IN ('NA', 'CR') OR (V_TOTAL_FEE <> 0)) THEN  --ADDED FOR JIRA MVCHW - 454
 IF V_UPD_AMT < 0 THEN

          --IF V_LOGIN_TXN = 'Y' AND V_CLAWBACK = 'Y' V_DR_CR_FLAG NOT IN ('NA', 'CR') OR (V_TOTAL_FEE <> 0) THEN  commented for JIRA MVCHW - 454
          IF V_LOGIN_TXN = 'Y' AND V_CLAWBACK = 'Y' THEN    --ADDED FOR JIRA MVCHW - 454
               
                V_ACTUAL_FEE_AMNT := V_TOTAL_FEE;
               -- V_CLAWBACK_AMNT   := V_TOTAL_FEE - V_ACCT_BALANCE;
                -- V_FEE_AMT         := V_ACCT_BALANCE;
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
                                         --AND ccd_pan_code = v_hash_pan --Commented for FSS-4755
                                         AND ccd_acct_no = v_card_acct_no  and CCD_FEE_CODE=V_FEE_CODE 
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
                                    ROUND(V_CLAWBACK_AMNT,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                    'N',
                                    SYSDATE,
                                    SYSDATE,
                                    P_DELIVERY_CHANNEL,
                                    P_TXN_CODE,
                                    '1',
                                    '1');
                          ELSIF v_chrg_dtl_cnt < v_tot_clwbck_count then  -- Modified for fwr 64 

                                 UPDATE CMS_ACCTCLAWBACK_DTL
                                    SET CAD_CLAWBACK_AMNT = ROUND(CAD_CLAWBACK_AMNT +
                                                       V_CLAWBACK_AMNT,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
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
     END IF; -- ADDED FOR JIRA ID : MVCHW-454 
    --End  Clawback Changes (MVHOST - 346)  on 20/04/2013
    
    
        
      /*   -- Commented since same is not required as per defect 10406 
       
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
        
      */   -- Commented since same is not required as per defect 10406 

   -------------------------------------------------------------------------------------------------------------------------
   --SN: Shifted calling of SP_UPD_TRANSACTION_ACCNT_AUTH above before 0011034 changes ,to  avoid overwriting of V_RESP_CODE
   --------------------------------------------------------------------------------------------------------------------------   

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

   -------------------------------------------------------------------------------------------------------------------------
   --EN: Shifted calling of SP_UPD_TRANSACTION_ACCNT_AUTH above before 0011034 changes ,to  avoid overwriting of V_RESP_CODE
   --------------------------------------------------------------------------------------------------------------------------

    BEGIN

     IF TO_NUMBER(V_APPLPAN_CARDSTAT) = 0 THEN
       V_RESP_CDE := '8';
       

       --RAISE EXP_REJECT_RECORD; -- Commented for MVHOST-346

     ELSIF TO_NUMBER(V_APPLPAN_CARDSTAT) = 1 THEN
       V_RESP_CDE := '9';
       
       
     ELSIF TO_NUMBER(V_APPLPAN_CARDSTAT) = 9 THEN
       V_RESP_CDE := '7';
       

       --RAISE EXP_REJECT_RECORD; -- Commented for MVHOST-346
     ELSIF TO_NUMBER(V_APPLPAN_CARDSTAT) = 2 THEN
       V_RESP_CDE := '10';

       --RAISE EXP_REJECT_RECORD;  -- Commented for MVHOST-346
     ELSIF TO_NUMBER(V_APPLPAN_CARDSTAT) = 3 THEN
       V_RESP_CDE := '11';
       
       --RAISE EXP_REJECT_RECORD; -- Commented for MVHOST-346

      --Sn: Added for defect 0011034   
     
     ELSIF V_APPLPAN_CARDSTAT = '4' THEN       
     V_RESP_CDE := '127';
     
     ELSIF V_APPLPAN_CARDSTAT = '5' THEN
     V_RESP_CDE := '128';
     

     ELSIF V_APPLPAN_CARDSTAT = '6' THEN
     V_RESP_CDE := '129';
     
     
     ELSIF V_APPLPAN_CARDSTAT = '8' THEN
     V_RESP_CDE := '130';
     

     ELSIF V_APPLPAN_CARDSTAT = '11' THEN
     V_RESP_CDE := '131';
     
     
     ELSIF V_APPLPAN_CARDSTAT = '12' THEN
     V_RESP_CDE := '132';
     
      --En: Added for defect 0011034                                
        
     END IF;
     
    exception when others 
    then
       V_RESP_CDE := '21';
       v_err_msg := 'Error while comparig card status '||substr(sqlerrm,1,100); -- Added during 10871 chanegs , since error msg OK was logging even response id was <> 0
       RAISE EXP_REJECT_RECORD;    

    END;

    --Sn find narration
    BEGIN
   /*  SELECT CTM_TRAN_DESC
       INTO V_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE; */

     IF TRIM(V_TRANS_DESC) IS NOT NULL THEN

       V_NARRATION := V_TRANS_DESC || '/';

     END IF;

     IF TRIM(P_MERCHANT_NAME) IS NOT NULL THEN

       V_NARRATION := V_NARRATION || P_MERCHANT_NAME || '/';

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
    
    v_timestamp := systimestamp;              -- Added on 20-Apr-2013 for defect 10871
    
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
         CSL_MERCHANT_NAME, --Added by Deepa on 08-May-2012 to log Merchant name,city and state
         CSL_MERCHANT_CITY,
         CSL_MERCHANT_STATE,
         CSL_PANNO_LAST4DIGIT,  --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
         csl_acct_type,             -- Added on 20-Apr-2013 for defect 10871
         csl_time_stamp,            -- Added on 20-Apr-2013 for defect 10871
         csl_prod_code,csl_card_type              -- Added on 20-Apr-2013 for defect 10871
         ) 

       VALUES
        (V_HASH_PAN,
         ROUND(V_LEDGER_BAL,2),                      -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
         ROUND(V_TRAN_AMT,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
         V_DR_CR_FLAG,
         V_TRAN_DATE,
         ROUND(DECODE(V_DR_CR_FLAG,
               'DR',
               V_LEDGER_BAL - V_TRAN_AMT,   -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
               'CR',
               V_LEDGER_BAL + V_TRAN_AMT,   -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
               'NA',
               V_LEDGER_BAL), 2),              -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
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
         P_MERCHANT_NAME, --Added by Deepa on 08-May-2012 to log Merchant name,city and state
         NULL,
         P_ATMNAME_LOC,
         (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))), --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
         v_cam_type_code,   -- added on 20-Apr-2013 for defect 10871
         v_timestamp,       -- Added on 20-Apr-2013 for defect 10871
         v_prod_code,V_PROD_CATTYPE        -- Added on 20-Apr-2013 for defect 10871
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
                  V_LEDGER_BAL - V_TRAN_AMT,    -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
                  'CR',
                  V_LEDGER_BAL + V_TRAN_AMT,    -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
                  'NA',
                  V_LEDGER_BAL)                 -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
        INTO V_FEE_OPENING_BAL
        FROM DUAL;
     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '12';
        V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ;--||
                   -- P_CARD_NO;  commented for FSS-2320
        RAISE EXP_REJECT_RECORD;
     END;

     --En find fee opening balance

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
           CSL_MERCHANT_NAME, --Added by Deepa on 08-May-2012 to log Merchant name,city and state
           CSL_MERCHANT_CITY,
           CSL_MERCHANT_STATE,
           CSL_PANNO_LAST4DIGIT,      --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number  
           csl_acct_type,             -- Added on 20-Apr-2013 for defect 10871                         
           csl_time_stamp,             -- Added on 20-Apr-2013 for defect 10871
           csl_prod_code,csl_card_type              -- Added on 20-Apr-2013 for defect 10871           
           ) 
        VALUES
          (V_HASH_PAN,
           ROUND(V_FEE_OPENING_BAL,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
           ROUND(V_TOTAL_FEE,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
           'DR',
           V_TRAN_DATE,
           ROUND(V_FEE_OPENING_BAL - V_TOTAL_FEE,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
           --'Complimentary ' || V_DURATION ||' '|| V_NARRATION, -- Modified by Trivikram  on 27-July-2012 --Commented for MVCSD-4471
            v_fee_desc, -- Added for MVCSD-4471
           P_INST_CODE,
           V_ENCR_PAN,
           P_RRN,
           V_AUTH_ID,
           P_TRAN_DATE,
           P_TRAN_TIME,
           'Y',              -- Modified for MVCSD-4471
           P_DELIVERY_CHANNEL,
           P_TXN_CODE,
           V_CARD_ACCT_NO, --Added by Deepa to log the account number ,INS_DATE and INS_USER
           1,
           SYSDATE,
           P_MERCHANT_NAME, --Added by Deepa on 08-May-2012 to log Merchant name,city and state
           NULL,
           P_ATMNAME_LOC,
           (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))), --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
           v_cam_type_code,   -- added on 20-Apr-2013 for defect 10871
           v_timestamp,        -- Added on 20-Apr-2013 for defect 10871
           v_prod_code,V_PROD_CATTYPE        -- Added on 20-Apr-2013 for defect 10871
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
     --Added by Deepa for Fee Changes on June 20 2012
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
         csl_acct_type,             -- Added on 20-Apr-2013 for defect 10871                         
         csl_time_stamp,             -- Added on 20-Apr-2013 for defect 10871
         csl_prod_code,csl_card_type              -- Added on 20-Apr-2013 for defect 10871         
         )
       VALUES
        (V_HASH_PAN,
         ROUND(V_FEE_OPENING_BAL,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
         ROUND(V_FLAT_FEES,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
         'DR',
         V_TRAN_DATE,
         ROUND(V_FEE_OPENING_BAL - V_FLAT_FEES,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
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
         P_MERCHANT_NAME, --Added by Deepa on 08-May-2012 to log Merchant name,city and state
         NULL,
         P_ATMNAME_LOC,
         (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),
         v_cam_type_code,   -- Added on 20-Apr-2013 for defect 10871
         v_timestamp,        -- Added on 20-Apr-2013 for defect 10871
         v_prod_code,V_PROD_CATTYPE        -- Added on 20-Apr-2013 for defect 10871         
         );
       --En Entry for Fixed Fee
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
         CSL_PANNO_LAST4DIGIT,      --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
         csl_acct_type,             -- Added on 20-Apr-2013 for defect 10871                         
         csl_time_stamp,            -- Added on 20-Apr-2013 for defect 10871
         csl_prod_code,csl_card_type              -- Added on 20-Apr-2013 for defect 10871
         ) 
       VALUES
        (V_HASH_PAN,
         ROUND(V_FEE_OPENING_BAL,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
         ROUND(V_PER_FEES,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
         'DR',
         V_TRAN_DATE,
         ROUND(V_FEE_OPENING_BAL - V_PER_FEES,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
         --'Percetage Fee debited for ' || V_NARRATION, -- Added for MVCSD-4471
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
         P_MERCHANT_NAME, --Added by Deepa on 08-May-2012 to log Merchant name,city and state
         NULL,
         P_ATMNAME_LOC,
         (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),
         v_cam_type_code,   -- Added on 20-Apr-2013 for defect 10871
         v_timestamp,        -- Added on 20-Apr-2013 for defect 10871
         v_prod_code ,V_PROD_CATTYPE       -- Added on 20-Apr-2013 for defect 10871
         );
       --En Entry for Percentage Fee

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
           CSL_MERCHANT_NAME, --Added by Deepa on 08-May-2012 to log Merchant name,city and state
           CSL_MERCHANT_CITY,
           CSL_MERCHANT_STATE,
           CSL_PANNO_LAST4DIGIT,      --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
           csl_acct_type,             -- Added on 20-Apr-2013 for defect 10871                         
           csl_time_stamp,             -- Added on 20-Apr-2013 for defect 10871
           csl_prod_code ,csl_card_type             -- Added on 20-Apr-2013 for defect 10871
           ) 
        VALUES
          (V_HASH_PAN,
           ROUND(V_FEE_OPENING_BAL,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
           ROUND(V_FEE_AMT,2), --modified for MVHOST-346  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
           'DR',
           V_TRAN_DATE,
           ROUND(V_FEE_OPENING_BAL - V_FEE_AMT,2),    --modified for MVHOST-346  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
           --'Fee debited for ' || V_NARRATION, -- Commented for MVCSD-4471
           v_fee_desc, -- Added for MVCSD-4471
           P_INST_CODE,
           V_ENCR_PAN,
           P_RRN,
           V_AUTH_ID,
           P_TRAN_DATE,
           P_TRAN_TIME,
           'Y',                     -- Modified for MVCSD-4471
           P_DELIVERY_CHANNEL,
           P_TXN_CODE,
           V_CARD_ACCT_NO, --Added by Deepa to log the account number ,INS_DATE and INS_USER
           1,
           SYSDATE,
           P_MERCHANT_NAME, --Added by Deepa on 08-May-2012 to log Merchant name,city and state
           NULL,
           P_ATMNAME_LOC,
           (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),    --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
           v_cam_type_code,   -- Added on 20-Apr-2013 for defect 10871
           v_timestamp,        -- Added on 20-Apr-2013 for defect 10871
           v_prod_code,V_PROD_CATTYPE        -- Added on 20-Apr-2013 for defect 10871
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
                       ROUND(V_CLAWBACK_AMNT,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                       V_FEE_CRACCT_NO,
                       V_ENCR_PAN,
                       P_RRN,
                       V_TRAN_DATE,
                       'T',
                       'C',
                       V_CLAWBACK,
                       P_INST_CODE,
                       V_FEE_CODE,
                       ROUND(V_ACTUAL_FEE_AMNT,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                       V_FEE_PLAN,
                       P_DELIVERY_CHANNEL,
                       P_TXN_CODE,
                       ROUND(V_FEE_AMT,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
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
        CTD_INTERNATION_IND_RESPONSE)
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
        P_INTERNATIONAL_IND);
     --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while inserting  data in to CMS_TRANSACTION_LOG_DTL ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

    --En create a entry for successful
    ---Sn update daily and weekly transcounter  and amount
    BEGIN
     /*SELECT CAT_PAN_CODE
       INTO V_AVAIL_PAN
       FROM CMS_AVAIL_TRANS
      WHERE CAT_PAN_CODE = V_HASH_PAN
           AND CAT_TRAN_CODE = P_TXN_CODE AND
           CAT_TRAN_MODE = P_TXN_MODE;*/

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

     /*
      IF SQL%ROWCOUNT = 0 THEN
        V_ERR_MSG  := 'Problem while updating data in avail trans ' ||
                   SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
      END IF;
      */
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from avail trans ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

    --En update daily and weekly transaction counter and amount
    --Sn create detail for response message
    -- added for mini statement
    IF V_OUTPUT_TYPE = 'B' THEN
     --Balance Inquiry
     NULL;
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
    --V_RESP_CDE := '1'; -- Commented during defect 0011034 changes becase V_RESP_CODE overwrites 0011034 related ccode   

    BEGIN
     --Add for PreAuth Transaction of CMSAuth;
     --Sn creating entries for preauth txn
     --if incoming message not contains checking for prod preauth expiry period
     --if preauth expiry period is not configured checking for instution expirty period
     BEGIN
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
        V_ERR_MSG  := 'Problem while inserting preauth transaction details' ||
                    SUBSTR(SQLERRM, 1, 300);
        RAISE EXP_REJECT_RECORD;
     END;

     IF V_RESP_CDE = '1' THEN
       --Sn find business date
       V_BUSINESS_TIME := TO_CHAR(V_TRAN_DATE, 'HH24:MI');

       IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
        V_BUSINESS_DATE := TRUNC(V_TRAN_DATE) + 1;
       ELSE
        V_BUSINESS_DATE := TRUNC(V_TRAN_DATE);
       END IF;

       --En find businesses date
       
       --Sn commented for fwr-48
    /*   BEGIN
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
       END; */
       
       --En commented for fwr-48

       
       IF V_OUTPUT_TYPE = 'N' THEN
        --Balance Inquiry
        NULL;

       END IF;
     END IF;

     --En create GL ENTRIES
     
     
     ----------------------------------------------------------------------------------------------------------------------------------------
     --SN: Query taken outside of above If Condition (IF v_resp_cde = 1) during 0011034 changes so that proper balance will get log in txnlog
     -----------------------------------------------------------------------------------------------------------------------------------------
      --Sn find prod code and card type and available balance for the card number
       BEGIN
        SELECT CAM_ACCT_BAL
          INTO V_ACCT_BALANCE
          FROM CMS_ACCT_MAST
         WHERE CAM_ACCT_NO =
              (SELECT CAP_ACCT_NO
                FROM CMS_APPL_PAN
                WHERE CAP_PAN_CODE = V_HASH_PAN AND
                    CAP_MBR_NUMB = P_MBR_NUMB AND
                    CAP_INST_CODE = P_INST_CODE) AND
              CAM_INST_CODE = P_INST_CODE
           FOR UPDATE NOWAIT;
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
     ----------------------------------------------------------------------------------------------------------------------------------------
     --EN: Query taken outside of above If Condition (IF v_resp_cde = 1) during 0011034 changes so that proper balance will get log in txnlog
     -----------------------------------------------------------------------------------------------------------------------------------------            

     ---Sn Updation of Usage limit and amount
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
        V_ERR_MSG  := 'Cannot get the Transaction Limit Details of the Card' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERR_MSG  := 'Error while selecting CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 1 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 1 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 2 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 2 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 3 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 3 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 4 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 4 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 5 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 5 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 6 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 6 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;
       --En Usage limit and amount updation for MMPOS

     END;
    END;

    ---En Updation of Usage limit and amount
    BEGIN
     IF V_RESP_CDE = 1 THEN
       V_RESP_CDE := '9';
     END IF;
    END;
    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
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
  EXCEPTION
    --<< MAIN EXCEPTION >>
    WHEN EXP_REJECT_RECORD THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
              cam_type_code                 --Added for defect 10871
        INTO V_ACCT_BALANCE, V_LEDGER_BAL,
             v_cam_type_code                --Added for defect 10871
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =
            (SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN AND
                   CAP_INST_CODE = P_INST_CODE) AND
            CAM_INST_CODE = P_INST_CODE;
     EXCEPTION
       WHEN OTHERS THEN
        V_ACCT_BALANCE := 0;
        V_LEDGER_BAL   := 0;
     END;
     BEGIN
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
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
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
             V_ERR_MSG  := 'Error while updating 7 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 7 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 8 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 8 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 9 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 9 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 10 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 10 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 11 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 11 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 12 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 12 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;
       --En Usage limit updation for MMPOS

     END;

     --Sn select response code and insert record into txn log dtl
     BEGIN
       P_RESP_CODE := V_RESP_CDE;
       P_RESP_MSG  := V_ERR_MSG;
       -- Assign the response code to the out parameter
       SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = P_INST_CODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESP_CDE;
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while selecting data from response master ' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69';
        ---ISO MESSAGE FOR DATABASE ERROR Server Declined
        ROLLBACK;
     END;

     BEGIN
       IF V_DUPCHK_COUNT > 0 THEN --Modified duplicate rrn check
        IF TO_NUMBER(P_DELIVERY_CHANNEL) = 8 THEN
          BEGIN
            SELECT RESPONSE_ID
             INTO V_DUPRRN_RESP_ID --V_RESP_CDE  --modified by Pankaj S. on 26_Feb_2013
             FROM VMSCMS.TRANSACTIONLOG_VW A,                                        --Added for VMS-5739/FSP-991
                 (SELECT MIN(ADD_INS_DATE) MINDATE
                    FROM VMSCMS.TRANSACTIONLOG_VW                                    --Added for VMS-5739/FSP-991
                   WHERE RRN = P_RRN and ACCT_BALANCE is not null) B
            WHERE A.ADD_INS_DATE = MINDATE AND RRN = P_RRN and ACCT_BALANCE is not null;
			
		
            
            --Added For SPIL RRN checks to assign the old rrn response code to this response code on 14/05/2013     
            SELECT cms_iso_respcde
              INTO V_DUPRRN_RESP_CODE
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = V_DUPRRN_RESP_ID;
            --End

            --Sn Commented by Pankaj S. on 26_Feb_2013
            /*P_RESP_CODE := V_RESP_CDE;
            SELECT CAM_ACCT_BAL
             INTO V_ACCT_BALANCE
             FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =
                 (SELECT CAP_ACCT_NO
                    FROM CMS_APPL_PAN
                   WHERE CAP_PAN_CODE = V_HASH_PAN AND
                        CAP_MBR_NUMB = P_MBR_NUMB AND
                        CAP_INST_CODE = P_INST_CODE) AND
                 CAM_INST_CODE = P_INST_CODE
              FOR UPDATE NOWAIT;*/
            --En Commented by Pankaj S. on 26_Feb_2013

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
         CTD_INTERNATION_IND_RESPONSE)
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
         P_INTERNATIONAL_IND);

     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Declined
        ROLLBACK;
        RETURN;
     END;



         -----------------------------------------------
         --SN: Added on 20-Apr-2013 for defect 10871
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
         
         if v_timestamp is null 
         then     
             v_timestamp := systimestamp;              -- Added on 20-Apr-2013 for defect 10871
         
         end if;
              
         -----------------------------------------------
         --EN: Added on 20-Apr-2013 for defect 10871
         -----------------------------------------------          
     
    WHEN OTHERS THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;

     BEGIN
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
        V_ERR_MSG  := 'Error while selecting 2 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 13 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 13 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 14 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 14 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 15 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 15 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 16 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 16 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 17 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 17 CMS_TRANSLIMIT_CHECK' ||
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
             V_ERR_MSG  := 'Error while updating 18 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 18 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;
       --En Usage limit updation for MMPOS

     END;

     --Sn select response code and insert record into txn log dtl
     BEGIN
       SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = P_INST_CODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESP_CDE;

     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while selecting data from response master ' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Declined
        ROLLBACK;
     END;
     
       -----------------------------------------------
         --SN: Added on 20-Apr-2013 for defect 10871
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
         
          --Added For Mantis ID-12422
         BEGIN
                SELECT cam_acct_bal, cam_ledger_bal,cam_type_code                       
                  INTO v_acct_balance, v_ledger_bal,v_cam_type_code                    
                  FROM cms_acct_mast
                 WHERE cam_acct_no =V_ACCT_NUMBER
                         /* (SELECT cap_acct_no
                             FROM cms_appl_pan
                            WHERE cap_pan_code = v_hash_pan
                              AND cap_inst_code = p_inst_code)*/
                   AND cam_inst_code = p_inst_code;
         EXCEPTION
                WHEN OTHERS
                THEN
                   v_acct_balance := 0;
                   v_ledger_bal := 0;
         END;
        --End
         
         
         
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
         
         if v_timestamp is null 
         then     
             v_timestamp := systimestamp;              -- Added on 20-Apr-2013 for defect 10871
         
         end if;
              
         -----------------------------------------------
         --EN: Added on 20-Apr-2013 for defect 10871
         -----------------------------------------------    

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
         CTD_INTERNATION_IND_RESPONSE)
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
         P_INTERNATIONAL_IND);
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Decline Response 220509
        ROLLBACK;
        RETURN;
     END;
     --En select response code and insert record into txn log dtl
     
     
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
      CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
      FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
      FEEATTACHTYPE, -- Added by Trivikram on 05-Sep-2012
      MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      Merchant_State,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      Error_Msg,
      Acct_Type,       --Added for defect 10871 
      Time_Stamp ,      --Added for defect 10871
      STORE_ID,  --SantoshP 15 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
      remark --Added for error msg need to display in CSR(declined by rule)
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
      DECODE(V_RESP_CDE,
            '7',
            'C',
            '8',
            'C',
            '9',
            'C',
            '10',
            'C',
            '11',
            'C',
            '127','C', --Added for defect 0011034
            '128','C', --Added for defect 0011034
            '129','C', --Added for defect 0011034
            '130','C', --Added for defect 0011034
            '132','C', --Added for defect 0011034
            '133','C', --Added for defect 0011034
            'F'),
      DECODE(V_RESP_CDE, --  Decode Added for defect MVHOST-346
            '7',
            '00',
            '8',
            '00',
            '9',
            '00',
            '10',
            '00',
            '11',
            '00', 
            '127','00',  --Added for defect 0011034
            '128','00',  --Added for defect 0011034
            '129','00',  --Added for defect 0011034
            '130','00',  --Added for defect 0011034
            '132','00',  --Added for defect 0011034
            '133','00',  --Added for defect 0011034                     
            P_RESP_CODE
            ),
      P_TRAN_DATE,
      SUBSTR(P_TRAN_TIME, 1, 10),
      V_HASH_PAN,
      NULL,
      NULL, --P_topup_acctno    ,
      NULL, --P_topup_accttype,
      P_BANK_CODE,
      TRIM(TO_CHAR(nvl(V_TOTAL_AMT,0), '99999999999999990.99')),    --NVL added for defect 10871
      NULL,
      P_RULEGRP_ID,
      P_MCC_CODE,
      P_CURR_CODE,
      NULL, -- P_add_charge,
      V_PROD_CODE,
      V_PROD_CATTYPE,
      TRIM(TO_CHAR(nvl(P_TIP_AMT,0), '99999999999999990.99')),      --TRIM(To_char added for defect 10871
      P_DECLINE_RULEID,
      P_ATMNAME_LOC,
      V_AUTH_ID,
      V_TRANS_DESC,
      TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '99999999999999990.99')),     --NVL added for defect 10871
      '0.00',                                                      -- NULL replaced by 0.00 , on 20-Apr-2013 for defect 10871
      '0.00', -- Partial amount (will be given for partial txn)    -- NULL replaced by 0.00 , on 20-Apr-2013 for defect 10871
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
      nvl(V_SERVICETAX_AMOUNT,0), --NVL added for defect 10871
      nvl(V_CESS_AMOUNT,0),       --NVL added for defect 10871
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
      ROUND(nvl(V_UPD_AMT,0),2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
      ROUND(nvl(V_UPD_LEDGER_AMT,0),2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
      P_INTERNATIONAL_IND,
      V_RESP_CDE,
      V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
      V_FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
      V_FEEATTACH_TYPE, -- Added by Trivikram on 05-Sep-2012
        P_MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      NULL,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      P_Atmname_Loc, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      V_Err_Msg,        -- changed from p_resp_msg to V_ERR_MSG for defect 10871
      V_Cam_Type_Code,   --added for defect 10871
      V_Timestamp ,       --added for defect 10871
      P_STORE_ID,  --SantoshP 15 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
      V_ERR_MSG --Added for error msg need to display in CSR(declined by rule)
      );

    DBMS_OUTPUT.PUT_LINE('AFTER INSERT IN TRANSACTIONLOG');
    P_CAPTURE_DATE := V_BUSINESS_DATE;
    P_AUTH_ID      := V_AUTH_ID;
  EXCEPTION
    WHEN OTHERS THEN
     ROLLBACK;
     P_RESP_CODE := '69'; -- Server Declione
     P_RESP_MSG  := 'Problem while inserting data into transaction log  ' ||
                 SUBSTR(SQLERRM, 1, 300);
  END;
  
   --Sn Added by Pankaj S. on 26_Feb_2013
   IF V_DUPCHK_COUNT > 0 THEN--Modified duplicate rrn check
        IF TO_NUMBER(P_DELIVERY_CHANNEL) = 8 THEN
        P_RESP_CODE:=V_DUPRRN_RESP_CODE;
   END IF;
   END IF;
   --En Added by Pankaj S. on 26_Feb_2013

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    P_RESP_CODE := '69'; -- Server Declined
    P_RESP_MSG  := 'Main exception from  authorization ' ||
                SUBSTR(SQLERRM, 1, 300);
END;

/

show error;