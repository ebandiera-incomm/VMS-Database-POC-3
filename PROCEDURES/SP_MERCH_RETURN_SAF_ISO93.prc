CREATE OR REPLACE PROCEDURE VMSCMS.SP_MERCH_RETURN_SAF_ISO93 (P_INST_CODE         IN NUMBER,
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
                                             P_PREAUTH_SEQNO     IN VARCHAR2,
                                             P_RVSL_CODE         IN NUMBER,
                                             P_POS_VERFICATION   IN VARCHAR2, --Added by Deepa
                                             P_INTERNATIONAL_IND IN VARCHAR2,
                                             P_NETWORKID_SWITCH    IN VARCHAR2, --Added on 20130626 for the Mantis ID 11344
                                             P_NETWORKID_ACQUIRER    IN VARCHAR2,-- Added on 20130626 for the Mantis ID 11344
                                             p_network_setl_date    IN  VARCHAR2, --Added on 20130626 for the Mantis ID 11123
                                             p_merchant_zip         IN       VARCHAR2,  --Added by Pankaj S. for Mantis ID 11540
                                             P_CVV_VERIFICATIONTYPE IN  VARCHAR2, --Added on 17.07.2013 for the Mantis ID 11611
                                             P_PULSE_TRANSACTIONID        IN       VARCHAR2,--Added for MVHOST 926
                                             P_VISA_TRANSACTIONID          IN       VARCHAR2,--Added for MVHOST 926
                                             P_MC_TRACEID                 IN       VARCHAR2,--Added for MVHOST 926
                                             P_CARDVERIFICATION_RESULT      IN       VARCHAR2,--Added for MVHOST 926
                                             P_ADDRVERIFY_FLAG    IN VARCHAR2,
                                             P_ZIP_CODE           IN VARCHAR2,
                                               p_req_resp_code IN NUMBER,--Added for 15197
                                             P_AUTH_ID           OUT VARCHAR2,
                                             P_RESP_CODE         OUT VARCHAR2,
                                             P_RESP_MSG          OUT VARCHAR2,
                                             P_LEDGER_BAL        OUT VARCHAR2,    -- OLS changes(Mantis ID-11088)
                                             P_CAPTURE_DATE      OUT DATE,
                                             P_ISO_RESPCDE        OUT VARCHAR2  --Added on 17.07.2013 for the Mantis ID 11612
                                             ,P_ADDR_VERFY_RESPONSE  out VARCHAR2-- added for MVHOST-926
                                             ,P_MERCHANT_ID IN       VARCHAR2       DEFAULT NULL
                                             ,P_MERCHANT_CNTRYCODE IN       VARCHAR2 DEFAULT NULL
					      ,P_cust_addr      IN VARCHAR2   DEFAULT NULL
                          ,p_surchrg_ind   IN VARCHAR2 DEFAULT '2' --Added for VMS-5856          
                          ,p_resp_id       OUT VARCHAR2 --Added for sending to FSS (VMS-8018)
						  ) IS
  /*************************************************
      * Modified By     :  Trivikram
      * Modified Date   :  14-NOV-12
      * Modified Reason : Modified msgtype 9220 and 9221 with 1220 and 1221
      * Reviewer        : B.Besky Anand
      * Reviewed Date   : 14-NOV-12
      * Build Number    :  CMS3.5.1_RI0021_B0008
      * Modified by     : Sagar M.
      * Modified Date   : 09-Feb-13
      * Modified reason : Product Category spend limit not being adhered to by VMS
      * Modified for    : NA
      * Reviewer        : Dhiarj
      * Build Number    : CMS3.5.1_RI0023.2_B0001

      * Modified By      : Pankaj S.
      * Modified Date    : 15-Mar-2013
      * Modified Reason  : Logging of system initiated card status change(FSS-390)
      * Reviewer         : Dhiraj
      * Reviewed Date    :
      * Build Number     : CMS3.5.1_RI0024_B0008

      * Modified By      : Sagar M.
      * Modified Date    : 20-Apr-2013
      * Modified Reason  : Logging of below details in tranasctionlog and statementlog table
                          1) ledger balance in statementlog
                          2) Product code,Product category code,Card status,Acct Type,drcr flag
                          3) Timestamp and Amount values logging correction
      * Reviewer         : Dhiraj
      * Reviewed Date    : 20-Apr-2013
      * Build Number     : RI0024.1_B0010

      * Modified By       : SaiPrasad.K.S
      * Modified Date     : 11-May-2013
      * Modified Reason   : OLS changes
      * Reviewer          : Dhiraj
      * Reviewed Date     : 16-May-2013
      * Build Number      : RI0024.1.1_B0001

      * Modified By       : Pankaj S.
      * Modified Date     : 21-May-2013
      * Modified Reason   : OLS changes(Mantis ID -11088)
      * Reviewer          : Dhiraj
      * Reviewed Date     :
      * Build Number      : RI0024.1.1_B0001

       * Modified by      : Deepa T
       * Modified for     : Mantis ID 11344,11123
       * Modified Reason  : Log the AcquirerNetworkID received in tag 005 and TermFIID received in tag 020 ,
                            Logging of network settlement date for OLS transactions
       * Modified Date    : 26-Jun-2013
       * Reviewer         :
       * Reviewed Date    :
       * Build Number     : RI0024.2_B0009

       * Modified by      : Pankaj S.
       * Modified for     : Mantis ID 0011540
       * Modified Reason  : Merchant related information (like name, city & state) logging
       * Modified Date    : 10_July_2013
       * Reviewer         : Dhiraj
       * Reviewed Date    :
       * Build Number     : RI0024.3_B0003

       * Modified by      : Sachin P.
       * Modified for     : Mantis ID -11611,11612
       * Modified Reason  : 11611-Input parameters needs to be included for the CVV verification
                             We are doing and it needs to be logged in transactionlog
                            11612-Output parameter needs to be included to return the cms_iso_respcde of cms_response_mast
       * Modified Date    : 17-Jul-2013
       * Reviewer         :
       * Reviewed Date    :
       * Build Number     : RI0024.3_B0005

      * Modified by      : Sagar M.
      * Modified for     : MVHOST-500
      * Modified Reason  : To check message type in case of Duplicate RRN check
                           and reject if same RRN repeats with 1220,1221
      * Modified Date    : 26-Jun-2013
      * Reviewer         : Dhiarj
      * Reviewed Date    : 01-Aug-2013
      * Build Number     : RI0024.3.1_B0001

      * Modified by      : Sagar M.
      * Modified for     : 0012198
      * Modified Reason  : To reject duplicate STAN transaction
      * Modified Date    : 29-Aug-2013
      * Reviewer         : Dhiarj
      * Reviewed Date    : 29-Aug-2013
      * Build Number     : RI0024.3.5_B0001

      * Modified by       :  Pankaj S.
      * Modified Reason   :  Enabling Limit configuration and validation for Preauth(1.7.3.9 changes integrate)
      * Modified Date     :  23-Oct-2013
      * Reviewer          :  Dhiraj
      * Reviewed Date     :
      * Build Number      : RI0024.5.2_B0001

      * Modified by       : Pankaj S.
      * Modified for      : Mantis ID 13024
      * Modified Reason   : To log international ind in txnlog table
      * Modified Date     : 18_Nov_2013
      * Reviewer          : Dhiraj
      * Reviewed Date     : 18_Nov_2013
      * Build Number      : RI0024.3.11_B0004

      * Modified By      : MageshKumar S
      * Modified Date    : 28-Jan-2014
      * Modified for     : MVCSD-4471
      * Modified Reason  : Narration change for FEE amount
      * Reviewer         : Dhiraj
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

     * Modified by       : Dhinakaran B
     * Modified for      : VISA Certtification Changes integration in 2.2.2
     * Modified Date     : 01-JUL-2014
     * Build Number      :  RI0027.2.2_B0001

     * Modified By      :  Mageshkumar S
     * Modified For     :  FWR-48
     * Modified Date    :  25-July-2014
     * Modified Reason  :  GL Mapping Removal changes.
     * Reviewer         :  Spankaj
     * Build Number     :  RI0027.3.1_B0001

     * Modified Date    : 29-SEP-2014
       * Modified By      : Abdul Hameed M.A
       * Modified for     : FWR 70
       * Reviewer        : spankaj
       * Release Number   : RI0027.4_B0002

     * Modified Date    : 11-Nov2014
     * Modified By      : Dhinakaran B
     * Modified for     : MVHOST-1041
     * Reviewer         : Spankaj
     * Release Number   : RI0027.4.2.1

     * Modified Date    : 30-DEC-2014
     * Modified By      : Dhinakaran B
     * Modified for     : MVHOST-1080/To Log the Merchant id & CountryCode
     * Reviewer         :
     * Reviewed Date    :
     * Release Number   :

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

      * Modified By      :  Abdul Hameed M.A
     * Modified For     :  OLS AVS CHANGES
     * Modified Date    :  23-Apr-2015
     * Reviewer         :  Spankaj
     * Build Number     :  RI0027.5.2_B0001

	 * Modified by      : Narayanaswamy.T
     * Modified for     : FSS-4119 - ATM withdrawal transactions should contain terminal id and city in the statement
     * Modified Date    : 01-Mar-2016
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOST_4.0_B0001
     
         * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
	
	* Modified By      : Vini Pushkaran
    * Modified Date    : 25/10/2017
    * Purpose          : FSS-5303
    * Reviewer         : Saravanan. 
    * Release Number   : VMSGPRHOST17.10_B0004 
	
	 * Modified by       : Akhil 
     * Modified Date     : 05-JAN-18
     * Modified For      : VMS-103
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.12

     * Modified by       : Vini
     * Modified Date     : 10-Jan-2018
     * Modified For      : VMS-162
     * Reviewer          : Saravanankumar
     * Build Number      : VMSGPRHOSTCSD_17.12.1
	   
	 * Modified by       : Vini
     * Modified Date     : 18-Jan-2018
     * Modified For      : VMS-162
     * Reviewer          : Saravanankumar
     * Build Number      : VMSGPRHOSTCSD_18.01
	 
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
     
     * Modified By      : MAGESHKUMAR
     * Modified Date    : 19-JUNE-2020
     * Purpose          : VMS-2709(Internal Issue Identified,For declined cases logging updated amount in acct and ledger balance columns)
     * Reviewer         : SARAVANAKUMAR A
     * Release Number   : R32_build_2
	 
	   * Modified By      : Karthick/Jey
       * Modified Date    : 05-17-2022
       * Purpose          : Archival changes.
       * Reviewer         : Venkat Singamaneni
       * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991

	   * Modified By      : Areshka A.
       * Modified Date    : 03-Nov-2023
       * Purpose          : VMS-8018: Added new out parameter (response id) for sending to FSS
       * Reviewer         : 
       * Release Number   : 

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
  V_FEEAMNT_TYPE CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
  V_PER_FEES     CMS_FEE_MAST.CFM_PER_FEES%TYPE;
  V_FLAT_FEES    CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_CLAWBACK     CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
  V_FEE_PLAN     CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;
  V_FREETXN_EXCEED VARCHAR2(1); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_DURATION VARCHAR2(20); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_FEEATTACH_TYPE  VARCHAR2(2); -- Added by Trivikram on 5th Sept 2012
  v_chnge_crdstat   VARCHAR2(2):='N';  --Added by Pankaj S. for FSS-390
  V_CAM_TYPE_CODE   cms_acct_mast.cam_type_code%type; -- Added on 17-Apr-2013 for defect 10871
  v_timestamp       timestamp;                         -- Added on 17-Apr-2013 for defect 10871
  V_CMS_ISO_RESPCDE             CMS_RESPONSE_MAST.CMS_ISO_RESPCDE%TYPE; -- Added for OLS changes
  V_STAN_COUNT                  NUMBER; -- Added for Duplicate Stan check 0012198

  --Sn Added by Pankaj S. for enabling limit validation
   v_prfl_flag             cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_prfl_code             cms_appl_pan.cap_prfl_code%TYPE;
   v_comb_hash             pkg_limits_check.type_hash;
   --En Added by Pankaj S. for enabling limit validation
   V_FEE_DESC         cms_fee_mast.cfm_fee_desc%TYPE;  -- Added for MVCSD-4471

    V_CAP_CUST_CODE    CMS_APPL_PAN.CAP_CUST_CODE%TYPE;
  v_txn_nonnumeric_chk    VARCHAR2 (2);
  v_cust_nonnumeric_chk   VARCHAR2 (2);
  V_ADDRVRIFY_FLAG        CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_CHECK%TYPE;
  V_ENCRYPT_ENABLE        CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
  V_ADDRVERIFY_RESP       CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_RESPONSE%TYPE;
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

  V_ADDR_ONE CMS_ADDR_MAST.CAM_ADD_ONE%type;
  V_ADDR_TWO CMS_ADDR_MAST.CAM_ADD_TWO%type;
  V_REMOVESPACE_ADDRCUST     VARCHAR2(100);
  V_REMOVESPACE_ADDRTXN      VARCHAR2(20);
  V_REMOVESPACECHAR_ADDRCUST VARCHAR2(100);
  V_REMOVESPACECHAR_ADDRTXN  VARCHAR2(20);
  V_ADDR_VERFY               number;
  V_REMOVESPACECHAR_ADDRONECUST   VARCHAR2(100);
   v_badcredit_flag             cms_prod_cattype.cpc_badcredit_flag%TYPE;
   v_badcredit_transgrpid       vms_group_tran_detl.vgd_group_id%TYPE;
   v_cnt                        NUMBER(2); 
   v_card_stat                  cms_appl_pan.cap_card_stat%TYPE   := '12'; 
   l_profile_code   cms_prod_cattype.cpc_profile_code%type;
    --  v_enable_flag                VARCHAR2 (20)                          := 'Y'; --Code commented for VMS-2709
   v_initialload_amt         cms_acct_mast.cam_new_initialload_amt%type;
   
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
   v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN
  SAVEPOINT V_AUTH_SAVEPOINT;
  V_RESP_CDE := '1';
  -- P_ERR_MSG  := 'OK';
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
     -- SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;

     --  SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
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
            ,ctm_tran_desc --Added for 15197
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,
             v_prfl_flag  --Added by Pankaj S. for enabling limit validation
             ,V_TRANS_DESC --Added for 15197
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

    --sn  Added for 15197
     IF p_req_resp_code >= 100
      THEN
         V_TRAN_AMT := P_TXN_AMT;
     v_resp_cde := '1';
         v_err_msg := 'Decline Notification transaction';
         RAISE exp_reject_record;
      END IF;
      --En --Added for 15197

    /*  Commented For MVHOST-1041
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



    --Sn Duplicate RRN Check
    BEGIN
     SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM TRANSACTIONLOG
      WHERE TERMINAL_ID = P_TERM_ID AND RRN = P_RRN AND
           BUSINESS_DATE = P_TRAN_DATE AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL --Added by ramkumar.Mk on 25 march 2012
           AND MSGTYPE IN ('1200','1201','1220','1221') --Added for MVHOST-500
           AND TXN_CODE =   P_TXN_CODE  --Added for MVHOST-500 on 02.08.2013
           AND CUSTOMER_CARD_NO = V_HASH_PAN ; --ADDED BY ABDUL HAMEED M.A ON 06-03-2014

     IF V_RRN_COUNT > 0 THEN
       V_RESP_CDE := '22';
       V_ERR_MSG  := 'Duplicate RRN from the Terminal ' || P_TERM_ID ||
                  ' on ' || P_TRAN_DATE;
       RAISE EXP_REJECT_RECORD;
     END IF;
    END;

    --En Duplicate RRN Check
    */
    --Sn SAF  txn Check

    IF P_MSG = '1221' THEN     -- Modified msgtype 9220 and 9221 with 1220 and 1221  by Trivikram on 14/Nov/2012 ,
     
	 
	 --Added for VMS-5739/FSP-991
     select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');
	
 
    IF (v_Retdate>v_Retperiod) THEN	                                                       --Added for VMS-5739/FSP-991
	
     SELECT COUNT(*)
       INTO V_SAF_TXN_COUNT
       FROM TRANSACTIONLOG
      WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
           CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
         --  AND INSTCODE = P_INST_CODE --For Instcode removal of 2.4.2.4.2 release
           AND TERMINAL_ID = P_TERM_ID AND
           RESPONSE_CODE = '00' AND MSGTYPE = '1220';
		   
    ELSE
	
	   SELECT COUNT(*)
       INTO V_SAF_TXN_COUNT
       FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                         --Added for VMS-5739/FSP-991
       WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
           CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
         --  AND INSTCODE = P_INST_CODE --For Instcode removal of 2.4.2.4.2 release
           AND TERMINAL_ID = P_TERM_ID AND
           RESPONSE_CODE = '00' AND MSGTYPE = '1220';
	
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
           ,CAP_CUST_CODE
       INTO V_PROD_CODE,
           V_PROD_CATTYPE,
           V_EXPRY_DATE,
           V_APPLPAN_CARDSTAT,
           V_ATMONLINE_LIMIT,
           V_ATMONLINE_LIMIT,
           V_PROXUNUMBER,
           V_ACCT_NUMBER,
           v_prfl_code  --Added by Pankaj S. for enabling limit validation
           ,V_CAP_CUST_CODE
       FROM CMS_APPL_PAN
      WHERE CAP_PAN_CODE = V_HASH_PAN;
      --AND CAP_INST_CODE = P_INST_CODE; --For Instcode removal of 2.4.2.4.2 release
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

    --En find card detail
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

      BEGIN

     SELECT  CPC_ADDR_VERIFICATION_CHECK,
             cpc_badcredit_flag,
             cpc_badcredit_transgrpid,
	     cpc_profile_code, 
	     CPC_ENCRYPT_ENABLE,
	     NVL(CPC_ADDR_VERIFICATION_RESPONSE, 'U')
       INTO  V_ADDRVRIFY_FLAG,
             v_badcredit_flag,
             v_badcredit_transgrpid,
	     l_profile_code, 
	     V_ENCRYPT_ENABLE,
	     V_ADDRVERIFY_RESP
       FROM CMS_PROD_CATTYPE
      WHERE CPC_INST_CODE = P_INST_CODE AND
	        CPC_PROD_CODE = V_PROD_CODE AND
            CPC_CARD_TYPE = V_PROD_CATTYPE;

    EXCEPTION
     WHEN NO_DATA_FOUND THEN

       V_ADDRVRIFY_FLAG    := 'Y';

     WHEN OTHERS THEN

       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting BIN level Configuration' || SUBSTR(SQLERRM,1,200);
       RAISE EXP_REJECT_RECORD;

    END;
        v_zip_code_trimmed:=TRIM(P_ZIP_CODE); --Added for 15165

   --St: Added for OLS  changes( AVS & ZIP validation changes) on 11/05/2013
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
            trim(decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_add_one),cam_add_one)),
            trim(decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(cam_add_two),cam_add_two))
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
              --   IF SUBSTR (p_zip_code, 1, 5) = SUBSTR (v_zip_code, 1, 5) then -- Added on 20/12/13 for FSS-1388
                --Modified for 15165

                  IF SUBSTR (v_zip_code_trimmed, 1, 5) = SUBSTR (v_zip_code, 1, 5) then

                      P_ADDR_VERFY_RESPONSE := 'W';
                 else
                      P_ADDR_VERFY_RESPONSE := 'N';
                 end if;

        elsif v_txn_nonnumeric_chk <> '0' and v_cust_nonnumeric_chk = '0' then -- It Means txn zip code is aplhanumeric and cust zip code is numeric

            --    if  p_zip_code = v_zip_code then
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

                  --    if  p_zip_code = v_zip_code then
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
                        THEN

                         select REGEXP_REPLACE (p_zip_code, '([0-9 ])', '')
                          INTO v_removespacenum_txn
                          FROM DUAL;

                        select REGEXP_REPLACE (V_ZIP_CODE, '([0-9 ])', '')
                          into V_REMOVESPACENUM_CUST
                          FROM DUAL;

                           select REGEXP_REPLACE (p_zip_code, '([a-zA-Z ])', '')
                          INTO v_removespacechar_txn
                          FROM DUAL;

                        select REGEXP_REPLACE (V_ZIP_CODE, '([a-zA-Z ])', '')
                          into V_REMOVESPACECHAR_CUST
                          FROM DUAL;

                            IF SUBSTR (v_removespacenum_txn, 1, 3) =
                                    SUBSTR (V_REMOVESPACENUM_CUST, 1, 3)
                            then
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

         IF P_ADDRVERIFY_FLAG in('2','3') THEN

           P_ADDR_VERFY_RESPONSE := V_ADDRVERIFY_RESP;

         ELSE

           P_ADDR_VERFY_RESPONSE := 'NA';

         END IF;

        END IF;

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

     if (UPPER (TRIM(p_networkid_switch)) = 'BANKNET' and P_ADDR_VERFY_RESPONSE = 'Y') then
          P_ADDR_VERFY_RESPONSE := 'Z';
      end if;
      end if;
    /*BEGIN
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
                     P_POS_VERFICATION,
                     P_MCC_CODE,
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
    END;*/


    --SN -- Commented for FWR-48
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
       V_ERR_MSG  := 'Error while selecting CMS_FUNC_MAST ' || P_TXN_CODE ||
                  SQLERRM;
       RAISE EXP_REJECT_RECORD;
    END; */

    --En find function code attached to txn code

     --EN -- Commented for FWR-48

    --Sn find prod code and card type and available balance for the card number
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO,
            CAM_TYPE_CODE,nvl(cam_new_initialload_amt,cam_initialload_amt)                                  --Added for defct 10871
       INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO,
            V_CAM_TYPE_CODE,v_initialload_amt                                --Added for defct 10871
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO = V_ACCT_NUMBER
          /* (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
                 CAP_INST_CODE = P_INST_CODE)*/ --For Instcode removal of 2.4.2.4.2 release
         AND  CAM_INST_CODE = P_INST_CODE
           FOR UPDATE;                           -- Added for Concurrent Processsing Issue
        --FOR UPDATE NOWAIT;                     -- Commented for Concurrent Processsing Issue

    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '14'; --Ineligible Transaction
       V_ERR_MSG  := 'Invalid Card ';
       RAISE EXP_REJECT_RECORD ;
	   WHEN OTHERS THEN
       V_RESP_CDE := '12';
    
       V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                  SQLERRM;
       RAISE EXP_REJECT_RECORD;
    END;

    --En find prod code and card type for the card number

      /*Commented For MVHOST-1041

    ------------------------------------------------------
        --Sn Added for Concurrent Processsing Issue
    ------------------------------------------------------

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

      --Sn Duplicate RRN Check
        BEGIN
         SELECT COUNT(1)
           INTO V_RRN_COUNT
           FROM TRANSACTIONLOG
          WHERE TERMINAL_ID = P_TERM_ID AND RRN = P_RRN AND
               BUSINESS_DATE = P_TRAN_DATE AND
               DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
               AND MSGTYPE IN ('1200','1201','1220','1221')
               AND TXN_CODE =   P_TXN_CODE
               AND CUSTOMER_CARD_NO = V_HASH_PAN ; --ADDED BY ABDUL HAMEED M.A ON 06-03-2014

         IF V_RRN_COUNT > 0 THEN
           V_RESP_CDE := '22';
           V_ERR_MSG  := 'Duplicate RRN from the Terminal ' || P_TERM_ID ||
                      ' on ' || P_TRAN_DATE;
           RAISE EXP_REJECT_RECORD;
         END IF;
        END;

        --En Duplicate RRN Check
        */

        IF P_MSG = '1221' THEN

        
	   IF (v_Retdate>v_Retperiod) THEN	                                                       --Added for VMS-5739/FSP-991
	   
         SELECT COUNT(*)
           INTO V_SAF_TXN_COUNT
           FROM TRANSACTIONLOG
          WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
               CUSTOMER_CARD_NO = V_HASH_PAN
              -- AND INSTCODE = P_INST_CODE --For Instcode removal of 2.4.2.4.2 release
               AND TERMINAL_ID = P_TERM_ID AND
               RESPONSE_CODE = '00' AND MSGTYPE = '1220';
			   
		ELSE
		
		   SELECT COUNT(*)
           INTO V_SAF_TXN_COUNT
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                        --Added for VMS-5739/FSP-991
          WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
               CUSTOMER_CARD_NO = V_HASH_PAN
              -- AND INSTCODE = P_INST_CODE --For Instcode removal of 2.4.2.4.2 release
               AND TERMINAL_ID = P_TERM_ID AND
               RESPONSE_CODE = '00' AND MSGTYPE = '1220';
			   
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
    begin
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
    --End MVHOST-1022

   

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
                      P_INTERNATIONAL_IND, --Added by Deepa for Fees Changes
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
                      V_FEE_DESC, --Added for MVCSD-4471
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


         SELECT TO_NUMBER(CBP_PARAM_VALUE)          -- Added on 09-Feb-2013 for max card balance check based on product category
         INTO V_MAX_CARD_BAL
         FROM CMS_BIN_PARAM
         WHERE CBP_INST_CODE = P_INST_CODE AND
                CBP_PARAM_NAME = 'Max Card Balance' AND
                CBP_PROFILE_CODE = l_profile_code;

        /*
         SELECT TO_NUMBER(CBP_PARAM_VALUE)          -- Commented on 09-Feb-2013 for max card balance check based on product category
           INTO V_MAX_CARD_BAL
           FROM CMS_BIN_PARAM
          WHERE CBP_INST_CODE = P_INST_CODE AND
               CBP_PARAM_NAME = 'Max Card Balance' AND
               CBP_PROFILE_CODE IN
                                (
                                 SELECT CPM_PROFILE_CODE
                                 FROM CMS_PROD_MAST
                                 WHERE CPM_PROD_CODE = V_PROD_CODE
                                );
                               */

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
             execute immediate 'SELECT  count(*) 
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
            into v_cnt;
            IF v_cnt = 1
            THEN
             --  v_enable_flag := 'N'; --Code commented for VMS-2709
               IF    ((V_UPD_AMT) > v_initialload_amt
                     )                                     --initialloadamount
                  OR ((V_UPD_LEDGER_AMT) > v_initialload_amt
                     )
               THEN                                        --initialloadamount
           UPDATE CMS_APPL_PAN
                     SET cap_card_stat = '18'
                   WHERE cap_inst_code = p_inst_code
                     AND cap_pan_code = v_hash_pan;
                  --Sn Logging of system initiated card status change(FSS-390)
   
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
    
    --En Logging of system initiated card status change(FSS-390)
               END IF;
            END IF;
         END IF;
        /* IF v_enable_flag = 'Y' --Code commented for VMS-2709
         THEN
            IF    ((V_UPD_AMT) > v_max_card_bal)
               OR ((V_UPD_LEDGER_AMT) > v_max_card_bal)
            THEN
               v_resp_cde := '30';
               v_err_msg := 'EXCEEDING MAXIMUM CARD BALANCE';
            RAISE EXP_REJECT_RECORD;
           END IF;
        END IF;*/
    --Sn check balance
--    IF (V_UPD_LEDGER_AMT > V_MAX_CARD_BAL) OR (V_UPD_AMT > V_MAX_CARD_BAL) THEN
--     BEGIN
--         IF V_APPLPAN_CARDSTAT<>'12' THEN --added for FSS-390
--         IF v_badcredit_flag = 'Y' THEN
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
--        END IF;
--        --En added for FSS-390
--     EXCEPTION
--       WHEN EXP_REJECT_RECORD THEN
--        RAISE EXP_REJECT_RECORD;
--       WHEN OTHERS THEN
--        V_ERR_MSG  := 'Error while updating the card status';
--        V_RESP_CDE := '21';
--        RAISE EXP_REJECT_RECORD;
--     END;
--    END IF;

    --En check balance
    
    
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
    /* SELECT CTM_TRAN_DESC
       INTO V_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;*/ --Unwanted Code commented for VMS-2709

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
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN

       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error in finding the narration ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

    END;
    --En find narration

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
         CSL_PANNO_LAST4DIGIT,  --Added by Srinivasu on 15-May-2012 to log Last $ Digit of the card number
         CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
         CSL_TIME_STAMP,        -- Added on 17-Apr-2013 for defect 10871
         CSL_PROD_CODE,          -- Added on 17-Apr-2013 for defect 10871
         csl_card_type
         )
       VALUES
        (V_HASH_PAN,
         V_LEDGER_BAL,      -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871
         V_TRAN_AMT,
         V_DR_CR_FLAG,
         V_TRAN_DATE,
         DECODE(V_DR_CR_FLAG,
               'DR',
               V_LEDGER_BAL - V_TRAN_AMT,   -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871
               'CR',
               V_LEDGER_BAL + V_TRAN_AMT,   -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871
               'NA',
               V_LEDGER_BAL),               -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871
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
         V_CAM_TYPE_CODE,   -- Added on 17-Apr-2013 for defect 10871
         v_timestamp,       -- Added on 17-Apr-2013 for defect 10871
         v_prod_code,        -- Added on 17-Apr-2013 for defect 10871
         V_PROD_CATTYPE
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
                  V_LEDGER_BAL - V_TRAN_AMT,    -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871
                  'CR',
                  V_LEDGER_BAL + V_TRAN_AMT,    -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871
                  'NA',
                  V_LEDGER_BAL)                 -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871
        INTO V_FEE_OPENING_BAL
        FROM DUAL;
     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '12';
        V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                    P_CARD_NO;
        RAISE EXP_REJECT_RECORD;
     END;

     --En find fee opening balance
     --Sn create entries for FEES attached
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
           CSL_PANNO_LAST4DIGIT,  --Added by Trivikram on 23-May-2012 to log Last $ Digit of the card number
           CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
           CSL_TIME_STAMP,        -- Added on 17-Apr-2013 for defect 10871
           CSL_PROD_CODE          -- Added on 17-Apr-2013 for defect 10871
           )
        VALUES
          (V_HASH_PAN,
           V_FEE_OPENING_BAL,
           V_TOTAL_FEE,
           'DR',
           V_TRAN_DATE,
           V_FEE_OPENING_BAL - V_TOTAL_FEE,
          -- 'Complimentary ' || V_DURATION ||' '|| V_NARRATION, --Commented for MVCSD-4471 -- Modified by Trivikram  on 27-July-2012
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
           (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),    --Added by Trivikram on 23-May-2012 to log Last $ Digit of the card number
           V_CAM_TYPE_CODE,   -- Added on 17-Apr-2013 for defect 10871
           v_timestamp,       -- Added on 17-Apr-2013 for defect 10871
           v_prod_code        -- Added on 17-Apr-2013 for defect 10871
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
             CSL_PROD_CODE          -- Added on 17-Apr-2013 for defect 10871
             )
           VALUES
            (V_HASH_PAN,
             V_FEE_OPENING_BAL,
             V_FLAT_FEES,
             'DR',
             V_TRAN_DATE,
             V_FEE_OPENING_BAL - V_FLAT_FEES,
            -- 'Fixed Fee debited for ' || V_NARRATION, --Commented for MVCSD-4471
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
             V_CAM_TYPE_CODE,   -- Added on 17-Apr-2013 for defect 10871
             v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
             v_prod_code        -- Added on 17-Apr-2013 for defect 10871
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
             CSL_PANNO_LAST4DIGIT,  --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
             CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
             CSL_TIME_STAMP,         -- Added on 17-Apr-2013 for defect 10871
             CSL_PROD_CODE          -- Added on 17-Apr-2013 for defect 10871
             )
           VALUES
            (V_HASH_PAN,
             V_FEE_OPENING_BAL,
             V_PER_FEES,
             'DR',
             V_TRAN_DATE,
             V_FEE_OPENING_BAL - V_PER_FEES,
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
             (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),
             v_cam_type_code,   -- Added on 17-Apr-2013 for defect 10871
             v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
             v_prod_code        -- Added on 17-Apr-2013 for defect 10871
             );

           --En Entry for Percentage Fee
 END IF;
         ELSE

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
               CSL_PANNO_LAST4DIGIT,  --Added by Trivikram on 23-May-2012 to log Last $ Digit of the card number
               CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
               CSL_TIME_STAMP,        -- Added on 17-Apr-2013 for defect 10871
               CSL_PROD_CODE          -- Added on 17-Apr-2013 for defect 10871
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
               v_cam_type_code,   -- Added on 17-Apr-2013 for defect 10871
               v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
               v_prod_code        -- Added on 17-Apr-2013 for defect 10871
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
        ctd_merchant_zip,  --Added by Pankaj S. for 11540
        ctd_internation_ind_response  --Added by Pankaj S. for Mantis ID 13024
        ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,
        CTD_CARDVERIFICATION_RESULT--Added for MVHOST 926
        ,ctd_req_resp_code ,ctd_ins_user --Added for 15197
        ,CTD_MERCHANT_ID,CTD_COUNTRY_CODE
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
        p_merchant_zip,  --Added by Pankaj S. for 11540
        p_international_ind  --Added by Pankaj S. for Mantis ID 13024
        ,P_PULSE_TRANSACTIONID,--Added for MVHOST 926
        P_VISA_TRANSACTIONID,--Added for MVHOST 926
        P_MC_TRACEID,--Added for MVHOST 926
        P_CARDVERIFICATION_RESULT--Added for MVHOST 926
        ,p_req_resp_code ,1 --Added for 15197
        ,P_MERCHANT_ID,P_MERCHANT_CNTRYCODE
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
  /*  BEGIN --Unwanted Code commented for VMS-2709
     SELECT CAT_PAN_CODE
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
     
      IF SQL%ROWCOUNT = 0 THEN
        V_ERR_MSG  := 'Problem while updating data in avail trans ' ||
                   SUBSTR(SQLERRM, 1, 300);
        V_RESP_CDE := '21';
        RAISE EXP_REJECT_RECORD;
      END IF;
      
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from avail trans ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;*/ --Unwanted Code commented for VMS-2709

    --En update daily and weekly transaction counter and amount
    --Sn create detail for response message
    --Sn commented here n used same below
    /*IF V_OUTPUT_TYPE = 'B' THEN
     --Balance Inquiry
     P_RESP_MSG := TO_CHAR(V_UPD_AMT);
    END IF;*/
    --En commented here n used same below

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

   /* BEGIN --Unwanted Code commented for VMS-2709

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
    END;*/ --Unwanted Code commented for VMS-2709

    ---En Updation of Usage limit and amount
    P_RESP_ID := V_RESP_CDE; --Added for VMS-8018
    BEGIN
     SELECT CMS_B24_RESPCDE, CMS_ISO_RESPCDE --Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
       INTO P_RESP_CODE,
           --V_CMS_ISO_RESPCDE -- Added for OLS Changes
           p_iso_respcde --Commented and replaced  on 17.07.2013 for the Mantis ID 11612
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
    --Sn Added for OLS issue(Mantis ID-11088)
    BEGIN
        SELECT cam_acct_bal, cam_ledger_bal
          INTO v_acct_balance, v_ledger_bal
          FROM cms_acct_mast
         WHERE cam_acct_no = V_ACCT_NUMBER
                 /* (SELECT cap_acct_no
                     FROM cms_appl_pan
                    WHERE cap_pan_code = v_hash_pan
                      AND cap_inst_code = p_inst_code)*/--For Instcode removal of 2.4.2.4.2 release
           AND cam_inst_code = p_inst_code;
    EXCEPTION
        WHEN OTHERS
        THEN
           v_acct_balance := 0;
           v_ledger_bal := 0;
    END;

    IF V_OUTPUT_TYPE = 'B' THEN
    P_RESP_MSG := TO_CHAR(v_acct_balance);
    END IF;
    --En Added for OLS issue(Mantis ID-11088)

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
     --Sn Block moved from bottom to top 09-Feb-2015
      if V_PROD_CODE is null
     then

         BEGIN

             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_CARD_STAT,
                    CAP_ACCT_NO
                    ,cap_proxy_number --Added for 15197
               INTO V_PROD_CODE,
                    V_PROD_CATTYPE,
                    V_APPLPAN_CARDSTAT,
                    V_ACCT_NUMBER
                    ,V_PROXUNUMBER --Added for 15197
               FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN; --P_card_no;
         EXCEPTION
         WHEN OTHERS THEN

         NULL;

         END;

     end if;
     --En Block moved from bottom to top 09-Feb-2015
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
              cam_type_code                     --Added for defect 10871
              ,cam_acct_no --Added for 15197
        INTO  V_ACCT_BALANCE, V_LEDGER_BAL,
              v_cam_type_code                   --Added for defect 10871
              ,V_ACCT_NUMBER --Added for 15197
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO = V_ACCT_NUMBER
            /*(SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN AND
                   CAP_INST_CODE = P_INST_CODE)*/ AND --For Instcode removal of 2.4.2.4.2 release
            CAM_INST_CODE = P_INST_CODE;
     EXCEPTION
       WHEN OTHERS THEN
        V_ACCT_BALANCE := 0;
        V_LEDGER_BAL   := 0;
     END;
    /* BEGIN --Unwanted Code commented for VMS-2709
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
     END IF;*/ --Unwanted Code commented for VMS-2709

     --Sn select response code and insert record into txn log dtl
     BEGIN
       P_RESP_MSG  := V_ERR_MSG;
       P_RESP_CODE := V_RESP_CDE;
       P_RESP_ID   := V_RESP_CDE; --Added for VMS-8018

       -- Assign the response code to the out parameter
       SELECT CMS_B24_RESPCDE, cms_iso_respcde --Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
        INTO P_RESP_CODE,
             --V_CMS_ISO_RESPCDE -- Added for OLS Changes
             p_iso_respcde --Commented and replaced  on 17.07.2013 for the Mantis ID 11612
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
     
     
  if P_ISO_RESPCDE in ('L49','L50')   then   
  begin   
   IF v_badcredit_flag = 'Y'
         THEN
             execute immediate 'SELECT  count(*)
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
            into v_cnt;
            IF v_cnt = 1
            THEN
              -- v_enable_flag := 'N'; --Code commented for VMS-2709
               IF    ((V_UPD_AMT) > v_initialload_amt
                     )                                     --initialloadamount
                  OR ((V_UPD_LEDGER_AMT) > v_initialload_amt
                     )
               THEN                                        --initialloadamount
           UPDATE CMS_APPL_PAN
                     SET cap_card_stat = '18'
                   WHERE cap_inst_code = p_inst_code
                     AND cap_pan_code = v_hash_pan;
                  --Sn Logging of system initiated card status change(FSS-390)
   
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
                              P_RESP_MSG
                             );

       IF v_resp_cde <> '00' AND P_RESP_MSG <> 'OK'
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
    
    --En Logging of system initiated card status change(FSS-390)
               END IF;
            END IF;
         END IF;
         
 end;       
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
         ctd_merchant_zip,  --Added by Pankaj S. for 11540
         ctd_internation_ind_response  --Added by Pankaj S. for Mantis ID 13024
         ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,
         CTD_CARDVERIFICATION_RESULT--Added for MVHOST 926
         ,ctd_req_resp_code ,ctd_ins_user --Added for 15197
         ,CTD_MERCHANT_ID,CTD_COUNTRY_CODE
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
         p_merchant_zip,  --Added by Pankaj S. for 11540
         p_international_ind  --Added by Pankaj S. for Mantis ID 13024
         ,P_PULSE_TRANSACTIONID,--Added for MVHOST 926
        P_VISA_TRANSACTIONID,--Added for MVHOST 926
        P_MC_TRACEID,--Added for MVHOST 926
       -- P_MEDAGATE_RESPVERBIAGE--Added for MVHOST 926
       P_CARDVERIFICATION_RESULT--Added for MVHOST 926
         ,p_req_resp_code ,1 --Added for 15197
         ,P_MERCHANT_ID,P_MERCHANT_CNTRYCODE
         );

       P_RESP_MSG := V_ERR_MSG;
     EXCEPTION
       WHEN OTHERS THEN
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '69'; -- Server Declined
        P_RESP_ID   := '69'; --Added for VMS-8018
        ROLLBACK;
        RETURN;
     END;

     -----------------------------------------------
     --SN: Added on 17-Apr-2013 for defect 10871
     -----------------------------------------------
     /*
     if V_PROD_CODE is null
     then

         BEGIN

             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_CARD_STAT,
                    CAP_ACCT_NO
                    ,cap_proxy_number --Added for 15197
               INTO V_PROD_CODE,
                    V_PROD_CATTYPE,
                    V_APPLPAN_CARDSTAT,
                    V_ACCT_NUMBER
                    ,V_PROXUNUMBER --Added for 15197
               FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN; --P_card_no;
         EXCEPTION
         WHEN OTHERS THEN

         NULL;

         END;

     end if;*/


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

    WHEN OTHERS THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;


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
       SELECT CMS_B24_RESPCDE, cms_iso_respcde --Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
        INTO P_RESP_CODE,
             --V_CMS_ISO_RESPCDE -- Added for OLS changes
             p_iso_respcde --Commented and replaced  on 17.07.2013 for the Mantis ID 11612
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
         ctd_merchant_zip,  --Added by Pankaj S. for 11540
         ctd_internation_ind_response  --Added by Pankaj S. for Mantis ID 13024
         ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,
         --CTD_MEDAGATE_RESPVERBIAGE--Added for MVHOST 926
         CTD_CARDVERIFICATION_RESULT--Added for MVHOST 926
           ,ctd_req_resp_code ,ctd_ins_user --Added for 15197
           ,CTD_MERCHANT_ID,CTD_COUNTRY_CODE
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
         p_merchant_zip,  --Added by Pankaj S. for 11540
         p_international_ind  --Added by Pankaj S. for Mantis ID 13024
         ,P_PULSE_TRANSACTIONID,--Added for MVHOST 926
        P_VISA_TRANSACTIONID,--Added for MVHOST 926
        P_MC_TRACEID,--Added for MVHOST 926
       -- P_MEDAGATE_RESPVERBIAGE--Added for MVHOST 926
       P_CARDVERIFICATION_RESULT--Added for MVHOST 926
         ,p_req_resp_code ,1 --Added for 15197
         ,P_MERCHANT_ID,P_MERCHANT_CNTRYCODE
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

     if V_ACCT_BALANCE is null
     then

         BEGIN
           SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
                  cam_type_code                     --Added for defect 10871
            INTO  V_ACCT_BALANCE, V_LEDGER_BAL,
                  v_cam_type_code                   --Added for defect 10871
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

     end if;

     if v_timestamp is null
     then
         v_timestamp := systimestamp;              -- Added on 17-Apr-2013 for defect 10871

     end if;

     -----------------------------------------------
     --EN: Added on 17-Apr-2013 for defect 10871
     -----------------------------------------------

  END;

  --Sn added for OLS changes(Mantis ID-11088)
  P_LEDGER_BAL := to_char(v_ledger_bal);
  --En added for OLS changes(Mantis ID-11088)

  --- Sn create GL ENTRIES
  IF V_RESP_CDE = '1' THEN

    V_BUSINESS_TIME := TO_CHAR(V_TRAN_DATE, 'HH24:MI');

    IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
     V_BUSINESS_DATE := TRUNC(V_TRAN_DATE) + 1;
    ELSE
     V_BUSINESS_DATE := TRUNC(V_TRAN_DATE);
    END IF;

    --En find businesses date

    --SN -- Commented for FWR-48

  /*  BEGIN
    IF(p_req_resp_code < 100) THEN --Added for 15197
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
     END IF;
    EXCEPTION
     WHEN OTHERS THEN
       V_GL_UPD_FLAG := 'N';
       P_RESP_CODE   := V_RESP_CDE;
       V_ERR_MSG     := V_GL_ERR_MSG;
       RAISE EXP_REJECT_RECORD;
    END; */

    --EN -- Commented for FWR-48

    --Sn find prod code and card type and available balance for the card number
    BEGIN
     SELECT CAM_ACCT_BAL
       INTO V_ACCT_BALANCE
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
                 CAP_INST_CODE = P_INST_CODE) AND
           CAM_INST_CODE = P_INST_CODE;
        --FOR UPDATE NOWAIT;                             -- Commented for Concurrent Processsing Issue
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
     P_RESP_MSG := TO_CHAR(v_acct_balance); --v_upd_amt replaced by v_acct_balance during OLS changes
    END IF;
  END IF;

  --En create GL ENTRIES
  -- Sn Added for 15197
 IF p_req_resp_code >= 100  THEN --Added for 15197

        V_UPD_AMT:=V_ACCT_BALANCE;
      V_UPD_LEDGER_AMT:=V_LEDGER_BAL;

      END IF;

 --En Added for 15197

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
      FEEATTACHTYPE ,-- Added by Trivikram on 05-Sep-2012
            MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_STATE,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      ERROR_MSG,       -- Same was missing
      ACCT_TYPE,        -- Added on 17-Apr-2013 for defect 10871
      TIME_STAMP  ,       -- Added on 17-Apr-2013 for defect 10871
      NETWORKID_SWITCH, --Added on 20130626 for the Mantis ID 11344
      NETWORKID_ACQUIRER, --Added on 20130626 for the Mantis ID 11344
      NETWORK_SETTL_DATE, --Added on 20130626 for the Mantis ID 11123
      merchant_zip,  --Added by Pankaj S. for 11540
      CVV_VERIFICATIONTYPE,  --Added on 17.07.2013 for the Mantis ID 11611
      internation_ind_response  --Added by Pankaj S. for Mantis ID 13024
      ,addr_verify_response ,
      addr_verify_indicator
      ,add_ins_user
      ,merchant_id,
      surchargefee_ind_ptc --Added for VMS-5856
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
      --DECODE(V_CMS_ISO_RESPCDE, '00', 'C', 'F'), -- Added for OLS Changes
      DECODE(p_iso_respcde, '00', 'C', 'F'), --Commented and replaced  on 17.07.2013 for the Mantis ID 11612
      --V_CMS_ISO_RESPCDE, -- Added for OLS Changes
      p_iso_respcde ,--Commented and replaced  on 17.07.2013 for the Mantis ID 11612
      P_TRAN_DATE,
      SUBSTR(P_TRAN_TIME, 1, 10),
      V_HASH_PAN,
      NULL,
      NULL, --P_topup_acctno    ,
      NULL, --P_topup_accttype,
      P_BANK_CODE,
      TRIM(TO_CHAR(nvl(V_TOTAL_AMT,0), '99999999999999990.99')), --NVL added for defect 10871
      NULL,
      NULL,
      P_MCC_CODE,
      P_CURR_CODE,
      NULL, -- P_add_charge,
      V_PROD_CODE,
      V_PROD_CATTYPE,
      TRIM(TO_CHAR(nvl(P_TIP_AMT,0), '99999999999999990.99')), --trum(to_char added for defect 10871
      P_DECLINE_RULEID,
      P_ATMNAME_LOC,
      V_AUTH_ID,
      V_TRANS_DESC,
      TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '99999999999999990.99')), --NVL added for defect 10871
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
      nvl(V_FEE_AMT,0),  --Modified for 15197,
      nvl(V_SERVICETAX_AMOUNT,0),   --NVl added for defect 10871
      nvl(V_CESS_AMOUNT,0),         --NVl added for defect 10871
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
      DECODE(P_RESP_CODE, '00',nvl(V_UPD_AMT,0),nvl(V_ACCT_BALANCE,0)),
      DECODE(P_RESP_CODE, '00',nvl(V_UPD_LEDGER_AMT,0),nvl(V_LEDGER_BAL,0)),
      V_RESP_CDE,
      V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
      V_FEEATTACH_TYPE, -- Added by Trivikram on 05-Sep-2012
        P_MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      P_MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      P_ATMNAME_LOC, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      V_ERR_MSG,      -- Same was missing
      v_cam_type_code,   -- Added on 17-Apr-2013 for defect 10871
      v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
       P_NETWORKID_SWITCH , --Added on 20130626 for the Mantis ID 11344
       P_NETWORKID_ACQUIRER,-- Added on 20130626 for the Mantis ID 11344
       p_network_setl_date,  --Added on 20130626 for the Mantis ID 11123
       p_merchant_zip,  --Added by Pankaj S. for 11540
       NVL(P_CVV_VERIFICATIONTYPE,'N'),  --Added on 17.07.2013 for the Mantis ID 11611
       p_international_ind  --Added by Pankaj S. for Mantis ID 13024
       , P_ADDR_VERFY_RESPONSE,
       P_ADDRVERIFY_FLAG
       ,1
       ,P_MERCHANT_ID,
       DECODE(p_surchrg_ind,'2',NULL,p_surchrg_ind) --Added for VMS-5856
      );

    --DBMS_OUTPUT.PUT_LINE('AFTER INSERT IN TRANSACTIONLOG');
    P_CAPTURE_DATE := V_BUSINESS_DATE;
    P_AUTH_ID      := V_AUTH_ID;
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
show error