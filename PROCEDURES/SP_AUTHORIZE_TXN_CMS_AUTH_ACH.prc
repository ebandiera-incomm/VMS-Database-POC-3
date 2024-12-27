create or replace PROCEDURE        VMSCMS.SP_AUTHORIZE_TXN_CMS_AUTH_ACH (
                                            p_INST_CODE        IN NUMBER,
                                            p_MSG              IN VARCHAR2,
                                            p_RRN              VARCHAR2,
                                            p_DELIVERY_CHANNEL VARCHAR2,
                                            p_TERM_ID          VARCHAR2,
                                            p_TXN_CODE         VARCHAR2,
                                            p_TXN_MODE  VARCHAR2,
                                            p_TRAN_DATE VARCHAR2,
                                            p_TRAN_TIME VARCHAR2,
                                            p_CARD_NO   VARCHAR2,
                                            p_BANK_CODE VARCHAR2,
                                            p_TXN_AMT   NUMBER,
                                            p_MERCHANT_NAME     VARCHAR2,
                                            p_MERCHANT_CITY     VARCHAR2,
                                            p_MCC_CODE          VARCHAR2,
                                            p_CURR_CODE         VARCHAR2,
                                            p_PROD_ID           VARCHAR2,
                                            p_CATG_ID           VARCHAR2,
                                            p_TIP_AMT           VARCHAR2,
                                            p_TO_ACCT_NO        VARCHAR2,--Added for card to card transfer by removing the p_DECLINE_RULEID as the rule id is not passed
                                            p_ATMNAME_LOC       VARCHAR2,
                                            p_MCCCODE_GROUPID   VARCHAR2,
                                            p_CURRCODE_GROUPID  VARCHAR2,
                                            p_TRANSCODE_GROUPID VARCHAR2,
                                            p_RULES             VARCHAR2,
                                            p_PREAUTH_DATE      DATE,
                                            p_CONSODIUM_CODE    IN VARCHAR2,
                                            p_PARTNER_CODE      IN VARCHAR2,
                                            p_EXPRY_DATE        IN VARCHAR2,
                                            p_STAN              IN VARCHAR2,
                                            p_MBR_NUMB          IN VARCHAR2,
                                            p_RVSL_CODE         IN VARCHAR2,
                                            p_CURR_CONVERT_AMNT IN VARCHAR2,--Added for transactionlog insert
                                            p_ACHFILENAME       IN VARCHAR2,
                                            p_ODFI              IN VARCHAR2,
                                            p_RDFI              IN VARCHAR2,
                                            p_SECCODES          IN VARCHAR2,
                                            p_IMPDATE           IN VARCHAR2,
                                            p_PROCESSDATE       IN VARCHAR2,
                                            p_EFFECTIVEDATE     IN VARCHAR2,
                                            p_TRACENUMBER       IN VARCHAR2,
                                            p_INCOMING_CRFILEID IN VARCHAR2,
                                            p_ACHTRANTYPE_ID    IN VARCHAR2,
                                            p_BEFRETRAN_LEDGERBAL  IN VARCHAR2,
                                            p_BEFRETRAN_AVAILBALANCE IN VARCHAR2,
                                            p_INDIDNUM               IN VARCHAR2,
                                            p_INDNAME                IN VARCHAR2,
                                            p_COMPANYNAME            IN VARCHAR2,
                                            p_COMPANYID              IN VARCHAR2,
                                            p_ACH_ID                 IN VARCHAR2,
                                            p_COMPENTRYDESC          IN VARCHAR2,
                                            p_CUSTOMERLASTNAME       IN VARCHAR2,
                                            p_cardstatus             IN VARCHAR2,
                                            p_PROCESSTYPE      IN VARCHAR2,
                                            p_AUTH_ID      in VARCHAR2,
                                            P_CUSTFIRSTNAME    IN VARCHAR2, ---- Added by Trivikram on 29/Sep/2012 logging into transactionlog for display Customer Name in ACH Report FSS-418
                                            P_ach_exp_flag in varchar2,  -- CSR ACH Exception page display changes 18 sep 13 - Amudhan
                                            P_RESP_ID      OUT VARCHAR2,
                                            p_RESP_CODE    OUT VARCHAR2,
                                            p_RESP_MSG     OUT VARCHAR2,
                                            p_CAPTURE_DATE OUT DATE) IS

/*************************************************************************************************
     * modified by      : B.Besky
     * modified Date    : 08-OCT-12
     * modified reason  : Added IN Parameters in SP_STATUS_CHECK_GPR
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 08-OCT-12
     * Build Number     : CMS3.5.1_RI0019_B0007
     * Modified by      : Sagar M.
     * Modified Date    : 09-Feb-13
     * Modified reason  : Product Category spend limit not being adhered to by VMS
     * Modified for     : NA
     * Reviewer         : Dhiarj
     * Build Number     : CMS3.5.1_RI0023.2_B0002

     * Modified By      : Sagar M.
     * Modified Date    : 17-Apr-2013
     * Modified for     : Defect 10871
     * Modified Reason  : Logging of below details in tranasctionlog and statementlog table
                          1) ledger balance in statementlog
                          2) Product code,Product category code,Card status,Acct Type,drcr flag
                          3) Timestamp and Amount values logging correction
     * Reviewer         : Dhiraj
     * Reviewed Date    : 17-Apr-2013
     * Build Number     : RI0024.1_B0013

     * Modified By      : Siva Kumar A.
     * Modified Date    : 08-May-2013
     * Modified for     : MVHOST-321
     * Modified Reason  : Error message changed for Maximum card balance validation
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : RI0024.1_B0016

     * Modified by      : Dhinakaran B
     * Modified Reason  : MVHOST - 346
     * Modified Date    : 14-MAY-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 14-MAY-2013
     * Build Number     : RI0024.1_B0023

      * Modified by      : Ravi N
      * Modified for     : Mantis ID 0011282
      * Modified Reason  : Correction of Insufficient balance spelling mistake
      * Modified Date    : 20-Jun-2013
      * Reviewer         : Dhiraj
      * Reviewed Date    : 20-Jun-2013
      * Build Number     : RI0024.2_B0006

     * Modified By      :  Shweta M
     * Modified Date    :  14-Aug-2013
     * Modified For     :  MVHOST-367
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  19-aug-2013
     * Build Number     :  RI0024.4_B0002

      * Modified by      :  Amudhan  S.
      * Modified Reason  :  Exception queue change of Maximum card balance Exceed ed scenario-MVHOST-478 and Mantis Id: 12416
      * Modified Date    :  18-Sep-2013
      * Reviewer         :  Dhiraj
      * Reviewed Date    :
      * Build Number     :  RI0024.4_B0016

      * Modified by      :  Sagar M
      * Modified for     :  FSS-1315
      * Modified Reason  :  To ignore insufficient balance check for prenote transaction
                            (24.3.8 CHANGES MERGED)
      * Modified Date    :  23-Sep-2013
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  23-Sep-2013
      * Build Number     :  RI0024.4.1_B0001

      * Modified by     :  Sagar M (RI0024.3.8_B0004 changes merged)
      * Modified for    :  1) Defect 12498 (Review observation changes for FSS-1315)
                           2) Defect 12487
      * Modified Reason :  1) Review observation changes for FSS-1315
                           2) to log proper balance in transactionlog defect 12487
      * Modified Date   :  30-Sep-2013
      * Reviewer        :  Dhiraj
      * Reviewed Date   :  30-Sep-2013
      * Build Number    :  RI0024.4.3_B0001

      * Modified by     :  Sagar M (RI0024.3.8_B0004 changes merged)
      * Modified for    :  Defect fix 12487
      * Modified Reason :  1) to log proper balance in transactionlog for prenote transaction
      * Modified Date   :  04-Oct-2013
      * Reviewer        :  Dhiraj
      * Reviewed Date   :  04-Oct-2013
      * Build Number    :  RI0024.4.3_B0001

      * Modified By      : RAVI N
      * Modified Date    : 29-JAN-2014
      * Modified Reason  : 0013542 [Negative Fees] && MVCSD-4471
      * Reviewer         : Dhiraj
      * Reviewed Date    :
      * Build Number     : RI0027.1_B0001

     * Modified By      : Revathi D
     * Modified Date    : 06-APR-2014
     * Modified for     :
     * Modified Reason  : 1.Round functions added upto 2nd decimal for amount columns in CMS_CHARGE_DTL,CMS_ACCTCLAWBACK_DTL,
                          CMS_STATEMENTS_LOG,TRANSACTIONLOG.
                          2.V_TRAN_AMT initial value assigned as zero.
     * Reviewer         : Pankaj S.
     * Reviewed Date    : 03-APR-2014
     * Build Number     : CMS3.5.1_RI0027.2_B0004

    * modified by       : Amudhan S/Siva Kumar M
    * modified Date     : 23-may-14/05-Jun-2014
    * modified for      : FWR 64 /HOSTCC-24
    * modified reason   : To restrict clawback fee entries as per the configuration done by user/The ACH Reason Code FROM R20 TO R03 to support Inactive or Non-Personalized cards in instances where a Direct Deposit is rejected. This change will need effective for all GPR Products.
    * Reviewer          : spankaj
    * Build Number      : RI0027.3_B0001
     * Modified By      : Sai
    * Modified Date    : 05-Oct-2014
    * Modified Reason  : 15811
    * Reviewer         : Spankaj
    * Build Number     : RI0027.4_B0003

      * Modified Date    : 31-OCT-2014
     * Modified By      : Abdul Hameed M.A
     * Modified for     : MVHOST 1022
     * Reviewer         : Spankaj
     * Release Number   : RI0027.4.3_B0001

      * Modified Date    : 10-NOV-2014
     * Modified By      : Abdul Hameed M.A
     * Modified for     : MANTIS id 15866
     * Reviewer         : Saravanakumar
     * Release Number   : RI0027.4.3_B0002

     * Modified By      : Pankaj S.
     * Modified Date    : 22-07-2015
     * Modified Reason  : For new ach changes
     * Reviewer         : Sarvanan
     * Reviewed Date    :
     * Build Number     : VMSGPRHOST3.0.4

    * Modified by      : Ramesh A
    * Modified for     : FSS-3610
    * Modified Date    : 31-Aug-2015
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOST_3.1_B0008

       * Modified by       :Siva kumar
       * Modified Date    : 22-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006

    * Modified By      : MageshKumar S
    * Modified Date    : 10/08/2016
    * Purpose          : FSS-4354&4356
    * Reviewer         : Saravana Kumar
    * Release Number   : VMSGPRHOSTCSD_4.2.1_B0001

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

            * Modified by       : Akhil
     * Modified Date     : 05-JAN-18
     * Modified For      : VMS-103
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.12

     * Modified by       : T. Narayanan
     * Modified Date     : 08-JAN-2020
     * Modified For      : VMS-1462
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_24.1
	 
	 * Modified by       : Pankaj S.
     * Modified Date     : 17-JUN-2022
     * Modified For      : VMS-5971
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_R65
 *************************************************************************************************/

  V_ERR_MSG          VARCHAR2(900) := 'OK';
  V_ACCT_BALANCE     NUMBER;
  V_TRAN_AMT         NUMBER:=0;
  V_AUTH_ID          TRANSACTIONLOG.AUTH_ID%TYPE;
  V_TOTAL_AMT        NUMBER;
  V_TRAN_DATE        DATE;
  V_FUNC_CODE        CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_PROD_CODE        CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE     CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_FEE_AMT          NUMBER;
  V_TOTAL_FEE        NUMBER;
  V_UPD_AMT          NUMBER;
  V_NARRATION        VARCHAR2(300);
  V_FEE_OPENING_BAL  NUMBER;
  V_RESP_CDE         VARCHAR2(3);
  V_EXPRY_DATE       DATE;
  V_DR_CR_FLAG       VARCHAR2(2);
  V_OUTPUT_TYPE      VARCHAR2(2);
  V_APPLPAN_CARDSTAT CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_ATMONLINE_LIMIT  CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  V_POSONLINE_LIMIT  CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  V_PRECHECK_FLAG    NUMBER;
  V_PREAUTH_FLAG     NUMBER;
  V_GL_UPD_FLAG      TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
  V_GL_ERR_MSG       VARCHAR2(500);
  V_SAVEPOINT        NUMBER := 0;
  V_TRAN_FEE         NUMBER;
  V_ERROR            VARCHAR2(500);
  V_BUSINESS_DATE    DATE;
  V_BUSINESS_TIME    VARCHAR2(5);
  V_CUTOFF_TIME      VARCHAR2(5);
  V_CARD_CURR        VARCHAR2(5);
  V_FEE_CODE         CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  V_FEE_CRGL_CATG    CMS_PRODCATTYPE_FEES.CPF_CRGL_CATG%TYPE;
  V_FEE_CRGL_CODE    CMS_PRODCATTYPE_FEES.CPF_CRGL_CODE%TYPE;
  V_FEE_CRSUBGL_CODE CMS_PRODCATTYPE_FEES.CPF_CRSUBGL_CODE%TYPE;
  V_FEE_CRACCT_NO    CMS_PRODCATTYPE_FEES.CPF_CRACCT_NO%TYPE;
  V_FEE_DRGL_CATG    CMS_PRODCATTYPE_FEES.CPF_DRGL_CATG%TYPE;
  V_FEE_DRGL_CODE    CMS_PRODCATTYPE_FEES.CPF_DRGL_CODE%TYPE;
  V_FEE_DRSUBGL_CODE CMS_PRODCATTYPE_FEES.CPF_DRSUBGL_CODE%TYPE;
  V_FEE_DRACCT_NO    CMS_PRODCATTYPE_FEES.CPF_DRACCT_NO%TYPE;
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
  V_TXN_TYPE         NUMBER(1);
  V_MINI_TOTREC      NUMBER(2);
  V_MINISTMT_ERRMSG  VARCHAR2(500);
  V_MINISTMT_OUTPUT  VARCHAR2(900);
  V_FEE_ATTACH_TYPE  VARCHAR2(1);
  EXP_REJECT_RECORD EXCEPTION;
  V_LEDGER_BAL     NUMBER;
  V_CARD_ACCT_NO   VARCHAR2(20);
  V_HASH_PAN       CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN       CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_MAX_CARD_BAL   NUMBER;
  V_MIN_ACT_AMT    NUMBER; --added for minimum activation amount check
  V_CURR_DATE      DATE;
  V_UPD_LEDGER_BAL NUMBER;
  V_PROXUNUMBER    CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER    CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_TRANS_DESC     cms_transaction_mast.ctm_tran_desc%TYPE; --VARCHAR2(50);
   V_STATUS_CHK            NUMBER;
   v_appliocationprocess_stat   VARCHAR2 (3);
   --Added by Deepa On June 19 2012 for Fees Changes
   V_FEEAMNT_TYPE          CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
  V_PER_FEES              CMS_FEE_MAST.CFM_PER_FEES%TYPE;
  V_FLAT_FEES             CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_CLAWBACK              CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
  V_FEE_PLAN              CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;
  V_CLAWBACK_AMNT         CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_FREETXN_EXCEED VARCHAR2(1); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_DURATION VARCHAR2(20); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_FEEATTACH_TYPE  VARCHAR2(2); -- Added by Trivikram on 5th Sept 2012
  V_CAM_TYPE_CODE   cms_acct_mast.cam_type_code%type; -- Added on 17-Apr-2013 for defect 10871
  v_timestamp       timestamp;                         -- Added on 17-Apr-2013 for defect 10871

  V_LOGIN_TXN       CMS_TRANSACTION_MAST.CTM_LOGIN_TXN%TYPE;  --Added For Clawback Changes (MVHOST - 346)  on 14/05/2013
  V_ACTUAL_FEE_AMNT NUMBER;                                   --Added For Clawback Changes (MVHOST - 346)  on 14/05/2013
  V_CLAWBACK_COUNT  NUMBER;                                   --Added For Clawback Changes (MVHOST - 346)  on 14/05/2013
  V_ACH_AUTO_CLEAR_FLAG varchar2(2); -- CSR ACH Exception page display changes 18 sep 13 - Amudhan
  v_fee_desc        cms_fee_mast.cfm_fee_desc%TYPE;  -- Added for MVCSD-4471
   v_tot_clwbck_count CMS_FEE_MAST.cfm_clawback_count%TYPE; -- Added for FWR 64
  v_chrg_dtl_cnt    NUMBER;     -- Added for FWR 64
  v_achbypass  varchar2(1);
  V_PROFILE_CODE       CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
  v_badcredit_flag             cms_prod_cattype.cpc_badcredit_flag%TYPE;
   v_badcredit_transgrpid       vms_group_tran_detl.vgd_group_id%TYPE;
     v_cnt       number;
         v_card_stat                  cms_appl_pan.cap_card_stat%TYPE   := '12';
         v_initialload_amt         cms_acct_mast.cam_new_initialload_amt%type;
         v_enable_flag varchar2(20):='Y';
         V_BANK_SEC_COUNT NUMBER(5):=0;
		 v_Retperiod  date;  --Added for VMS-5739/FSP-991
		v_Retdate  date; --Added for VMS-5739/FSP-991
 BEGIN
  SAVEPOINT V_AUTH_SAVEPOINT;
  V_RESP_CDE   := '1';
  p_RESP_MSG := 'OK';
  V_TRAN_AMT   := p_CURR_CONVERT_AMNT;

  BEGIN

    --SN CREATE HASH PAN
    BEGIN
     V_HASH_PAN := GETHASH(p_CARD_NO);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG := 'Error while converting pan into hash value' ||
                 SUBSTR(SQLERRM, 1, 200);                           -- Change in error message as per review observations on FSS-1315 -- 12498
       RAISE EXP_REJECT_RECORD;
    END;
    --EN CREATE HASH PAN

    --SN create encr pan
    BEGIN
     V_ENCR_PAN := FN_EMAPS_MAIN(p_CARD_NO);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG := 'Error while converting pan into encrypted value' ||
                 SUBSTR(SQLERRM, 1, 200);                           -- Change in error message as per review observations on FSS-1315 -- 12498
       RAISE EXP_REJECT_RECORD;
    END;
    --EN create encr pan

    /*  -- Commented to use below query as per review observation FSS-1315 -- 12498

    BEGIN
     SELECT CTM_TRAN_DESC
       INTO V_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = p_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = p_DELIVERY_CHANNEL AND
           CTM_INST_CODE = p_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_TRANS_DESC := 'Transaction type ' || p_TXN_CODE;
     WHEN OTHERS THEN

       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error in finding the narration ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

    END;

    */ -- Commented to use below query as per review observation FSS-1315 -- 12498

    --SN : details fetched using single query instead of multiple queries as per review observation FSS-1315 -- 12498

    BEGIN

     SELECT CTM_CREDIT_DEBIT_FLAG,
            CTM_OUTPUT_TYPE,
            TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
            CTM_LOGIN_TXN,  --Added For Clawback changes (MVHOST - 346)  on 14052013
            CTM_TRAN_DESC
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_LOGIN_TXN,
            V_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = p_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = p_DELIVERY_CHANNEL AND
           CTM_INST_CODE = p_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21'; --Ineligible Transaction
       V_ERR_MSG  := 'Transflag  not defined for txn code ' ||
                  p_TXN_CODE || ' and delivery channel ' ||
                  p_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21'; --Ineligible Transaction
       V_ERR_MSG  := 'Error while selecting transflag ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --EN : details fetched using single query instead of multiple queries as per review observation FSS-1315 -- 12498
    --SN: VMS-5971 changes
	IF p_delivery_channel = '15' AND p_rules = 'E' THEN
       IF v_dr_cr_flag = 'CR' THEN 
          v_dr_cr_flag := 'DR';
       END IF;
       v_trans_desc := v_trans_desc||' - Reversal';
    END IF;
	--EN: VMS-5971 changes

  V_AUTH_ID :=p_AUTH_ID;
    --sN CHECK INST CODE
    BEGIN
     IF p_INST_CODE IS NULL THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Institute code cannot be null ';
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting Institute code ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --eN CHECK INST CODE

    --Sn check txn currency
    BEGIN
     IF TRIM(p_CURR_CODE) IS NULL THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Transaction currency  cannot be null ';
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting Transcurrency  ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En check txn currency

    --Sn get date
    BEGIN
     V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(p_TRAN_DATE), 1, 8) || ' ' ||
                        SUBSTR(TRIM(p_TRAN_TIME), 1, 10),
                        'yyyymmdd hh24:mi:ss');
    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Problem while converting transaction date ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En get date
    --Sn find service tax
    BEGIN
     SELECT CIP_PARAM_VALUE
       INTO V_SERVICETAX_PERCENT
       FROM CMS_INST_PARAM
      WHERE CIP_PARAM_KEY = 'SERVICETAX' AND CIP_INST_CODE = p_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Service Tax is  not defined in the system';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting service tax from system '||substr(sqlerrm,1,100); -- Sqlerrm appended as per review observation for FSS-1315 -- 12498
       RAISE EXP_REJECT_RECORD;
    END;

    --En find service tax

    --Sn find cess
    BEGIN
     SELECT CIP_PARAM_VALUE
       INTO V_CESS_PERCENT
       FROM CMS_INST_PARAM
      WHERE CIP_PARAM_KEY = 'CESS' AND CIP_INST_CODE = p_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Cess is not defined in the system';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting cess from system '||substr(sqlerrm,1,100); -- Sqlerrm appended as per review observation for FSS-1315 -- 12498
       RAISE EXP_REJECT_RECORD;
    END;

    --En find cess

    ---Sn find cutoff time
    BEGIN
     SELECT CIP_PARAM_VALUE
       INTO V_CUTOFF_TIME
       FROM CMS_INST_PARAM
      WHERE CIP_PARAM_KEY = 'CUTOFF' AND CIP_INST_CODE = p_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_CUTOFF_TIME := 0;
       V_RESP_CDE    := '21';
       V_ERR_MSG     := 'Cutoff time is not defined in the system';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting cutoff  dtl  from system '||substr(sqlerrm,1,100); -- Sqlerrm appended as per review observation for FSS-1315 -- 12498
       RAISE EXP_REJECT_RECORD;
    END;

    ---En find cutoff time

   --Sn select authorization processe flag
    BEGIN
     SELECT PTP_PARAM_VALUE
       INTO V_PRECHECK_FLAG
       FROM PCMS_TRANAUTH_PARAM
      WHERE PTP_PARAM_NAME = 'PRE CHECK' AND PTP_INST_CODE = p_INST_CODE;
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
      WHERE PTP_PARAM_NAME = 'PRE AUTH' AND PTP_INST_CODE = p_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21'; --only for master setups
       V_ERR_MSG  := 'Master set up is not done for Authorization Process';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21'; --only for master setups
       V_ERR_MSG  := 'Error while selecting preauth flag' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En select authorization process   flag
    --Sn find card detail
    BEGIN
     SELECT CAP_PROD_CODE,
           CAP_CARD_TYPE,
           TO_CHAR(CAP_EXPRY_DATE, 'DD-MON-YY'),
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
      WHERE CAP_INST_CODE = p_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '16'; --Ineligible Transaction
       V_ERR_MSG  := 'Card number not found ' || p_TXN_CODE;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '12';
       V_ERR_MSG  := 'Problem while selecting card detail' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En find card detail
       --Sn GPR Card status check
  BEGIN
       SP_STATUS_CHECK_GPR(p_INST_CODE,
                    p_CARD_NO,
                    p_DELIVERY_CHANNEL,
                    V_EXPRY_DATE,
                    V_APPLPAN_CARDSTAT,
                    p_TXN_CODE,
                    p_TXN_MODE,
                    V_PROD_CODE,
                    V_PROD_CATTYPE,
                    p_MSG,
                    p_TRAN_DATE,
                    p_TRAN_TIME,
                    NULL,
                    NULL,   --Added IN Parameters in SP_STATUS_CHECK_GPR for pos sign indicator,international indicator,mcccode by Besky on 08-oct-12
                    p_MCC_CODE,
                    V_RESP_CDE,
                    V_ERR_MSG);

       IF ((V_RESP_CDE <> '1' AND V_ERR_MSG <> 'OK') OR (V_RESP_CDE <> '0' AND V_ERR_MSG <> 'OK')) THEN
          v_achbypass:=vmsusach.check_achbypass ( v_acct_number, UPPER (TRIM (p_companyname)), 8 );
          IF v_achbypass='N' THEN
            v_achbypass :='8';
           RAISE EXP_REJECT_RECORD;
          ELSE
             v_resp_cde:='1';
          END IF;
       ELSE
            V_STATUS_CHK:=V_RESP_CDE;
            V_RESP_CDE:='1';
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
  IF V_STATUS_CHK='1' THEN

    -- Expiry Check
    IF p_DELIVERY_CHANNEL NOT IN ('11','15') THEN  --'15' added by Pankaj For ACH canada changes
     BEGIN


       IF TO_DATE(p_TRAN_DATE, 'YYYYMMDD') >
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
        V_ERR_MSG  := 'ERROR IN EXPIRY DATE CHECK : Tran Date - ' ||
                    p_TRAN_DATE || ', Expiry Date - ' || V_EXPRY_DATE || ',' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;




     END;

    -- End Expiry Check
    -- Begin Added by ramkumar.MK on 4 april 4 2012
    ELSE
        BEGIN
         SELECT ccs_CARD_STATUS
        INTO v_appliocationprocess_stat
        FROM cms_cardissuance_status
       WHERE ccs_pan_code = v_hash_pan AND ccs_inst_code = p_INST_CODE;

      IF v_appliocationprocess_stat <> '15'
      THEN
         V_RESP_CDE := '225';---'12';                         --Ineligible Transaction
         V_ERR_MSG := 'INVALID APPLICATION ISSUANCE STATUS';
         RAISE EXP_REJECT_RECORD;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_RESP_CDE := '12';                         --Ineligible Transaction
         V_ERR_MSG := 'APPLICATION ISSUANCE STATUS NOT FOUND FOR CARD '||fn_mask(p_CARD_NO,'X',7,6); -- Channge in error message as per review observation for FSS-1315 -- 12498
         RAISE EXP_REJECT_RECORD;

       when EXP_REJECT_RECORD then
       raise EXP_REJECT_RECORD;
      WHEN OTHERS THEN
         V_RESP_CDE := '12';
         V_ERR_MSG :='WHILE FETCHING APPLICATION ISSUANCE STATUS '||SUBSTR(SQLERRM,1,100);          -- Channge in error message as per review observation for FSS-1315 -- 12498
         RAISE EXP_REJECT_RECORD;

   END;
    -- End Added by ramkumar.MK on 4 april 4 2012

   END IF;




    --Sn check for precheck
    IF V_PRECHECK_FLAG = 1 THEN
     BEGIN
       SP_PRECHECK_TXN(p_INST_CODE,
                    p_CARD_NO,
                    p_DELIVERY_CHANNEL,
                    V_EXPRY_DATE,
                    V_APPLPAN_CARDSTAT,
                    p_TXN_CODE,
                    p_TXN_MODE,
                    p_TRAN_DATE,
                    p_TRAN_TIME,
                    V_TRAN_AMT,
                    V_ATMONLINE_LIMIT,
                    V_POSONLINE_LIMIT,
                    V_RESP_CDE,
                    V_ERR_MSG);

       IF (V_RESP_CDE <> '1' OR V_ERR_MSG <> 'OK') THEN
          v_achbypass:=vmsusach.check_achbypass ( v_acct_number, UPPER (TRIM (p_companyname)), 8 );
          IF v_achbypass='N' THEN
            v_achbypass :='8';
           RAISE EXP_REJECT_RECORD;
          ELSE
              v_resp_cde:='1';
          END IF;
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
  END IF;
    --En check for Precheck
    --Sn check for Preauth
    IF V_PREAUTH_FLAG = 1 THEN
     BEGIN

       SP_PREAUTHORIZE_TXN(p_CARD_NO,
                       p_MCC_CODE,
                       p_CURR_CODE,
                       V_TRAN_DATE,
                       p_TXN_CODE,
                       p_INST_CODE,
                       p_TRAN_DATE,
                       p_TXN_AMT,
                       p_DELIVERY_CHANNEL,
                       V_RESP_CDE,
                       V_ERR_MSG);

       IF (V_RESP_CDE <> '1' OR V_ERR_MSG <> 'OK') THEN
          v_achbypass:=vmsusach.check_achbypass ( v_acct_number, UPPER (TRIM (p_companyname)), 9 );
          IF v_achbypass='N' THEN
            v_achbypass :='9';
            RAISE EXP_REJECT_RECORD;
          ELSE
              v_resp_cde:='1';
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

    --En check for preauth

   /*  -- Commented as per review observation FSS-1315 -- 12498

    --Sn find debit and credit flag
    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1'))
           ,CTM_LOGIN_TXN  --Added For Clawback changes (MVHOST - 346)  on 14052013
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_LOGIN_TXN
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = p_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = p_DELIVERY_CHANNEL AND
           CTM_INST_CODE = p_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21'; --Ineligible Transaction
       V_ERR_MSG  := 'Transflag  not defined for txn code ' ||
                  p_TXN_CODE || ' and delivery channel ' ||
                  p_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21'; --Ineligible Transaction
       V_ERR_MSG  := 'Error while selecting transflag ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

   */ -- Commented as per review observation FSS-1315  -- 12498

    --En find debit and credit flag
    --Sn find function code attached to txn code
  /*  BEGIN
     SELECT CFM_FUNC_CODE
       INTO V_FUNC_CODE
       FROM CMS_FUNC_MAST
      WHERE CFM_TXN_CODE = p_TXN_CODE AND CFM_TXN_MODE = p_TXN_MODE AND
           CFM_DELIVERY_CHANNEL = p_DELIVERY_CHANNEL AND
           CFM_INST_CODE = p_INST_CODE;
     --TXN mode and delivery channel we need to attach
     --bkz txn code may be same for all type of channels
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '89'; --Ineligible Transaction --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
       V_ERR_MSG  := 'Function code not defined for txn code ' ||
                  p_TXN_CODE;
       RAISE EXP_REJECT_RECORD;
     WHEN TOO_MANY_ROWS THEN
       V_RESP_CDE := '89';
       V_ERR_MSG  := 'More than one function defined for txn code ' || --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
                  p_TXN_CODE;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '89'; --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
       V_ERR_MSG  := 'Error while selecting func code' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;*/

    --En find function code attached to txn code

    --Get the card no
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO,
            CAM_TYPE_CODE,nvl(cam_new_initialload_amt,cam_initialload_amt)                                   -- Added on 17-Apr-2013 for defect 10871
       INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO,
            v_CAM_TYPE_CODE,v_initialload_amt                                 -- Added on 17-Apr-2013 for defect 10871
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO = V_ACCT_NUMBER                     -- V_ACCT_NUMBER used as per review observation FSS-1315 -- 12498
          /* (SELECT CAP_ACCT_NO                            -- Commented as per review observation FSS-1315 -- 12498
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN
                 AND CAP_MBR_NUMB = p_MBR_NUMB AND
                 CAP_INST_CODE = p_INST_CODE)       */
       AND CAM_INST_CODE = p_INST_CODE
        FOR UPDATE NOWAIT;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '14'; --Ineligible Transaction
       V_ERR_MSG  := 'Invalid Card ';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '12';
       V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                  fn_mask(p_CARD_NO,'X',7,6) ||' '||substr(sqlerrm,1,100);              -- sqlerrm appended as per review observation for FSS-1315 -- 12498
       RAISE EXP_REJECT_RECORD;
    END;

    --Sn find fees amount attaced to func code, prod_code and card type
    ---Sn dynamic fee calculation .
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
                      NULL,--Added by Deepa for Fees Changes
                      NULL,--Added by Deepa for Fees Changes
                      V_RESP_CDE,--Added by Deepa for Fees Changes
                      P_MSG,--Added by Deepa for Fees Changes
                      p_RVSL_CODE,--Added by Deepa on June 25 2012 for Reversal txn Fee
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
                      V_FEEAMNT_TYPE,--Added by Deepa for Fees Changes
                      V_CLAWBACK,--Added by Deepa for Fees Changes
                      V_FEE_PLAN,--Added by Deepa for Fees Changes
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
     SP_CALCULATE_WAIVER(p_INST_CODE,
                     p_CARD_NO,
                     '000',
                     V_PROD_CODE,
                     V_PROD_CATTYPE,
                     V_FEE_CODE,
                     V_FEE_PLAN,  -- Added by Trivikram on 21/aug/2012
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
    BEGIN
        SELECT cpc_profile_code,cpc_badcredit_flag,cpc_badcredit_transgrpid
	 INTO V_PROFILE_CODE,v_badcredit_flag,v_badcredit_transgrpid
        FROM cms_prod_cattype
        WHERE  cpc_inst_code = p_inst_code
        AND cpc_prod_code = v_prod_code
        AND cpc_card_type = v_prod_cattype;
        EXCEPTION
        WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG :='Profile code not defined for product code '|| v_prod_code|| 'card type '|| v_prod_cattype|| SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
        END;

    --added for minimum activation amount check beg
    IF p_TXN_CODE = '68' THEN
     BEGIN
       SELECT TO_NUMBER(CBP_PARAM_VALUE)
        INTO V_MIN_ACT_AMT
        FROM CMS_BIN_PARAM
        WHERE CBP_INST_CODE = p_INST_CODE AND
            CBP_PARAM_NAME = 'Min Card Balance' AND
            CBP_PROFILE_CODE = V_PROFILE_CODE;

       IF V_TRAN_AMT < V_MIN_ACT_AMT THEN
        v_achbypass:=vmsusach.check_achbypass ( v_acct_number, UPPER (TRIM (p_companyname)), 7 );
        IF v_achbypass='N' THEN
            v_achbypass :='7';
           V_RESP_CDE := '39';
           V_ERR_MSG  := 'Amount should be = or > than ' || V_MIN_ACT_AMT ||
                       ' for Card Activation';
           RAISE EXP_REJECT_RECORD;
        END IF;
       END IF;

     EXCEPTION WHEN EXP_REJECT_RECORD       -- Added during review observation changes for FSS-1315 -- 12498
     THEN
         RAISE;

     WHEN OTHERS THEN
        V_RESP_CDE := '39';
        V_ERR_MSG  := 'While comparing transaction amount with min amount '||substr(sqlerrm,1,100); -- Change in error message for FSS-1315
        RAISE EXP_REJECT_RECORD;
     END;
    END IF;
    --added for minimum activation amount check beg
     IF (TO_NUMBER(p_TXN_CODE) = 21) OR (TO_NUMBER(p_TXN_CODE) = 23) OR
      (TO_NUMBER(p_TXN_CODE) = 33) THEN
     V_DR_CR_FLAG := 'CR';
     V_TXN_TYPE   := '1';
    END IF;
    
    --Sn find total transaction   amount
    IF V_DR_CR_FLAG = 'CR' THEN
     V_TOTAL_AMT      := V_TRAN_AMT - V_TOTAL_FEE;
     V_UPD_AMT        := V_ACCT_BALANCE + V_TOTAL_AMT;
     V_UPD_LEDGER_BAL := V_LEDGER_BAL + V_TOTAL_AMT;

    ELSIF V_DR_CR_FLAG = 'DR' THEN
     V_TOTAL_AMT      := V_TRAN_AMT + V_TOTAL_FEE;
     V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
     V_UPD_LEDGER_BAL := V_LEDGER_BAL - V_TOTAL_AMT;
    
    ELSIF V_DR_CR_FLAG = 'NA' THEN

     V_TOTAL_AMT      := V_TOTAL_FEE;
     V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
     V_UPD_LEDGER_BAL := V_LEDGER_BAL - V_TOTAL_AMT;

    ELSE
     V_RESP_CDE := '12'; --Ineligible Transaction
     V_ERR_MSG  := 'Invalid transflag    txn code ' || p_TXN_CODE;
     RAISE EXP_REJECT_RECORD;
    END IF;
    
--Modified for MVHOST-346 14052013
    IF (TO_NUMBER(p_TXN_CODE) = 21) OR (TO_NUMBER(p_TXN_CODE) = 23) OR
      (TO_NUMBER(p_TXN_CODE) = 33) THEN
     V_DR_CR_FLAG := 'NA';
     V_TXN_TYPE   := '0';
    END IF;
    --En find total transaction   amout
    --Sn check balance
    /*   Commented For Clawback Changes (MVHOST - 346)  on 14/05/2013
    IF V_DR_CR_FLAG NOT IN ('NA', 'CR') -- For credit transaction or Non-Financial transaction Insufficient Balance Check is not required. -- 29th June 2011
    THEN
     IF V_UPD_AMT < 0 THEN
       V_RESP_CDE := '15'; --Ineligible Transaction
       V_ERR_MSG  := 'Insufficient Balance '; -- modified by Ravi N for Mantis ID 0011282
       RAISE EXP_REJECT_RECORD;
     END IF;
    END IF;*/

--Start Clawback Changes (MVHOST - 346)  on 14/05/2013
   IF V_UPD_AMT < 0 THEN

               IF V_LOGIN_TXN = 'Y' AND V_CLAWBACK = 'Y' AND V_DR_CR_FLAG = 'NA' AND V_TOTAL_FEE <> 0 THEN

                V_ACTUAL_FEE_AMNT := V_TOTAL_FEE;
                --Added on 29/01/14 for regarding 0013542
--                V_CLAWBACK_AMNT   := V_TOTAL_FEE - V_ACCT_BALANCE;
--                V_FEE_AMT         := V_ACCT_BALANCE;
--
                 IF (V_ACCT_BALANCE >0) THEN
                  V_CLAWBACK_AMNT   := V_TOTAL_FEE - V_ACCT_BALANCE;
                  V_FEE_AMT         := V_ACCT_BALANCE;
                ELSE
                  V_CLAWBACK_AMNT   := V_TOTAL_FEE;
                  V_FEE_AMT         := 0;
                End IF;
            --End
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

                                   BEGIN

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

                                   EXCEPTION WHEN OTHERS                        --Exception handled as per review observation for FSS-1315 -- 12498
                                   THEN

                                    V_RESP_CDE := '21';
                                    V_ERR_MSG  := 'Error while inserting into Account ClawBack details' ||SUBSTR(SQLERRM, 1, 200);
                                     RAISE EXP_REJECT_RECORD;

                                   END;


                           ELSIF v_chrg_dtl_cnt < v_tot_clwbck_count then  -- Modified for fwr 64
                                   BEGIN

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

                                           if  sql%rowcount = 0                 -- Added as per review observation changes for FSS-1315 -- 12498
                                           then
                                                V_RESP_CDE := '21';
                                                V_ERR_MSG  := 'No records found for update in clawback table';
                                                RAISE EXP_REJECT_RECORD;

                                           end if;

                                   EXCEPTION WHEN EXP_REJECT_RECORD
                                   THEN
                                       RAISE EXP_REJECT_RECORD;

                                   WHEN OTHERS                                  --Exception handled as per review observation for FSS-1315 -- 12498
                                   THEN

                                    V_RESP_CDE := '21';
                                    V_ERR_MSG  := 'Error while updating into Account ClawBack details' ||SUBSTR(SQLERRM, 1, 200);
                                     RAISE EXP_REJECT_RECORD;

                                   END;

                                END IF;

                          EXCEPTION WHEN EXP_REJECT_RECORD
                          THEN
                              RAISE EXP_REJECT_RECORD;


                          WHEN OTHERS THEN
                             V_RESP_CDE := '21';
                             V_ERR_MSG  := 'Error while fetching count from Account ClawBack details' ||
                                        SUBSTR(SQLERRM, 1, 200);                 --Channge in error messgae as per review observation for FSS-1315 -- 12498
                             RAISE EXP_REJECT_RECORD;

                          END;

                    END IF;

               ELSE

                 --IF P_DELIVERY_CHANNEL <> 11 and P_TXN_CODE not in ('23','33') -- added on 23-sep-2013 for FSS-1315
                 IF P_DELIVERY_CHANNEL NOT IN('11','15') and P_TXN_CODE not in ('23','33') --15 added by Pankaj S. for ACH canada
                 then

                    V_RESP_CDE := '15';
                    V_ERR_MSG  := 'Insufficient Balance '; -- modified by Ravi N for Mantis ID 0011282
                    RAISE EXP_REJECT_RECORD;

                 END IF;               -- added on 23-sep-2013 for FSS-1315

               END IF;

          --V_UPD_AMT        := 0;   -- commented as per discussion for 12487
          -- V_UPD_LEDGER_BAL := 0;    -- commented as per discussion for 12487
           V_TOTAL_AMT      := V_TRAN_AMT + V_FEE_AMT  ;

   END IF;
   --End  Clawback Changes (MVHOST - 346)  on 14/05/2013
IF (P_DELIVERY_CHANNEL IN ('11','15') and P_TXN_CODE not in ('23','33')) then   --15 added by Pankaj S. for ACH canada
    -- Check for maximum card balance configured for the product profile.
    BEGIN

         SELECT TO_NUMBER(CBP_PARAM_VALUE)      -- Added on 09-Feb-2013 for max card balance check based on product category
           INTO V_MAX_CARD_BAL
           FROM CMS_BIN_PARAM
          WHERE CBP_INST_CODE = p_INST_CODE AND
               CBP_PARAM_NAME = 'Max Card Balance' AND
               CBP_PROFILE_CODE  = V_PROFILE_CODE;


        /*
         SELECT TO_NUMBER(CBP_PARAM_VALUE)  -- Commented on 09-Feb-2013 for max card balance check based on product category
           INTO V_MAX_CARD_BAL
           FROM CMS_BIN_PARAM
          WHERE CBP_INST_CODE = p_INST_CODE AND
               CBP_PARAM_NAME = 'Max Card Balance' AND
               CBP_PROFILE_CODE IN
               (SELECT CPM_PROFILE_CODE
                 FROM CMS_PROD_MAST
                WHERE CPM_PROD_CODE = V_PROD_CODE);
                */

    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG := substr(SQLERRM,1,100); -- substr added as per review observation for FSS-1315 -- 12498
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
                  OR ((V_UPD_LEDGER_BAL) > v_initialload_amt
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
                                P_AUTH_ID,
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
         IF v_enable_flag = 'Y'
         THEN
            IF    ((V_UPD_AMT) > v_max_card_bal)
               OR ((V_UPD_LEDGER_BAL) > v_max_card_bal)
            THEN
               v_resp_cde := '30';
               v_err_msg := 'EXCEEDING MAXIMUM CARD BALANCE';
               RAISE EXP_REJECT_RECORD;
            END IF;
         END IF;
    --Sn check balance
    IF (V_UPD_LEDGER_BAL > V_MAX_CARD_BAL) OR (V_UPD_AMT > V_MAX_CARD_BAL) THEN
   -- CSR ACH Exception page display changes 18 sep 13 - Amudhan  starts
     if P_ach_exp_flag <> 'FD' then
     V_ACH_AUTO_CLEAR_FLAG := 'Y';
     else
     V_ACH_AUTO_CLEAR_FLAG := 'N';
     end if;
      -- CSR ACH Exception page display changes 18 sep 13 - Amudhan ends
--     V_RESP_CDE := '30';
--     V_ERR_MSG  := 'WILL EXCEED MAX BALANCE CONFIG'; --Modified for MVHOST-321 on 08-May-13
--     RAISE EXP_REJECT_RECORD;
    END IF;

    --En check balance
    --Modified for MVHOST-346 14052013
    /*IF (TO_NUMBER(p_TXN_CODE) = 21) OR (TO_NUMBER(p_TXN_CODE) = 23) OR
      (TO_NUMBER(p_TXN_CODE) = 33) THEN
     V_DR_CR_FLAG := 'NA';
     V_TXN_TYPE   := '0';
    END IF;*/
end if;
    --Sn create gl entries and acct update
    BEGIN
     SP_UPD_TRANSACTION_ACCNT_AUTH(p_INST_CODE,
                             V_TRAN_DATE,
                             V_PROD_CODE,
                             V_PROD_CATTYPE,
                             V_TRAN_AMT,
                             V_FUNC_CODE,
                             p_TXN_CODE,
                             V_DR_CR_FLAG,
                             p_RRN,
                             p_TERM_ID,
                             p_DELIVERY_CHANNEL,
                             p_TXN_MODE,
                             p_CARD_NO,
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
                             '',
                             p_MSG,
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
       V_ERR_MSG  := 'Error from SP_UPD_TRANSACTION_ACCNT_AUTH ' ||
                  SUBSTR(SQLERRM, 1, 200);                          -- Change in error message as per review observation for FSS-1315 -- 12498
       RAISE EXP_REJECT_RECORD;
    END;

    --En create gl entries and acct update

    --Sn find narration
    BEGIN

      /*                                                            --Commented since not required as per review observation for FSS-1315 -- 12498
       SELECT CTM_TRAN_DESC
       INTO V_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
       WHERE CTM_TRAN_CODE = p_TXN_CODE
       AND CTM_DELIVERY_CHANNEL = p_DELIVERY_CHANNEL
       AND CTM_INST_CODE = p_INST_CODE;
      */

           IF (p_TXN_CODE ='07') THEN

                IF TRIM(V_TRANS_DESC) IS NOT NULL THEN

                    V_NARRATION := V_TRANS_DESC || '/';

                END IF;

                IF TRIM(V_AUTH_ID) IS NOT NULL THEN

                    V_NARRATION := V_NARRATION || V_AUTH_ID|| '/';

                END IF;



                IF TRIM(p_TO_ACCT_NO) IS NOT NULL THEN

                    V_NARRATION := V_NARRATION || p_TO_ACCT_NO || '/';

                END IF;

                IF TRIM(p_TRAN_DATE) IS NOT NULL THEN

                    V_NARRATION := V_NARRATION || p_TRAN_DATE ;

                END IF;

            ELSE

                IF TRIM(V_TRANS_DESC) IS NOT NULL THEN

                  V_NARRATION := V_TRANS_DESC || '/';

                END IF;

                IF TRIM(p_MERCHANT_NAME) IS NOT NULL THEN

                    V_NARRATION := V_NARRATION || p_MERCHANT_NAME || '/';

                END IF;

                IF TRIM(p_MERCHANT_CITY) IS NOT NULL THEN

                    V_NARRATION := V_NARRATION || p_MERCHANT_CITY || '/';

                END IF;

                IF TRIM(p_TRAN_DATE) IS NOT NULL THEN

                    V_NARRATION := V_NARRATION || p_TRAN_DATE || '/';

                END IF;

                IF TRIM(V_AUTH_ID) IS NOT NULL THEN

                    V_NARRATION := V_NARRATION || V_AUTH_ID;

                END IF;


           END IF;



    EXCEPTION
    /*                                                                          -- commented since select query not required as per review observation for FSS-1315 -- 12498
     WHEN NO_DATA_FOUND THEN
       V_TRANS_DESC := 'Transaction type ' || p_TXN_CODE;
    */
     WHEN OTHERS THEN

       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error in preparing the narration ' ||
                  SUBSTR(SQLERRM, 1, 200);                                      -- Change in error msg as per review observation for FSS-1315 -- 12498
       RAISE EXP_REJECT_RECORD;

    END;

    v_timestamp := systimestamp;              -- Added on 17-Apr-2013 for defect 10871

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
         CSL_PAN_NO_ENCR,
         CSL_RRN,
         CSL_AUTH_ID,
         CSL_BUSINESS_DATE,
         CSL_BUSINESS_TIME,
         TXN_FEE_FLAG,
         CSL_DELIVERY_CHANNEL,
         CSL_INST_CODE,
         CSL_TXN_CODE,
         CSL_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
         CSL_INS_USER,
         CSL_INS_DATE,
         csl_merchant_name,--Added by Deepa on 03-May-2012 to log Merchant name,city and state
         csl_merchant_city,
         csl_merchant_state,
         CSL_PANNO_LAST4DIGIT,   --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
         CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
         CSL_TIME_STAMP,         -- Added on 17-Apr-2013 for defect 10871
         CSL_PROD_CODE,            -- Added on 17-Apr-2013 for defect 10871
         csl_card_type
         )
     VALUES
         (
         V_HASH_PAN,
         ROUND(V_LEDGER_BAL,2),      -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
         ROUND(V_TRAN_AMT,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
         V_DR_CR_FLAG,
         V_TRAN_DATE,
         ROUND(DECODE(V_DR_CR_FLAG,
               'DR',
               V_LEDGER_BAL - V_TRAN_AMT,   -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871
               'CR',
               V_LEDGER_BAL + V_TRAN_AMT,   -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871
               'NA',
               V_LEDGER_BAL),2),               -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
         V_NARRATION,
         V_ENCR_PAN,
         p_RRN,
         V_AUTH_ID,
         p_TRAN_DATE,
         p_TRAN_TIME,
         'N',
         p_DELIVERY_CHANNEL,
         p_INST_CODE,
         p_TXN_CODE,
         V_CARD_ACCT_NO,
         1,
         sysdate,--Added by Deepa to log the account number ,INS_DATE and INS_USER
         P_MERCHANT_NAME,--Added by Deepa on 03-May-2012 to log Merchant name,city and state
         P_MERCHANT_CITY,
         P_ATMNAME_LOC,
         (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))),    --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
         V_CAM_TYPE_CODE,   -- Added on 17-Apr-2013 for defect 10871
         v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
         V_PROD_CODE,         -- Added on 17-Apr-2013 for defect 10871
         V_PROD_CATTYPE
         );

     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Problem while inserting into statement log for tran amt ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;



     BEGIN
       SP_DAILY_BIN_BAL(p_CARD_NO,
                    V_TRAN_DATE,
                    V_TRAN_AMT,
                    V_DR_CR_FLAG,
                    p_INST_CODE,
                    p_BANK_CODE,
                    V_ERR_MSG);

              IF V_ERR_MSG <> 'OK' THEN
                 V_RESP_CDE := '21';
                 V_ERR_MSG  := 'FROM SP_DAILY_BIN_BAL ' ||V_ERR_MSG||' '||fn_mask(p_CARD_NO,'X',7,6);
                 RAISE EXP_REJECT_RECORD; -- change in error msg and V_ERR_MSG appended during review observation changes for FSS-1315 -- 12498
              END IF;

     EXCEPTION WHEN EXP_REJECT_RECORD                                           --Exception handled as per review observation for FSS-1315 -- 12498
     THEN
         RAISE;

     WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Error while calling SP_DAILY_BIN_BAL ' ||
                    p_CARD_NO;
        RAISE EXP_REJECT_RECORD;
     END;
    END IF;
    --En create a entry in statement log
    --Sn find fee opening balance
    IF V_TOTAL_FEE <> 0 OR V_FREETXN_EXCEED = 'N' THEN -- Modified by Trivikram on 26-July-2012 for logging fee of free transaction
     BEGIN
       SELECT DECODE(V_DR_CR_FLAG,
                  'DR',
                  V_LEDGER_BAL - V_TRAN_AMT,
                  'CR',
                  V_LEDGER_BAL + V_TRAN_AMT,
                  'NA',
                  V_LEDGER_BAL)
        INTO V_FEE_OPENING_BAL
        FROM DUAL;
     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                    p_CARD_NO;
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
         CSL_PAN_NO_ENCR,
         CSL_RRN,
         CSL_AUTH_ID,
         CSL_BUSINESS_DATE,
         CSL_BUSINESS_TIME,
         TXN_FEE_FLAG,
         CSL_DELIVERY_CHANNEL,
         CSL_INST_CODE,
         CSL_TXN_CODE,
         CSL_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
         CSL_INS_USER,
         CSL_INS_DATE,
         csl_merchant_name,--Added by Deepa on 03-May-2012 to log Merchant name,city and state
         csl_merchant_city,
         csl_merchant_state,
         CSL_PANNO_LAST4DIGIT,   --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
         CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
         CSL_TIME_STAMP,         -- Added on 17-Apr-2013 for defect 10871
         CSL_PROD_CODE            -- Added on 17-Apr-2013 for defect 10871
         )
       VALUES
        (
         V_HASH_PAN,
         ROUND(V_FEE_OPENING_BAL,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
         ROUND(V_TOTAL_FEE,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
         'DR',
         V_TRAN_DATE,
         ROUND(V_FEE_OPENING_BAL - V_TOTAL_FEE,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
         --'Complimentary ' || V_DURATION ||' '|| V_NARRATION, -- Modified by Trivikram  on 27-July-2012  -- Commented for MVCSD-4471
         v_fee_desc, -- Added for MVCSD-4471
         V_ENCR_PAN,
         p_RRN,
         V_AUTH_ID,
         p_TRAN_DATE,
         p_TRAN_TIME,
         'Y',
         p_DELIVERY_CHANNEL,
         p_INST_CODE,
         p_TXN_CODE,
         V_CARD_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
         1,
         sysdate,
         P_MERCHANT_NAME,--Added by Deepa on 03-May-2012 to log Merchant name,city and state
         P_MERCHANT_CITY,
         P_ATMNAME_LOC,
         (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))),    --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
         V_CAM_TYPE_CODE,   -- Added on 17-Apr-2013 for defect 10871
         v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
         V_PROD_CODE         -- Added on 17-Apr-2013 for defect 10871
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
         IF V_FEEAMNT_TYPE='A' THEN

            -- Added by Trivikram on 23/aug/2012 for logged fixed fee and percentage fee with waiver

            V_FLAT_FEES := ROUND(V_FLAT_FEES -
                                ((V_FLAT_FEES * V_WAIV_PERCNT) / 100),2);


                V_PER_FEES  := ROUND(V_PER_FEES -
                            ((V_PER_FEES * V_WAIV_PERCNT) / 100),2);

            --En Entry for Fixed Fee

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
                     csl_merchant_name,
                     csl_merchant_city,
                     csl_merchant_state,
                     CSL_PANNO_LAST4DIGIT,
                     CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
                     CSL_TIME_STAMP,         -- Added on 17-Apr-2013 for defect 10871
                     CSL_PROD_CODE            -- Added on 17-Apr-2013 for defect 10871
                     )
                   VALUES
                    (
                     V_HASH_PAN,
                     ROUND(V_FEE_OPENING_BAL,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                     ROUND(V_FLAT_FEES,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                     'DR',
                     V_TRAN_DATE,
                     ROUND(V_FEE_OPENING_BAL - V_FLAT_FEES,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                     --'Fixed Fee debited for ' || V_NARRATION,  -- Commented for MVCSD-447
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
                     sysdate,
                     P_MERCHANT_NAME,
                     P_MERCHANT_CITY,
                     P_ATMNAME_LOC,
                     (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))),
                     V_CAM_TYPE_CODE,   -- Added on 17-Apr-2013 for defect 10871
                     v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
                     V_PROD_CODE         -- Added on 17-Apr-2013 for defect 10871
                     );


                 EXCEPTION WHEN OTHERS                                          --Exception when others added as per review observation for FSS-1315 -- 12498
                 THEN

                    V_RESP_CDE := '21';
                    V_ERR_MSG  := 'Problem while inserting into statement log for flat fee ' ||
                            SUBSTR(SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;

                 END;


             --En Entry for Fixed Fee
             V_FEE_OPENING_BAL:=V_FEE_OPENING_BAL - V_FLAT_FEES;
             --Sn Entry for Percentage Fee

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
                         CSL_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
                         CSL_INS_USER,
                         CSL_INS_DATE,
                         csl_merchant_name,--Added by Deepa on 03-May-2012 to log Merchant name,city and state
                         csl_merchant_city,
                         csl_merchant_state,
                         CSL_PANNO_LAST4DIGIT,  --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                         CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
                         CSL_TIME_STAMP,         -- Added on 17-Apr-2013 for defect 10871
                         CSL_PROD_CODE            -- Added on 17-Apr-2013 for defect
                         )
                       VALUES
                        (
                         V_HASH_PAN,
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
                         V_CARD_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
                         1,
                         sysdate,
                         P_MERCHANT_NAME,--Added by Deepa on 03-May-2012 to log Merchant name,city and state
                         P_MERCHANT_CITY,
                         P_ATMNAME_LOC,
                         (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))),
                         V_CAM_TYPE_CODE,   -- Added on 17-Apr-2013 for defect 10871
                         v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
                         V_PROD_CODE         -- Added on 17-Apr-2013 for defect 10871
                         );

                 EXCEPTION WHEN OTHERS                                          --Exception when others added as per review observation for FSS-1315 -- 12498
                 THEN

                    V_RESP_CDE := '21';
                    V_ERR_MSG  := 'Problem while inserting into statement log for percent fee ' ||SUBSTR(SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;

                 END;

             --En Entry for Percentage Fee

         ELSE
            --Sn create entries for FEES attached


                 BEGIN

                    INSERT INTO CMS_STATEMENTS_LOG
                    (CSL_PAN_NO,
                     CSL_OPENING_BAL,
                     CSL_TRANS_AMOUNT,
                     CSL_TRANS_TYPE,
                     CSL_TRANS_DATE,
                     CSL_CLOSING_BALANCE,
                     CSL_TRANS_NARRRATION,
                     CSL_PAN_NO_ENCR,
                     CSL_RRN,
                     CSL_AUTH_ID,
                     CSL_BUSINESS_DATE,
                     CSL_BUSINESS_TIME,
                     TXN_FEE_FLAG,
                     CSL_DELIVERY_CHANNEL,
                     CSL_INST_CODE,
                     CSL_TXN_CODE,
                     CSL_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
                     CSL_INS_USER,
                     CSL_INS_DATE,
                     csl_merchant_name,--Added by Deepa on 03-May-2012 to log Merchant name,city and state
                     csl_merchant_city,
                     csl_merchant_state,
                     CSL_PANNO_LAST4DIGIT,  --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                     CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
                     CSL_TIME_STAMP,         -- Added on 17-Apr-2013 for defect 10871
                     CSL_PROD_CODE            -- Added on 17-Apr-2013 for defect 10871
                     )
                   VALUES
                    (
                     V_HASH_PAN,
                     ROUND(V_FEE_OPENING_BAL,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                     ROUND(V_FEE_AMT,2), --modified for MVHOST-346 ,--Modified by Revathi on 02-APR-2014 for 3decimal place issue
                     'DR',
                     V_TRAN_DATE,
                     ROUND(V_FEE_OPENING_BAL - V_FEE_AMT,2), --modified for MVHOST-346 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                     --'Fee debited for ' || V_NARRATION, -- Added for MVCSD-4471
                     v_fee_desc, -- Added for MVCSD-4471
                     V_ENCR_PAN,
                     p_RRN,
                     V_AUTH_ID,
                     p_TRAN_DATE,
                     p_TRAN_TIME,
                     'Y',
                     p_DELIVERY_CHANNEL,
                     p_INST_CODE,
                     p_TXN_CODE,
                     V_CARD_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
                     1,
                     sysdate,
                     P_MERCHANT_NAME,--Added by Deepa on 03-May-2012 to log Merchant name,city and state
                     P_MERCHANT_CITY,
                     P_ATMNAME_LOC,
                     (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))), --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                     V_CAM_TYPE_CODE,   -- Added on 17-Apr-2013 for defect 10871
                     v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
                     V_PROD_CODE         -- Added on 17-Apr-2013 for defect 10871
                     );

                 EXCEPTION WHEN OTHERS                                          --Exception when others added as per review observation for FSS-1315 -- 12498
                 THEN

                    V_RESP_CDE := '21';
                    V_ERR_MSG  := 'Problem while inserting into statement log for attached fee ' ||SUBSTR(SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;

                 END;

                --Start  Clawback Changes (MVHOST - 346)  on 14/05/2013
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
                          --End  Clawback Changes (MVHOST - 346)  on 14/05/2013


         END IF;
      EXCEPTION WHEN EXP_REJECT_RECORD                                    -- Added exception as per review observation for FSS-1315 -- 12498
      THEN
          RAISE EXP_REJECT_RECORD;

      WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'error occured while inserting into statement log for tran fee ' ||
                    SUBSTR(SQLERRM, 1, 200); -- Change in err message as per review observation for FSS-1315 -- 12498
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
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_MSG_TYPE,
        CTD_CUST_ACCT_NUMBER,
        CTD_INST_CODE

        )
     VALUES
       (p_DELIVERY_CHANNEL,
        p_TXN_CODE,
        V_TXN_TYPE,
        p_TXN_MODE,
        p_TRAN_DATE,
        p_TRAN_TIME,
        V_HASH_PAN,
        p_TXN_AMT,
        p_CURR_CODE,
        V_TRAN_AMT,
        V_LOG_ACTUAL_FEE,
        V_LOG_WAIVER_AMT,
        V_SERVICETAX_AMOUNT,
        V_CESS_AMOUNT,
        V_TOTAL_AMT,
        V_CARD_CURR,
        'Y',
        'Successful',
        p_RRN,
        p_STAN,
        V_ENCR_PAN,
        p_MSG,
        V_ACCT_NUMBER,
        p_INST_CODE);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while inserting into CMS_TRANSACTION_LOG_DTL ' ||SUBSTR(SQLERRM, 1, 300); --Change in err msg as per review observation FSS-1315 -- 12498
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

    --En create a entry for successful
    ---Sn update daily and weekly transcounter  and amount
    BEGIN
     /*SELECT CAT_PAN_CODE
       INTO V_AVAIL_PAN
       FROM CMS_AVAIL_TRANS
      WHERE CAT_PAN_CODE = V_HASH_PAN --p_card_no
           AND CAT_TRAN_CODE = p_TXN_CODE AND
           CAT_TRAN_MODE = p_TXN_MODE;*/

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
      WHERE CAT_INST_CODE = p_INST_CODE AND CAT_PAN_CODE = V_HASH_PAN
           AND CAT_TRAN_CODE = p_TXN_CODE AND
           CAT_TRAN_MODE = p_TXN_MODE;
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
    IF V_OUTPUT_TYPE = 'B' THEN
     --Balance Inquiry
     p_RESP_MSG := TO_CHAR(V_UPD_AMT);
    END IF;

    --En create detail fro response message
    --Sn mini statement
    IF V_OUTPUT_TYPE = 'M' THEN
     --Mini statement
     BEGIN
       SP_GEN_MINI_STMT(p_INST_CODE,
                    p_CARD_NO,
                    V_MINI_TOTREC,
                    V_MINISTMT_OUTPUT,
                    V_MINISTMT_ERRMSG);

       IF V_MINISTMT_ERRMSG <> 'OK' THEN
        V_ERR_MSG  := V_MINISTMT_ERRMSG;
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
       END IF;

       p_RESP_MSG := LPAD(TO_CHAR(V_MINI_TOTREC), 2, '0') ||
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
    P_RESP_ID :=V_RESP_CDE;
    V_RESP_CDE := '1';

    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO p_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = p_INST_CODE AND
           CMS_DELIVERY_CHANNEL = TO_NUMBER(p_DELIVERY_CHANNEL) AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from response master for respose code' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;


    ------------------------------------------------------------------
    --Sn Added query to get the latest balance after transaction 12487
    ------------------------------------------------------------------

     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL                 -- Added on 17-Apr-2013 for defect 10871
        INTO V_ACCT_BALANCE, V_LEDGER_BAL                   -- Added on 17-Apr-2013 for defect 10871
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO = v_acct_number
        and   CAM_INST_CODE = p_INST_CODE;
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '14';
       V_ERR_MSG  := 'Invalid account number '||v_acct_number||' and institution '||p_INST_CODE;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '12';
       V_ERR_MSG  := 'Error while selecting balance for account ' ||v_acct_number ||' '||substr(sqlerrm,1,100);
       RAISE EXP_REJECT_RECORD;
     END;

    ------------------------------------------------------------------
    --En Added query to get the latest balance after transaction 12487
    ------------------------------------------------------------------

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
        WHERE CAM_ACCT_NO =
            (SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN AND
                   CAP_INST_CODE = p_INST_CODE) AND
            CAM_INST_CODE = p_INST_CODE;
     EXCEPTION
       WHEN OTHERS THEN
        V_ACCT_BALANCE := 0;
        V_LEDGER_BAL   := 0;
     END;

     --Sn select response code and insert record into txn log dtl
     --HOSTCC-24 changes
     IF V_APPLPAN_CARDSTAT ='0' AND V_RESP_CDE ='10'  THEN

     V_RESP_CDE :='223';
     V_ERR_MSG := 'INACTIVE CARD STATUS';

     ELSE

     P_RESP_ID :=V_RESP_CDE;
     p_RESP_CODE := V_RESP_CDE;


     END IF;


        BEGIN
          SELECT CMS_ISO_RESPCDE
            INTO p_RESP_CODE
            FROM CMS_RESPONSE_MAST
           WHERE CMS_INST_CODE = p_INST_CODE AND
                 CMS_DELIVERY_CHANNEL = p_DELIVERY_CHANNEL AND
                 CMS_RESPONSE_ID = V_RESP_CDE;

          p_RESP_MSG := V_ERR_MSG;
        EXCEPTION
          WHEN OTHERS THEN
            p_RESP_MSG  := 'Problem while selecting data from response master ' ||
                             V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
            p_RESP_CODE := '89'; ---ISO MESSAGE FOR DATABASE ERROR --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
            ROLLBACK;
            --  RETURN;
        END;

     BEGIN
       INSERT INTO CMS_TRANSACTION_LOG_DTL
        (CTD_DELIVERY_CHANNEL,
         CTD_TXN_CODE,
         CTD_TXN_TYPE,
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
         CTD_CUSTOMER_CARD_NO_ENCR,
         CTD_MSG_TYPE,
         CTD_CUST_ACCT_NUMBER,
         CTD_INST_CODE)
       VALUES
        (p_DELIVERY_CHANNEL,
         p_TXN_CODE,
         V_TXN_TYPE,
         p_TXN_MODE,
         p_TRAN_DATE,
         p_TRAN_TIME,
         --p_card_no
         V_HASH_PAN,
         p_TXN_AMT,
         p_CURR_CODE,
         V_TRAN_AMT,
         NULL,
         NULL,
         NULL,
         NULL,
         V_TOTAL_AMT,
         V_CARD_CURR,
         'E',
         V_ERR_MSG,
         p_RRN,
         p_STAN,
         V_ENCR_PAN,
         p_MSG,
         V_ACCT_NUMBER,
         p_INST_CODE);

       p_RESP_MSG := V_ERR_MSG;
     EXCEPTION
       WHEN OTHERS THEN
        --p_RESP_CODE := 'R20'; --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
        p_RESP_CODE := 'R16';
        p_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                      SUBSTR(SQLERRM, 1, 300);
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

            IF p_delivery_channel = '15' AND p_rules = 'E' THEN
                IF v_dr_cr_flag = 'CR' THEN
                   v_dr_cr_flag:='DR';
                END IF;
            END IF;
        EXCEPTION
         WHEN OTHERS THEN

         NULL;

        END;

     end if;

     if v_timestamp is null
     then
         v_timestamp := systimestamp;              -- Added on 17-Apr-2013 for defect 10871

     end if;

     -----------------------------------------------
     --EN: Added on 17-Apr-2013 for defect 10871
     -----------------------------------------------

    WHEN OTHERS THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,CAM_ACCT_NO,
              cam_type_code                                 -- Added on 17-Apr-2013 for defect 10871
        INTO V_ACCT_BALANCE, V_LEDGER_BAL,V_ACCT_NUMBER,
             v_cam_type_code                                -- Added on 17-Apr-2013 for defect 10871
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =
            (SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN AND
                   CAP_INST_CODE = p_INST_CODE) AND
            CAM_INST_CODE = p_INST_CODE;
     EXCEPTION
       WHEN OTHERS THEN
        V_ACCT_BALANCE := 0;
        V_LEDGER_BAL   := 0;
     END;
     --Sn select response code and insert record into txn log dtl

     P_RESP_ID :=V_RESP_CDE;

     BEGIN
       SELECT CMS_ISO_RESPCDE
        INTO p_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = p_INST_CODE AND
            CMS_DELIVERY_CHANNEL = p_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESP_CDE;

       p_RESP_MSG := V_ERR_MSG;
     EXCEPTION
       WHEN OTHERS THEN
        p_RESP_MSG  := 'Problem while selecting data from response master ' ||
                      V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
      --  p_RESP_CODE := 'R20';
         p_RESP_CODE := 'R16';
        ROLLBACK;
     END;

     BEGIN
       INSERT INTO CMS_TRANSACTION_LOG_DTL
        (CTD_DELIVERY_CHANNEL,
         CTD_TXN_CODE,
         CTD_TXN_TYPE,
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
         CTD_CUSTOMER_CARD_NO_ENCR,
         CTD_MSG_TYPE,
         CTD_CUST_ACCT_NUMBER,
         CTD_INST_CODE)
       VALUES
        (p_DELIVERY_CHANNEL,
         p_TXN_CODE,
         V_TXN_TYPE,
         p_TXN_MODE,
         p_TRAN_DATE,
         p_TRAN_TIME,
         V_HASH_PAN,
         p_TXN_AMT,
         p_CURR_CODE,
         V_TRAN_AMT,
         NULL,
         NULL,
         NULL,
         NULL,
         V_TOTAL_AMT,
         V_CARD_CURR,
         'E',
         V_ERR_MSG,
         p_RRN,
         p_STAN,
         V_ENCR_PAN,
         p_MSG,
         V_ACCT_NUMBER,
         p_INST_CODE);
     EXCEPTION
       WHEN OTHERS THEN
        p_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                      SUBSTR(SQLERRM, 1, 300);
        --p_RESP_CODE := 'R20';
         p_RESP_CODE := 'R16';
        ROLLBACK;
        RETURN;
     END;
     --En select response code and insert record into txn log dtl

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

     if v_timestamp is null
     then
         v_timestamp := systimestamp;              -- Added on 17-Apr-2013 for defect 10871

     end if;

     -----------------------------------------------
     --EN: Added on 17-Apr-2013 for defect 10871
     -----------------------------------------------




  END;

  --- Sn create GL ENTRIES
  IF V_RESP_CDE = '1' THEN
    --Sn find business date
    V_BUSINESS_TIME := TO_CHAR(V_TRAN_DATE, 'HH24:MI');

    IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
     V_BUSINESS_DATE := TRUNC(V_TRAN_DATE) + 1;
    ELSE
     V_BUSINESS_DATE := TRUNC(V_TRAN_DATE);
    END IF;

    --En find businesses date
    /*BEGIN
     SP_CREATE_GL_ENTRIES_CMSAUTH(p_INST_CODE,
                            V_BUSINESS_DATE,
                            V_PROD_CODE,
                            V_PROD_CATTYPE,
                            V_TRAN_AMT,
                            V_FUNC_CODE,
                            p_TXN_CODE,
                            V_DR_CR_FLAG,
                            p_CARD_NO,
                            V_FEE_CODE,
                            V_TOTAL_FEE,
                            V_FEE_CRACCT_NO,
                            V_FEE_DRACCT_NO,
                            V_CARD_ACCT_NO,
                            p_RVSL_CODE,
                            p_MSG,
                            p_DELIVERY_CHANNEL,
                            V_RESP_CDE,
                            V_GL_UPD_FLAG,
                            V_GL_ERR_MSG);

     IF V_GL_ERR_MSG <> 'OK' OR V_GL_UPD_FLAG <> 'Y' THEN
       V_GL_UPD_FLAG := 'N';
       p_RESP_CODE := V_RESP_CDE;
       V_ERR_MSG := V_GL_ERR_MSG;
       RAISE EXP_REJECT_RECORD;
     END IF;

    EXCEPTION WHEN EXP_REJECT_RECORD                                            --Handled execption as per review observation for FSS-1315 -- 12498
    THEN
        RAISE EXP_REJECT_RECORD;

    WHEN OTHERS THEN
       V_GL_UPD_FLAG := 'N';
       p_RESP_CODE := V_RESP_CDE;
        V_ERR_MSG := V_GL_ERR_MSG;
       RAISE EXP_REJECT_RECORD;
    END;*/
  END IF;

  --En create GL ENTRIES
  --if transaction approved from exception queue it will update only process type
if p_PROCESSTYPE <> 'N' THEN
  --Sn create a entry in txn log
   BEGIN
        SELECT COUNT(*) INTO V_BANK_SEC_COUNT FROM VMS_ISSUBANK_MAST,VMS_BANKFEATURE_MAST,CMS_PROD_CATTYPE WHERE
        VIM_BANK_ID=VBM_BANK_ID
        AND CPC_ISSU_BANK=VIM_BANK_NAME
        AND UPPER(P_SECCODES)='WEB'
        AND CPC_PROD_CODE=V_PROD_CODE AND CPC_CARD_TYPE=V_PROD_CATTYPE
        AND VBM_FEATURE_ID=1;
     EXCEPTION
        WHEN OTHERS THEN
           NULL;
     END;

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
      ACHFILENAME,
      ODFI  ,
      RDFI  ,
      SECCODES,
      IMPDATE ,
      PROCESSDATE,
      EFFECTIVEDATE,
      TRACENUMBER  ,
      INCOMING_CRFILEID,
      ACHTRANTYPE_ID   ,
      BEFRETRAN_LEDGERBAL,
      BEFRETRAN_AVAILBALANCE,
      INDIDNUM,
      INDNAME  ,
      COMPANYNAME,
      COMPANYID,
      ACH_ID    ,
      COMPENTRYDESC,
      CUSTOMERLASTNAME,
      cardstatus  ,
      PROCESSTYPE,
      FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
      FEEATTACHTYPE, -- Added by Trivikram on 05-Sep-2012
      CUSTFIRSTNAME,  -- Added by Trivikram on 29/Sep/2012 logging into transactionlog for display Customer Name in ACH Report FSS-418
      ERROR_MSG,       -- Added on 09-Feb-2013 since same was missing
      ACCT_TYPE,        -- Added on 17-Apr-2013 for defect 10871
      TIME_STAMP,         -- Added on 17-Apr-2013 for defect 10871
      MERCHANT_NAME, --Added by Shweta on 14Aug13  For MVHOST-367
      ACH_AUTO_CLEAR_FLAG, -- CSR ACH Exception page display changes 18 sep 13 - Amudhan
      ach_exception_queue_flag, -- CSR ACH Exception page display changes 18 sep 13 - Amudhan
      remark --Added for error msg need to display in CSR(declined by rule)
     )
    VALUES
     (p_MSG,
      p_RRN,
      p_DELIVERY_CHANNEL,
      p_TERM_ID,
      V_BUSINESS_DATE,
      p_TXN_CODE,
      V_TXN_TYPE,
      p_TXN_MODE,
      DECODE(p_RESP_CODE, '00', 'C', 'F'),
      p_RESP_CODE,
      p_TRAN_DATE,
      SUBSTR(p_TRAN_TIME, 1, 10),
      V_HASH_PAN,
    --  NULL,
     --   NULL, --p_topup_acctno ,
     V_HASH_PAN,V_ACCT_NUMBER,--Modified for 15866
      NULL, --p_topup_accttype,
      p_BANK_CODE,
      TRIM(TO_CHAR(nvl(V_TOTAL_AMT,0), '99999999999999990.99')), -- NVL added on 17-Apr-2013 for defect 10871
      NULL,
      NULL, -- Partial amount (will be given for partial txn)
      p_MCC_CODE,
      p_CURR_CODE,
      v_achbypass, --NULL -- p_add_charge,
      V_PROD_CODE,
      V_PROD_CATTYPE,
      TRIM(TO_CHAR(nvl(P_TIP_AMT,0), '999999999999999990.99')), -- TRIM(TO_CHAR(NVL added on 17-Apr-2013 for defect 10871
      NULL,
      p_ATMNAME_LOC,
      V_AUTH_ID,
      V_TRANS_DESC,
      TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')), -- NVL added on 17-Apr-2013 for defect 10871
      '0.00', -- NULL replaced by 0.00 , on 17-Apr-2013 for defect 10871
      '0.00', -- Partial amount (will be given for partial txn) -- NULL replaced by 0.00 , on 17-Apr-2013 for defect 10871
      p_MCCCODE_GROUPID,
      p_CURRCODE_GROUPID,
      p_TRANSCODE_GROUPID,
      p_RULES,
      p_PREAUTH_DATE,
      V_GL_UPD_FLAG,
      p_STAN,
      p_INST_CODE,
      V_FEE_CODE,
      nvl(V_FEE_AMT,0),             -- NVL added on 17-Apr-2013 for defect 10871
      nvl(V_SERVICETAX_AMOUNT,0),   -- NVL added on 17-Apr-2013 for defect 10871
      nvl(V_CESS_AMOUNT,0),         -- NVL added on 17-Apr-2013 for defect 10871
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
      p_RVSL_CODE,
      V_ACCT_NUMBER,
      --DECODE(P_RESP_CODE, '00', nvl(V_UPD_AMT,0),nvl(V_ACCT_BALANCE,0)),      -- to_char(nvl)) added on 17-Apr-2013 for defect 10871
      --DECODE(P_RESP_CODE, '00', nvl(V_UPD_LEDGER_BAL,0),nvl(V_LEDGER_BAL,0)), -- to_char(nvl)) added on 17-Apr-2013 for defect 10871
     ROUND(nvl(V_ACCT_BALANCE,0),2),      -- to_char(nvl)) added on 17-Apr-2013 for defect 10871  -- added for 12487 fix on 03-Oct-2013 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
     ROUND(nvl(V_LEDGER_BAL,0), 2),-- to_char(nvl)) added on 17-Apr-2013 for defect 10871         -- added for 12487 fix on 03-Oct-2013 --Modified by Revathi on 02-APR-2014 for 3decimal place issue
      V_RESP_CDE,
      p_ACHFILENAME ,
      p_ODFI,
      p_RDFI,
      p_SECCODES,
      p_IMPDATE ,
      p_PROCESSDATE,
      p_EFFECTIVEDATE,
      p_TRACENUMBER  ,
      p_INCOMING_CRFILEID,
      p_ACHTRANTYPE_ID   ,
      ROUND(p_BEFRETRAN_LEDGERBAL,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
      ROUND(p_BEFRETRAN_AVAILBALANCE,2),--Modified by Revathi on 02-APR-2014 for 3decimal place issue
      DECODE(NVL(LENGTH(TRIM(TRANSLATE(SUBSTR(TRIM (RTRIM (LTRIM (UPPER (p_indidnum), 'IRS'), 'IRS')),1,9), '0123456789',' '))),0),0,DECODE(V_BANK_SEC_COUNT,0,FN_MASKACCT_SSN(P_INST_CODE,P_INDIDNUM ,0),P_INDIDNUM),p_INDIDNUM),
      p_INDNAME  ,
      p_COMPANYNAME,
      p_COMPANYID ,
      p_ACH_ID ,
      p_COMPENTRYDESC,
      p_CUSTOMERLASTNAME,
      V_APPLPAN_CARDSTAT ,
      p_PROCESSTYPe,
       --Added cardstatus insert in transactionlog by srinivasu.k
      V_FEE_PLAN,--Added by Deepa for Fee Plan on June 10 2012
      V_FEEATTACH_TYPE, -- Added by Trivikram on 05-Sep-2012
      P_CUSTFIRSTNAME,  -- Added by Trivikram on 29/Sep/2012 logging into transactionlog for display Customer Name in ACH Report FSS-418
      V_ERR_MSG,         -- Added on 09-Feb-2013 since same was missing
      v_cam_type_code,   -- Added on 17-Apr-2013 for defect 10871
      v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
      p_COMPANYNAME, --Added by Shweta on 14Aug13  For MVHOST-367
      V_ACH_AUTO_CLEAR_FLAG, -- CSR ACH Exception page display changes 18 sep 13 - Amudhan
      P_ach_exp_flag, -- CSR ACH Exception page display changes 18 sep 13 - Amudhan
      V_ERR_MSG --Added for error msg need to display in CSR(declined by rule)
    );

    p_CAPTURE_DATE := V_BUSINESS_DATE;
  EXCEPTION
    WHEN OTHERS THEN
     ROLLBACK;
     p_RESP_CODE := '89';
     p_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
  END;

  end if;

  --If transaction is approved from csr or Host application p_PROCESSTYPE is n will update and the same record moved to history
  if p_PROCESSTYPE = 'N' THEN

      BEGIN
	  
	  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)

    THEN
             update transactionlog
             set PROCESSTYPE= p_PROCESSTYPE,response_code=p_RESP_CODE
             WHERE RRN = p_RRN
             AND BUSINESS_DATE = p_TRAN_DATE
             AND TXN_CODE = p_TXN_CODE AND INSTCODE = p_INST_CODE;
ELSE
			update VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
             set PROCESSTYPE= p_PROCESSTYPE,response_code=p_RESP_CODE
             WHERE RRN = p_RRN
             AND BUSINESS_DATE = p_TRAN_DATE
             AND TXN_CODE = p_TXN_CODE AND INSTCODE = p_INST_CODE;
END IF;
			 

            IF SQL%ROWCOUNT = 0                                                 -- added as per review observation for FSS-1315 -- 12498
            THEN
              p_RESP_CODE := '89';
              p_RESP_MSG  := 'record not found for udate in transactionlog';
              ROLLBACK;
              RETURN;
            END IF;

      EXCEPTION
          WHEN OTHERS THEN
            p_RESP_CODE := '89';
            p_RESP_MSG  := 'Error while updating transactionlog' ||
                         SUBSTR(SQLERRM, 1, 300);
      END;

  END IF;
  --En create a entry in txn log


EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    p_RESP_CODE := '89';
    p_RESP_MSG  := 'Main exception from  authorization ' ||
                 SUBSTR(SQLERRM, 1, 300);
END;
/
show error;