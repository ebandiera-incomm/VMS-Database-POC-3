CREATE OR REPLACE PROCEDURE VMSCMS.SP_TRANSACTION_REVERSAL_SPIL (P_INST_CODE           IN NUMBER,
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
                                              P_Orgnl_Terminal_Id   In Varchar2,
                                              P_CURR_CODE           IN VARCHAR2,
                                              P_Merchant_Name       In Varchar2,
                                              P_STORE_ID            In Varchar2,--SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
                                             --Added for serial number changes on 29/10/14
                                              P_RESP_CDE            OUT VARCHAR2,
                                              P_RESP_MSG            OUT varchar2,
                                              P_RESP_MSG_M24        OUT varchar2,
                                               P_ACCT_BAL           OUT VARCHAR2,
                                               P_SERIAL_NUMBER     IN VARCHAR2 DEFAULT NULL,
                                               P_Merchant_zip      in varchar2 default null) IS --added for VMS-622 (redemption_delay zip code validation)
  /*************************************************
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
      * Reviewed Date    : 25-Jul-2013
      * Build Number     : RI0024.4_B0002

      * Modified by      : Sachin P.
      * Modified for     : Mantis Id:11695
      * Modified Reason  : Reversal Fee details(FeePlan id,FeeCode,Fee amount
                          and FeeAttach Type) are not logged in transactionlog
                          table.
      * Modified Date    : 30.07.2013
      * Reviewer         : Dhiraj
      * Reviewed Date    : 30.07.2013
      * Build Number     : RI0024.4_B0002

      * Modified By      : Sai Prasad K S
      * Modified Date    : 16-Aug-2013
      * Modified Reason  : FWR-11
      * Build Number     : RI0024.4_B0004

      * Modified By       : SIVA ARCOT
      * Modified Date     : 10-Sep-2013
      * Modified Reason   : Mantis Id-0010997 & FWR-11
      * Build Number      : RI0024.4_B0010

      * Modified by       : Deepa T
      * Modified for      : Mantis ID- 13632
      * Modified Reason   : To include the success response code in the Redemption transaction check
      * Modified Date     : 07.Feb.2014
      * Reviewer          : Dhiraj
      * Reviewed Date     : 07.Feb.2014
      * Build Number      : RI0024.6.6


      * Modified Date    : 10-May-2014
      * Modified By      : Amudhan
      * Modified reason  : FSS-1636 :Remove the check on the verification of financial transaction for only SPIL valins transaction
      * Reviewer         :  spankaj
      * Reviewed Date    : 12-May-2014
      * Release Number   : RI0027.0.1.2_B0001

      * Modified Date   : 14-May-2014
      * Modified By      : Ramesh
      * Modified reason  : mantis Id:14577 - Account balance went to negative value while doing Reverse valins transaction
      * Reviewer         :  spankaj
      * Reviewed Date    : 14-May-2014
      * Release Number   : RI0027.0.1.2_B0002

      * Modified Date    : 10-Feb-2014
      * Modified By      : Sagar More
      * Modified for     : Met-23 - Spil_3.0
      * Modified reason  : msgtype 1200 checked in query to find original transaction
      * Reviewer         : Dhiraj
      * Reviewed Date    : 10-Feb-2014
      * Release Number   : RI0027.1_B0001

      * Modified by       : Pankaj S.
      * Modified for      : Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
      * Modified Date     : 24-MAR-2014
      * Reviewer          : Dhiraj
      * Reviewed Date     : 07-April-2014
      * Build Number      : RI0027.2_B0004

      * Modified Date    : 14-May-2014
      * Modified By      : Ramesh
      * Modified reason  : Integrated changes from RI0027.0.1.2_B0002 to 2.2.1 release
      * Reviewer         : spankaj
      * Reviewed Date    : 21-May-2014
      * Release Number   : RI0027.2.1_B0001

      * Modified by      : MageshKumar.S
      * Modified Date    : 21-Jun-14
      * Modified For     : FSS-1720
      * Modified reason  : SPIL valins & SPIL revvalins,timestamp logged same in statementslog table
      * Reviewer         : spankaj
      * Build Number     : RI0027.1.9_B0002

      * Modified By      :  Mageshkumar S
      * Modified For     :  FWR-48
      * Modified Date    :  25-July-2014
      * Modified Reason  :  GL Mapping Removal Changes.
      * Reviewer         :  Spankaj
      * Build Number     :  RI0027.3.1_B0001

      * Modified by      : MageshKumar.S
      * Modified Date    : 26-August-14
      * Modified For     : FSS-1802
      * Modified reason  : For SPIL revvalins duplicate attempt needs to echo back of original rvsl
      * Build Number     : RI0027.3.2_B0002
      
    * Modified by       : Ramesh.A
    * Modified Date     : 29-OCT-14
    * Modified For      : SPIL Serial Number changes    
    * Reviewer          : Saravanakumar
    * Build Number      : RI0027.4.3_B0002
    
    * Modified by       : Siva kusuma M
    * Modified Date     : 05-Aug-2015
    * Modified For      :  FSS-2320
    * Reviewer          : Spankaj
    * Build Number      : VMSGPRHOSTCSD_3.1_B0001
    
    * Modified by       : Pankaj S.
    * Modified Date     : 21-Sep-2016
    * Modified For      :  FSS-4767
    * Reviewer          : Saravanakumar
    * Build Number      : 
    
    * Modified by       : Spankaj
    * Modified Date     : 21-Nov-2016
    * Modified For      : FSS-4762:VMS OTC Support for Instant Payroll Card
    * Reviewer          : Saravanakumar
    * Build Number      : VMSGPRHOSTCSD4.11 
     
    * Modified by       : Pankaj S.
    * Modified Date     : 09-Mar-17
    * Modified For      : FSS-4647
    * Modified reason   : Redemption Delay Changes
    * Reviewer          : Saravanakumar
    * Build Number      : VMSGPRHOST_17.3
    
    
        * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
	
	 * Modified By      : Veneetha C
     * Modified Date    : 21-JAN-2019
     * Purpose          : VMS-622 Redemption delay for activations /reloads processed through ICGPRM
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST R11
	 
	* Modified By      : Karthick
    * Modified Date    : 08-23-2022
    * Purpose          : Archival changes.
    * Reviewer         : venkat Singamaneni
    * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991
    
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
  V_AUTHID_DATE        VARCHAR2(8);
  V_TXN_NARRATION      CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  V_FEE_NARRATION      CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  --Added by Deepa for the changes to include Merchant name,city and state in statements log
  V_TXN_MERCHNAME  CMS_STATEMENTS_LOG.CSL_MERCHANT_NAME%TYPE;
  V_FEE_MERCHNAME  CMS_STATEMENTS_LOG.CSL_MERCHANT_NAME%TYPE;
  V_TXN_MERCHCITY  CMS_STATEMENTS_LOG.CSL_MERCHANT_CITY%TYPE;
  V_FEE_MERCHCITY  CMS_STATEMENTS_LOG.CSL_MERCHANT_CITY%TYPE;
  V_TXN_MERCHSTATE CMS_STATEMENTS_LOG.CSL_MERCHANT_STATE%TYPE;
  V_FEE_MERCHSTATE CMS_STATEMENTS_LOG.CSL_MERCHANT_STATE%TYPE;
  --Added by Deepa on June 26 2012 for Reversal Txn fee
  V_FEE_AMT   NUMBER;
  V_FEE_PLAN  CMS_FEE_PLAN.CFP_PLAN_ID%TYPE;
  V_TXN_TYPE  NUMBER(1);
  V_TRAN_DATE DATE;
  --Sn added by Pankaj S. for 10871
  v_acct_type        cms_acct_mast.cam_type_code%TYPE;
  v_cap_card_stat    cms_appl_pan.cap_card_stat%TYPE;
  v_timestamp        timestamp(3);
  --En added by Pankaj S. for 10871
  V_FEE_CODE           CMS_FEE_MAST.CFM_FEE_CODE%TYPE; --Added on 30.07.2013 for 11695
  V_FEEATTACH_TYPE     VARCHAR2(2); --Added on 30.07.2013 for 11695
  v_feecap_flag VARCHAR2(1);
  v_orgnl_fee_amt  CMS_FEE_MAST.CFM_FEE_AMT%TYPE; --Added for FWR-11
  V_ACCT_NUMBER        CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_ORGNL_TXN_FEE_PLAN     TRANSACTIONLOG.FEE_PLAN%TYPE;
  V_REVERSAL_AMT_FLAG VARCHAR2(1) := 'F';  ---Added for Mantis Id-0010997

  --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
  v_prfl_code                cms_appl_pan.cap_prfl_code%TYPE;
  v_prfl_flag                cms_transaction_mast.ctm_prfl_flag%type;
  v_tran_type                cms_transaction_mast.ctm_tran_type%type;
  v_pos_verification         transactionlog.pos_verification%type;
  v_internation_ind_response transactionlog.internation_ind_response %type;
  v_add_ins_date             transactionlog.add_ins_date %type;
  --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)

   V_DUPCHK_CARDSTAT TRANSACTIONLOG.CARDSTATUS%TYPE; -- added for handling duplicate request echo back
   V_DUPCHK_ACCTBAL  TRANSACTIONLOG.ACCT_BALANCE%TYPE; -- added for handling duplicate request echo back
   V_DUPCHK_COUNT    NUMBER; -- added for handling duplicate request echo back
   v_dupl_flag number DEFAULT 0; -- added for handling duplicate request echo back

  V_SP_COUNT      NUMBER;   --Added for serial number changes on 29/10/14
  V_RES_CDE      NUMBER; --Added for serial number changes on 29/10/14 
  V_RESP_MSG      VARCHAR2(500); --Added for serial number changes on 29/10/14
  --Sn Added for FSS-4647
  v_redmption_delay_flag   cms_prod_cattype.cpc_redemption_delay_flag%TYPE;
  v_txn_redmption_flag  cms_transaction_mast.ctm_redemption_delay_flag%TYPE;
  --En Added for FSS-4647 
 v_valins_act_flag cms_prod_cattype.CPC_VALINS_ACT_FLAG%TYPE;
 
 v_Retperiod  date;  --Added for VMS-5739/FSP-991
 v_Retdate  date; --Added for VMS-5739/FSP-991
  
  CURSOR FEEREVERSE IS
    SELECT CSL_TRANS_NARRRATION,
         CSL_MERCHANT_NAME,
         CSL_MERCHANT_CITY,
         CSL_MERCHANT_STATE,
         CSL_TRANS_AMOUNT
     FROM CMS_STATEMENTS_LOG
    WHERE CSL_BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
         CSL_BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND
         CSL_RRN = P_ORGNL_RRN AND
         CSL_DELIVERY_CHANNEL = V_ORGNL_DELIVERY_CHANNEL AND
         CSL_TXN_CODE = V_ORGNL_TXN_CODE AND
         CSL_PAN_NO = V_ORGNL_CUSTOMER_CARD_NO AND
         CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'Y';
BEGIN

  P_RESP_CDE := '00';
  P_RESP_MSG := 'OK';
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

   --Sn find the type of orginal txn (credit or debit)
  BEGIN
    SELECT CTM_CREDIT_DEBIT_FLAG,
         CTM_TRAN_DESC,
         TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
         CTM_PRFL_FLAG, --Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
         NVL(ctm_redemption_delay_flag,'N')
     INTO V_DR_CR_FLAG, V_TRAN_DESC, V_TXN_TYPE,
          v_prfl_flag, --Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
          v_txn_redmption_flag
     FROM CMS_TRANSACTION_MAST
    WHERE CTM_TRAN_CODE = P_TXN_CODE AND
         CTM_DELIVERY_CHANNEL = P_DELV_CHNL AND
         CTM_INST_CODE = P_INST_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Transaction detail is not found in master for orginal txn code' ||
                P_TXN_CODE || 'delivery channel ' || P_DELV_CHNL;
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Problem while selecting debit/credit flag ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En find the type of orginal txn (credit or debit)

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
    V_TRAN_DATE     := V_RVSL_TRANDATE;

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
    --    SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;

    --    SELECT V_AUTHID_DATE || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
    SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG   := 'Error while generating authid ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '21'; -- Server Declined
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En generate auth id

  --Sn - added for FSS-1802
--  BEGIN
--    SELECT CAP_CARD_STAT
--     INTO V_CAP_CARD_STAT
--     FROM CMS_APPL_PAN
--    WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
--  EXCEPTION
--    WHEN EXP_RVSL_REJECT_RECORD THEN
--     RAISE;
--    WHEN NO_DATA_FOUND THEN
--     V_RESP_CDE := '21';
--     V_ERRMSG   := 'Invalid Card number ' || V_HASH_PAN;
--     RAISE EXP_RVSL_REJECT_RECORD;
--    WHEN OTHERS THEN
--     V_RESP_CDE := '21';
--     V_ERRMSG   := 'Error while selecting card number ' || V_HASH_PAN;
--     RAISE EXP_RVSL_REJECT_RECORD;
--  END;
--En - added for FSS-1802

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
         FEE_PLAN,
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
         AMOUNT,
         --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
         pos_verification,
         internation_ind_response,
         add_ins_date,
         decode(txn_type,'1','F','0','N')
         --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
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
         V_ORGNL_TXN_FEE_PLAN,
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
         V_ORGNL_TXN_AMNT,
         --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
         v_pos_verification,
         v_internation_ind_response,
         v_add_ins_date,
         v_tran_type
         --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
     FROM VMSCMS.TRANSACTIONLOG               --Added for VMS-5739/FSP-991
    WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
         AND INSTCODE = P_INST_CODE AND MSGTYPE IN ('0200','1200') AND
         DELIVERY_CHANNEL = P_DELV_CHNL; --Added by ramkumar.Mk on 25 march 2012
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
         FEE_PLAN,
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
         AMOUNT,
         --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
         pos_verification,
         internation_ind_response,
         add_ins_date,
         decode(txn_type,'1','F','0','N')
         --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
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
         V_ORGNL_TXN_FEE_PLAN,
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
         V_ORGNL_TXN_AMNT,
         --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
         v_pos_verification,
         v_internation_ind_response,
         v_add_ins_date,
         v_tran_type
         --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST               --Added for VMS-5739/FSP-991
    WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
         AND INSTCODE = P_INST_CODE AND MSGTYPE IN ('0200','1200') AND
         DELIVERY_CHANNEL = P_DELV_CHNL; --Added by ramkumar.Mk on 25 march 2012
		 END IF;
		 
    IF V_ORGNL_RESP_CODE <> '00' THEN
     V_RESP_CDE := '23';
     V_ERRMSG   := ' The original transaction was not successful';
     RAISE EXP_RVSL_REJECT_RECORD;
    END IF;

    IF V_TRAN_REVERSE_FLAG = 'Y' THEN
    --SN Modified for FSS-4767
    /* --Sn - added for handling duplicate request echo back - Fss-1802
    begin
        SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
        INTO V_DUPCHK_CARDSTAT, V_DUPCHK_ACCTBAL
        from(SELECT CARDSTATUS, ACCT_BALANCE   FROM TRANSACTIONLOG
                WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
                DELIVERY_CHANNEL = P_DELV_CHNL
                and ACCT_BALANCE is not null
                order by add_ins_date desc)
                where rownum=1;

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
            WHERE CAM_ACCT_NO = (SELECT CAP_ACCT_NO  FROM CMS_APPL_PAN
                                WHERE CAP_PAN_CODE = V_HASH_PAN
                                AND CAP_MBR_NUMB = P_MBR_NUMB
                                AND CAP_INST_CODE = P_INST_CODE) AND
            CAM_INST_CODE = P_INST_CODE;

        EXCEPTION
            WHEN OTHERS THEN
                V_RESP_CDE := '12';
                V_ERRMSG   := 'Error while selecting acct balance ' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_RVSL_REJECT_RECORD;
        END;


        V_DUPCHK_COUNT:=0;


        if V_DUPCHK_CARDSTAT= V_CAP_CARD_STAT and V_DUPCHK_ACCTBAL=V_ACCT_BALANCE then
            V_DUPCHK_COUNT:=1;*/
            v_dupl_flag:=1;
            V_RESP_CDE := '52';
            V_ERRMSG   := 'The reversal already done for the original transaction';
            RAISE EXP_RVSL_REJECT_RECORD;
        --end if;

    --end if;
    -- V_RESP_CDE := '52';
    -- V_ERRMSG   := 'The reversal already done for the orginal transaction';
    -- RAISE EXP_RVSL_REJECT_RECORD;
    END IF;
--En - added for handling duplicate request echo back - Fss-1802
 --EN Modified for FSS-4767


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
            AMOUNT,
            --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
            pos_verification,
            internation_ind_response,
            add_ins_date,
            decode(txn_type,'1','F','0','N')
            --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
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
            V_ORGNL_TXN_AMNT,
            --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
            v_pos_verification,
            v_internation_ind_response,
            v_add_ins_date,
            v_tran_type
            --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
        FROM VMSCMS.TRANSACTIONLOG                       -------Added for VMS-5739/FSP-991
        WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
            AND INSTCODE = P_INST_CODE AND RESPONSE_CODE = '00' AND
            DELIVERY_CHANNEL = P_DELV_CHNL --Added by ramkumar.Mk on 25 march 2012
            AND MSGTYPE IN ('0200','1200');
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
            AMOUNT,
            --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
            pos_verification,
            internation_ind_response,
            add_ins_date,
            decode(txn_type,'1','F','0','N')
            --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
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
            V_ORGNL_TXN_AMNT,
            --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
            v_pos_verification,
            v_internation_ind_response,
            v_add_ins_date,
            v_tran_type
            --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                       -------Added for VMS-5739/FSP-991
        WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
            AND INSTCODE = P_INST_CODE AND RESPONSE_CODE = '00' AND
            DELIVERY_CHANNEL = P_DELV_CHNL --Added by ramkumar.Mk on 25 march 2012
            AND MSGTYPE IN ('0200','1200');
			END IF;

       IF V_TRAN_REVERSE_FLAG = 'Y' THEN
     --SN Modified for FSS-4767
     /*  --Sn - added for handling duplicate request echo back - Fss-1802
    begin
        SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
        INTO V_DUPCHK_CARDSTAT, V_DUPCHK_ACCTBAL
        from(SELECT CARDSTATUS, ACCT_BALANCE   FROM TRANSACTIONLOG
                WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
                DELIVERY_CHANNEL = P_DELV_CHNL
                and ACCT_BALANCE is not null
                order by add_ins_date desc)
        where rownum=1;

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
            WHERE CAM_ACCT_NO = (SELECT CAP_ACCT_NO  FROM CMS_APPL_PAN
                                WHERE CAP_PAN_CODE = V_HASH_PAN
                                AND CAP_MBR_NUMB = P_MBR_NUMB
                                AND CAP_INST_CODE = P_INST_CODE) AND
            CAM_INST_CODE = P_INST_CODE;

        EXCEPTION
            WHEN OTHERS THEN
                V_RESP_CDE := '12';
                V_ERRMSG   := 'Error while selecting acct balance ' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_RVSL_REJECT_RECORD;
        END;


        V_DUPCHK_COUNT:=0;


        if V_DUPCHK_CARDSTAT= V_CAP_CARD_STAT and V_DUPCHK_ACCTBAL=V_ACCT_BALANCE then
            V_DUPCHK_COUNT:=1;*/
            v_dupl_flag:=1;
            V_RESP_CDE := '52';
            V_ERRMSG   := 'The reversal already done for the orginal transaction';
            RAISE EXP_RVSL_REJECT_RECORD;
        --end if;

    --end if;
    -- V_RESP_CDE := '52';
    -- V_ERRMSG   := 'The reversal already done for the orginal transaction';
    -- RAISE EXP_RVSL_REJECT_RECORD;
    END IF;
--En - added for handling duplicate request echo back - Fss-1802
  --EN Modified for FSS-4767


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
                AMOUNT,
                --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
                pos_verification,
                internation_ind_response,
                add_ins_date,
                decode(txn_type,'1','F','0','N')
                --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
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
                V_ORGNL_TXN_AMNT,
                --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
                v_pos_verification,
                v_internation_ind_response,
                v_add_ins_date,
                v_tran_type
                --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
            FROM VMSCMS.TRANSACTIONLOG    --Added for VMS-5739/FSP-991
           WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
                AND INSTCODE = P_INST_CODE AND RESPONSE_CODE != '00' AND
                DELIVERY_CHANNEL = P_DELV_CHNL --Added by ramkumar.Mk on 25 march 2012
                AND MSGTYPE IN ('0200','1200');
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
                AMOUNT,
                --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
                pos_verification,
                internation_ind_response,
                add_ins_date,
                decode(txn_type,'1','F','0','N')
                --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
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
                V_ORGNL_TXN_AMNT,
                --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
                v_pos_verification,
                v_internation_ind_response,
                v_add_ins_date,
                v_tran_type
                --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
            FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST     --Added for VMS-5739/FSP-991
           WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
                AND INSTCODE = P_INST_CODE AND RESPONSE_CODE != '00' AND
                DELIVERY_CHANNEL = P_DELV_CHNL --Added by ramkumar.Mk on 25 march 2012
                AND MSGTYPE IN ('0200','1200');
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

  IF V_ORGNL_CUSTOMER_CARD_NO <> V_HASH_PAN THEN

    V_RESP_CDE := '21';
    V_ERRMSG   := 'Customer card number is not matching in reversal and orginal transaction';
    RAISE EXP_RVSL_REJECT_RECORD;

  END IF;
  --En check card number

--ST:Added for serial number changes on 29/10/14
  IF P_SERIAL_NUMBER IS NOT NULL THEN    
    BEGIN
        select count(1) INTO V_SP_COUNT
        from CMS_SPILSERIAL_LOGGING 
        where CSL_INST_CODE=P_INST_CODE
        and CSL_DELIVERY_CHANNEL=P_DELV_CHNL and  CSL_TXN_CODE=P_TXN_CODE
        and CSL_MSG_TYPE=P_MSG_TYP and CSL_SERIAL_NUMBER=P_SERIAL_NUMBER AND CSL_RESPONSE_CODE='00';
        
        IF V_SP_COUNT > 0 THEN
         V_RESP_CDE := '215';
         V_ERRMSG  := 'Duplicate Request';
         RAISE EXP_RVSL_REJECT_RECORD;             
        END IF;
        
      EXCEPTION      
       WHEN EXP_RVSL_REJECT_RECORD THEN
         RAISE;
       WHEN OTHERS THEN
         V_RESP_CDE := '21';
         V_ERRMSG  := 'Error while validating serial number '||substr(sqlerrm,1,200);
         RAISE EXP_RVSL_REJECT_RECORD;      
    END;  
  END IF;
  --EMD:Added for serial number changes on 29/10/14
  
IF P_DELV_CHNL = '08' AND P_TXN_CODE <> '22' THEN -- Added on10/05/14 for FSS-1636

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
     FROM VMSCMS.TRANSACTIONLOG                          --Added for VMS-5739/FSP-991
    WHERE TO_DATE(BUSINESS_DATE || BUSINESS_TIME, 'yyyymmdd hh24miss') >
         TO_DATE(V_ORGNL_BUSINESS_DATE || V_ORGNL_BUSINESS_TIME,
                'yyyymmdd hh24miss') AND CUSTOMER_CARD_NO = V_HASH_PAN AND
         INSTCODE = P_INST_CODE AND TXN_TYPE = '1'
         AND RESPONSE_CODE='00'; -- Modified by Deepa T to add success response code for 13632 on 07-Feb-2014;
	ELSE
	    SELECT COUNT(1)
     INTO V_TXNCNT_AFTERTOPUP
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                          --Added for VMS-5739/FSP-991
    WHERE TO_DATE(BUSINESS_DATE || BUSINESS_TIME, 'yyyymmdd hh24miss') >
         TO_DATE(V_ORGNL_BUSINESS_DATE || V_ORGNL_BUSINESS_TIME,
                'yyyymmdd hh24miss') AND CUSTOMER_CARD_NO = V_HASH_PAN AND
         INSTCODE = P_INST_CODE AND TXN_TYPE = '1'
         AND RESPONSE_CODE='00'; -- Modified by Deepa T to add success response code for 13632 on 07-Feb-2014;
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

  IF V_TXNCNT_AFTERTOPUP > 0 THEN

    V_RESP_CDE := '67';
    V_ERRMSG   := 'Card successfully loaded and load amount has been redeemed';
    RAISE EXP_RVSL_REJECT_RECORD;

  END IF;

END IF;  -- Added on10/05/14 for FSS-1636
--Sn Below block moved up & commented down during MVHOST_756 & MVCSD-4113
  BEGIN
    SELECT CAP_PROD_CODE, CAP_CARD_TYPE
           ,cap_card_stat,
           cap_prfl_code,  --Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
           cap_acct_no  --Added during FSS-4767
     INTO V_PROD_CODE, V_CARD_TYPE,
          v_cap_card_stat,  --added by Pankaj S. for 10871
          v_prfl_code,  --Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
          v_acct_number --Added during FSS-4767
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INST_CODE AND CAP_MBR_NUMB = p_mbr_numb AND CAP_PAN_CODE = V_HASH_PAN;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '21';
     --V_ERRMSG   := P_CARD_NO || ' Card no not found in CMS';  commented for FSS-.2320.
      V_ERRMSG   := 'Card no not found in CMS';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while retriving card detail ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --En Below block moved up & commented down during MVHOST_756 & MVCSD-4113
  --Sn find the converted tran amt
  V_TRAN_AMT := P_ACTUAL_AMT;

 BEGIN
     select CPC_VALINS_ACT_FLAG INTO V_VALINS_ACT_FLAG
     from cms_prod_cattype
     where CPC_INST_CODE=P_INST_CODE and CPC_PROD_CODE=V_PROD_CODE
     and CPC_CARD_TYPE=V_CARD_TYPE;
   EXCEPTION     
      WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERRMSG   := 'Error while retriving product category detail ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_RVSL_REJECT_RECORD;  
    END;
    if  V_VALINS_ACT_FLAG = 'Y' and V_ORGNL_TXN_CODE <> P_TXN_CODE then    
      V_Resp_Cde := '53';
      V_ERRMSG   := 'Matching transaction not found';
       RAISE EXP_RVSL_REJECT_RECORD;  
    end if;
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

  IF V_REVERSAL_AMT < V_ORGNL_TOTAL_AMOUNT THEN  ---Modified For Mantis id-0010997
    V_REVERSAL_AMT_FLAG :='P';
  END IF;

  IF V_DR_CR_FLAG = 'NA' THEN
    V_RESP_CDE := '21';
    V_ERRMSG   := 'Not a valid orginal transaction for reversal';
    RAISE EXP_RVSL_REJECT_RECORD;
  END IF;
  IF V_DR_CR_FLAG <> V_ORGNL_TRANSACTION_TYPE THEN
    V_RESP_CDE := '21';
    V_ERRMSG   := 'Orginal transaction type is not matching with actual transaction type';
    RAISE EXP_RVSL_REJECT_RECORD;
  END IF;
  --Sn reverse the amount






  --Sn find the orginal func code
  --SN - Commented for fwr-48
/*  BEGIN
    SELECT CFM_FUNC_CODE
     INTO V_FUNC_CODE
     FROM CMS_FUNC_MAST
    WHERE CFM_TXN_CODE = V_ORGNL_TXN_CODE AND
         CFM_TXN_MODE = V_ORGNL_TXN_MODE AND
         CFM_DELIVERY_CHANNEL = V_ORGNL_DELIVERY_CHANNEL AND
         CFM_INST_CODE = P_INST_CODE;
    --TXN mode and delivery channel we need to attach
    --bkz txn code may be same for all type of channels
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '69'; --Ineligible Transaction
     V_ERRMSG   := 'Function code not defined for txn code ' || P_TXN_CODE;
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN TOO_MANY_ROWS THEN
     V_RESP_CDE := '69';
     V_ERRMSG   := 'More than one function defined for txn code ' ||
                P_TXN_CODE;
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '69';
     V_ERRMSG   := 'Problem while selecting function code from function mast  ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END; */

  -- En - Commented for fwr-48

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
    SELECT CAM_ACCT_NO,cam_type_code, CAM_ACCT_BAL,CAM_LEDGER_BAL --Added for mantis Id:14577
     INTO V_CARD_ACCT_NO,v_acct_type,  --v_acct_type added by Pankaj S. for 10871
          V_ACCT_BALANCE,V_LEDGER_BALANCE  --Added for mantis Id:14577
     FROM CMS_ACCT_MAST
    WHERE CAM_ACCT_NO =v_acct_number
      --SN Modified during FSS-4767
       /*  (SELECT CAP_ACCT_NO
            FROM CMS_APPL_PAN
           WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
                CAP_INST_CODE = P_INST_CODE) */AND
      --EN Modified during FSS-4767          
         CAM_INST_CODE = P_INST_CODE
      FOR UPDATE NOWAIT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '14'; --Ineligible Transaction
     V_ERRMSG   := 'Invalid Card ';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '12';
     V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||V_HASH_PAN;
                --P_CARD_NO;  commented for FSS-.2320.
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --Sn reverse  the amount
  --St  --Added for mantis Id:14577
  if V_ACCT_BALANCE < V_ORGNL_TXN_AMNT then
     V_RESP_CDE := '15';
     V_ERRMSG   := 'Insufficient Funds';
      RAISE EXP_RVSL_REJECT_RECORD;
  end if;
  --En  --Added for mantis Id:14577

  --Sn find narration

  BEGIN
  
  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
	   
	   v_Retdate := TO_DATE(SUBSTR(TRIM(P_ORGNL_BUSINESS_DATE), 1, 8), 'yyyymmdd');
	   
	 IF (v_Retdate>v_Retperiod)                                            --Added for VMS-5739/FSP-991
    THEN  

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
     FROM VMSCMS_HISTORY.cms_statements_log_HIST --Added for VMS-5739/FSP-991
    WHERE CSL_BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
         CSL_BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND CSL_RRN = P_RRN AND
         CSL_DELIVERY_CHANNEL = V_ORGNL_DELIVERY_CHANNEL AND
         CSL_TXN_CODE = V_ORGNL_TXN_CODE AND
         CSL_PAN_NO = V_ORGNL_CUSTOMER_CARD_NO AND
         CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'N';
		
	END IF ;
	

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_TXN_NARRATION := NULL;
    WHEN OTHERS THEN
     V_FEE_NARRATION := NULL;

  END;

  --En find narration
 v_timestamp:=systimestamp; --added by Pankaj S. for 10871

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
  
  --SN Commented during FSS-4767
  --Sn reverse the fee
  /*BEGIN
    SP_DAILY_BIN_BAL(P_CARD_NO,
                 V_RVSL_TRANDATE,
                 V_REVERSAL_AMT,
                 'DR',
                 P_INST_CODE,
                 P_BANK_CODE,
                 V_ERRMSG);
  EXCEPTION
    WHEN OTHERS THEN
     NULL;
  END;*/
  --EN Commented during FSS-4767
  --Added by Deepa For Reversal Fees on June 27 2012

  IF V_REVERSAL_AMT_FLAG <>'P' THEN   --Modified For Mantis Id-0010997
  IF V_ORGNL_TXN_TOTALFEE_AMT > 0 or V_ORGNL_TXN_FEECODE is not null THEN --Modified for FWR-11
  -- SN Added for FWR-11
  BEGIN
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
    BEGIN

     FOR C1 IN FEEREVERSE LOOP
         -- SN Added for FWR-11
      V_ORGNL_TRANFEE_AMT := C1.CSL_TRANS_AMOUNT;
       if v_feecap_flag = 'Y' then
       BEGIN
            SP_TRAN_FEES_REVCAPCHECK(P_INST_CODE,
                    V_ACCT_NUMBER,
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
                          P_TXN_CODE,
                          V_RVSL_TRANDATE,
                          P_TXN_MODE,
                        --  C1.CSL_TRANS_AMOUNT,
                        V_ORGNL_TRANFEE_AMT, -- Modified for FWR-11
                          P_CARD_NO,
                          V_ACTUAL_FEECODE,
                        --  C1.CSL_TRANS_AMOUNT,
                        V_ORGNL_TRANFEE_AMT, -- Modified for FWR-11
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
                          C1.CSL_TRANS_NARRRATION,
                          C1.CSL_MERCHANT_NAME,
                          C1.CSL_MERCHANT_CITY,
                          C1.CSL_MERCHANT_STATE,
                          V_RESP_CDE,
                          V_ERRMSG);

        V_FEE_NARRATION := C1.CSL_TRANS_NARRRATION;

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

     END LOOP;

    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_FEE_NARRATION := NULL;
     WHEN OTHERS THEN
       V_FEE_NARRATION := NULL;

    END;

  END IF;

  IF V_FEE_NARRATION IS NULL THEN
    --Added by Deepa For Reversal Fees on June 27 2012
    BEGIN
    --SN Added for FWR-11
           if v_feecap_flag = 'Y' then
        BEGIN
            SP_TRAN_FEES_REVCAPCHECK(P_INST_CODE,
                    V_ACCT_NUMBER,
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
       --EN Added for FWR-11
     SP_REVERSE_FEE_AMOUNT(P_INST_CODE,
                       P_RRN,
                       P_DELV_CHNL,
                       P_ORGNL_TERMINAL_ID,
                       P_MERC_ID,
                       P_TXN_CODE,
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
                       V_FEE_MERCHNAME,
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

  END IF;
  END IF;  ----Added For Mantis-Id-0010997
  --Sn reverse the GL entries

  --Sn Below block commented here & moved up during MVHOST_756 & MVCSD-4113
 /* --Sn get the product code
  BEGIN

    SELECT CAP_PROD_CODE, CAP_CARD_TYPE
           ,cap_card_stat
     INTO V_PROD_CODE, V_CARD_TYPE,
          v_cap_card_stat  --added by Pankaj S. for 10871
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := P_CARD_NO || ' Card no not in master';
     RAISE EXP_RVSL_REJECT_RECORD;

    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while retriving card detail ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;

  END;*/
  --En Below block commented here & moved up during MVHOST_756 & MVCSD-4113

  IF V_GL_UPD_FLAG = 'Y' THEN

    --Sn find business date
    V_BUSINESS_TIME := TO_CHAR(V_RVSL_TRANDATE, 'HH24:MI');
    IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
     V_RVSL_TRANDATE := TRUNC(V_RVSL_TRANDATE) + 1;
    ELSE
     V_RVSL_TRANDATE := TRUNC(V_RVSL_TRANDATE);
    END IF;
    --En find businesses date

    --SN - Commented for fwr-48

  /*  SP_REVERSE_GL_ENTRIES(P_INST_CODE,
                     V_RVSL_TRANDATE,
                     V_PROD_CODE,
                     V_CARD_TYPE,
                     V_REVERSAL_AMT,
                     V_FUNC_CODE,
                     P_TXN_CODE,
                     V_DR_CR_FLAG,
                     P_CARD_NO,
                     V_ACTUAL_FEECODE,
                     V_ORGNL_TXN_TOTALFEE_AMT,
                     V_ORGNL_TRANFEE_CR_ACCTNO,
                     V_ORGNL_TRANFEE_DR_ACCTNO,
                     V_CARD_ACCT_NO,
                     P_RVSL_CODE,
                     P_MSG_TYP,
                     P_DELV_CHNL,
                     V_RESP_CDE,
                     V_GL_UPD_FLAG,
                     V_ERRMSG);
    IF V_GL_UPD_FLAG <> 'Y' THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := V_ERRMSG || 'Error while retriving gl detail ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
    END IF; */

    --En - Commented for fwr-48

  END IF;
  --En reverse the GL entries

  V_RESP_CDE := '1';
  --Added by Deepa on June 26 2012 for Reversal Fee Calculation

  --Sn reversal Fee Calculation
  BEGIN

    SP_TRAN_REVERSAL_FEES(P_INST_CODE,
                     P_CARD_NO,
                     P_DELV_CHNL,
                     V_ORGNL_TXN_MODE,
                     P_TXN_CODE,
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
                     V_FEE_CODE,      --Added on 29.07.2013 for 11695
                     V_FEEATTACH_TYPE --Added on 29.07.2013 for 11695
                     );

    IF V_ERRMSG <> 'OK' THEN
     RAISE EXP_RVSL_REJECT_RECORD;
    END IF;
  END;
  --En reversal Fee Calculation

   --Sn added by Pankaj S. for 10871
     BEGIN
	 
	 --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
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
           AND csl_business_time = p_business_time
           AND csl_trans_type = decode(v_dr_cr_flag,'CR','DR','DR','CR',v_dr_cr_flag); -- Added on 21-JUn-2014 for FSS-1720
		   
 ELSE
 
  UPDATE VMSCMS_HISTORY.cms_statements_log_HIST                  --Added for VMS-5739/FSP-991
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
           AND csl_business_time = p_business_time
           AND csl_trans_type = decode(v_dr_cr_flag,'CR','DR','DR','CR',v_dr_cr_flag); -- Added on 21-JUn-2014 for FSS-1720
 
 END IF;
 
       IF SQL%ROWCOUNT =0
       THEN
         NULL;
       END IF;
       EXCEPTION
       WHEN OTHERS
       THEN
          V_RESP_CDE := '21';
          v_errmsg :=
               'Error while updating timestamp in statementlog-' || SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_RVSL_REJECT_RECORD;
    END;
    --Sn added by Pankaj S. for 10871


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
        P_TXN_CODE,
        --P_TXN_TYPE,
        V_TXN_TYPE, --Modified by Deepa on June 26 2012 As the value is passed as NULL
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
     V_ERRMSG   := 'Problem while selecting data from response master ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '21';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En create a entry for successful

  --Sn generate response code

  --V_RESP_CDE := '1';
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

  --Sn Modified by MageshKumar.S on 21-06-2013 for FSS-1248

  BEGIN
       SELECT CAM_ACCT_BAL,CAM_LEDGER_BAL -- added by MageshKumar.S on 21-06-2013 for Defect Id : FSS-1248
        INTO V_ACCT_BALANCE,V_LEDGER_BALANCE
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =v_acct_number
        --SN Modified during FSS-4767
           /* (SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN AND
                   CAP_MBR_NUMB = P_MBR_NUMB AND
                   CAP_INST_CODE = P_INST_CODE)*/ AND
        --EN Modified during FSS-4767                   
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

  --En Modified by MageshKumar.S on 21-06-2013 for FSS-1248
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
      FEE_PLAN, --Added by Deepa on June 26 2012 for fee plan
      MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_STATE , -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      --Sn added by Pankaj S. for 10871
      customer_acct_no,
      cr_dr_flag,
      cardstatus,
      acct_type,
      error_msg,
      time_stamp,
      --En added by Pankaj S. for 10871
      reversal_code, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      ACCT_BALANCE, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      Ledger_Balance, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      Add_Ins_User, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      STORE_ID ,--SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
      merchant_zip--added for VMS-622 (redemption_delay zip code validation)
      )
    VALUES
     (P_MSG_TYP,
      P_RRN,
      P_DELV_CHNL,
      P_TERMINAL_ID,
      V_RVSL_TRANDATE,
      P_TXN_CODE,
      --P_TXN_TYPE,
      V_TXN_TYPE, --Modified by Deepa on June 26 2012 As the value is passed as NULL
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
      TRIM(TO_CHAR(V_REVERSAL_AMT, '9999999999990.99')) --modified for 10871
      -- reversal amount will be passed in the table as the same is used in the recon report.
     ,
      NULL,
      NULL,
      P_MERC_ID,
      V_CURR_CODE,
      V_PROD_CODE,
      V_CARD_TYPE,
      V_FEE_AMT, --Added by Deepa on June 26 2012 for logging fee
      '0.00', --Modified by Pankaj S. for 10871
      NULL,
      NULL,
      V_AUTH_ID,
      V_TRAN_DESC,
      TRIM(TO_CHAR(V_REVERSAL_AMT, '9999999999990.99')), --modified for 10871
      -- reversal amount will be passed in the table as the same is used in the recon report.
      '0.00', --Modified by Pankaj S. for 10871 --- PRE AUTH AMOUNT
      '0.00', --Modified by Pankaj S. for 10871 -- Partial amount (will be given for partial txn)
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      'Y',
      P_STAN,
      P_INST_CODE,
        --NULL,
      V_FEE_CODE, --Added on 30.07.2013 for 11695
      --NULL,
      V_FEEATTACH_TYPE, --Added on 30.07.2013 for 11695
      'N',
      V_ENCR_PAN,
      NULL,
      V_ORGNL_CUSTOMER_CARD_NO,
      P_RRN,
      V_ORGNL_BUSINESS_DATE,
      V_ORGNL_BUSINESS_TIME,
      V_ORGNL_TERMID,
      V_RESP_CDE,
      V_FEE_PLAN,--Added by Deepa on June 26 2012 for fee plan
      V_TXN_MERCHNAME, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      V_TXN_MERCHCITY, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      V_TXN_MERCHSTATE, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      --Sn added by Pankaj S. for 10871
      v_card_acct_no,
       -- v_dr_cr_flag,--Commented and modified on 25.07.2013 for 11693
      decode(v_dr_cr_flag,'CR','DR','DR','CR',v_dr_cr_flag),
      v_cap_card_stat,
      v_acct_type,
      v_errmsg,
      v_timestamp,
      --En added by Pankaj S. for 10871
      P_RVSL_CODE, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      V_ACCT_BALANCE, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      V_Ledger_Balance, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      1, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      P_STORE_ID , --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
      P_Merchant_zip--added for VMS-622 (redemption_delay zip code validation)
      );

    --Sn update reverse flag
    BEGIN
	
	--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(V_ORGNL_BUSINESS_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)             --Added for VMS-5739/FSP-991
    THEN
	
     UPDATE TRANSACTIONLOG
        SET TRAN_REVERSE_FLAG = 'Y'
      WHERE RRN = P_RRN AND BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
           BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE = P_INST_CODE;
		   
	ELSE
	
	 UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST                   --Added for VMS-5739/FSP-991
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
   --SN Commented during FSS-4767
   /*
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

    BEGIN

     --Sn Limit and amount check for ATM
     IF P_DELV_CHNL = '01' THEN

       IF V_RVSL_TRANDATE > V_BUSINESS_DATE_TRAN THEN

        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0,
              CTC_ATMUSAGE_AMT       = 0,
              CTC_ATMUSAGE_LIMIT     = 0,
              CTC_BUSINESS_DATE      = TO_DATE(P_BUSINESS_DATE ||
                                        '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = 0
         WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
              CTC_MBR_NUMB = P_MBR_NUMB;

        IF SQL%ROWCOUNT = 0 THEN

          V_RESP_CDE := '21';
          V_ERRMSG   := 'updating 1 CMS_TRANSLIMIT_CHECK';
          RAISE EXP_RVSL_REJECT_RECORD;
        END IF;

       ELSE
        IF P_ORGNL_BUSINESS_DATE = P_BUSINESS_DATE THEN

          IF V_REVERSAL_AMT IS NULL THEN
            V_ATM_USAGEAMNT := V_ATM_USAGEAMNT;
          ELSE
            V_ATM_USAGEAMNT := V_ATM_USAGEAMNT -
                           TRIM(TO_CHAR(V_REVERSAL_AMT,
                                     '999999999999.99'));
          END IF;

          UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_POSUSAGE_AMT = V_ATM_USAGEAMNT
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN AND CTC_MBR_NUMB = P_MBR_NUMB;

          IF SQL%ROWCOUNT = 0 THEN

            V_RESP_CDE := '21';
            V_ERRMSG   := 'updating 2 CMS_TRANSLIMIT_CHECK';
            RAISE EXP_RVSL_REJECT_RECORD;
          END IF;

        END IF;
       END IF;
     END IF;
     --En Limit and amount check for ATM

     --Sn Limit and amount check for POS

     IF P_DELV_CHNL = '02' THEN

       IF V_RVSL_TRANDATE > V_BUSINESS_DATE_TRAN THEN

        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0,
              CTC_ATMUSAGE_AMT       = 0,
              CTC_ATMUSAGE_LIMIT     = 0,
              CTC_BUSINESS_DATE      = TO_DATE(P_BUSINESS_DATE ||
                                        '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = 0
         WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
              CTC_MBR_NUMB = P_MBR_NUMB;
        IF SQL%ROWCOUNT = 0 THEN

          V_RESP_CDE := '21';
          V_ERRMSG   := 'updating 3 CMS_TRANSLIMIT_CHECK';
          RAISE EXP_RVSL_REJECT_RECORD;
        END IF;
       ELSE
        IF P_ORGNL_BUSINESS_DATE = P_BUSINESS_DATE THEN

          IF V_REVERSAL_AMT IS NULL THEN
            V_POS_USAGEAMNT := V_POS_USAGEAMNT;

          ELSE
            V_POS_USAGEAMNT := V_POS_USAGEAMNT -
                           TRIM(TO_CHAR(V_REVERSAL_AMT,
                                     '999999999999.99'));
          END IF;

          UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_POSUSAGE_AMT = V_POS_USAGEAMNT
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN AND CTC_MBR_NUMB = P_MBR_NUMB;

          IF SQL%ROWCOUNT = 0 THEN

            V_RESP_CDE := '21';
            V_ERRMSG   := 'updating 4 CMS_TRANSLIMIT_CHECK';
            RAISE EXP_RVSL_REJECT_RECORD;
          END IF;
        END IF;
       END IF;
     END IF;

     --En Limit and amount check for POS

     --Sn Limit and amount check for MMPOS

     IF P_DELV_CHNL = '04' THEN

       IF V_RVSL_TRANDATE > V_BUSINESS_DATE_TRAN THEN

        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0,
              CTC_ATMUSAGE_AMT       = 0,
              CTC_ATMUSAGE_LIMIT     = 0,
              CTC_BUSINESS_DATE      = TO_DATE(P_BUSINESS_DATE ||
                                        '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = 0
         WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
              CTC_MBR_NUMB = P_MBR_NUMB;
        IF SQL%ROWCOUNT = 0 THEN

          V_RESP_CDE := '21';
          V_ERRMSG   := 'updating 5 CMS_TRANSLIMIT_CHECK';
          RAISE EXP_RVSL_REJECT_RECORD;
        END IF;
       ELSE
        IF P_ORGNL_BUSINESS_DATE = P_BUSINESS_DATE THEN

          IF V_REVERSAL_AMT IS NULL THEN
            V_MMPOS_USAGEAMNT := V_MMPOS_USAGEAMNT;

          ELSE

            IF V_DR_CR_FLAG = 'CR' THEN

             V_MMPOS_USAGEAMNT := V_MMPOS_USAGEAMNT;
            ELSE
             V_MMPOS_USAGEAMNT := V_MMPOS_USAGEAMNT -
                              TRIM(TO_CHAR(V_REVERSAL_AMT,
                                        '999999999999.99'));
            END IF;

          END IF;

          UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_POSUSAGE_AMT = V_MMPOS_USAGEAMNT
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN AND CTC_MBR_NUMB = P_MBR_NUMB;
          IF SQL%ROWCOUNT = 0 THEN

            V_RESP_CDE := '21';
            V_ERRMSG   := 'updating 6 CMS_TRANSLIMIT_CHECK';
            RAISE EXP_RVSL_REJECT_RECORD;
          END IF;
        END IF;
       END IF;
     END IF;

     --En Limit and amount check for MMPOS
    EXCEPTION
     WHEN EXP_RVSL_REJECT_RECORD THEN
       RAISE EXP_RVSL_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while updating 1 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;*/
    --EN Commented during FSS-4767
    
      IF v_orgnl_txn_totalfee_amt=0 AND v_orgnl_txn_feecode IS NOT NULL THEN
        BEGIN
           vmsfee.fee_freecnt_reverse (v_acct_number, v_orgnl_txn_feecode, v_errmsg);
        
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

    IF V_ERRMSG = 'OK' THEN

    -- Moved up by MageshKumar.S on 21-06-2013 for Defect Id:FSS-1248

     --Sn find prod code and card type and available balance for the card number

     /*BEGIN
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
        V_ERRMSG   := 'Invalid Card ';
        RAISE EXP_RVSL_REJECT_RECORD;
       WHEN OTHERS THEN
        V_RESP_CDE := '12';
        V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                    SQLERRM;
        RAISE EXP_RVSL_REJECT_RECORD;
     END;*/

     --En find prod code and card type for the card number

      -- Moved up by MageshKumar.S on 21-06-2013 for Defect Id:FSS-1248

        --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
        BEGIN
           IF v_add_ins_date IS NOT NULL AND v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y' THEN
              pkg_limits_check.sp_limitcnt_rever_reset
                                  (p_inst_code,
                                   NULL,
                                   NULL,
                                   v_orgnl_mcccode,
                                   v_orgnl_txn_code,
                                   v_tran_type,
                                   v_internation_ind_response,
                                   v_pos_verification,
                                   v_prfl_code,
                                   v_reversal_amt,
                                   v_orgnl_txn_amnt,
                                   p_delv_chnl,
                                   v_hash_pan,
                                   v_add_ins_date,
                                   v_resp_cde,
                                   v_errmsg
                                  );
           END IF;

           IF v_errmsg <> 'OK' THEN
              RAISE exp_rvsl_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_rvsl_reject_record THEN
              RAISE;
           WHEN OTHERS THEN
              v_resp_cde := '21';
              v_errmsg := 'Error from Limit count reveer Process ' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_rvsl_reject_record;
        END;
       --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)

     P_RESP_MSG := TO_CHAR(V_ACCT_BALANCE);

    ELSE

     P_RESP_MSG := V_ERRMSG;

    END IF;
    
   --SnAdded for FSS-4647
   BEGIN
       SELECT NVL(cpc_redemption_delay_flag,'N')
         INTO v_redmption_delay_flag
         FROM cms_prod_cattype
        WHERE cpc_prod_code = v_prod_code
             AND cpc_card_type = v_card_type
             AND cpc_inst_code = p_inst_code;
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          v_errmsg := 'Product category not found';
          v_resp_cde := '21';
          RAISE exp_rvsl_reject_record;
       WHEN OTHERS
       THEN
          v_errmsg :=
             'Error while fetching redemption delay flag from prodcattype: '
             || SUBSTR (SQLERRM, 1, 200);
          v_resp_cde := '21';
          RAISE exp_rvsl_reject_record;
    END;
    
    IF v_txn_redmption_flag='Y' AND v_redmption_delay_flag='Y' THEN
    BEGIN
       vmsredemptiondelay.redemption_delay (v_acct_number,
                            p_orgnl_rrn,
                            p_delv_chnl,
                            p_txn_code,
                            v_orgnl_txn_amnt,
                            v_prod_code,
                            v_card_type,
                            UPPER (p_merchant_name),
                            P_Merchant_zip,--added for VMS-622 (redemption_delay zip code validation)
                            v_errmsg,
                            'Y');
        IF v_errmsg<>'OK' THEN
             RAISE  exp_rvsl_reject_record;
        END IF;                      
    EXCEPTION
       WHEN exp_rvsl_reject_record THEN
         RAISE;
       WHEN OTHERS
       THEN
          v_errmsg :=
             'Error while calling sp_log_delayed_load: '
             || SUBSTR (SQLERRM, 1, 200);
          v_resp_cde := '21';
          RAISE exp_rvsl_reject_record;
    END;
    END IF;
   --EnAdded for FSS-4647
    
    --ST:Added for serial number changes on 29/10/14
     IF P_SERIAL_NUMBER IS NOT NULL THEN
      BEGIN
              SP_SPIL_SERIALNUMBER_LOGGING(             
                    p_inst_code,
                    P_MSG_TYP ,                                               
                    P_DELV_CHNL,                                               
                    P_TXN_CODE,
                    P_SERIAL_NUMBER,
                    V_AUTH_ID,
                    P_RESP_CDE,
                    V_HASH_PAN,
                    P_RRN,
                    systimestamp,
                    v_res_cde,
                    V_RESP_MSG);
            
        IF v_res_cde <>'00' OR V_RESP_MSG <> 'OK' THEN   
          v_resp_cde := '69';
          v_errmsg := V_RESP_MSG;
          RAISE exp_rvsl_reject_record;
        END IF;

       EXCEPTION        
       when exp_rvsl_reject_record then
       raise;
         WHEN OTHERS THEN
          v_resp_cde := '21';
          P_RESP_MSG  := 'Error while calling SP_SPIL_SERIALNUMBER_LOGGING ' || SUBSTR(SQLERRM, 1, 300);                    
          RAISE exp_rvsl_reject_record;   
    END;
  END IF;
  --END:Added for serial number changes on 29/10/14

  EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
     RAISE;

    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while inserting records in transaction log ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --En  create a entry in GL


EXCEPTION
  -- << MAIN EXCEPTION>>
  WHEN EXP_RVSL_REJECT_RECORD THEN
    ROLLBACK TO V_SAVEPOINT;
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            cam_type_code --added by Pankaj S. for 10871
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
            v_acct_type --added by Pankaj S. for 10871
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
                 CAP_INST_CODE = P_INST_CODE) AND
           CAM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;
    P_ACCT_BAL := V_ACCT_BALANCE;    
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
       FROM VMSCMS.TRANSACTIONLOG_VW A,
           (SELECT MIN(ADD_INS_DATE) MINDATE
             FROM VMSCMS.TRANSACTIONLOG_VW                                --Added for VMS-5739/FSP-991
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
   --SN Commented during FSS-4767
   /* BEGIN

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
       V_ERRMSG   := 'Error while selecting 2 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;

    BEGIN

     --Sn limit update for ATM

     IF P_DELV_CHNL = '01' THEN

       IF V_RVSL_TRANDATE > V_BUSINESS_DATE_TRAN THEN

        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0,
              CTC_ATMUSAGE_AMT       = 0,
              CTC_ATMUSAGE_LIMIT     = 0,
              CTC_BUSINESS_DATE      = TO_DATE(P_BUSINESS_DATE ||
                                        '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = 0
         WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
              CTC_MBR_NUMB = P_MBR_NUMB;
        IF SQL%ROWCOUNT = 0 THEN

          V_RESP_CDE := '21';
          V_ERRMSG   := 'updating 2 -1  CMS_TRANSLIMIT_CHECK';
          RAISE EXP_RVSL_REJECT_RECORD;
        END IF;
       END IF;
     END IF;

     --Sn limit update for POS

     IF P_DELV_CHNL = '02' THEN

       IF V_RVSL_TRANDATE > V_BUSINESS_DATE_TRAN THEN

        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0,
              CTC_ATMUSAGE_AMT       = 0,
              CTC_ATMUSAGE_LIMIT     = 0,
              CTC_BUSINESS_DATE      = TO_DATE(P_BUSINESS_DATE ||
                                        '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = 0
         WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
              CTC_MBR_NUMB = P_MBR_NUMB;
        IF SQL%ROWCOUNT = 0 THEN

          V_RESP_CDE := '21';
          V_ERRMSG   := 'updating 2 -2  CMS_TRANSLIMIT_CHECK';
          RAISE EXP_RVSL_REJECT_RECORD;
        END IF;
       END IF;
     END IF;

     --Sn limit update for MMPOS
     IF P_DELV_CHNL = '04' THEN

       IF V_RVSL_TRANDATE > V_BUSINESS_DATE_TRAN THEN

        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0,
              CTC_ATMUSAGE_AMT       = 0,
              CTC_ATMUSAGE_LIMIT     = 0,
              CTC_BUSINESS_DATE      = TO_DATE(P_BUSINESS_DATE ||
                                        '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = 0
         WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
              CTC_MBR_NUMB = P_MBR_NUMB;
        IF SQL%ROWCOUNT = 0 THEN

          V_RESP_CDE := '21';
          V_ERRMSG   := 'updating 2 -3  CMS_TRANSLIMIT_CHECK';
          RAISE EXP_RVSL_REJECT_RECORD;
        END IF;
       END IF;
     END IF;
    EXCEPTION
     WHEN EXP_RVSL_REJECT_RECORD THEN
       RAISE EXP_RVSL_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while updating 2 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;*/
   --EN Commented during FSS-4767--
      --Sn added by Pankaj S. for 10871
      IF v_dr_cr_flag IS NULL THEN
      BEGIN
        SELECT  ctm_credit_debit_flag,ctm_tran_desc,
                to_number(decode(ctm_tran_type, 'N', '0', 'F', '1'))
          INTO v_dr_cr_flag, v_tran_desc, v_txn_type
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

 --ST:Added for serial number changes on 29/10/14
    IF P_SERIAL_NUMBER IS NOT NULL THEN
      BEGIN
              SP_SPIL_SERIALNUMBER_LOGGING(             
                    p_inst_code,
                    P_MSG_TYP ,                                               
                    P_DELV_CHNL,                                               
                    P_TXN_CODE,
                    P_SERIAL_NUMBER,
                    V_AUTH_ID,
                    P_RESP_CDE,
                    V_HASH_PAN,
                    P_RRN,
                    systimestamp,
                    v_res_cde,
                    V_RESP_MSG);
            
        IF v_res_cde <>'00' OR V_RESP_MSG <> 'OK' THEN
          P_RESP_CDE := '89';   
          P_RESP_MSG := V_RESP_MSG;         
        END IF;
                            
       EXCEPTION              
         WHEN OTHERS THEN
          P_RESP_CDE := '89';
          P_RESP_MSG  := 'Error while calling SP_SPIL_SERIALNUMBER_LOGGING ' || SUBSTR(SQLERRM, 1, 300);                             
    END;
  END IF;
  --END:Added for serial number changes on 29/10/14
  
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
        TRANS_DESC,
         MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_STATE,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      --Sn added by Pankaj S. fro 10871
      customer_acct_no,
      productid,
      cr_dr_flag,
      cardstatus,
      acct_type,
      error_msg,
      time_stamp,
      --En added by Pankaj S. fro 10871
      Reversal_Code, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
      STORE_ID, --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
    --SN Added on 30.07.2013 for 11695
      FEE_PLAN,
      FEECODE,
      TRANFEE_AMT,
      FEEATTACHTYPE,
      merchant_zip--added for VMS-622 (redemption_delay zip code validation)
    --EN Added on 30.07.2013 for 11695
        )
     VALUES
       (P_MSG_TYP,
        P_RRN,
        P_DELV_CHNL,
        P_TERMINAL_ID,
        V_RVSL_TRANDATE,
        P_TXN_CODE,
        --P_TXN_TYPE,
        V_TXN_TYPE, --Modified by Deepa on June 26 2012 As the value is passed as NULL
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
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')),--modified by Pankaj S. for 10871
        V_CURRCODE,
        NULL,
        v_card_type, --Added by Pankaj S. for 10871
        P_TERMINAL_ID,
        V_AUTH_ID,
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')),--modified by Pankaj S. for 10871
        '0.00',  --modified by Pankaj S. for 10871
        '0.00',  --modified by Pankaj S. for 10871
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
        V_TRAN_DESC,
        V_TXN_MERCHNAME, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        V_TXN_MERCHCITY, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        V_TXN_MERCHSTATE, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        --Sn added by Pankaj S. for 10871
        v_card_acct_no,
        v_prod_code,
         -- v_dr_cr_flag,--Commented and modified on 25.07.2013 for 11693
        decode(v_dr_cr_flag,'CR','DR','DR','CR',v_dr_cr_flag),
        v_cap_card_stat,
        v_acct_type,
        v_errmsg,
        nvl(v_timestamp,systimestamp),
        --En added by Pankaj S. for 10871
        P_Rvsl_Code ,-- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
       P_STORE_ID, --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
         --SN Added on 30.07.2013 for 11695
         V_FEE_PLAN,
         V_FEE_CODE,
         V_FEE_AMT,
         V_FEEATTACH_TYPE,
         P_Merchant_zip--added for VMS-622 (redemption_delay zip code validation)
         --EN Added on 30.07.2013 for 11695
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
        --P_TXN_TYPE,
        V_TXN_TYPE, --Modified by Deepa on June 26 2012 As the value is passed as NULL
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
    
    --SN Commented during FSS-4767
    /*BEGIN

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
       V_ERRMSG   := 'Error while selecting 3 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;

    BEGIN

     --Sn limit update for ATM

     IF P_DELV_CHNL = '01' THEN

       IF V_RVSL_TRANDATE > V_BUSINESS_DATE_TRAN THEN

        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0,
              CTC_ATMUSAGE_AMT       = 0,
              CTC_ATMUSAGE_LIMIT     = 0,
              CTC_BUSINESS_DATE      = TO_DATE(P_BUSINESS_DATE ||
                                        '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = 0
         WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
              CTC_MBR_NUMB = P_MBR_NUMB;
       END IF;
     END IF;

     --Sn limit update for POS

     IF P_DELV_CHNL = '02' THEN

       IF V_RVSL_TRANDATE > V_BUSINESS_DATE_TRAN THEN

        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0,
              CTC_ATMUSAGE_AMT       = 0,
              CTC_ATMUSAGE_LIMIT     = 0,
              CTC_BUSINESS_DATE      = TO_DATE(P_BUSINESS_DATE ||
                                        '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = 0
         WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
              CTC_MBR_NUMB = P_MBR_NUMB;
       END IF;
     END IF;

     --Sn limit update for MMPOS
     IF P_DELV_CHNL = '04' THEN

       IF V_RVSL_TRANDATE > V_BUSINESS_DATE_TRAN THEN

        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0,
              CTC_ATMUSAGE_AMT       = 0,
              CTC_ATMUSAGE_LIMIT     = 0,
              CTC_BUSINESS_DATE      = TO_DATE(P_BUSINESS_DATE ||
                                        '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = 0
         WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
              CTC_MBR_NUMB = P_MBR_NUMB;
       END IF;
     END IF;
    END;*/
    --EN Commented during FSS-4767

     --Sn added by Pankaj S. for 10871
      IF v_dr_cr_flag IS NULL THEN
      BEGIN
        SELECT  ctm_credit_debit_flag,ctm_tran_desc,
                to_number(decode(ctm_tran_type, 'N', '0', 'F', '1'))
          INTO v_dr_cr_flag, v_tran_desc, v_txn_type
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
       SELECT cam_type_code
        INTO v_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_inst_code
         AND cam_acct_no = v_card_acct_no;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
      --En added by Pankaj S. for 10871

 --ST:Added for serial number changes on 29/10/14
    IF P_SERIAL_NUMBER IS NOT NULL THEN
      BEGIN
              SP_SPIL_SERIALNUMBER_LOGGING(             
                    p_inst_code,
                    P_MSG_TYP ,                                               
                    P_DELV_CHNL,                                               
                    P_TXN_CODE,
                    P_SERIAL_NUMBER,
                    V_AUTH_ID,
                    P_RESP_CDE,
                    V_HASH_PAN,
                    P_RRN,
                    systimestamp,
                    v_res_cde,
                    V_RESP_MSG);
            
        IF v_res_cde <>'00' OR V_RESP_MSG <> 'OK' THEN
          P_RESP_CDE := '89';   
          P_RESP_MSG := V_RESP_MSG;         
        END IF;

       EXCEPTION               
         WHEN OTHERS THEN
          P_RESP_CDE := '89';
          P_RESP_MSG  := 'Error while calling SP_SPIL_SERIALNUMBER_LOGGING ' || SUBSTR(SQLERRM, 1, 300);                             
    END;
  END IF;
  --END:Added for serial number changes on 29/10/14
  
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
        TRANS_DESC,
         MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_STATE,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
       --Sn added by Pankaj S. for 10871
      customer_acct_no,
      productid,
      cr_dr_flag,
      cardstatus,
      acct_type,
      error_msg,
      time_stamp,
      --En added by Pankaj S. for 10871
      Reversal_Code, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
     STORE_ID,   --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
    --SN Added on 30.07.2013 for 11695
      FEE_PLAN,
      FEECODE,
      TRANFEE_AMT,
      FEEATTACHTYPE,
      merchant_Zip--added for VMS-622 (redemption_delay zip code validation)
    --EN Added on 30.07.2013 for 11695
        )
     VALUES
       (P_MSG_TYP,
        P_RRN,
        P_DELV_CHNL,
        P_TERMINAL_ID,
        V_RVSL_TRANDATE,
        P_TXN_CODE,
        --P_TXN_TYPE,
        V_TXN_TYPE, --Modified by Deepa on June 26 2012 As the value is passed as NULL
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
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')), --modified by Pankaj S. for 10871
        V_CURRCODE,
        NULL,
        v_card_type, --Added by Pankaj S. for 10871
        P_TERMINAL_ID,
        V_AUTH_ID,
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')), --modified by Pankaj S. for 10871
        '0.00',  --Modified by Pankaj S. for 10871
        '0.00',  --Modified by Pankaj S. for 10871
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
        V_TRAN_DESC,
        V_TXN_MERCHNAME, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        V_TXN_MERCHCITY, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        V_TXN_MERCHSTATE, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
         --Sn added by Pankaj S. for 10871
        v_card_acct_no,
        v_prod_code,
         -- v_dr_cr_flag,--Commented and modified on 25.07.2013 for 11693
        decode(v_dr_cr_flag,'CR','DR','DR','CR',v_dr_cr_flag),
        v_cap_card_stat,
        v_acct_type,
        v_errmsg,
        Nvl(V_Timestamp,Systimestamp),
        --En added by Pankaj S. for 10871
        P_Rvsl_Code, -- added by MageshKumar.S for defect Id:FSS-1248 on 21-06-2013
       P_STORE_ID ,--SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
         --SN Added on 30.07.2013 for 11695
         V_FEE_PLAN,
         V_FEE_CODE,
         V_FEE_AMT,
         V_FEEATTACH_TYPE,
         P_Merchant_zip--added for VMS-622 (redemption_delay zip code validation)
         --EN Added on 30.07.2013 for 11695
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
        --P_TXN_TYPE,
        V_TXN_TYPE, --Modified by Deepa on June 26 2012 As the value is passed as NULL
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
    p_resp_msg_m24 := v_errmsg;
END;

/

show error