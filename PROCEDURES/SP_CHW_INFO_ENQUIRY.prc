set define off;
CREATE OR REPLACE PROCEDURE VMSCMS.SP_CHW_INFO_ENQUIRY (
    P_INST_CODE              IN      NUMBER,
    P_MSG                      IN      VARCHAR2,
    P_RRN                      IN      VARCHAR2,
    P_DELIVERY_CHANNEL     IN      VARCHAR2,
    P_TERM_ID                 IN      VARCHAR2,
    P_TXN_CODE                 IN      VARCHAR2,
    P_TXN_MODE                 IN      VARCHAR2,
    P_TRAN_DATE              IN      VARCHAR2,
    P_TRAN_TIME              IN      VARCHAR2,
    P_CARD_NO                 IN      VARCHAR2, 
    P_BANK_CODE              IN      VARCHAR2,
    P_TXN_AMT                 IN      NUMBER,
    P_RULE_INDICATOR         IN      VARCHAR2,
    P_RULEGRP_ID             IN      VARCHAR2,
    P_MCC_CODE                 IN      VARCHAR2,
    P_CURR_CODE              IN      VARCHAR2,
    P_PROD_ID                 IN      VARCHAR2,
    P_CATG_ID                 IN      VARCHAR2,
    P_DECLINE_RULEID         IN      VARCHAR2,
    P_ATMNAME_LOC             IN      VARCHAR2,
    P_MCCCODE_GROUPID      IN      VARCHAR2,
    P_CURRCODE_GROUPID     IN      VARCHAR2,
    P_TRANSCODE_GROUPID     IN      VARCHAR2,
    P_RULES                     IN      VARCHAR2,
    P_EXPRY_DATE             IN      VARCHAR2,
    P_STAN                     IN      VARCHAR2,
    P_MBR_NUMB                 IN      VARCHAR2,
    P_RVSL_CODE              IN      NUMBER,
    P_IPADDRESS              IN      VARCHAR2,
    P_MOBILE_NO              IN      VARCHAR2,      --Added on 12-03-2014 for FWR-43
    P_DEVICE_ID              IN      VARCHAR2,      --Added on 12-03-2014 for FWR-43
    P_RESP_CODE                  OUT VARCHAR2,
    P_RESP_MSG                     OUT VARCHAR2,
    P_AUTH_ID                     OUT VARCHAR2,
    P_ACTIVE_DATE                 OUT VARCHAR2,
    P_EXP_DATE                     OUT VARCHAR2,
    P_CARD_STATUS                 OUT VARCHAR2,
    P_LAST_USED                  OUT VARCHAR2,
    P_ADDLINEONE                 OUT VARCHAR2,
    P_ADDLINETWO                 OUT VARCHAR2,
    P_CITY                         OUT VARCHAR2,
    P_ZIP                          OUT VARCHAR2,
    P_PHONENUMBER                 OUT VARCHAR2,
    P_OTHERPHONE                 OUT VARCHAR2,
    P_STATE                         OUT VARCHAR2,
    P_COUNTRY                     OUT VARCHAR2,
    P_PHYADDLINEONE             OUT VARCHAR2,
    P_PHYADDLINETWO             OUT VARCHAR2,
    P_PHYCITY                     OUT VARCHAR2,
    P_PHYZIP                      OUT VARCHAR2,
    P_PHYPHONENUMBER             OUT VARCHAR2,
    P_PHYOTHERPHONE             OUT VARCHAR2,
    P_PHYSTATE                     OUT VARCHAR2,
    P_PHYCOUNTRY                 OUT VARCHAR2,
    P_PHYEMAIL                     OUT VARCHAR2,
    P_FIRSTNAME                  OUT VARCHAR2,
    P_LASTNAME                     OUT VARCHAR2,
    P_CAPTURE_DATE              OUT DATE,
    P_CARD_STATUS_MESG         OUT VARCHAR2, -- Added by siva kumar .m    on july 11 2012    Adding Description for Card Status.
    P_CARD4DIGT                  OUT VARCHAR2, -- Added by siva kumar .m    on july 11 2012  Adding Description for Card Status.
    P_SPENDING_ACCT_NO         OUT VARCHAR2, -- Added by siva kumar m on 24/08/2012
    P_SAVINGSS_ACCT_NO         OUT VARCHAR2,
    p_ssn_out              out     varchar2, --added for INGO changes of 3.2 release
    p_dob_out              out     varchar2, --added for INGO changes of 3.2 release
    p_disp_name_out        out     varchar2, --added for INGO changes of 3.2 release
    p_id_type_out          out     varchar2, --added for INGO changes of 3.2 release
    p_partner_id_in        in      varchar2) --added for INGO changes of 3.2 release
IS                                                  -- Added by siva kumar m on 24/08/2012
    /*************************************************
         * modified by         : Ramesh.A
         * modified Date        : 23-NOV-12
         * modified reason    : Modified for user defined exception for selecting sms and email alert query.
         * Reviewer             : Saravanakumar
         * Reviewed Date        : 23-OCT-2012
         * Build Number        :    CMS3.5.1_RI0023_B0001

         * Modified by         : Dhinakaran B
         * Modified Reason    : MVHOST - 346
         * Modified Date        : 20-APR-2013
         * Reviewer             :
         * Reviewed Date        :
         * Build Number        :

         * Modified By       : Sagar M.
         * Modified Date      : 20-Apr-2013
         * Modified for      : Defect 10871
         * Modified Reason  : Logging of below details handled in tranasctionlog and statementlog table
                                    1) ledger balance in statementlog
                                    2) Product code,Product category code,Card status,Acct Type,drcr flag
                                    3) Timestamp and Amount values logging correction
        * Reviewer             : Dhiraj
        * Reviewed Date     : 20-Apr-2013
        * Build Number      : RI0024.1_B0013

        * Modified by         : Ravi N
        * Modified for          : Mantis ID 0011282
        * Modified Reason  : Correction of Insufficient balance spelling mistake
        * Modified Date     : 20-Jun-2013
        * Reviewer             : Dhiraj
        * Reviewed Date     : 20-Jun-2013
        * Build Number      : RI0024.2_B0006

      * Modified by        : Anil Kumar
      * Modified for        : JIRA ID MVCHW-454
      * Modified Reason    : Insufficient Balance for Non-financial Transactions.
      * Modified Date     : 16-07-2013
      * Reviewer            :
      * Reviewed Date     :
      * Build Number        : RI0024.3_B0005

      * Modified by        : MageshKumar.S
      * Modified Reason    : JH-6(Fast50 && Fedral And State Tax Refund Alerts)
      * Modified Date     : 19-09-2013
      * Reviewer            : Dhiraj
      * Reviewed Date     : 19-Sep-2013
      * Build Number        : RI0024.5_B0001

      * Modified by        : Amudhan S
      * Modified Reason    : Mantis ID:12307
      * Modified Date     : 06-10-2013
      * Reviewer            : Dhiraj
      * Reviewed Date     : 06-10-2013
      * Build Number        : RI0027_B0002

         * Modified by       :RAVI N
      * Modified Reason    : MVCSD-4471
      * Modified Date     : 05-02-2014
      * Reviewer            : Dhiraj
      * Reviewed Date     :
      * Build Number        : RI0027.1_B0001

      * Modified By        : DINESH B.
      * Modified Date     : 13-Mar-2014
      * Modified Reason    : Logging Device Id and mobile number for MVCSD-4121 & FWR-43
      * Reviewer            : Dhiraj
      * Reviewed Date     : 10-Mar-2014
      * Build Number        : RI0027.2_B0002

      * Modified By        : DINESH B.
      * Modified Date     : 25-Mar-2014
      * Modified Reason    : Review changes done for MVCSD-4121 & FWR-43
      * Reviewer            : Pankaj S.
      * Reviewed Date     : 01-April-2014
      * Build Number        : RI0027.2_B0003

    * Modified By       : Sankar S
    * Modified Date     : 08-APR-2014
    * Modified for      :
    * Modified Reason  : 1.Round functions added upto 2nd decimal for amount columns in CMS_CHARGE_DTL,CMS_ACCTCLAWBACK_DTL,
                                CMS_STATEMENTS_LOG,TRANSACTIONLOG.
                                2.V_TRAN_AMT initial value assigned as zero.
    * Reviewer             : Pankaj S.
    * Reviewed Date     : 08-APR-2014
    * Build Number      : CMS3.5.1_RI0027.2_B0005

    * modified by       : Amudhan S
    * modified Date     : 23-may-14
    * modified for      : FWR 64
    * modified reason   : To restrict clawback fee entries as per the configuration done by user.
    * Reviewer          : SPankaj
    * Build Number      : RI0027.3_B0001

    * Modified by       : MageshKumar S.
    * Modified Date     : 25-July-14
    * Modified For      : FWR-48
    * Modified reason   : GL Mapping removal changes
    * Reviewer          : Spankaj
    * Build Number      : RI0027.3.1_B0001

   * Modified By      : Raja Gopal G
   * Modified Date    : 30-Jul-2014
   * Modified Reason  : Check Deposit Pending ,Accepted And Rejected Alerts(FWR 67)
   * Reviewer         : Spankaj
   * Build Number     : RI0027.3.1_B0002

   * Modified by      : Pankaj S.
   * Modified for     : Transactionlog Functional Removal
   * Modified Date    : 13-May-2015
   * Reviewer         :  Saravanankumar
   * Build Number     : VMSGPRHOAT_3.0.3_B0001

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

    * Created Date     :  09-AUG-2015
    * Created By       :  MAGESHKUMAR S
    * Created For      :  INGO
    * Reviewer         :  SPankaj
    * Build Number     :  VMSGPRHOSTCSD_3.2_B0001

       * Modified by       :Siva kumar
       * Modified Date    : 22-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006

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

       * Modified by       :Vini
       * Modified Date    : 10-Jan-2018
       * Modified For     : VMS-162
       * Reviewer         : Saravanankumar
       * Build Number     : VMSGPRHOSTCSD_17.12.1

     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01

    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-15-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
    *************************************************/
    V_ERR_MSG                    VARCHAR2 (900) := 'OK';
    V_ACCT_BALANCE             NUMBER;
    V_LEDGER_BAL                NUMBER;
    V_TRAN_AMT                    NUMBER := 0; --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
    V_AUTH_ID                    TRANSACTIONLOG.AUTH_ID%TYPE;
    V_TOTAL_AMT                 NUMBER;
    V_TRAN_DATE                 DATE;
    V_FUNC_CODE                 CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
    V_PROD_CODE                 CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
    V_PROD_CATTYPE             CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
    V_FEE_AMT                    NUMBER;
    V_TOTAL_FEE                 NUMBER;
    V_UPD_AMT                    NUMBER;
    V_UPD_LEDGER_AMT            NUMBER;
    --V_TRANS_DESC             VARCHAR2(50);
    V_FEE_OPENING_BAL         NUMBER;
    V_RESP_CDE                    VARCHAR2 (5);
    V_EXPRY_DATE                DATE;
    V_DR_CR_FLAG                VARCHAR2 (2);
    V_OUTPUT_TYPE                VARCHAR2 (2);
    V_APPLPAN_CARDSTAT        CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
    V_ATMONLINE_LIMIT         CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
    V_POSONLINE_LIMIT         CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
    V_ERROR_MSG                 VARCHAR2 (500);
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
    V_MMPOS_USAGEAMNT         CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
    V_MMPOS_USAGELIMIT        CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_LIMIT%TYPE;
    V_PREAUTH_USAGE_LIMIT    NUMBER;
    --V_ACCT_NUMBER          VARCHAR2(20);
    V_HOLD_AMOUNT                NUMBER;
    V_HASH_PAN                    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
    V_ENCR_PAN                    CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
    V_RRN_COUNT                 NUMBER;
    V_TRAN_TYPE                 VARCHAR2 (2);
    V_DATE                        DATE;
    V_TIME                        VARCHAR2 (10);
    V_MAX_CARD_BAL             NUMBER;
    V_CURR_DATE                 DATE;
    V_MINI_STAT_RES            VARCHAR2 (4000);
    V_MINI_STAT_VAL            VARCHAR2 (500);
    V_INTERNATIONAL_FLAG     CHARACTER (1);
    V_PROXUNUMBER                CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
    V_ACCT_NUMBER                CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
    V_AUTHID_DATE                VARCHAR2 (8);
    V_STATUS_CHK                NUMBER;
    --Added by Deepa On June 19 2012 for Fees Changes
    V_FEEAMNT_TYPE             CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
    V_PER_FEES                    CMS_FEE_MAST.CFM_PER_FEES%TYPE;
    V_FLAT_FEES                 CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
    V_CLAWBACK                    CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
    V_FEE_PLAN                    CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;
    -- Added by siva kumar on july 11 2012 Adding Description for Card Status .
    V_COUNT                        NUMBER;
    V_TXNCODE                    TRANSACTIONLOG.TXN_CODE%TYPE;
    V_CARDSTATUS                VARCHAR2 (50);
    V_PAN4DIGT                    VARCHAR2 (4);
    V_FREETXN_EXCEED            VARCHAR2 (1); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
    V_DURATION                    VARCHAR2 (20); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
    V_TRANS_DESC                CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812

    V_CUST_CODE                 CMS_APPL_PAN.CAP_CUST_CODE%TYPE; -- Added by siva kumar m on 24/08/2012
    V_SWITCH_ACCT_TYPE        CMS_ACCT_TYPE.CAT_SWITCH_TYPE%TYPE DEFAULT '22';
    V_ACCT_TYPE                 CMS_ACCT_MAST.CAM_TYPE_CODE%TYPE;
    V_FEEATTACH_TYPE            VARCHAR2 (2); -- Added by Trivikram on 5th Sept 2012

    v_lowbalance                cms_smsandemail_alert.CSA_LOWBAL_FLAG%TYPE;
    v_dailybalance             cms_smsandemail_alert.CSA_DAILYBAL_FLAG%TYPE;
    v_negetivebalance         cms_smsandemail_alert.CSA_NEGBAL_FLAG%TYPE;
    v_loadorcredit             cms_smsandemail_alert.CSA_LOADORCREDIT_FLAG%TYPE;
    v_highauth                    cms_smsandemail_alert.CSA_HIGHAUTHAMT_FLAG%TYPE;
    v_insufficient             cms_smsandemail_alert.CSA_INSUFF_FLAG%TYPE;
    v_incorrectpin             cms_smsandemail_alert.CSA_INCORRPIN_FLAG%TYPE;

    V_LOGIN_TXN                 CMS_TRANSACTION_MAST.CTM_LOGIN_TXN%TYPE; --Added For Clawback Changes (MVHOST - 346)  on 20/04/2013
    V_ACTUAL_FEE_AMNT         NUMBER; --Added For Clawback Changes (MVHOST - 346)  on 20/04/2013
    V_CLAWBACK_AMNT            CMS_FEE_MAST.CFM_FEE_AMT%TYPE; --Added For Clawback Changes (MVHOST - 346)  on 20/04/2013
    V_CLAWBACK_COUNT            NUMBER; --Added For Clawback Changes (MVHOST - 346)  on 20/04/2013
    v_cam_type_code            cms_acct_mast.cam_type_code%TYPE; -- Added on 20-apr-2013 for defect 10871
    v_timestamp                 TIMESTAMP; -- Added on 20-Apr-2013 for defect 10871

    v_fast50_flag                cms_smsandemail_alert.CSA_FAST50_FLAG%TYPE; -- Added by MageshKumar.S on 19/09/2013 for JH-6
    v_federalstate_flag        cms_smsandemail_alert.CSA_FEDTAX_REFUND_FLAG%TYPE; -- Added by MageshKumar.S on 19/09/2013 for JH-6
    V_FEE_DESC                    cms_fee_mast.cfm_fee_Desc%TYPE; --Added on 05/02/14 for regarding MVCSD-4471
  v_tot_clwbck_count  CMS_FEE_MAST.cfm_clawback_count%TYPE; -- Added for FWR 64
  v_chrg_dtl_cnt      NUMBER;     -- Added for FWR 64
  v_chkdepositPending       cms_smsandemail_alert.CSA_DEPPENDING_FLAG%TYPE; -- Added by Raja Gopal G for FWR 67
    v_chkdepositAccepted      cms_smsandemail_alert.CSA_DEPACCEPTED_FLAG%TYPE;  -- Added by Raja Gopal G for FWR 67
    v_chkdepositRejected      cms_smsandemail_alert.CSA_DEPREJECTED_FLAG%TYPE; -- Added by Raja Gopal G for FWR 67
    V_PROFILE_CODE       CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
    V_ENCRYPT_ENABLE          CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
    v_Retperiod  date;  --Added for VMS-5733/FSP-991
    v_Retdate  date; --Added for VMS-5733/FSP-991
BEGIN
    SAVEPOINT V_AUTH_SAVEPOINT;
    V_RESP_CDE := '1';
    V_ERROR_MSG := 'OK';
    P_RESP_MSG := 'OK';

    BEGIN
        --SN CREATE HASH PAN
        --Gethash is used to hash the original Pan no
        BEGIN
            V_HASH_PAN := GETHASH (P_CARD_NO);
        EXCEPTION
            WHEN OTHERS
            THEN
                V_ERR_MSG :=
                    'Error while converting hash pan  '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --EN CREATE HASH PAN

        --SN create encr pan
        --Fn_Emaps_Main is used for Encrypt the original Pan no
        BEGIN
            V_ENCR_PAN := FN_EMAPS_MAIN (P_CARD_NO);
        EXCEPTION
            WHEN OTHERS
            THEN
                V_ERR_MSG :=
                    'Error while converting encryption pan  '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --EN create encr pan

        /* Commented for not required
             --Sn find narration
             BEGIN
              SELECT CTM_TRAN_DESC
                 INTO V_TRANS_DESC
                 FROM CMS_TRANSACTION_MAST
                WHERE CTM_TRAN_CODE = P_TXN_CODE AND
                      CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
                      CTM_INST_CODE = P_INST_CODE;
             EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 V_TRANS_DESC := 'Transaction type ' || P_TXN_CODE;
                  RAISE EXP_REJECT_RECORD;
              WHEN OTHERS THEN
                 V_TRANS_DESC := 'Transaction type ' || P_TXN_CODE;
                  RAISE EXP_REJECT_RECORD;
             END;

             --En find narration


        */
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

        --Sn find debit and credit flag
        BEGIN
            SELECT CTM_CREDIT_DEBIT_FLAG, CTM_OUTPUT_TYPE, TO_NUMBER (DECODE (CTM_TRAN_TYPE,  'N', '0',  'F', '1')), CTM_TRAN_TYPE, CTM_TRAN_DESC
                     , CTM_LOGIN_TXN --Added For Clawback changes (MVHOST - 346)  on 200413
              INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE, V_TRANS_DESC
                     , V_LOGIN_TXN
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
                V_RESP_CDE := '21';                       --Ineligible Transaction
                V_ERR_MSG :=
                    'Error while selecting transaction details'
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En find debit and credit flag

        --Sn Duplicate RRN Check
        BEGIN
        --Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

IF (v_Retdate>v_Retperiod) --Added for VMS-5733/FSP-991
    THEN
            SELECT COUNT (1)
              INTO V_RRN_COUNT
              FROM TRANSACTIONLOG
             WHERE      RRN = P_RRN
                     AND                                             --Changed for admin dr cr.
                         BUSINESS_DATE = P_TRAN_DATE
                     AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; --Added by ramkumar.Mk on 25 march 2012
        ELSE
        SELECT COUNT (1)
              INTO V_RRN_COUNT
              FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST  --Added for VMS-5733/FSP-991
             WHERE      RRN = P_RRN
                     AND                                             --Changed for admin dr cr.
                         BUSINESS_DATE = P_TRAN_DATE
                     AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; --Added by ramkumar.Mk on 25 march 2012
         END IF;            
                     

            IF V_RRN_COUNT > 0
            THEN
                V_RESP_CDE := '22';
                V_ERR_MSG :=
                        'Duplicate RRN from the Treminal '
                    || P_TERM_ID
                    || ' on '
                    || P_TRAN_DATE;
                RAISE EXP_REJECT_RECORD;
            END IF;
        END;

        --En Duplicate RRN Check

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
                V_ERR_MSG :=
                    'Error while selecting service tax from system'
                    || SUBSTR (SQLERRM, 1, 200);
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
                V_ERR_MSG :=
                    'Error while selecting cess from system'
                    || SUBSTR (SQLERRM, 1, 200);
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
                V_ERR_MSG :=
                    'Error while selecting cutoff  dtl  from system '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        ---En find cutoff time





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

        --Sn find card detail
        BEGIN
            SELECT CAP_PROD_CODE, CAP_CARD_TYPE, CAP_EXPRY_DATE, CAP_CARD_STAT, CAP_ATM_ONLINE_LIMIT
                     , CAP_POS_ONLINE_LIMIT, CAP_PROXY_NUMBER, CAP_ACCT_NO, TO_CHAR (CAP_ACTIVE_DATE, 'MM/DD/YYYY HH24MISS'), TO_CHAR (CAP_EXPRY_DATE, 'MM/YY')
                     , CAP_CARD_STAT, SUBSTR (P_CARD_NO, LENGTH (P_CARD_NO) - 3, LENGTH (P_CARD_NO)), CAP_CUST_CODE,
                     cap_last_txndate
              INTO V_PROD_CODE, V_PROD_CATTYPE, V_EXPRY_DATE, V_APPLPAN_CARDSTAT, V_ATMONLINE_LIMIT
                     , V_ATMONLINE_LIMIT, V_PROXUNUMBER, V_ACCT_NUMBER, P_ACTIVE_DATE, P_EXP_DATE
                     , P_CARD_STATUS, V_PAN4DIGT, V_CUST_CODE,
                     p_last_used
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



        --En find card detail
        --Sn find the tran amt
        IF ( (V_TRAN_TYPE = 'F') OR (P_MSG = '0100'))
        THEN
            IF (P_TXN_AMT >= 0)
            THEN
                V_TRAN_AMT := P_TXN_AMT;
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
                                        NULL,
                                        NULL, --Added IN Parameters in SP_STATUS_CHECK_GPR for pos sign indicator,international indicator,mcccode by Besky on 08-oct-12
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
                        IF V_RESP_CDE <> '13'
                        THEN
                            RAISE EXP_REJECT_RECORD;
                        END IF;
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
                SP_PREAUTHORIZE_TXN (P_CARD_NO,
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

                IF (V_RESP_CDE <> '1' OR TRIM (V_ERR_MSG) <> 'OK')
                THEN
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
                    'Error while selecting CMS_FUNC_MAST'
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;*/

        --En find function code attached to txn code

     --En-commented for fwr-48

        --Sn find prod code and card type and available balance for the card number
        BEGIN
                 SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, cam_type_code -- Added for defect 10871
                    INTO V_ACCT_BALANCE, V_LEDGER_BAL, v_cam_type_code -- Added for defect 10871
                    FROM CMS_ACCT_MAST
                  WHERE CAM_ACCT_NO = V_ACCT_NUMBER AND CAM_INST_CODE = P_INST_CODE
            FOR UPDATE NOWAIT;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '14';                       --Ineligible Transaction
                V_ERR_MSG := 'Invalid Card ';
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '12';
                V_ERR_MSG :=
                    'Error while selecting data from card Master for card number '
                    || SQLERRM;
                RAISE EXP_REJECT_RECORD;
        END;

        --En find prod code and card type for the card number

        --En Internation Flag check
        BEGIN
            SP_TRAN_FEES_CMSAUTH (P_INST_CODE,
                                         P_CARD_NO,
                                         P_DELIVERY_CHANNEL,
                                         V_TXN_TYPE,
                                         P_TXN_MODE,
                                         P_TXN_CODE,
                                         P_CURR_CODE,
                                         '',
                                         '',
                                         V_TRAN_AMT,
                                         V_TRAN_DATE,
                                         NULL,            --Added by Deepa for Fees Changes
                                         NULL,            --Added by Deepa for Fees Changes
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
                                         V_FEE_DESC --Added on 05/02/14 for regarding MVCSD-4471
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
            IF P_TXN_CODE = '11' AND P_MSG = '0100'
            THEN
                V_TOTAL_AMT := V_TRAN_AMT + V_TOTAL_FEE;
                V_UPD_AMT := V_ACCT_BALANCE - V_TOTAL_AMT;
                V_UPD_LEDGER_AMT := V_LEDGER_BAL - V_TOTAL_AMT;
            ELSE
                IF V_TOTAL_FEE = 0
                THEN
                    V_TOTAL_AMT := 0;
                ELSE
                    V_TOTAL_AMT := V_TOTAL_FEE;
                END IF;

                V_UPD_AMT := V_ACCT_BALANCE - V_TOTAL_AMT;
                V_UPD_LEDGER_AMT := V_LEDGER_BAL - V_TOTAL_AMT;
            END IF;
        ELSE
            V_RESP_CDE := '12';                          --Ineligible Transaction
            V_ERR_MSG := 'Invalid transflag    txn code ' || P_TXN_CODE;
            RAISE EXP_REJECT_RECORD;
        END IF;

        --En find total transaction     amout
        --Sn check balance
        /* Commented For Clawback Changes (MVHOST - 346)  on 20/04/2013
      -- IF (V_DR_CR_FLAG NOT IN ('NA', 'CR')  AND P_TXN_CODE <> '93') OR (V_TOTAL_FEE <> 0) -- For credit transaction or Non-Financial transaction Insufficient Balance Check is not required. -- 29th June 2011
            IF (V_DR_CR_FLAG NOT IN ('NA', 'CR') AND P_TXN_CODE <> '93') OR
          V_TOTAL_FEE <> 0 --Modified for  As it needs to check insufficient balance for fee
        THEN
         IF V_UPD_AMT < 0 THEN
            V_RESP_CDE := '15'; --Ineligible Transaction
            V_ERR_MSG  := 'Insufficient Balance '; -- modified by Ravi N for Mantis ID 0011282
            RAISE EXP_REJECT_RECORD;
         END IF;
        END IF;

        --En check balance    */

        --Start Clawback Changes (MVHOST - 346)  on 20/04/2013
        IF (V_DR_CR_FLAG NOT IN ('NA', 'CR') OR (V_TOTAL_FEE <> 0))
        THEN                                                      --ADDED FOR JIRA MVCHW - 454
            IF V_UPD_AMT < 0
            THEN
                --Sn IVR ClawBack amount updation
                --IF V_LOGIN_TXN = 'Y' AND V_CLAWBACK = 'Y' V_DR_CR_FLAG NOT IN ('NA', 'CR') OR (V_TOTAL_FEE <> 0) THEN  --commented for JIRA MVCHW - 454
                IF V_LOGIN_TXN = 'Y' AND V_CLAWBACK = 'Y'
                THEN                                              --ADDED FOR JIRA MVCHW - 454
                    V_ACTUAL_FEE_AMNT := V_TOTAL_FEE;

                    --V_CLAWBACK_AMNT   := V_TOTAL_FEE - V_ACCT_BALANCE;    --commented for JIRA MVCHW - 454
                    --   V_FEE_AMT           := V_ACCT_BALANCE;  --commented for JIRA MVCHW - 454
                    --Start    ADDED FOR JIRA MVCHW - 454
                    IF (V_ACCT_BALANCE > 0)
                    THEN
                        V_CLAWBACK_AMNT := V_TOTAL_FEE - V_ACCT_BALANCE;
                        V_FEE_AMT := V_ACCT_BALANCE;
                    ELSE
                        V_CLAWBACK_AMNT := V_TOTAL_FEE;
                        V_FEE_AMT := 0;
                    END IF;

                    --END FOR JIRA MVCHW - 454

                    IF V_CLAWBACK_AMNT > 0
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
                                 WHERE    ccd_inst_code = p_inst_code
                                         AND ccd_delivery_channel = p_delivery_channel
                                         AND ccd_txn_code = p_txn_code
                                         --AND ccd_pan_code = v_hash_pan  --Commented for FSS-4755
                                         AND ccd_acct_no = V_ACCT_NUMBER and CCD_FEE_CODE=V_FEE_CODE
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
                            SELECT COUNT (*)
                              INTO V_CLAWBACK_COUNT
                              FROM CMS_ACCTCLAWBACK_DTL
                             WHERE      CAD_INST_CODE = P_INST_CODE
                                     AND CAD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                                     AND CAD_TXN_CODE = P_TXN_CODE
                                     AND CAD_PAN_CODE = V_HASH_PAN
                                     AND CAD_ACCT_NO = V_ACCT_NUMBER;

                            IF V_CLAWBACK_COUNT = 0
                            THEN
                                INSERT
                                  INTO CMS_ACCTCLAWBACK_DTL (CAD_INST_CODE,
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
                                VALUES (P_INST_CODE,
                                          V_ACCT_NUMBER,
                                          V_HASH_PAN,
                                          V_ENCR_PAN,
                                          ROUND (V_CLAWBACK_AMNT, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                          'N',
                                          SYSDATE,
                                          SYSDATE,
                                          P_DELIVERY_CHANNEL,
                                          P_TXN_CODE,
                                          '1',
                                          '1');
            ELSIF v_chrg_dtl_cnt < v_tot_clwbck_count then  -- Modified for fwr 64
                                UPDATE CMS_ACCTCLAWBACK_DTL
                                    SET CAD_CLAWBACK_AMNT =
                                             ROUND (CAD_CLAWBACK_AMNT + V_CLAWBACK_AMNT,
                                                      2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                         CAD_RECOVERY_FLAG = 'N',
                                         CAD_LUPD_DATE = SYSDATE
                                 WHERE      CAD_INST_CODE = P_INST_CODE
                                         AND CAD_ACCT_NO = V_ACCT_NUMBER
                                         AND CAD_PAN_CODE = V_HASH_PAN
                                         AND CAD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                                         AND CAD_TXN_CODE = P_TXN_CODE;
                            END IF;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                V_RESP_CDE := '21';
                                V_ERR_MSG :=
                                    'Error while inserting Account ClawBack details'
                                    || SUBSTR (SQLERRM, 1, 200);
                                RAISE EXP_REJECT_RECORD;
                        END;
                    END IF;
                ELSE
                    V_RESP_CDE := '15';
                    V_ERR_MSG := 'Insufficient Balance '; -- modified by Ravi N for Mantis ID 0011282
                    RAISE EXP_REJECT_RECORD;
                END IF;

                V_UPD_AMT := 0;
                V_UPD_LEDGER_AMT := 0;
                V_TOTAL_AMT := V_TRAN_AMT + V_FEE_AMT;
            END IF;
        END IF;                                                     --ADDED FOR JIRA MVCHW-454

        --End  Clawback Changes (MVHOST - 346)  on 20/04/2013
        BEGIN
        SELECT cpc_profile_code, CPC_ENCRYPT_ENABLE
        INTO V_PROFILE_CODE, V_ENCRYPT_ENABLE
        FROM cms_prod_cattype
        WHERE  cpc_inst_code = p_inst_code
        AND cpc_prod_code = v_prod_code
        AND cpc_card_type = v_prod_cattype;
        EXCEPTION
        WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG :='Profile code not defined for product code '|| v_prod_code|| 'card type '|| v_prod_cattype;
        RAISE EXP_REJECT_RECORD;
        END;

        -- Check for maximum card balance configured for the product profile.
        BEGIN
            SELECT TO_NUMBER (CBP_PARAM_VALUE)
              INTO V_MAX_CARD_BAL
              FROM CMS_BIN_PARAM
             WHERE      CBP_INST_CODE = P_INST_CODE
                     AND CBP_PARAM_NAME = 'Max Card Balance'
                     AND CBP_PROFILE_CODE = V_PROFILE_CODE;
        EXCEPTION
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG :=
                    'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --Sn check balance
        IF (V_UPD_LEDGER_AMT > V_MAX_CARD_BAL) OR (V_UPD_AMT > V_MAX_CARD_BAL)
        THEN
            V_RESP_CDE := '30';
            V_ERR_MSG := 'EXCEEDING MAXIMUM CARD BALANCE / BAD CREDIT STATUS';
            RAISE EXP_REJECT_RECORD;
        END IF;

        --En check balance

        --Sn create gl entries and acct update
        BEGIN
            SP_UPD_TRANSACTION_ACCNT_AUTH (P_INST_CODE,
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
                                                     V_ACCT_NUMBER,
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

        v_timestamp := SYSTIMESTAMP;      -- Added on 20-Apr-2013 for defect 10871

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
                                                          CSL_ACCT_TYPE, --Added for defect 10871
                                                          CSL_TIME_STAMP, --Added for defect 10871
                                                          CSL_PROD_CODE, --Added for defect 10871
                                                          CSL_RRN, --    Added for defect 12307 - Amudhan 06NOV13
                                                          CSL_ACCT_NO, --  Added for defect 12307 - Amudhan 06NOV13
                                                          TXN_FEE_FLAG, --  Added for defect 12307 - Amudhan 06NOV13
                                                          CSL_AUTH_ID, --  Added for defect 12307 - Amudhan 06NOV13
                                                          CSL_BUSINESS_DATE, --  Added for defect 12307 - Amudhan 06NOV13
                                                          CSL_BUSINESS_TIME, --  Added for defect 12307 - Amudhan 06NOV13
                                                          CSL_DELIVERY_CHANNEL, --  Added for defect 12307 - Amudhan 06NOV13
                                                          CSL_TXN_CODE, --  Added for defect 12307 - Amudhan 06NOV13
                                                          CSL_INS_USER, --  Added for defect 12307 - Amudhan 06NOV13
                                                          CSL_INS_DATE, --  Added for defect 12307 - Amudhan 06NOV13
                                                          CSL_PANNO_LAST4DIGIT,
                                                          csl_card_type--    Added for defect 12307 - Amudhan 06NOV13
                                                                                     )
                      VALUES (
                                    V_HASH_PAN,
                                    ROUND (V_ledger_BAL, 2), --V_ACCT_BALANCE replaced by V_LEDGER_BAL for defect 10871 --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                    ROUND (V_TRAN_AMT, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                    V_DR_CR_FLAG,
                                    V_TRAN_DATE,
                                    ROUND (
                                        DECODE (V_DR_CR_FLAG,
                                                  'DR', V_ledger_BAL - V_TRAN_AMT, --V_ACCT_BALANCE replaced by V_LEDGER_BAL for defect 10871
                                                  'CR', V_ledger_BAL + V_TRAN_AMT, --V_ACCT_BALANCE replaced by V_LEDGER_BAL for defect 10871
                                                  'NA', V_ledger_BAL),
                                        2), --V_ACCT_BALANCE replaced by V_LEDGER_BAL for defect 10871 --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                    V_TRANS_DESC,
                                    P_INST_CODE,
                                    V_ENCR_PAN,
                                    v_cam_type_code,                --Added for defect 10871
                                    v_timestamp,                    --Added for defect 10871
                                    v_prod_code,                    --Added for defect 10871
                                    P_RRN, --  Added for defect 12307 - Amudhan 06NOV13
                                    V_ACCT_NUMBER, --  Added for defect 12307 - Amudhan 06NOV13
                                    'Y',   --  Added for defect 12307 - Amudhan 06NOV13
                                    V_AUTH_ID, --    Added for defect 12307 - Amudhan 06NOV13
                                    P_TRAN_DATE, --  Added for defect 12307 - Amudhan 06NOV13
                                    P_TRAN_TIME, --  Added for defect 12307 - Amudhan 06NOV13
                                    P_DELIVERY_CHANNEL, --    Added for defect 12307 - Amudhan 06NOV13
                                    P_TXN_CODE, --  Added for defect 12307 - Amudhan 06NOV13
                                    1,      --  Added for defect 12307 - Amudhan 06NOV13
                                    SYSDATE, --  Added for defect 12307 - Amudhan 06NOV13
                                    (SUBSTR (P_CARD_NO,
                                                LENGTH (P_CARD_NO) - 3,
                                                LENGTH (P_CARD_NO))),V_PROD_CATTYPE --  Added for defect 12307 - Amudhan 06NOV13
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
                SELECT DECODE (V_DR_CR_FLAG,    'DR', V_ledger_BAL - V_TRAN_AMT, --V_ACCT_BALANCE replaced by V_LEDGER_BAL for defect 10871
                                                                                                  'CR', V_ledger_BAL + V_TRAN_AMT, --V_ACCT_BALANCE replaced by V_LEDGER_BAL for defect 10871
                                                                                                                                             'NA', V_ledger_BAL) --V_ACCT_BALANCE replaced by V_LEDGER_BAL for defect 10871
                  INTO V_FEE_OPENING_BAL
                  FROM DUAL;
            EXCEPTION
                WHEN OTHERS
                THEN
                    V_RESP_CDE := '12';
                    V_ERR_MSG :=
                        'Error while selecting data from card Master for card number '
                        || P_CARD_NO;
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
                                                              CSL_ACCT_TYPE, --Added for defect 10871
                                                              CSL_TIME_STAMP, --Added for defect 10871
                                                              CSL_PROD_CODE, --Added for defect 10871
                                                              CSL_RRN, --    Added for defect 12307 - Amudhan 06NOV13
                                                              CSL_ACCT_NO, --  Added for defect 12307 - Amudhan 06NOV13
                                                              TXN_FEE_FLAG, --  Added for defect 12307 - Amudhan 06NOV13
                                                              CSL_AUTH_ID, --  Added for defect 12307 - Amudhan 06NOV13
                                                              CSL_BUSINESS_DATE, --  Added for defect 12307 - Amudhan 06NOV13
                                                              CSL_BUSINESS_TIME, --  Added for defect 12307 - Amudhan 06NOV13
                                                              CSL_DELIVERY_CHANNEL, --  Added for defect 12307 - Amudhan 06NOV13
                                                              CSL_TXN_CODE, --  Added for defect 12307 - Amudhan 06NOV13
                                                              CSL_INS_USER, --  Added for defect 12307 - Amudhan 06NOV13
                                                              CSL_INS_DATE, --  Added for defect 12307 - Amudhan 06NOV13
                                                              CSL_PANNO_LAST4DIGIT,csl_card_type --    Added for defect 12307 - Amudhan 06NOV13
                                                                                         )
                          VALUES (
                                        V_HASH_PAN,
                                        ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                        ROUND (V_TOTAL_FEE, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                        'DR',
                                        V_TRAN_DATE,
                                        ROUND (V_FEE_OPENING_BAL - V_TOTAL_FEE, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                        -- 'Fee debited for ' || V_TRANS_DESC,--Comment on 05/02/14 for regarding MVCSD-4471
                                        V_FEE_DESC, --Added on 05/02/14 for regarding MVCSD-4471
                                        P_INST_CODE,
                                        V_ENCR_PAN,
                                        v_cam_type_code,            --Added for defect 10871
                                        v_timestamp,                --Added for defect 10871
                                        v_prod_code,                --Added for defect 10871
                                        P_RRN, --  Added for defect 12307 - Amudhan 06NOV13
                                        V_ACCT_NUMBER, --  Added for defect 12307 - Amudhan 06NOV13
                                        'Y', --  Added for defect 12307 - Amudhan 06NOV13
                                        V_AUTH_ID, --    Added for defect 12307 - Amudhan 06NOV13
                                        P_TRAN_DATE, --  Added for defect 12307 - Amudhan 06NOV13
                                        P_TRAN_TIME, --  Added for defect 12307 - Amudhan 06NOV13
                                        P_DELIVERY_CHANNEL, --    Added for defect 12307 - Amudhan 06NOV13
                                        P_TXN_CODE, --  Added for defect 12307 - Amudhan 06NOV13
                                        1,  --  Added for defect 12307 - Amudhan 06NOV13
                                        SYSDATE, --  Added for defect 12307 - Amudhan 06NOV13
                                        (SUBSTR (P_CARD_NO,
                                                    LENGTH (P_CARD_NO) - 3,
                                                    LENGTH (P_CARD_NO))),V_PROD_CATTYPE --  Added for defect 12307 - Amudhan 06NOV13
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
                                                                  CSL_PANNO_LAST4DIGIT,
                                                                  CSL_ACCT_TYPE, --Added for defect 10871
                                                                  CSL_TIME_STAMP, --Added for defect 10871
                                                                  CSL_PROD_CODE,csl_card_type --Added for defect 10871
                                                                                    )
                              VALUES (
                                            V_HASH_PAN,
                                            ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                            ROUND (V_FLAT_FEES, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                            'DR',
                                            V_TRAN_DATE,
                                            ROUND (V_FEE_OPENING_BAL - V_FLAT_FEES, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                            --'Complimentary ' || V_DURATION ||' '|| V_TRANS_DESC, -- Modified by Trivikram  on 27-July-2012 //Commented for MVCSD--4471
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
                                            V_ACCT_NUMBER,
                                            1,
                                            SYSDATE,
                                            (SUBSTR (P_CARD_NO,
                                                        LENGTH (P_CARD_NO) - 3,
                                                        LENGTH (P_CARD_NO))),
                                            v_cam_type_code,        --Added for defect 10871
                                            v_timestamp,            --Added for defect 10871
                                            v_prod_code,V_PROD_CATTYPE             --Added for defect 10871
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
                                                                  CSL_PANNO_LAST4DIGIT, --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                                                                  CSL_ACCT_TYPE, --Added for defect 10871
                                                                  CSL_TIME_STAMP, --Added for defect 10871
                                                                  csl_prod_code,csl_card_type --Added for defect 10871
                                                                                    )
                              VALUES (
                                            V_HASH_PAN,
                                            ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                            ROUND (V_PER_FEES, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                            'DR',
                                            V_TRAN_DATE,
                                            ROUND (V_FEE_OPENING_BAL - V_PER_FEES, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                            --'Percetage Fee debited for ' || V_TRANS_DESC,--Comment on 05/02/14 for regarding MVCSD-4471
                                            'Percetage Fee debited for ' || V_FEE_DESC, --Added on 05/02/14 for regarding MVCSD-4471
                                            P_INST_CODE,
                                            V_ENCR_PAN,
                                            P_RRN,
                                            V_AUTH_ID,
                                            P_TRAN_DATE,
                                            P_TRAN_TIME,
                                            'Y',
                                            P_DELIVERY_CHANNEL,
                                            P_TXN_CODE,
                                            V_ACCT_NUMBER, --Added by Deepa to log the account number ,INS_DATE and INS_USER
                                            1,
                                            SYSDATE,
                                            (SUBSTR (P_CARD_NO,
                                                        LENGTH (P_CARD_NO) - 3,
                                                        LENGTH (P_CARD_NO))),
                                            v_cam_type_code,        --Added for defect 10871
                                            v_timestamp,            --Added for defect 10871
                                            v_prod_code,V_PROD_CATTYPE             --Added for defect 10871
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
                                                                  CSL_ACCT_TYPE, --Added for defect 10871
                                                                  CSL_TIME_STAMP, --Added for defect 10871
                                                                  csl_prod_code, --Added for defect 10871
                                                                  CSL_RRN, --    Added for defect 12307 - Amudhan 06NOV13
                                                                  CSL_ACCT_NO, --  Added for defect 12307 - Amudhan 06NOV13
                                                                  TXN_FEE_FLAG, --  Added for defect 12307 - Amudhan 06NOV13
                                                                  CSL_AUTH_ID, --  Added for defect 12307 - Amudhan 06NOV13
                                                                  CSL_BUSINESS_DATE, --  Added for defect 12307 - Amudhan 06NOV13
                                                                  CSL_BUSINESS_TIME, --  Added for defect 12307 - Amudhan 06NOV13
                                                                  CSL_DELIVERY_CHANNEL, --  Added for defect 12307 - Amudhan 06NOV13
                                                                  CSL_TXN_CODE, --  Added for defect 12307 - Amudhan 06NOV13
                                                                  CSL_INS_USER, --  Added for defect 12307 - Amudhan 06NOV13
                                                                  CSL_INS_DATE, --  Added for defect 12307 - Amudhan 06NOV13
                                                                  CSL_PANNO_LAST4DIGIT,csl_card_type --    Added for defect 12307 - Amudhan 06NOV13
                                                                                             )
                              VALUES (
                                            V_HASH_PAN,
                                            ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                            ROUND (V_FEE_AMT, 2), --modified for MVHOST-346 --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                            'DR',
                                            V_TRAN_DATE,
                                            ROUND (V_FEE_OPENING_BAL - V_FEE_AMT, 2), --modified for MVHOST-346 --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                            --'Fee debited for ' || V_TRANS_DESC,
                                            V_FEE_DESC, --Added on 05/02/14 for regarding MVCSD-4471
                                            P_INST_CODE,
                                            V_ENCR_PAN,
                                            v_cam_type_code,        --Added for defect 10871
                                            v_timestamp,            --Added for defect 10871
                                            v_prod_code,            --Added for defect 10871
                                            P_RRN, --  Added for defect 12307 - Amudhan 06NOV13
                                            V_ACCT_NUMBER, --  Added for defect 12307 - Amudhan 06NOV13
                                            'Y', --  Added for defect 12307 - Amudhan 06NOV13
                                            V_AUTH_ID, --    Added for defect 12307 - Amudhan 06NOV13
                                            P_TRAN_DATE, --  Added for defect 12307 - Amudhan 06NOV13
                                            P_TRAN_TIME, --  Added for defect 12307 - Amudhan 06NOV13
                                            P_DELIVERY_CHANNEL, --    Added for defect 12307 - Amudhan 06NOV13
                                            P_TXN_CODE, --  Added for defect 12307 - Amudhan 06NOV13
                                            1, --  Added for defect 12307 - Amudhan 06NOV13
                                            SYSDATE, --  Added for defect 12307 - Amudhan 06NOV13
                                            (SUBSTR (P_CARD_NO,
                                                        LENGTH (P_CARD_NO) - 3,
                                                        LENGTH (P_CARD_NO))),V_PROD_CATTYPE --  Added for defect 12307 - Amudhan 06NOV13
                                                                                  );


                        --Start    Clawback Changes (MVHOST - 346)    on 20/04/2013
                        IF V_LOGIN_TXN = 'Y' AND V_CLAWBACK_AMNT > 0 and v_chrg_dtl_cnt < v_tot_clwbck_count THEN  -- Modified for fwr 64

                            BEGIN
                                INSERT INTO CMS_CHARGE_DTL (CCD_PAN_CODE,
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
                                                                     CCD_FEEATTACHTYPE)
                                      VALUES (V_HASH_PAN,
                                                 V_ACCT_NUMBER,
                                                 ROUND (V_CLAWBACK_AMNT, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                                 V_FEE_CRACCT_NO,
                                                 V_ENCR_PAN,
                                                 P_RRN,
                                                 V_TRAN_DATE,
                                                 'T',
                                                 'C',
                                                 V_CLAWBACK,
                                                 P_INST_CODE,
                                                 V_FEE_CODE,
                                                 ROUND (V_ACTUAL_FEE_AMNT, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                                 V_FEE_PLAN,
                                                 P_DELIVERY_CHANNEL,
                                                 P_TXN_CODE,
                                                 ROUND (V_FEE_AMT, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                                 P_MBR_NUMB,
                                                 DECODE (V_ERR_MSG, 'OK', 'SUCCESS'),
                                                 V_FEEATTACH_TYPE);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    V_RESP_CDE := '21';
                                    V_ERR_MSG :=
                                        'Problem while inserting into CMS_CHARGE_DTL '
                                        || SUBSTR (SQLERRM, 1, 200);
                                    RAISE EXP_REJECT_RECORD;
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

        --END LOOP;
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
                                                             CTD_DEVICE_ID,    --Added FWR -43
                                                             CTD_MOBILE_NUMBER ---Added FWR -43
                                                                                    )
                  VALUES (P_DELIVERY_CHANNEL,
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
                             P_DEVICE_ID,                                        --Added FWR -43
                             P_MOBILE_NO);
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
        ---Sn update daily and weekly transcounter  and amount
        BEGIN
            /*SELECT CAT_PAN_CODE
              INTO V_AVAIL_PAN
              FROM CMS_AVAIL_TRANS
             WHERE CAT_PAN_CODE = V_HASH_PAN
                    AND CAT_TRAN_CODE = P_TXN_CODE AND
                    CAT_TRAN_MODE = P_TXN_MODE;*/

            UPDATE CMS_AVAIL_TRANS
                SET CAT_MAXDAILY_TRANCNT =
                         DECODE (CAT_MAXDAILY_TRANCNT,
                                    0, CAT_MAXDAILY_TRANCNT,
                                    CAT_MAXDAILY_TRANCNT - 1),
                     CAT_MAXDAILY_TRANAMT =
                         DECODE (V_DR_CR_FLAG,
                                    'DR', CAT_MAXDAILY_TRANAMT - V_TRAN_AMT,
                                    CAT_MAXDAILY_TRANAMT),
                     CAT_MAXWEEKLY_TRANCNT =
                         DECODE (CAT_MAXWEEKLY_TRANCNT,
                                    0, CAT_MAXWEEKLY_TRANCNT,
                                    CAT_MAXDAILY_TRANCNT - 1),
                     CAT_MAXWEEKLY_TRANAMT =
                         DECODE (V_DR_CR_FLAG,
                                    'DR', CAT_MAXWEEKLY_TRANAMT - V_TRAN_AMT,
                                    CAT_MAXWEEKLY_TRANAMT)
             WHERE      CAT_INST_CODE = P_INST_CODE
                     AND CAT_PAN_CODE = V_HASH_PAN
                     AND CAT_TRAN_CODE = P_TXN_CODE
                     AND CAT_TRAN_MODE = P_TXN_MODE;
        /*IF SQL%ROWCOUNT = 0 THEN
            V_ERR_MSG  := 'Problem while updating data in avail trans ' ||
                          SUBSTR(SQLERRM, 1, 300);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
         END IF;
         */
        EXCEPTION
            /*WHEN EXP_REJECT_RECORD THEN
                RAISE;
             WHEN NO_DATA_FOUND THEN
                NULL;*/
            WHEN OTHERS
            THEN
                V_ERR_MSG :=
                    'Problem while selecting data from avail trans '
                    || SUBSTR (SQLERRM, 1, 300);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
        END;

        --En update daily and weekly transaction counter and amount
        --Sn create detail for response message
        -- added for mini statement
        IF V_OUTPUT_TYPE = 'B'
        THEN
            NULL;
        END IF;

        -- added for mini statement
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
            IF V_RESP_CDE = '1'
            THEN
                --Sn find business date
                V_BUSINESS_TIME := TO_CHAR (V_TRAN_DATE, 'HH24:MI');

                IF V_BUSINESS_TIME > V_CUTOFF_TIME
                THEN
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
                                                            V_ACCT_NUMBER,
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
                END; */

         --En-commented for fwr-48

                --Sn find prod code and card type and available balance for the card number
                BEGIN
                         SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
                            INTO V_ACCT_BALANCE, V_LEDGER_BAL
                            FROM CMS_ACCT_MAST
                          WHERE CAM_ACCT_NO =
                                      (SELECT CAP_ACCT_NO
                                          FROM CMS_APPL_PAN
                                         WHERE      CAP_PAN_CODE = V_HASH_PAN
                                                 AND CAP_MBR_NUMB = P_MBR_NUMB
                                                 AND CAP_INST_CODE = P_INST_CODE)
                                  AND CAM_INST_CODE = P_INST_CODE
                    FOR UPDATE NOWAIT;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        V_RESP_CDE := '14';                 --Ineligible Transaction
                        V_ERR_MSG := 'Invalid Card ';
                        RAISE EXP_REJECT_RECORD;
                    WHEN OTHERS
                    THEN
                        V_RESP_CDE := '12';
                        V_ERR_MSG :=
                            'Error while selecting data from card Master for card number '
                            || SQLERRM;
                        RAISE EXP_REJECT_RECORD;
                END;

                --En find prod code and card type for the card number

                -- changed to fetch the 'Physical address and Office address from two rows
                IF V_OUTPUT_TYPE = 'N'
                THEN
                    BEGIN
                        IF ( (P_TXN_CODE = '15' AND P_DELIVERY_CHANNEL = '10')
                             OR (P_TXN_CODE IN('15','46','47') AND P_DELIVERY_CHANNEL = '13')) --added for INGO changes of 3.2 release
                        THEN                                                --Modified for FWR-43
                            SELECT NVL (decode(V_ENCRYPT_ENABLE,'Y',fn_dmaps_main(cam_add_one),cam_add_one), ' '),
                                   NVL (decode(v_encrypt_enable,'Y',fn_dmaps_main(cam_add_two),cam_add_two), ' '),
                                   NVL (decode(v_encrypt_enable,'Y',fn_dmaps_main(cam_city_name),cam_city_name), ' '),
                                   NVL (decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(CAM_PIN_CODE),CAM_PIN_CODE), ' '),
                                   NVL (decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_phone_one),cam_phone_one), ' ')
                                     , -- Commented by srinivasuk removed physical address phone number and phy other phnone number
                                      NVL (decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_mobl_one),cam_mobl_one), ' '), -- Commented by srinivasuk  removed physical address phone number and phy other phnone number
                                                                      NVL (CAM_STATE_CODE, '0'), NVL (CAM_CNTRY_CODE, '0'),
                                  NVL (decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_email),cam_email), ' ')
                              INTO P_PHYADDLINEONE, P_PHYADDLINETWO, P_PHYCITY, P_PHYZIP, P_PHONENUMBER
                                     , --Added by dhina for integrating sathya changes on 290712
                                      P_OTHERPHONE, --Added by dhina for integrating sathya changes on 290712
                                                         --    P_PHYPHONENUMBER, Commented by srinivasuk  removed physical address phone number and phy other phnone number
                                                         -- P_PHYOTHERPHONE, Commented by srinivasuk  removed physical address phone number and phy other phnone number
                                                         P_PHYSTATE, P_PHYCOUNTRY, P_PHYEMAIL
                              FROM CMS_ADDR_MAST
                             WHERE      CAM_INST_CODE = P_INST_CODE
                                     AND CAM_CUST_CODE = V_CUST_CODE
                                     AND CAM_ADDR_FLAG = 'P';

                            BEGIN
                                SELECT decode(V_ENCRYPT_ENABLE,'Y',fn_dmaps_main(cam_add_one),cam_add_one),
                                       NVL (decode(v_encrypt_enable,'Y',fn_dmaps_main(cam_add_two),cam_add_two), ' '),
                                       NVL (decode(v_encrypt_enable,'Y',fn_dmaps_main(cam_city_name),cam_city_name), ' '),
                                       NVL (decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(CAM_PIN_CODE),CAM_PIN_CODE), ' '), --   NVL(CAM_PHONE_ONE, ' '),--Commented by dhina for integrating sathya changes on 290712
                                                                                                                                                              --     NVL(CAM_MOBL_ONE, ' '),--Commented by dhina for integrating sathya changes on 290712
                                                                                                                                                              NVL (CAM_STATE_CODE, '0')
                                         , NVL (CAM_CNTRY_CODE, '0')
                                  INTO P_ADDLINEONE, P_ADDLINETWO, P_CITY, P_ZIP, --          P_PHONENUMBER,Commented by dhina for integrating sathya changes on 290712
                                                                                                  --          P_OTHERPHONE,Commented by dhina for integrating sathya changes on 290712
                                                                                                  P_STATE
                                         , P_COUNTRY
                                  FROM CMS_ADDR_MAST
                                 WHERE      CAM_INST_CODE = P_INST_CODE
                                         AND CAM_CUST_CODE = V_CUST_CODE
                                         AND CAM_ADDR_FLAG = 'O';

                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    P_ADDLINEONE := ' ';
                                    P_ADDLINETWO := ' ';
                                    P_CITY := ' ';
                                    P_ZIP := ' ';
                                    --   P_PHONENUMBER := ' ';--Commented by dhina for integrating sathya changes on 290712
                                    --   P_OTHERPHONE  := ' ';--Commented by dhina for integrating sathya changes on 290712
                                    P_STATE := ' ';
                                    P_COUNTRY := ' ';
                            END;

                            BEGIN
                                SELECT NVL (decode(v_encrypt_enable,'Y',fn_dmaps_main(ccm_first_name),ccm_first_name), ' '),
                                       NVL (decode(v_encrypt_enable,'Y',fn_dmaps_main(ccm_last_name),ccm_last_name), ' '),
                                NVL(fn_dmaps_main(ccm_ssn_encr),' '),to_char(CCM_BIRTH_DATE,'mmddyyyy'), --added for INGO changes of 3.2 release
                                TRIM(SUBSTR(NVL(CCM_FIRST_NAME,'')||' '||NVL(CCM_LAST_NAME,''),0,26)),NVL(CCM_ID_TYPE,' ') --added for INGO changes of 3.2 release
                                  INTO P_FIRSTNAME, P_LASTNAME,p_ssn_out,p_dob_out,p_disp_name_out,p_id_type_out --added for INGO changes of 3.2 release
                                  FROM CMS_CUST_MAST
                                 WHERE CCM_INST_CODE = P_INST_CODE
                                         AND CCM_CUST_CODE = V_CUST_CODE;
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    V_RESP_CDE := '12';
                                    V_ERR_MSG :=
                                        'Error while selecting data from customer master for card number '
                                        || SQLERRM;
                                    RAISE EXP_REJECT_RECORD;
                            END;

                            --sn    getting alerts by siva kumar for cr 20
                            BEGIN
                                SELECT CSA_LOWBAL_FLAG, CSA_DAILYBAL_FLAG, CSA_NEGBAL_FLAG, CSA_LOADORCREDIT_FLAG, CSA_HIGHAUTHAMT_FLAG
                                         , CSA_INSUFF_FLAG, CSA_INCORRPIN_FLAG, CSA_FAST50_FLAG, CSA_FEDTAX_REFUND_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
                     CSA_DEPPENDING_FLAG,CSA_DEPACCEPTED_FLAG,CSA_DEPREJECTED_FLAG -- Addded by Raja Gopal G for FWR 67
                                  INTO v_lowbalance, v_dailybalance, v_negetivebalance, v_loadorcredit, v_highauth
                                         , v_insufficient, v_incorrectpin, v_fast50_flag, v_federalstate_flag, -- Added by MageshKumar.S on 19/09/2013 for JH-6
                     v_chkdepositPending,v_chkdepositAccepted ,v_chkdepositRejected
                                  FROM cms_smsandemail_alert
                                 WHERE csa_pan_code = V_HASH_PAN
                                         AND CSA_INST_CODE = P_INST_CODE;
                            EXCEPTION
                                WHEN NO_DATA_FOUND
                                THEN
                                    V_RESP_CDE := '12';
                                    V_ERR_MSG :=
                                        'No data found from sms and email alerts for card number '
                                        || SUBSTR (SQLERRM, 1, 200);

                                    RAISE EXP_REJECT_RECORD;
                                WHEN TOO_MANY_ROWS
                                THEN --Added by Ramesh.A on 23/11/2012 for user defined exception
                                    V_RESP_CDE := '12';
                                    V_ERR_MSG :=
                                        'Too many records found from sms and email v for card number '
                                        || SUBSTR (SQLERRM, 1, 200);

                                    RAISE EXP_REJECT_RECORD;
                                WHEN OTHERS
                                THEN
                                    V_RESP_CDE := '12';
                                    V_ERR_MSG :=
                                        'Error while selecting data from sms and email alerts for card number '
                                        || SUBSTR (SQLERRM, 1, 200);

                                    RAISE EXP_REJECT_RECORD;
                            END;


                            IF      v_lowbalance IN ('0', '2')
                                AND v_dailybalance IN ('0', '2')
                                AND v_negetivebalance IN ('0', '2')
                                AND v_loadorcredit IN ('0', '2')
                                AND v_highauth IN ('0', '2')
                                AND v_insufficient IN ('0', '2')
                                AND v_incorrectpin IN ('0', '2')
                                AND v_fast50_flag IN ('0', '2')
                                AND v_federalstate_flag IN ('0', '2')
                AND v_chkdepositPending IN ('0', '2') -- Added by Raja Gopal G for FWR 67
                AND v_chkdepositAccepted IN ('0', '2')
                AND v_chkdepositRejected IN ('0', '2')
                            THEN        -- Added by MageshKumar.S on 19/09/2013 for JH-6
                                P_CARD4DIGT := 0;                               -- return '0'
                            ELSE
                                P_CARD4DIGT := 1;                               -- return '1'
                            END IF;
                        -- en  getting alerts by siva kumar for cr 20
                        END IF;
                    EXCEPTION
                        WHEN EXP_REJECT_RECORD
                        THEN --Added by Ramesh.A on 23/11/2012 for user defined exception
                            RAISE;
                        WHEN OTHERS
                        THEN
                            V_RESP_CDE := '12';
                            V_ERR_MSG :=
                                'Error while selecting data from ADDRESS MAST for card number '
                                || SUBSTR (SQLERRM, 1, 200);
                            RAISE EXP_REJECT_RECORD;
                    END;

                    BEGIN
                        IF ((P_TXN_CODE = '16' AND P_DELIVERY_CHANNEL = '10') OR (P_TXN_CODE = '47' AND P_DELIVERY_CHANNEL = '13')) --added for INGO changes of 3.2 release
                        THEN
                            /* Commented for not required
                        SELECT TO_CHAR(CAP.CAP_ACTIVE_DATE, 'MM/DD/YYYY HH24MISS'), --Modified by sivapragasam on May 15 2012 to select active date
                                      TO_CHAR(CAP.CAP_EXPRY_DATE, 'MM/YY'),
                                      CAP.CAP_CARD_STAT,
                                      SUBSTR(P_CARD_NO,
                                              LENGTH(P_CARD_NO) - 3,
                                              LENGTH(P_CARD_NO)),CAP_CUST_CODE
                                 INTO P_ACTIVE_DATE, P_EXP_DATE, P_CARD_STATUS, V_PAN4DIGT,V_CUST_CODE     -- Added cust_code by siva kumar m on 24/08/2012
                                 FROM CMS_APPL_PAN CAP
                                WHERE CAP_PAN_CODE = V_HASH_PAN AND
                                      CAP_MBR_NUMB = P_MBR_NUMB AND
                                      CAP_INST_CODE = P_INST_CODE; */

                            --Sn Commented for Transactionlog Functional Removal
                            /*SELECT TO_CHAR (MAX (TO_DATE (T.BUSINESS_DATE || ' ' || T.BUSINESS_TIME, 'YYYY/MM/DD HH24:MI:SS')), 'MM/DD/YYYY')
                              INTO P_LAST_USED
                              FROM TRANSACTIONLOG T
                             WHERE T.CUSTOMER_CARD_NO = V_HASH_PAN
                                     AND T.RESPONSE_CODE = '00';*/

                            --En Commented for Transactionlog Functional Removal

                            -- ST Adding Description for Card Status .
                            P_CARD4DIGT := V_PAN4DIGT;

                            --St Added by Ramesh.A on 25/09/2012
                            IF P_CARD_STATUS = '0'
                            THEN
                                --Sn Modified for Transactionlog Functional Removal
                                /*SELECT COUNT (*)
                                  INTO V_COUNT
                                  FROM TRANSACTIONLOG
                                 WHERE RESPONSE_CODE = '00'
                                         AND ( (TXN_CODE = '68'
                                                  AND DELIVERY_CHANNEL = '04')
                                                OR (TXN_CODE = '02'
                                                     AND DELIVERY_CHANNEL IN ('10', '07'))
                                                OR (TXN_CODE = '74'
                                                     AND DELIVERY_CHANNEL = '03')
                                                OR (TXN_CODE = '09'
                                                     AND DELIVERY_CHANNEL = '07'))
                                         AND CUSTOMER_CARD_NO = V_HASH_PAN
                                         AND INSTCODE = P_INST_CODE;*/

                                IF P_ACTIVE_DATE IS NULL--V_COUNT = 0
                                THEN
                                    P_CARD_STATUS_MESG := 'INACTIVE';
                                ELSE
                                    P_CARD_STATUS_MESG := 'BLOCKED';
                                END IF;
                                --En Modified for Transactionlog Functional Removal
                            ELSE
                                SELECT CCS_STAT_DESC
                                  INTO V_CARDSTATUS
                                  FROM CMS_CARD_STAT
                                 WHERE CCS_STAT_CODE = P_CARD_STATUS
                                         AND CCS_INST_CODE = P_INST_CODE;

                                P_CARD_STATUS_MESG := V_CARDSTATUS;
                            END IF;

                            --END

                            /*  Commented by Ramesh.A    on 25/09/2012
                                            IF P_CARD_STATUS = '0' THEN

                                             SELECT COUNT(*)
                                                INTO V_COUNT
                                                FROM TRANSACTIONLOG
                                              WHERE RESPONSE_CODE = '00' AND
                                                     ((TXN_CODE = '69' AND DELIVERY_CHANNEL = '04') OR
                                                     (TXN_CODE = '05' AND
                                                     DELIVERY_CHANNEL IN ('10', '07'))) AND
                                                     CUSTOMER_CARD_NO = V_HASH_PAN AND
                                                     INSTCODE = P_INST_CODE;

                                             IF V_COUNT = 0 THEN

                                                P_CARD_STATUS_MESG := 'INACTIVE';

                                             ELSE
                                                SELECT TXN_CODE
                                                 INTO V_TXNCODE
                                                 FROM (SELECT TXN_CODE
                                                          FROM TRANSACTIONLOG
                                                         WHERE RESPONSE_CODE = '00' AND
                                                                ((TXN_CODE = '69' AND
                                                                DELIVERY_CHANNEL = '04') OR
                                                                (TXN_CODE = '05' AND
                                                                DELIVERY_CHANNEL IN ('10', '07'))) AND
                                                                CUSTOMER_CARD_NO = V_HASH_PAN AND
                                                                INSTCODE = P_INST_CODE
                                                         ORDER BY TO_DATE(SUBSTR(TRIM(BUSINESS_DATE), 1, 8) || ' ' ||
                                                                            SUBSTR(TRIM(BUSINESS_TIME),
                                                                                  1,
                                                                                  10),
                                                                            'yyyymmdd hh24:mi:ss') DESC)
                                                 WHERE ROWNUM = 1;

                                                IF V_TXNCODE = '69' THEN

                                                      P_CARD_STATUS_MESG := 'INACTIVE';

                                                ELSE
                                                      IF V_TXNCODE = '05' THEN

                                                        P_CARD_STATUS_MESG := 'BLOCKED';

                                                      END IF;
                                                END IF;

                                             END IF;
                                            ELSE
                                             SELECT CCS_STAT_DESC
                                                INTO V_CARDSTATUS
                                                FROM CMS_CARD_STAT
                                              WHERE CCS_STAT_CODE = P_CARD_STATUS AND
                                                     CCS_INST_CODE = P_INST_CODE;

                                             P_CARD_STATUS_MESG := V_CARDSTATUS;

                                            END IF;
                                      */
                            --EN    Adding Description for Card Status .
                            P_SPENDING_ACCT_NO := V_ACCT_NUMBER; -- Added by siva kumar m as on 24/08/2012.

                            --Sn select acct type(Savings)  by siva kumar m as on 24/08/2012
                            BEGIN
                                SELECT CAT_TYPE_CODE
                                  INTO V_ACCT_TYPE
                                  FROM CMS_ACCT_TYPE
                                 WHERE CAT_INST_CODE = P_INST_CODE
                                         AND CAT_SWITCH_TYPE = V_SWITCH_ACCT_TYPE;
                            EXCEPTION
                                WHEN NO_DATA_FOUND
                                THEN
                                    V_RESP_CDE := '21';
                                    V_ERR_MSG :=
                                        'Acct type not defined in master(Savings)';
                                    RAISE EXP_REJECT_RECORD;
                                WHEN OTHERS
                                THEN
                                    V_RESP_CDE := '12';
                                    V_ERR_MSG :=
                                        'Error while selecting accttype(Savings) '
                                        || SUBSTR (SQLERRM, 1, 200);
                                    RAISE EXP_REJECT_RECORD;
                            END;

                            --En select acct type(Savings)


                            -- St select savings acct number.
                            BEGIN
                                SELECT CAM_ACCT_NO
                                  INTO P_SAVINGSS_ACCT_NO
                                  FROM CMS_ACCT_MAST
                                 WHERE CAM_ACCT_ID IN
                                             (SELECT CCA_ACCT_ID
                                                 FROM CMS_CUST_ACCT
                                                WHERE CCA_CUST_CODE = V_CUST_CODE
                                                        AND CCA_INST_CODE = P_INST_CODE)
                                         AND CAM_TYPE_CODE = V_ACCT_TYPE
                                         AND CAM_INST_CODE = P_INST_CODE;
                            EXCEPTION
                                WHEN NO_DATA_FOUND
                                THEN
                                    P_SAVINGSS_ACCT_NO := '';
                                WHEN OTHERS
                                THEN
                                    V_RESP_CDE := '12';
                                    V_ERR_MSG :=
                                        'Error while selecting savings acc number '
                                        || SUBSTR (SQLERRM, 1, 200);
                            END;
                        -- En select savings acct number.
                        ELSE
                            p_last_used:=NULL;   --added for Transactionlog functional removal
                        END IF;
                    EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                            V_RESP_CDE := '12';
                            V_ERR_MSG :=
                                'NO DATA FOUND IN APPLPAN/TRANSACTIONLOG'
                                || SUBSTR (SQLERRM, 1, 200);
                            RAISE EXP_REJECT_RECORD;
                        WHEN OTHERS
                        THEN
                            V_RESP_CDE := '12';
                            V_ERR_MSG :=
                                'Error while selecting data from LAST USED for card number '
                                || SQLERRM;
                            RAISE EXP_REJECT_RECORD;
                    END;
                END IF;
            END IF;

            --En create GL ENTRIES

            ---Sn Updation of Usage limit and amount
            BEGIN
                SELECT CTC_ATMUSAGE_AMT, CTC_POSUSAGE_AMT, CTC_ATMUSAGE_LIMIT, CTC_POSUSAGE_LIMIT, CTC_BUSINESS_DATE
                         , CTC_PREAUTHUSAGE_LIMIT, CTC_MMPOSUSAGE_AMT, CTC_MMPOSUSAGE_LIMIT
                  INTO V_ATM_USAGEAMNT, V_POS_USAGEAMNT, V_ATM_USAGELIMIT, V_POS_USAGELIMIT, V_BUSINESS_DATE_TRAN
                         , V_PREAUTH_USAGE_LIMIT, V_MMPOS_USAGEAMNT, V_MMPOS_USAGELIMIT
                  FROM CMS_TRANSLIMIT_CHECK
                 WHERE      CTC_INST_CODE = P_INST_CODE
                         AND CTC_PAN_CODE = V_HASH_PAN
                         AND CTC_MBR_NUMB = P_MBR_NUMB;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    V_ERR_MSG :=
                            'Cannot get the Transaction Limit Details of the Card'
                        || V_RESP_CDE
                        || SUBSTR (SQLERRM, 1, 300);
                    V_RESP_CDE := '21';
                    RAISE EXP_REJECT_RECORD;
                WHEN OTHERS
                THEN
                    V_ERR_MSG :=
                        'Error while selecting 1 CMS_TRANSLIMIT_CHECK'
                        || SUBSTR (SQLERRM, 1, 200);
                    V_RESP_CDE := '21';
                    RAISE EXP_REJECT_RECORD;
            END;

            BEGIN
                IF P_DELIVERY_CHANNEL = '01'
                THEN
                    IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN
                    THEN
                        IF P_TXN_AMT IS NULL
                        THEN
                            V_ATM_USAGEAMNT :=
                                TRIM (TO_CHAR (0, '99999999999999990.99'));
                        ELSE
                            V_ATM_USAGEAMNT :=
                                TRIM (TO_CHAR (V_TRAN_AMT, '99999999999999990.99'));
                        END IF;

                        V_ATM_USAGELIMIT := 1;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_ATMUSAGE_AMT = V_ATM_USAGEAMNT,
                                     CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT,
                                     CTC_POSUSAGE_AMT = 0,
                                     CTC_POSUSAGE_LIMIT = 0,
                                     CTC_PREAUTHUSAGE_LIMIT = 0,
                                     CTC_BUSINESS_DATE =
                                         TO_DATE (P_TRAN_DATE || '23:59:59',
                                                     'yymmdd' || 'hh24:mi:ss'),
                                     CTC_MMPOSUSAGE_AMT = 0,
                                     CTC_MMPOSUSAGE_LIMIT = 0
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;

                            IF SQL%ROWCOUNT = 0
                            THEN
                                V_ERR_MSG :=
                                    'updating 1 CMS_TRANSLIMIT_CHECK ERROR'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                            END IF;
                        EXCEPTION
                            WHEN EXP_REJECT_RECORD
                            THEN
                                RAISE EXP_REJECT_RECORD;
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 1 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    ELSE
                        IF P_TXN_AMT IS NULL
                        THEN
                            V_ATM_USAGEAMNT :=
                                V_ATM_USAGEAMNT
                                + TRIM (TO_CHAR (0, '99999999999999990.99'));
                        ELSE
                            V_ATM_USAGEAMNT :=
                                V_ATM_USAGEAMNT
                                + TRIM (TO_CHAR (V_TRAN_AMT, '99999999999999990.99'));
                        END IF;

                        V_ATM_USAGELIMIT := V_ATM_USAGELIMIT + 1;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_ATMUSAGE_AMT = V_ATM_USAGEAMNT,
                                     CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;

                            IF SQL%ROWCOUNT = 0
                            THEN
                                V_ERR_MSG :=
                                    'updating 2 CMS_TRANSLIMIT_CHECK ERROR'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                            END IF;
                        EXCEPTION
                            WHEN EXP_REJECT_RECORD
                            THEN
                                RAISE EXP_REJECT_RECORD;
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 2 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    END IF;
                END IF;

                IF P_DELIVERY_CHANNEL = '02'
                THEN
                    IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN
                    THEN
                        IF P_TXN_AMT IS NULL
                        THEN
                            V_POS_USAGEAMNT :=
                                TRIM (TO_CHAR (0, '99999999999999990.99'));
                        ELSE
                            V_POS_USAGEAMNT :=
                                TRIM (TO_CHAR (V_TRAN_AMT, '99999999999999990.99'));
                        END IF;

                        V_POS_USAGELIMIT := 1;

                        IF P_TXN_CODE = '11' AND P_MSG = '0100'
                        THEN
                            V_PREAUTH_USAGE_LIMIT := 1;
                            V_POS_USAGEAMNT := 0;
                        ELSE
                            V_PREAUTH_USAGE_LIMIT := 0;
                        END IF;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_POSUSAGE_AMT = V_POS_USAGEAMNT,
                                     CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT,
                                     CTC_ATMUSAGE_AMT = 0,
                                     CTC_ATMUSAGE_LIMIT = 0,
                                     CTC_BUSINESS_DATE =
                                         TO_DATE (P_TRAN_DATE || '23:59:59',
                                                     'yymmdd' || 'hh24:mi:ss'),
                                     CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT,
                                     CTC_MMPOSUSAGE_AMT = 0,
                                     CTC_MMPOSUSAGE_LIMIT = 0
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;

                            IF SQL%ROWCOUNT = 0
                            THEN
                                V_ERR_MSG :=
                                    'updating 3 CMS_TRANSLIMIT_CHECK ERROR'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                            END IF;
                        EXCEPTION
                            WHEN EXP_REJECT_RECORD
                            THEN
                                RAISE EXP_REJECT_RECORD;
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 3 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    ELSE
                        V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;

                        IF P_TXN_CODE = '11' AND P_MSG = '0100'
                        THEN
                            V_PREAUTH_USAGE_LIMIT := V_PREAUTH_USAGE_LIMIT + 1;
                            V_POS_USAGEAMNT := V_POS_USAGEAMNT;
                        ELSE
                            IF P_TXN_AMT IS NULL
                            THEN
                                V_POS_USAGEAMNT :=
                                    V_POS_USAGEAMNT
                                    + TRIM (TO_CHAR (0, '99999999999999990.99'));
                            ELSE
                                IF V_DR_CR_FLAG = 'CR'
                                THEN
                                    V_POS_USAGEAMNT := V_POS_USAGEAMNT;
                                ELSE
                                    V_POS_USAGEAMNT :=
                                        V_POS_USAGEAMNT
                                        + TRIM (
                                              TO_CHAR (V_TRAN_AMT,
                                                          '99999999999999990.99'));
                                END IF;
                            END IF;
                        END IF;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_POSUSAGE_AMT = V_POS_USAGEAMNT,
                                     CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT,
                                     CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;

                            IF SQL%ROWCOUNT = 0
                            THEN
                                V_ERR_MSG :=
                                    'updating 4 CMS_TRANSLIMIT_CHECK ERROR'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                            END IF;
                        EXCEPTION
                            WHEN EXP_REJECT_RECORD
                            THEN
                                RAISE EXP_REJECT_RECORD;
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 4 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    END IF;
                END IF;

                --Sn Usage limit and amount updation for MMPOS
                IF P_DELIVERY_CHANNEL = '04'
                THEN
                    IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN
                    THEN
                        IF P_TXN_AMT IS NULL
                        THEN
                            V_MMPOS_USAGEAMNT :=
                                TRIM (TO_CHAR (0, '99999999999999990.99'));
                        ELSE
                            V_MMPOS_USAGEAMNT :=
                                TRIM (TO_CHAR (V_TRAN_AMT, '99999999999999990.99'));
                        END IF;

                        V_MMPOS_USAGELIMIT := 1;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_MMPOSUSAGE_AMT = V_MMPOS_USAGEAMNT,
                                     CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT,
                                     CTC_ATMUSAGE_AMT = 0,
                                     CTC_ATMUSAGE_LIMIT = 0,
                                     CTC_BUSINESS_DATE =
                                         TO_DATE (P_TRAN_DATE || '23:59:59',
                                                     'yymmdd' || 'hh24:mi:ss'),
                                     CTC_PREAUTHUSAGE_LIMIT = 0,
                                     CTC_POSUSAGE_AMT = 0,
                                     CTC_POSUSAGE_LIMIT = 0
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;

                            IF SQL%ROWCOUNT = 0
                            THEN
                                V_ERR_MSG :=
                                    'updating 5 CMS_TRANSLIMIT_CHECK ERROR'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                            END IF;
                        EXCEPTION
                            WHEN EXP_REJECT_RECORD
                            THEN
                                RAISE EXP_REJECT_RECORD;
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 5 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    ELSE
                        V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;

                        IF P_TXN_AMT IS NULL
                        THEN
                            V_MMPOS_USAGEAMNT :=
                                V_MMPOS_USAGEAMNT
                                + TRIM (TO_CHAR (0, 999999999999999));
                        ELSE
                            V_MMPOS_USAGEAMNT :=
                                V_MMPOS_USAGEAMNT
                                + TRIM (TO_CHAR (V_TRAN_AMT, '99999999999999990.99'));
                        END IF;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_MMPOSUSAGE_AMT = V_MMPOS_USAGEAMNT,
                                     CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;

                            IF SQL%ROWCOUNT = 0
                            THEN
                                V_ERR_MSG :=
                                    'updating 6 CMS_TRANSLIMIT_CHECK ERROR'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                            END IF;
                        EXCEPTION
                            WHEN EXP_REJECT_RECORD
                            THEN
                                RAISE EXP_REJECT_RECORD;
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 6 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
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
            SELECT CMS_ISO_RESPCDE
              INTO P_RESP_CODE
              FROM CMS_RESPONSE_MAST
             WHERE      CMS_INST_CODE = P_INST_CODE
                     AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                     AND CMS_RESPONSE_ID = TO_NUMBER (V_RESP_CDE);
        EXCEPTION
            WHEN OTHERS
            THEN
                V_ERR_MSG :=
                    'Problem while selecting data from response master for respose code'
                    || V_RESP_CDE
                    || SUBSTR (SQLERRM, 1, 300);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
        END;

        BEGIN
        
        IF (v_Retdate>v_Retperiod) --Added for VMS-5733/FSP-991
    THEN
            UPDATE TRANSACTIONLOG
                SET IPADDRESS = P_IPADDRESS
             WHERE      RRN = P_RRN
                     AND BUSINESS_DATE = P_TRAN_DATE
                     AND TXN_CODE = P_TXN_CODE
                     AND MSGTYPE = P_MSG
                     AND BUSINESS_TIME = P_TRAN_TIME
                     AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
    ELSE
     UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
                SET IPADDRESS = P_IPADDRESS
             WHERE      RRN = P_RRN
                     AND BUSINESS_DATE = P_TRAN_DATE
                     AND TXN_CODE = P_TXN_CODE
                     AND MSGTYPE = P_MSG
                     AND BUSINESS_TIME = P_TRAN_TIME
                     AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
               END IF;      
        /*IF SQL%ROWCOUNT = 0 THEN
          V_ERR_MSG  := 'updating TRANSACTIONLOG ERROR' ||SUBSTR(SQLERRM, 1, 200);
          V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
         END IF;*/
        EXCEPTION
            /*WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;*/
            WHEN OTHERS
            THEN
                V_RESP_CDE := '69';
                V_ERROR_MSG :=
                    'Problem while inserting data into transaction log  dtl'
                    || SUBSTR (SQLERRM, 1, 300);
        END;
    ---
    EXCEPTION
        --<< MAIN EXCEPTION >>
        WHEN EXP_REJECT_RECORD
        THEN
            ROLLBACK TO V_AUTH_SAVEPOINT;

            BEGIN
                SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, cam_type_code --Added for defect 10871
                  INTO V_ACCT_BALANCE, V_LEDGER_BAL, v_cam_type_code --Added for defect 10871
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

            BEGIN
                SELECT CTC_ATMUSAGE_LIMIT, CTC_POSUSAGE_LIMIT, CTC_BUSINESS_DATE, CTC_PREAUTHUSAGE_LIMIT, CTC_MMPOSUSAGE_LIMIT
                  INTO V_ATM_USAGELIMIT, V_POS_USAGELIMIT, V_BUSINESS_DATE_TRAN, V_PREAUTH_USAGE_LIMIT, V_MMPOS_USAGELIMIT
                  FROM CMS_TRANSLIMIT_CHECK
                 WHERE      CTC_INST_CODE = P_INST_CODE
                         AND CTC_PAN_CODE = V_HASH_PAN
                         AND CTC_MBR_NUMB = P_MBR_NUMB;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    V_ERR_MSG :=
                        'Cannot get the Transaction Limit Details of the Card';
                    V_RESP_CDE := '21';
                    RAISE EXP_REJECT_RECORD;
                WHEN OTHERS
                THEN
                    V_ERR_MSG :=
                        'Error while selecting 2 CMS_TRANSLIMIT_CHECK'
                        || SUBSTR (SQLERRM, 1, 200);
                    V_RESP_CDE := '21';
                    RAISE EXP_REJECT_RECORD;
            END;

            --Added FWR -43 starts
            IF V_RESP_CDE = '00' AND V_ERR_MSG = 'OK'
            THEN
                BEGIN
                --Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';

IF (v_Retdate>v_Retperiod) --Added for VMS-5733/FSP-991
    THEN
                    UPDATE CMS_TRANSACTION_LOG_DTL
                        SET CTD_DEVICE_ID = P_DEVICE_ID,
                             CTD_MOBILE_NUMBER = P_MOBILE_NO
                     WHERE      CTD_INST_CODE = P_INST_CODE
                             AND CTD_CUSTOMER_CARD_NO = V_HASH_PAN
                             AND CTD_RRN = P_RRN
                             AND CTD_BUSINESS_DATE = P_TRAN_DATE
                             AND CTD_BUSINESS_TIME = P_TRAN_TIME
                             AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                             AND CTD_TXN_CODE = P_TXN_CODE
                             AND CTD_MSG_TYPE = P_MSG;
       ELSE
           
 UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST     --Added for VMS-5733/FSP-991
                        SET CTD_DEVICE_ID = P_DEVICE_ID, 
                             CTD_MOBILE_NUMBER = P_MOBILE_NO
                     WHERE      CTD_INST_CODE = P_INST_CODE
                             AND CTD_CUSTOMER_CARD_NO = V_HASH_PAN
                             AND CTD_RRN = P_RRN
                             AND CTD_BUSINESS_DATE = P_TRAN_DATE
                             AND CTD_BUSINESS_TIME = P_TRAN_TIME
                             AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                             AND CTD_TXN_CODE = P_TXN_CODE
                             AND CTD_MSG_TYPE = P_MSG;
END IF;

                    IF SQL%ROWCOUNT <> 1
                    THEN
                        V_ERR_MSG :=
                            'Problem while updating into CMS_TRANSACTION_LOG_DTL';
                        V_RESP_CDE := '89';
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
                            'Problem while updating into CMS_TRANSACTION_LOG_DTL '
                            || SUBSTR (SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
                END;
            END IF;

            --Added FWR -43 ends

            BEGIN
                IF P_DELIVERY_CHANNEL = '01'
                THEN
                    IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN
                    THEN
                        V_ATM_USAGEAMNT := 0;
                        V_ATM_USAGELIMIT := 1;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_ATMUSAGE_AMT = V_ATM_USAGEAMNT,
                                     CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT,
                                     CTC_POSUSAGE_AMT = 0,
                                     CTC_POSUSAGE_LIMIT = 0,
                                     CTC_PREAUTHUSAGE_LIMIT = 0,
                                     CTC_MMPOSUSAGE_AMT = 0,
                                     CTC_MMPOSUSAGE_LIMIT = 0,
                                     CTC_BUSINESS_DATE =
                                         TO_DATE (P_TRAN_DATE || '23:59:59',
                                                     'yymmdd' || 'hh24:mi:ss')
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 7 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    ELSE
                        V_ATM_USAGELIMIT := V_ATM_USAGELIMIT + 1;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 8 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    END IF;
                END IF;

                IF P_DELIVERY_CHANNEL = '02'
                THEN
                    IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN
                    THEN
                        V_POS_USAGEAMNT := 0;
                        V_POS_USAGELIMIT := 1;
                        V_PREAUTH_USAGE_LIMIT := 0;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_POSUSAGE_AMT = V_POS_USAGEAMNT,
                                     CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT,
                                     CTC_ATMUSAGE_AMT = 0,
                                     CTC_ATMUSAGE_LIMIT = 0,
                                     CTC_MMPOSUSAGE_AMT = 0,
                                     CTC_MMPOSUSAGE_LIMIT = 0,
                                     CTC_BUSINESS_DATE =
                                         TO_DATE (P_TRAN_DATE || '23:59:59',
                                                     'yymmdd' || 'hh24:mi:ss'),
                                     CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 9 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    ELSE
                        V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 10 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    END IF;
                END IF;

                --Sn Usage limit updation for MMPOS
                IF P_DELIVERY_CHANNEL = '04'
                THEN
                    IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN
                    THEN
                        V_MMPOS_USAGEAMNT := 0;
                        V_MMPOS_USAGELIMIT := 1;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_POSUSAGE_AMT = 0,
                                     CTC_POSUSAGE_LIMIT = 0,
                                     CTC_ATMUSAGE_AMT = 0,
                                     CTC_ATMUSAGE_LIMIT = 0,
                                     CTC_MMPOSUSAGE_AMT = V_MMPOS_USAGEAMNT,
                                     CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT,
                                     CTC_BUSINESS_DATE =
                                         TO_DATE (P_TRAN_DATE || '23:59:59',
                                                     'yymmdd' || 'hh24:mi:ss'),
                                     CTC_PREAUTHUSAGE_LIMIT = 0
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 11 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    ELSE
                        V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 12 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
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
                P_RESP_MSG := V_ERR_MSG;

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
                    ROLLBACK;
            END;

            --Sn Commented for Transactionlog Functional Removal Phase-II changes
            /*BEGIN
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
                                RETURN;
                        END;
                    END IF;
                END IF;
            END;*/
            --En Commented for Transactionlog Functional Removal Phase-II changes

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
                                                                 CTD_DEVICE_ID, --Added FWR -43
                                                                 CTD_MOBILE_NUMBER --Added FWR -43
                                                                                        )
                      VALUES (P_DELIVERY_CHANNEL,
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
                                 P_DEVICE_ID,                                    --Added FWR -43
                                 P_MOBILE_NO                                    --Added FWR -43
                                                );

                P_RESP_MSG := V_ERR_MSG;
            EXCEPTION
                WHEN OTHERS
                THEN
                    P_RESP_MSG :=
                        'Problem while inserting data into transaction log  dtl'
                        || SUBSTR (SQLERRM, 1, 300);
                    P_RESP_CODE := '69';                         -- Server Declined
                    ROLLBACK;
                    RETURN;
            END;


            -----------------------------------------------
            --SN: Added on 20-Apr-2013 for defect 10871
            -----------------------------------------------

            IF V_PROD_CODE IS NULL
            THEN
                BEGIN
                    SELECT CAP_PROD_CODE, CAP_CARD_TYPE, CAP_CARD_STAT, CAP_ACCT_NO
                      INTO V_PROD_CODE, V_PROD_CATTYPE, V_APPLPAN_CARDSTAT, V_ACCT_NUMBER
                      FROM CMS_APPL_PAN
                     WHERE CAP_INST_CODE = P_INST_CODE
                             AND CAP_PAN_CODE = V_HASH_PAN;                    --P_card_no;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        NULL;
                END;
            END IF;


            IF V_DR_CR_FLAG IS NULL
            THEN
                BEGIN
                    SELECT CTM_CREDIT_DEBIT_FLAG
                      INTO V_DR_CR_FLAG
                      FROM CMS_TRANSACTION_MAST
                     WHERE      CTM_TRAN_CODE = P_TXN_CODE
                             AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                             AND CTM_INST_CODE = P_INST_CODE;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        NULL;
                END;
            END IF;

            IF v_timestamp IS NULL
            THEN
                v_timestamp := SYSTIMESTAMP; -- Added on 20-Apr-2013 for defect 10871
            END IF;
        -----------------------------------------------
        --EN: Added on 20-Apr-2013 for defect 10871
        -----------------------------------------------


        WHEN OTHERS
        THEN
            ROLLBACK TO V_AUTH_SAVEPOINT;

            BEGIN
                SELECT CTC_ATMUSAGE_LIMIT, CTC_POSUSAGE_LIMIT, CTC_BUSINESS_DATE, CTC_PREAUTHUSAGE_LIMIT, CTC_MMPOSUSAGE_LIMIT
                  INTO V_ATM_USAGELIMIT, V_POS_USAGELIMIT, V_BUSINESS_DATE_TRAN, V_PREAUTH_USAGE_LIMIT, V_MMPOS_USAGELIMIT
                  FROM CMS_TRANSLIMIT_CHECK
                 WHERE      CTC_INST_CODE = P_INST_CODE
                         AND CTC_PAN_CODE = V_HASH_PAN
                         AND CTC_MBR_NUMB = P_MBR_NUMB;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    V_ERR_MSG :=
                            'Cannot get the Transaction Limit Details of the Card'
                        || V_RESP_CDE
                        || SUBSTR (SQLERRM, 1, 300);
                    V_RESP_CDE := '21';
                    RAISE EXP_REJECT_RECORD;
                WHEN OTHERS
                THEN
                    V_ERR_MSG :=
                        'Error while selecting 3 CMS_TRANSLIMIT_CHECK'
                        || SUBSTR (SQLERRM, 1, 200);
                    V_RESP_CDE := '21';
                    RAISE EXP_REJECT_RECORD;
            END;

            BEGIN
                IF P_DELIVERY_CHANNEL = '01'
                THEN
                    IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN
                    THEN
                        V_ATM_USAGEAMNT := 0;
                        V_ATM_USAGELIMIT := 1;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_ATMUSAGE_AMT = V_ATM_USAGEAMNT,
                                     CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT,
                                     CTC_POSUSAGE_AMT = 0,
                                     CTC_POSUSAGE_LIMIT = 0,
                                     CTC_PREAUTHUSAGE_LIMIT = 0,
                                     CTC_MMPOSUSAGE_AMT = 0,
                                     CTC_MMPOSUSAGE_LIMIT = 0,
                                     CTC_BUSINESS_DATE =
                                         TO_DATE (P_TRAN_DATE || '23:59:59',
                                                     'yymmdd' || 'hh24:mi:ss')
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 13 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    ELSE
                        V_ATM_USAGELIMIT := V_ATM_USAGELIMIT + 1;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_ATMUSAGE_LIMIT = V_ATM_USAGELIMIT
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 14 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    END IF;
                END IF;

                IF P_DELIVERY_CHANNEL = '02'
                THEN
                    IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN
                    THEN
                        V_POS_USAGEAMNT := 0;
                        V_POS_USAGELIMIT := 1;
                        V_PREAUTH_USAGE_LIMIT := 0;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_POSUSAGE_AMT = V_POS_USAGEAMNT,
                                     CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT,
                                     CTC_ATMUSAGE_AMT = 0,
                                     CTC_ATMUSAGE_LIMIT = 0,
                                     CTC_MMPOSUSAGE_AMT = 0,
                                     CTC_MMPOSUSAGE_LIMIT = 0,
                                     CTC_BUSINESS_DATE =
                                         TO_DATE (P_TRAN_DATE || '23:59:59',
                                                     'yymmdd' || 'hh24:mi:ss'),
                                     CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 15 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    ELSE
                        V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 16 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    END IF;
                END IF;

                --Sn Usage limit updation for MMPOS
                IF P_DELIVERY_CHANNEL = '04'
                THEN
                    IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN
                    THEN
                        V_MMPOS_USAGEAMNT := 0;
                        V_MMPOS_USAGELIMIT := 1;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_POSUSAGE_AMT = 0,
                                     CTC_POSUSAGE_LIMIT = 0,
                                     CTC_ATMUSAGE_AMT = 0,
                                     CTC_ATMUSAGE_LIMIT = 0,
                                     CTC_MMPOSUSAGE_AMT = V_MMPOS_USAGEAMNT,
                                     CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT,
                                     CTC_BUSINESS_DATE =
                                         TO_DATE (P_TRAN_DATE || '23:59:59',
                                                     'yymmdd' || 'hh24:mi:ss'),
                                     CTC_PREAUTHUSAGE_LIMIT = 0
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 17 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
                                V_RESP_CDE := '21';
                                RAISE EXP_REJECT_RECORD;
                        END;
                    ELSE
                        V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;

                        BEGIN
                            UPDATE CMS_TRANSLIMIT_CHECK
                                SET CTC_POSUSAGE_LIMIT = V_POS_USAGELIMIT
                             WHERE      CTC_INST_CODE = P_INST_CODE
                                     AND CTC_PAN_CODE = V_HASH_PAN
                                     AND CTC_MBR_NUMB = P_MBR_NUMB;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                V_ERR_MSG :=
                                    'Error while updating 18 CMS_TRANSLIMIT_CHECK'
                                    || SUBSTR (SQLERRM, 1, 200);
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
                 WHERE      CMS_INST_CODE = P_INST_CODE
                         AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                         AND CMS_RESPONSE_ID = V_RESP_CDE;

                P_RESP_MSG := V_ERR_MSG;
            EXCEPTION
                WHEN OTHERS
                THEN
                    P_RESP_MSG :=
                            'Problem while selecting data from response master '
                        || V_RESP_CDE
                        || SUBSTR (SQLERRM, 1, 300);
                    P_RESP_CODE := '69';                         -- Server Declined
                    ROLLBACK;
            END;

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
                                                                 CTD_DEVICE_ID, --Added FWR -43
                                                                 CTD_MOBILE_NUMBER --Added FWR -43
                                                                                        )
                      VALUES (P_DELIVERY_CHANNEL,
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
                                 P_DEVICE_ID,                                    --Added FWR -43
                                 P_MOBILE_NO                                    --Added FWR -43
                                                );
            EXCEPTION
                WHEN OTHERS
                THEN
                    P_RESP_MSG :=
                        'Problem while inserting data into transaction log  dtl'
                        || SUBSTR (SQLERRM, 1, 300);
                    P_RESP_CODE := '69';          -- Server Decline Response 220509
                    ROLLBACK;
                    RETURN;
            END;

            --En select response code and insert record into txn log dtl


            -----------------------------------------------
            --SN: Added on 20-Apr-2013 for defect 10871
            -----------------------------------------------

            IF V_PROD_CODE IS NULL
            THEN
                BEGIN
                    SELECT CAP_PROD_CODE, CAP_CARD_TYPE, CAP_CARD_STAT, CAP_ACCT_NO
                      INTO V_PROD_CODE, V_PROD_CATTYPE, V_APPLPAN_CARDSTAT, V_ACCT_NUMBER
                      FROM CMS_APPL_PAN
                     WHERE CAP_INST_CODE = P_INST_CODE
                             AND CAP_PAN_CODE = V_HASH_PAN;                    --P_card_no;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        NULL;
                END;
            END IF;


            IF V_DR_CR_FLAG IS NULL
            THEN
                BEGIN
                    SELECT CTM_CREDIT_DEBIT_FLAG
                      INTO V_DR_CR_FLAG
                      FROM CMS_TRANSACTION_MAST
                     WHERE      CTM_TRAN_CODE = P_TXN_CODE
                             AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                             AND CTM_INST_CODE = P_INST_CODE;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        NULL;
                END;
            END IF;

            IF v_timestamp IS NULL
            THEN
                v_timestamp := SYSTIMESTAMP; -- Added on 20-Apr-2013 for defect 10871
            END IF;
    -----------------------------------------------
    --EN: Added on 20-Apr-2013 for defect 10871
    -----------------------------------------------

    END;

    --- Sn create GL ENTRIES

    --Sn generate auth id
    BEGIN
        --     SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;

        --     SELECT V_AUTHID_DATE || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
        SELECT LPAD (SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;
    EXCEPTION
        WHEN OTHERS
        THEN
            P_RESP_MSG :=
                'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            P_RESP_CODE := '89';                               -- Server Declined
            ROLLBACK;
    END;

    --En generate auth id

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
                                             PROXY_NUMBER,
                                             REVERSAL_CODE,
                                             CUSTOMER_ACCT_NO,
                                             ACCT_BALANCE,
                                             LEDGER_BALANCE,
                                             RESPONSE_ID,
                                             IPADDRESS,
                                             CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
                                             FEE_PLAN,
                                             FEEATTACHTYPE, --Added by Trivikram on 05-Sep-2012
                                             ACCT_TYPE,             --Added for defect 10871
                                             TIME_STAMP,            --Added for defect 10871
                                             Error_msg,                --Added for defect 10871
                                             remark, --Added for error msg need to display in CSR(declined by rule)
                                             PARTNER_ID           )
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
                            SUBSTR (P_TRAN_TIME, 1, 10),
                            V_HASH_PAN,
                            NULL,
                            NULL,                                         --P_topup_acctno      ,
                            NULL,                                           --P_topup_accttype,
                            P_BANK_CODE,
                            TRIM (
                                TO_CHAR (NVL (V_TOTAL_AMT, 0),
                                            '99999999999999990.99')), -- NVL added for defect 10871
                            P_RULE_INDICATOR,
                            P_RULEGRP_ID,
                            P_MCC_CODE,
                            P_CURR_CODE,
                            NULL,                                               -- P_add_charge,
                            V_PROD_CODE,
                            V_PROD_CATTYPE,
                            '0.00',          --null replaced by 0.00 for defect 10871
                            P_DECLINE_RULEID,
                            P_ATMNAME_LOC,
                            V_AUTH_ID,
                            V_TRANS_DESC,
                            TRIM (
                                TO_CHAR (NVL (V_TRAN_AMT, 0), '99999999999999990.99')), -- NVL added for defect 10871
                            '0.00',          --null replaced by 0.00 for defect 10871
                            '0.00', -- Partial amount (will be given for partial txn) --null replaced by 0.00 for defect 10871
                            P_MCCCODE_GROUPID,
                            P_CURRCODE_GROUPID,
                            P_TRANSCODE_GROUPID,
                            P_RULES,
                            '',
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
                            ROUND (NVL (V_ACCT_BALANCE, 0), 2), --NVL added for defect 10871 --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                            ROUND (NVL (V_LEDGER_BAL, 0), 2), --NVL added for defect 10871 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                            V_RESP_CDE,
                            P_IPADDRESS,
                            V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
                            V_FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
                            V_FEEATTACH_TYPE,     -- Added by Trivikram on 05-Sep-2012
                            v_cam_type_code,                        --Added for defect 10871
                            v_timestamp,                            --Added for defect 10871
                            V_ERR_MSG,                                --Added for defect 10871
                            V_ERR_MSG, --Added for error msg need to display in CSR(declined by rule)
                            p_partner_id_in             );


        P_CAPTURE_DATE := V_BUSINESS_DATE;
        P_AUTH_ID := V_AUTH_ID;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            P_RESP_CODE := '69';                               -- Server Declione
            P_RESP_MSG :=
                'Problem while inserting data into transaction log  '
                || SUBSTR (SQLERRM, 1, 300);
    END;

    IF P_RESP_MSG = 'OK'
    THEN
        P_RESP_MSG := ' ';                             --added for response data
    END IF;
--En create a entry in txn log
EXCEPTION
    WHEN OTHERS
    THEN
        ROLLBACK;
        P_RESP_CODE := '69';                                  -- Server Declined
        P_RESP_MSG :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END;
/
show error