CREATE OR REPLACE PROCEDURE VMSCMS.SP_TXN_MERCHANDISE_RETURN_SAF (P_INST_CODE         IN NUMBER,
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
                                                P_MERCHANT_CITY     VARCHAR2,
                                                P_MCC_CODE          VARCHAR2,
                                                P_CURR_CODE         VARCHAR2,
                                                P_POS_VERFICATION   VARCHAR2, --Modified by Deepa On June 19th for Fees Changes
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
                                                P_PREAUTH_SEQNO     IN VARCHAR2,
                                                P_RVSL_CODE         IN NUMBER,
                                                P_NETWORK_SETL_DATE   IN VARCHAR2,  -- Added on 231112 for logging N/W settlement date in transactionlog
                                                P_MERCHANT_ID       IN VARCHAR2, --Added on 21.03.2013 for  Merchant Logging Info for the Reversal Txn
                                                P_MERCHANT_ZIP      IN VARCHAR2, --Added on 21.03.2013 for  Merchant Logging Info for the Reversal Txn                                   
                                                P_NETWORKID_SWITCH    IN VARCHAR2, --Added on 20130626 for the Mantis ID 11344
                                                p_international_ind IN VARCHAR2, -- Added for 13061 on 22-Nov-2013 
                                                P_AUTH_ID           OUT VARCHAR2,
                                                P_RESP_CODE         OUT VARCHAR2,
                                                P_RESP_MSG          OUT VARCHAR2,
                                                P_CAPTURE_DATE      OUT DATE) IS
  /*************************************************
    * modified by           :Ganesh S.
    * modified Date        : 23-NOV-12
    * modified reason      : Network Settlement Date Changes - New Requirement
    * Reviewer             : Dhiraj
    * Reviewed Date        : 23-NOV-12
    * Build Number         :  CMS3.5.1_RI0023_B0001

    * Modified By          : Pankaj S.
    * Modified Date        : 09-Feb-2013
    * Modified Reason      : Product Category spend limit not being adhered to by VMS
    * Reviewer             : Dhiraj
    * Reviewed Date        :
    * Build Number         :
    
    * Modified By          : Pankaj S.
    * Modified Date        : 15-Mar-2013
    * Modified Reason      : Logging of system initiated card status change(FSS-390)
    * Reviewer             : Dhiraj
    * Reviewed Date        : 
    * Build Number         : CMS3.5.1_RI0024_B0008
    
    * Modified By          : Sachin P
    * Modified Date        : 21-Mar-2013
    * Modified Reason      : Merchant Logging Info for the Reversal Txn
    * Modified For         : FSS-1077   
    * Reviewer             : Dhiraj 
    * Reviewed Date        : 
    * Build Number         : CMS3.5.1_RI0024_B0008
    
    * Modified by          :  Pankaj S.
    * Modified Reason      :  10871
    * Modified Date        :  19-Apr-2013
    * Reviewer             :  Dhiraj
    * Reviewed Date        :
    * Build Number         :  RI0024.1_B0013
    
   * Modified by           : Deepa T
   * Modified for          : Mantis ID 11344
   * Modified Reason       : Log the Network ID as ELAN             
   * Modified Date         : 26-Jun-2013
   * Reviewer              : Dhiraj
   * Reviewed Date         : 27-06-2013
   * Build Number          : RI0024.2_B0009
   
   * Modified by              :  Pankaj S.
   * Modified Reason       :  Enabling Limit configuration and validation for Preauth(1.7.3.9 changes integrate)
   * Modified Date         :  23-Oct-2013
   * Reviewer              :  Dhiraj
   * Reviewed Date         :  
   * Build Number          : RI0024.5.2_B0001
   
   * Modified by           :  Sagar More
   * Modified for          :  Mantis ID- 13061
   * Modified Reason       :  To pass international indicator in input parameter
   * Modified Date         :  19-Nov-2013
   * Reviewer              :  Sagar
   * Reviewed Date         :  20-Nov-2013
   * Build Number          :  RI0024.6.1_B0002   
   
   * Modified By             : MageshKumar S
   * Modified Date         : 28-Jan-2014
   * Modified for             : MVCSD-4471
   * Modified Reason       : Narration change for FEE amount
   * Reviewer                 : Dhiraj
   * Reviewed Date           : 
   * Build Number           : RI0027.1_B0001 
   
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
     
     * Modified by       : MageshKumar S.
     * Modified Date     : 25-July-14    
     * Modified For      : FWR-48
     * Modified reason   : GL Mapping removal changes
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3.1_B0001
     
     * Modified Date    : 11-Nov2014
     * Modified By      : Dhinakaran B
     * Modified for     : MVHOST-1041
     * Reviewer         :  
     * Release Number   :  
     
         * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
	 * Modified by       : Akhil 
     * Modified Date     : 05-JAN-18
     * Modified For      : VMS-103
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.12
	 
	* Modified By      : Karthick
    * Modified Date    : 08-23-2022
    * Purpose          : Archival changes.
    * Reviewer         : venkat Singamaneni
    * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991
   *************************************************/
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
  V_RESP_CDE           VARCHAR2(3);
  V_EXPRY_DATE         DATE;
  V_DR_CR_FLAG         VARCHAR2(2);
  V_OUTPUT_TYPE        VARCHAR2(2);
  V_APPLPAN_CARDSTAT   CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_ATMONLINE_LIMIT    CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  V_POSONLINE_LIMIT    CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  P_ERR_MSG            VARCHAR2(500);
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
  V_PREAUTH_USAGE_LIMIT NUMBER;
  V_CARD_ACCT_NO        VARCHAR2(20);
  V_HOLD_AMOUNT         NUMBER;
  V_HASH_PAN            CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN            CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_RRN_COUNT           NUMBER;
  V_TRAN_TYPE           VARCHAR2(2);
  V_DATE                DATE;
  V_TIME                VARCHAR2(10);
  V_MAX_CARD_BAL        NUMBER;
  V_CURR_DATE           DATE;
  V_SAF_TXN_COUNT       NUMBER;
  V_PROXUNUMBER         CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER         CMS_APPL_PAN.CAP_ACCT_NO%TYPE;

  --Added by Deepa On June 19 2012 for Fees Changes
  V_FEEAMNT_TYPE  CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
  V_PER_FEES      CMS_FEE_MAST.CFM_PER_FEES%TYPE;
  V_FLAT_FEES     CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_CLAWBACK      CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
  V_FEE_PLAN      CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;
  V_CLAWBACK_AMNT CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_FREETXN_EXCEED VARCHAR2(1); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_DURATION VARCHAR2(20); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_FEEATTACH_TYPE  VARCHAR2(2); -- Added by Trivikram on 5th Sept 2012
  v_chnge_crdstat   VARCHAR2(2):='N';  --Added by Pankaj S. for FSS-390
  --Sn added by Pankaj S. for 10871
  v_acct_type       cms_acct_mast.cam_type_code%TYPE;
  v_timestamp       timestamp(3);
  --En added by Pankaj S. for 10871
    --Sn Added by Pankaj S. for enabling limit validation
   v_prfl_flag             cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_prfl_code             cms_appl_pan.cap_prfl_code%TYPE;
   v_comb_hash             pkg_limits_check.type_hash;
   --En Added by Pankaj S. for enabling limit validation  
   V_FEE_DESC         cms_fee_mast.cfm_fee_desc%TYPE;  -- Added for MVCSD-4471
   v_mrlimitbreach_count  number default 0;
   v_mrminmaxlmt_ignoreflag  VARCHAR2 (1) default 'N';
     l_profile_code   cms_prod_cattype.cpc_profile_code%type;
  
v_badcredit_flag             cms_prod_cattype.cpc_badcredit_flag%TYPE;
   v_badcredit_transgrpid       vms_group_tran_detl.vgd_group_id%TYPE;
     v_cnt number;
         v_card_stat                  cms_appl_pan.cap_card_stat%TYPE   := '12'; 
   v_enable_flag                VARCHAR2 (20)                          := 'Y';
   v_initialload_amt         cms_acct_mast.cam_new_initialload_amt%type;
   
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
   v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN
  SAVEPOINT V_AUTH_SAVEPOINT;
  V_RESP_CDE := '1';
  P_ERR_MSG  := 'OK';
  P_RESP_MSG := 'OK';

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

    --En get date

    --Sn find debit and credit flag
    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,
           ctm_prfl_flag  --Added by Pankaj S. for enabling limit validation
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,
            v_prfl_flag  --Added by Pankaj S. for enabling limit validation
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
       V_ERR_MSG  := 'Error while selecting CMS_TRANSACTION_MAST ' ||
                  P_TXN_CODE || P_DELIVERY_CHANNEL || SQLERRM;
       RAISE EXP_REJECT_RECORD;
    END;

    --En find debit and credit flag

    --Sn Duplicate RRN Check
    BEGIN
	
	--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)                 --Added for VMS-5739/FSP-991
    THEN
	
     SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM TRANSACTIONLOG
      WHERE TERMINAL_ID = P_TERM_ID AND RRN = P_RRN AND
           BUSINESS_DATE = P_TRAN_DATE AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL --Added by ramkumar.Mk on 25 march 2012
           AND CUSTOMER_CARD_NO = V_HASH_PAN ; --ADDED BY ABDUL HAMEED M.A ON 06-03-2014
ELSE

   SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5739/FSP-991
      WHERE TERMINAL_ID = P_TERM_ID AND RRN = P_RRN AND
           BUSINESS_DATE = P_TRAN_DATE AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL --Added by ramkumar.Mk on 25 march 2012
           AND CUSTOMER_CARD_NO = V_HASH_PAN ; --ADDED BY ABDUL HAMEED M.A ON 06-03-2014


END IF;
     IF V_RRN_COUNT > 0 THEN
       V_RESP_CDE := '22';
       V_ERR_MSG  := 'Duplicate RRN from the Terminal ' || P_TERM_ID ||
                  ' on ' || P_TRAN_DATE;
       RAISE EXP_REJECT_RECORD;
     END IF;
    END;

    --En Duplicate RRN Check

    --Sn SAF  txn Check

    IF P_MSG = '9221' THEN

IF (v_Retdate>v_Retperiod)                 --Added for VMS-5739/FSP-991
    THEN 
	
     SELECT COUNT(*)
       INTO V_SAF_TXN_COUNT
       FROM TRANSACTIONLOG
      WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
           CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
           AND INSTCODE = P_INST_CODE AND TERMINAL_ID = P_TERM_ID AND
           RESPONSE_CODE = '00' AND MSGTYPE = '9220';
ELSE

 SELECT COUNT(*)
       INTO V_SAF_TXN_COUNT
       FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5739/FSP-991
      WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
           CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
           AND INSTCODE = P_INST_CODE AND TERMINAL_ID = P_TERM_ID AND
           RESPONSE_CODE = '00' AND MSGTYPE = '9220';

END IF;

     IF V_SAF_TXN_COUNT > 0 THEN

       V_RESP_CDE := '38';
       V_ERR_MSG  := 'Successful SAF Transaction has already done' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

     END IF;

    END IF;

    --En SAF  txn Check

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
           cap_prfl_code  --Added by Pankaj S. for enabling limit validation
       INTO V_PROD_CODE,
           V_PROD_CATTYPE,
           V_EXPRY_DATE,
           V_APPLPAN_CARDSTAT,
           V_ATMONLINE_LIMIT,
           V_ATMONLINE_LIMIT,
           V_PROXUNUMBER,
           V_ACCT_NUMBER,
           v_prfl_code  --Added by Pankaj S. for enabling limit validation
       FROM CMS_APPL_PAN
      WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '14';
       V_ERR_MSG  := 'CARD NOT FOUND ' || V_HASH_PAN;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '12';
       V_ERR_MSG  := 'Problem while selecting card detail' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

	BEGIN
              SELECT cpc_profile_code,cpc_badcredit_flag,cpc_badcredit_transgrpid
              into l_profile_code,v_badcredit_flag,v_badcredit_transgrpid
               FROM cms_prod_cattype
              WHERE cpc_inst_code = p_inst_code
                AND cpc_prod_code = v_prod_code
                AND cpc_card_type = v_prod_cattype;
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Error while selecting from  cms_prod_cattype ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21'; -- Server Declined
       RAISE EXP_REJECT_RECORD;
    END;
    --En find card detail
    --Sn find the tran amt
    IF ((V_TRAN_TYPE = 'F') OR (P_MSG = '0100')) THEN
     IF (P_TXN_AMT >= 0) THEN
       V_TRAN_AMT := nvl(P_TXN_AMT,0); --formatted by Pankaj S. for 10871
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
                     p_international_ind, --NULL, -- NULL commented and p_international_ind is passed for 13061
                     P_POS_VERFICATION,   --NULL, commented and P_POS_VERFICATION is passed for 13061  
                                         P_MCC_CODE, --Added IN Parameters in SP_STATUS_CHECK_GPR for pos sign indicator,international indicator,mcccode by Besky on 08-oct-12
                     V_RESP_CDE,
                     V_ERR_MSG);

     IF ((V_RESP_CDE <> '1' AND V_ERR_MSG <> 'OK') OR
        (V_RESP_CDE <> '0' AND V_ERR_MSG <> 'OK')) THEN
       RAISE EXP_REJECT_RECORD;
     ELSE
       V_RESP_CDE := '1';
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


    --Sn-commented for fwr-48
    --Sn find function code attached to txn code
 /*   BEGIN
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
       V_ERR_MSG  := 'Error while selecting CMS_FUNC_MAST ' || P_TXN_CODE ||
                  SQLERRM;
       RAISE EXP_REJECT_RECORD;
    END;*/

    --En find function code attached to txn code
    --En-commented for fwr-48
    --Sn find prod code and card type and available balance for the card number
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO,
            cam_type_code,nvl(cam_new_initialload_amt,cam_initialload_amt) --added by Pankaj S. for 10871
       INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO,
            v_acct_type,v_initialload_amt --added by Pankaj S. for 10871
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
                 CAP_INST_CODE = P_INST_CODE) AND
           CAM_INST_CODE = P_INST_CODE
           FOR UPDATE;                             -- Added for Concurrent Processsing Issue
           --FOR UPDATE NOWAIT;                    -- Commented for Concurrent Processsing Issue        
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
    
   ------------------------------------------------------
        --Sn Added for Concurrent Processsing Issue
    ------------------------------------------------------ 
        
       BEGIN
	   
	   IF (v_Retdate>v_Retperiod)            --Added for VMS-5739/FSP-991
    THEN
	
         SELECT COUNT(1)
           INTO V_RRN_COUNT
           FROM TRANSACTIONLOG
          WHERE TERMINAL_ID = P_TERM_ID AND RRN = P_RRN AND
               BUSINESS_DATE = P_TRAN_DATE AND
               DELIVERY_CHANNEL = P_DELIVERY_CHANNEL --Added by ramkumar.Mk on 25 march 2012
               AND CUSTOMER_CARD_NO = V_HASH_PAN ; --ADDED BY ABDUL HAMEED M.A ON 06-03-2014
   ELSE
   
   SELECT COUNT(1)
           INTO V_RRN_COUNT
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5739/FSP-991
          WHERE TERMINAL_ID = P_TERM_ID AND RRN = P_RRN AND
               BUSINESS_DATE = P_TRAN_DATE AND
               DELIVERY_CHANNEL = P_DELIVERY_CHANNEL --Added by ramkumar.Mk on 25 march 2012
               AND CUSTOMER_CARD_NO = V_HASH_PAN ; --ADDED BY ABDUL HAMEED M.A ON 06-03-2014
     
   END IF;
         IF V_RRN_COUNT > 0 THEN
           V_RESP_CDE := '22';
           V_ERR_MSG  := 'Duplicate RRN from the Terminal ' || P_TERM_ID ||
                      ' on ' || P_TRAN_DATE;
           RAISE EXP_REJECT_RECORD;
         END IF;
         
        END;

        --En Duplicate RRN Check


        IF P_MSG = '9221' THEN

   IF (v_Retdate>v_Retperiod)            --Added for VMS-5739/FSP-991
    THEN
         SELECT COUNT(*)
           INTO V_SAF_TXN_COUNT
           FROM TRANSACTIONLOG
          WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
               CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
               AND INSTCODE = P_INST_CODE AND TERMINAL_ID = P_TERM_ID AND
               RESPONSE_CODE = '00' AND MSGTYPE = '9220';
  ELSE
  
    SELECT COUNT(*)
           INTO V_SAF_TXN_COUNT
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5739/FSP-991
          WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
               CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
               AND INSTCODE = P_INST_CODE AND TERMINAL_ID = P_TERM_ID AND
               RESPONSE_CODE = '00' AND MSGTYPE = '9220';
   
  END IF;
         IF V_SAF_TXN_COUNT > 0 THEN

           V_RESP_CDE := '38';
           V_ERR_MSG  := 'Successful SAF Transaction has already done' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;

         END IF;

        END IF;    
    
    ------------------------------------------------------
        --En Added for Concurrent Processsing Issue
    ------------------------------------------------------   
    
     --Added for MVHOST-1022
    BEGIN
       IF p_delivery_channel = '02' AND p_txn_code = '25'
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
    --End MVHOST-1022      
    
       --Sn Added by Pankaj S. for enabling limit validation   
    IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y' THEN
    BEGIN
          pkg_limits_check.sp_limits_check (v_hash_pan,
                                            NULL,
                                            NULL,
                                            p_mcc_code,
                                            p_txn_code,
                                            v_tran_type,
                                            NULL,--international_ind
                                            NULL,--pos_verfication
                                            p_inst_code,
                                            NULL,
                                            v_prfl_code,
                                            v_tran_amt,
                                            p_delivery_channel,
                                            v_comb_hash,
                                            v_resp_cde,
                                            v_err_msg
                                            ,v_mrminmaxlmt_ignoreflag
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

    --En Check PreAuth Completion txn
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
                      p_international_ind, --NULL, --Added by Deepa for Fees Changes , NULL commented and p_international_ind passed for 13061
                      P_POS_VERFICATION, --Added by Deepa for Fees Changes
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
                      V_FEE_DESC --Added for MVCSD-4471
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

    -- Check for maximum card balance configured for the product profile.
    BEGIN
      --Sn Added on 09-Feb-2013 for max card balance check based on product category
         SELECT TO_NUMBER (cbp_param_value)
           INTO v_max_card_bal
           FROM cms_bin_param
          WHERE cbp_inst_code = p_inst_code
            AND cbp_param_name = 'Max Card Balance'
            AND cbp_profile_code=l_profile_code;
      --En Added on 09-Feb-2013 for max card balance check based on product category
      --Sn Commented on 09-Feb-2013 for max card balance check based on product category
     /*SELECT TO_NUMBER(CBP_PARAM_VALUE)
       INTO V_MAX_CARD_BAL
       FROM CMS_BIN_PARAM
      WHERE CBP_INST_CODE = P_INST_CODE AND
           CBP_PARAM_NAME = 'Max Card Balance' AND
           CBP_PROFILE_CODE IN
           (SELECT CPM_PROFILE_CODE
             FROM CMS_PROD_MAST
            WHERE CPM_PROD_CODE = V_PROD_CODE);*/
     --En Commented on 09-Feb-2013 for max card balance check based on product category
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
           UPDATE CMS_APPL_PAN
                     SET cap_card_stat = '18'
                   WHERE cap_inst_code = p_inst_code
                     AND cap_pan_code = v_hash_pan;

                  v_chnge_crdstat := 'Y';
               END IF;
            END IF;
         END IF;
         IF v_enable_flag = 'Y'
         THEN
            IF    ((V_UPD_AMT) > v_max_card_bal)
               OR ((V_UPD_LEDGER_AMT) > v_max_card_bal)
            THEN
               v_resp_cde := '30';
               v_err_msg := 'EXCEEDING MAXIMUM CARD BALANCE';
            RAISE EXP_REJECT_RECORD;
           END IF;
         END IF;
    --Sn check balance
--
--    IF (V_UPD_LEDGER_AMT > V_MAX_CARD_BAL) OR (V_UPD_AMT > V_MAX_CARD_BAL) THEN
--     BEGIN
--         IF V_APPLPAN_CARDSTAT<>'12' THEN --added for FSS-390
--        IF v_badcredit_flag = 'Y' THEN
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
--           UPDATE CMS_APPL_PAN
--             SET CAP_CARD_STAT = v_card_stat
--            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
--           IF SQL%ROWCOUNT = 0 THEN
--            V_ERR_MSG  := 'updating the card status is not happened';
--            V_RESP_CDE := '21';
--            RAISE EXP_REJECT_RECORD;
--           END IF;
--           --Sn added for FSS-390
--           v_chnge_crdstat:='Y'; 
--         END IF;
--         --En added for FSS-390   
--     EXCEPTION
--       WHEN EXP_REJECT_RECORD THEN
--        RAISE EXP_REJECT_RECORD;
--       WHEN OTHERS THEN
--        V_ERR_MSG  := 'Error while updating the card status';
--        V_RESP_CDE := '21';
--        RAISE EXP_REJECT_RECORD;
--     END;
--        
--    END IF;

    --En check balance

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
    --Sn Logging of system initiated card status change(FSS-390)
    IF v_chnge_crdstat='Y' THEN
    BEGIN
       sp_log_cardstat_chnge (p_inst_code,
                              v_hash_pan,
                              v_encr_pan,
                              v_auth_id,
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
    --En Logging of system initiated card status change(FSS-390) 
    --Sn find narration
    BEGIN
     SELECT CTM_TRAN_DESC
       INTO V_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;

     IF TRIM(V_TRANS_DESC) IS NOT NULL THEN

       V_NARRATION := V_TRANS_DESC || '/';

     END IF;

     IF TRIM(P_MERCHANT_NAME) IS NOT NULL THEN

       V_NARRATION := V_NARRATION || P_MERCHANT_NAME || '/';

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
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN

       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error in finding the narration ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

    END;

    --En find narration
    
    v_timestamp:=systimestamp;  --added by Pankaj S. for 10871  
      
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
         CSL_PANNO_LAST4DIGIT, --Added by Srinivasu on 15-May-2012 to log Last $ Digit of the card number
         --Sn added by Pankaj S. for 10871
         csl_prod_code,csl_card_type,
         csl_acct_type,
         csl_time_stamp
         --En added by Pankaj S. for 10871
         ) 
       VALUES
        (V_HASH_PAN,
         v_ledger_bal, --V_ACCT_BALANCE  replaced by Pankaj S. with v_ledger_bal for 10871
         V_TRAN_AMT,
         V_DR_CR_FLAG,
         V_TRAN_DATE,
         DECODE(V_DR_CR_FLAG,
               'DR',
               v_ledger_bal - V_TRAN_AMT, --V_ACCT_BALANCE  replaced by Pankaj S. with v_ledger_bal for 10871
               'CR',
               v_ledger_bal + V_TRAN_AMT, --V_ACCT_BALANCE  replaced by Pankaj S. with v_ledger_bal for 10871
               'NA', 
               v_ledger_bal), --V_ACCT_BALANCE  replaced by Pankaj S. with v_ledger_bal for 10871
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
         (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))), --Added by Srinivasu on 15-May-2012 to log Last $ Digit of the card number
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
                  v_ledger_bal - V_TRAN_AMT, --V_ACCT_BALANCE  replaced by Pankaj S. with v_ledger_bal for 10871
                  'CR',
                  v_ledger_bal + V_TRAN_AMT, --V_ACCT_BALANCE  replaced by Pankaj S. with v_ledger_bal for 10871
                  'NA',
                  v_ledger_bal)              --V_ACCT_BALANCE  replaced by Pankaj S. with v_ledger_bal for 10871
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
           CSL_PANNO_LAST4DIGIT, --Added by Trivikram on 23-May-2012 to log Last $ Digit of the card number
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
         --  'Complimentary ' || V_DURATION ||' '|| V_NARRATION, --Commented for MVCSD-4471 -- Modified by Trivikram  on 27-July-2012
           V_FEE_DESC, --Added for MVCSD-4471 
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
           (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),--Added by Trivikram on 23-May-2012 to log Last $ Digit of the card number
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
         (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),
         --Sn added by Pankaj S. for 10871
         v_prod_code,
         v_acct_type,
         v_timestamp
         --En added by Pankaj S. for 10871
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
         'Percentage Fee debited for ' || V_FEE_DESC, -- Added for MVCSD-4471
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
         --Sn added by Pankaj S. for 10871
         v_prod_code,
         v_acct_type,
         v_timestamp
         --En added by Pankaj S. for 10871
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
           CSL_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
           CSL_MERCHANT_CITY,
           CSL_MERCHANT_STATE,
           CSL_PANNO_LAST4DIGIT, --Added by Trivikram on 23-May-2012 to log Last $ Digit of the card number
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
          -- 'Fee debited for ' || V_NARRATION, --Commented for MVCSD-4471
           V_FEE_DESC, --Added for MVCSD-4471
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
           (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))), --Added by Trivikram on 23-May-2012 to log Last $ Digit of the card number
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
         --Sn Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
        CTD_MERCHANT_ZIP,
        CTD_MERCHANT_ID,    
        --En Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
        ctd_internation_ind_response        -- Added for 13061
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
        --Sn Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
        P_MERCHANT_ZIP,
        P_MERCHANT_ID,
        --En Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
        p_international_ind   -- Added for 13061       
        );
     --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from response master ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

    --En create a entry for successful
    ---Sn update daily and weekly transcounter  and amount
    BEGIN

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
    END;

    --En update daily and weekly transaction counter and amount
    --Sn create detail for response message
    IF V_OUTPUT_TYPE = 'B' THEN
     --Balance Inquiry
     P_RESP_MSG := TO_CHAR(V_UPD_AMT);
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

    BEGIN

     ---Sn Updation of Usage limit and amount
     BEGIN
       SELECT CTC_POSUSAGE_AMT, CTC_POSUSAGE_LIMIT, CTC_BUSINESS_DATE
        INTO V_POS_USAGEAMNT, V_POS_USAGELIMIT, V_BUSINESS_DATE_TRAN
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
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;

     BEGIN

       IF P_DELIVERY_CHANNEL = '02' THEN
        IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN

          V_POS_USAGELIMIT := 1;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_POSUSAGE_AMT       = 0,
                 CTC_POSUSAGE_LIMIT     = V_POS_USAGELIMIT,
                 CTC_ATMUSAGE_AMT       = 0,
                 CTC_ATMUSAGE_LIMIT     = 0,
                 CTC_BUSINESS_DATE      = TO_DATE(P_TRAN_DATE ||
                                            '23:59:59',
                                            'yymmdd' ||
                                            'hh24:mi:ss'),
                 CTC_PREAUTHUSAGE_LIMIT = 0,
                 CTC_MMPOSUSAGE_AMT     = 0,
                 CTC_MMPOSUSAGE_LIMIT   = 0
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN AND
                 CTC_MBR_NUMB = P_MBR_NUMB;

            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'updating 1 CMS_TRANSLIMIT_CHECK IS NOT HAPPENED';
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;
          EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 1 CMS_TRANSLIMIT_CHECK ' ||
                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        ELSE
          V_POS_USAGELIMIT := V_POS_USAGELIMIT + 1;
          BEGIN
            UPDATE CMS_TRANSLIMIT_CHECK
              SET CTC_POSUSAGE_LIMIT     = V_POS_USAGELIMIT,
                 CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
            WHERE CTC_INST_CODE = P_INST_CODE AND
                 CTC_PAN_CODE = V_HASH_PAN --P_card_no
                 AND CTC_MBR_NUMB = P_MBR_NUMB;
            IF SQL%ROWCOUNT = 0 THEN
             V_ERR_MSG  := 'updating 2 CMS_TRANSLIMIT_CHECK IS NOT HAPPENED';
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
            END IF;
          EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while updating 2 CMS_TRANSLIMIT_CHECK ' ||
                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
       END IF;

     END;
    END;

    ---En Updation of Usage limit and amount
    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_ERR_MSG  := 'No Data from response master for respose code' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from response master for respose code' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;
    
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
    
  EXCEPTION
    --<< MAIN EXCEPTION >>
    WHEN EXP_REJECT_RECORD THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
        INTO V_ACCT_BALANCE, V_LEDGER_BAL
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
       SELECT CTC_POSUSAGE_LIMIT, CTC_BUSINESS_DATE
        INTO V_POS_USAGELIMIT, V_BUSINESS_DATE_TRAN
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
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;

     IF P_DELIVERY_CHANNEL = '02' THEN
       IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
        V_POS_USAGEAMNT  := 0;
        V_POS_USAGELIMIT := 1;
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
                                          'yymmdd' || 'hh24:mi:ss'),
                CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN AND CTC_MBR_NUMB = P_MBR_NUMB;
          IF SQL%ROWCOUNT = 0 THEN
            V_ERR_MSG  := 'updating 3 CMS_TRANSLIMIT_CHECK IS NOT HAPPENED';
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
          END IF;
        EXCEPTION
          WHEN EXP_REJECT_RECORD THEN
            RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
            V_ERR_MSG  := 'Error while updating 3 CMS_TRANSLIMIT_CHECK ' ||
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
                CTC_PAN_CODE = V_HASH_PAN AND CTC_MBR_NUMB = P_MBR_NUMB;
          IF SQL%ROWCOUNT = 0 THEN
            V_ERR_MSG  := 'updating 4 CMS_TRANSLIMIT_CHECK IS NOT HAPPENED';
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
          END IF;
        EXCEPTION
          WHEN EXP_REJECT_RECORD THEN
            RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
            V_ERR_MSG  := 'Error while updating 4 CMS_TRANSLIMIT_CHECK ' ||
                       V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
        END;
       END IF;
     END IF;

     --Sn select response code and insert record into txn log dtl
     BEGIN
       P_RESP_MSG  := V_ERR_MSG;
       P_RESP_CODE := V_RESP_CDE;

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
         --Sn Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
        CTD_MERCHANT_ZIP,
        CTD_MERCHANT_ID,     
        --En Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
        ctd_internation_ind_response -- Added for 13061         
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
          --Sn Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
        P_MERCHANT_ZIP,
        P_MERCHANT_ID,     
        --En Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
        p_international_ind    -- Added for 13061       
         );

       P_RESP_MSG := V_ERR_MSG;
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Declined
        ROLLBACK;
        RETURN;
     END;
    WHEN OTHERS THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;
     
     --SN : Added during 13061 changes
     
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
        INTO V_ACCT_BALANCE, V_LEDGER_BAL
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
     
     --EN : Added during 13061 changes      

     BEGIN
       SELECT CTC_POSUSAGE_LIMIT, CTC_BUSINESS_DATE
        INTO V_POS_USAGELIMIT, V_BUSINESS_DATE_TRAN
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
        V_ERR_MSG  := 'Error while selecting CMS_TRANSLIMIT_CHECK 1' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
     END;

     IF P_DELIVERY_CHANNEL = '02' THEN
       IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN
        V_POS_USAGEAMNT  := 0;
        V_POS_USAGELIMIT := 1;
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
                                          'yymmdd' || 'hh24:mi:ss'),
                CTC_PREAUTHUSAGE_LIMIT = V_PREAUTH_USAGE_LIMIT
           WHERE CTC_INST_CODE = P_INST_CODE AND
                CTC_PAN_CODE = V_HASH_PAN AND CTC_MBR_NUMB = P_MBR_NUMB;
          IF SQL%ROWCOUNT = 0 THEN
            V_ERR_MSG  := 'updating 5 CMS_TRANSLIMIT_CHECK IS NOT HAPPENED';
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
          END IF;
        EXCEPTION
          WHEN EXP_REJECT_RECORD THEN
            RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
            V_ERR_MSG  := 'Error while updating 5 CMS_TRANSLIMIT_CHECK ' ||
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
                CTC_PAN_CODE = V_HASH_PAN AND CTC_MBR_NUMB = P_MBR_NUMB;
          IF SQL%ROWCOUNT = 0 THEN
            V_ERR_MSG  := 'updating 6 CMS_TRANSLIMIT_CHECK IS NOT HAPPENED';
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
          END IF;
        EXCEPTION
          WHEN EXP_REJECT_RECORD THEN
            RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
            V_ERR_MSG  := 'Error while updating 6 CMS_TRANSLIMIT_CHECK ' ||
                       V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
        END;
       END IF;
     END IF;

     --Sn select response code and insert record into txn log dtl
     BEGIN
       SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = P_INST_CODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESP_CDE;

       P_RESP_MSG := V_ERR_MSG;
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while selecting data from response master ' ||
                    V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Declined
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
         --Sn Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
         CTD_MERCHANT_ZIP,
         CTD_MERCHANT_ID,     
        --En Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
         ctd_internation_ind_response -- Added for 13061          
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
          --Sn Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
         P_MERCHANT_ZIP,
         P_MERCHANT_ID,    
        --En Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
        p_international_ind    -- Added for 13061         
         );
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
  IF V_RESP_CDE = '1' THEN

    V_BUSINESS_TIME := TO_CHAR(V_TRAN_DATE, 'HH24:MI');

    IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
     V_BUSINESS_DATE := TRUNC(V_TRAN_DATE) + 1;
    ELSE
     V_BUSINESS_DATE := TRUNC(V_TRAN_DATE);
    END IF;

    --En find businesses date
    --Sn-commented for fwr-48
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
    --En-commented for fwr-48

    --Sn find prod code and card type and available balance for the card number
    BEGIN
     SELECT CAM_ACCT_BAL,CAM_LEDGER_BAL
       INTO V_ACCT_BALANCE,V_LEDGER_BAL -- V_LEDGER_BAL added during 13061 changes
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
                 CAP_INST_CODE = P_INST_CODE) AND
           CAM_INST_CODE = P_INST_CODE;
        --FOR UPDATE NOWAIT;                                                    -- Commented for Concurrent Processsing Issue
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
     P_RESP_MSG := TO_CHAR(V_UPD_AMT);
    END IF;
  END IF;

  --En create GL ENTRIES
  
  --Sn added by Pankaj S. for 10871
   IF v_dr_cr_flag IS NULL
   THEN
      BEGIN
         SELECT ctm_credit_debit_flag,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type
           INTO v_dr_cr_flag,
                v_txn_type,
                v_tran_type
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
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
         SELECT cap_prod_code, cap_card_type, cap_card_stat,
                cap_acct_no
           INTO v_prod_code, v_prod_cattype, v_applpan_cardstat,
                v_acct_number
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
      CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
      FEE_PLAN,
      FEEATTACHTYPE, -- Added by Trivikram on 05-Sep-2012
        MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_STATE,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      NETWORK_SETTL_DATE,  -- Added on 201112 for logging N/W settlement date in transactionlog
      --Sn Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
      MERCHANT_ZIP,
      MERCHANT_ID,--En Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
      --Sn added by Pankaj S. for 10871
      error_msg,
      acct_type,
      time_stamp,
      --En added by Pankaj S. for 10871
      NETWORKID_SWITCH,   --Added on 20130626 for the Mantis ID 11344
      internation_ind_response, -- Added for 13061
      pos_verification 
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
      DECODE(P_RESP_CODE, '00', 'C', 'F'),
      P_RESP_CODE,
      P_TRAN_DATE,
      SUBSTR(P_TRAN_TIME, 1, 10),
      V_HASH_PAN,
      NULL,
      NULL, --P_topup_acctno    ,
      NULL, --P_topup_accttype,
      P_BANK_CODE,
      TRIM(TO_CHAR(nvl(V_TOTAL_AMT,0), '999999999999999990.99')), --modified for 10871
      NULL,
      NULL,
      P_MCC_CODE,
      P_CURR_CODE,
      NULL, -- P_add_charge,
      V_PROD_CODE,
      V_PROD_CATTYPE,
      trim(to_char(nvl(P_TIP_AMT,0),'999999999999999990.99')), --formatted for 10871
      P_DECLINE_RULEID,
      P_ATMNAME_LOC,
      V_AUTH_ID,
      V_TRANS_DESC,
      TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')),  --modified for 10871
      '0.00', --modified by Pankaj S. for 10871
      '0.00', --modified by Pankaj S. for 10871 -- Partial amount (will be given for partial txn)
      P_MCCCODE_GROUPID,
      P_CURRCODE_GROUPID,
      P_TRANSCODE_GROUPID,
      P_RULES,
      P_PREAUTH_DATE,
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
      V_PROXUNUMBER,
      P_RVSL_CODE,
      V_ACCT_NUMBER,
      V_ACCT_BALANCE,--V_UPD_AMT,    Changed for defect 13061   
      V_LEDGER_BAL,--V_UPD_LEDGER_AMT, Changed for defect 13061
      V_RESP_CDE,
      V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
      V_FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
      V_FEEATTACH_TYPE, -- Added by Trivikram on 05-Sep-2012
       P_MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      P_MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      P_ATMNAME_LOC, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      P_NETWORK_SETL_DATE , -- Added on 201112 for logging N/W settlement date in transactionlog
      --Sn Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
      P_MERCHANT_ZIP,
      P_MERCHANT_ID,--En Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn
      --Sn added by Pankaj S. for 10871
      v_err_msg,
      v_acct_type,
      nvl(v_timestamp,systimestamp),
      --En added by Pankaj S. for 10871
      P_NETWORKID_SWITCH,  --Added on 20130626 for the Mantis ID 11344
      p_international_ind,    -- Added for 13061
      P_POS_VERFICATION       -- Added for 13061
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
  --En create a entry in txn log
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    P_RESP_CODE := '69'; -- Server Declined
    P_RESP_MSG  := 'Main exception from  authorization ' ||
                SUBSTR(SQLERRM, 1, 300);
END;

/

show error