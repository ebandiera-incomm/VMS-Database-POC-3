set define off;
create or replace
PROCEDURE                                     VMSCMS.SP_TOPUP_PAN_CMS_SPIL ( 
                                        P_INSTCODE         IN NUMBER,
                                        P_RRN              IN VARCHAR2, --For SPIL Incomm Reference Number will be the RRN
                                        P_TERMINALID       IN VARCHAR2,
                                        P_STAN             IN VARCHAR2,
                                        P_TRANDATE         IN VARCHAR2,
                                        P_TRANTIME         IN VARCHAR2,
                                        P_PANNO            IN VARCHAR2,
                                        P_AMOUNT           IN NUMBER,
                                        P_CURRCODE         IN VARCHAR2,
                                        P_LUPDUSER         IN NUMBER,
                                        P_MSG              IN VARCHAR2,
                                        P_TXN_CODE         IN VARCHAR2,
                                        P_TXN_MODE         IN VARCHAR2,
                                        P_DELIVERY_CHANNEL IN VARCHAR2,
                                        P_Mbr_Numb         In Varchar2,
                                        P_RVSL_CODE        IN VARCHAR2,
                                        P_Merchant_Name    In Varchar2,
                                        P_STORE_ID          in varchar2,--SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES      
                                       --Added for serial number changes on 29/10/14
                                        P_RESP_CODE        OUT VARCHAR2,
                                        P_ERRMSG           OUT VARCHAR2,
                                        P_RESP_MSG         OUT varchar2,
                                        P_ACCT_BAL         OUT VARCHAR2,                                        
                                         P_SERIAL_NUMBER     IN VARCHAR2 DEFAULT NULL,
                                         p_merchant_zip    in varchar2 default null, 
										 p_merchant_id_in   in varchar2 default null) AS-- added for VMS-622 (redemption_delay zip code validation)

  /***********************************************************************************
     * Created Date     :  10-Dec-2012
     * Created By       :  Srinivasu
     * PURPOSE          :  For Topup PAN
     * Modified By      :  Besky
     * Modified Date    :  30-Nov-2012
     * Modified Reason  : SPIL Decline Transaction Reason displayed as 'Database Error'

     * Modified By      :  Pankaj S.
     * Modified Date    :  26-Feb-2013
     * Modified Reason  : Modified for SPIL RRN Check changes
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     :

     * Modified By      :  Saravanakumar
     * Modified Date    :  04-Mar-2013
     * Modified Reason  : Removeed txn code from duplicate rrn check
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     :

     * Modified By      :  MageshKumar.S
     * Modified Date    :  20-Mar-2013
     * Modified Reason  :  Modified for GPR card Generation for Startercard Manual Type
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     :

     * Modified By      :  Sagar
     * Modified Date    :  21-Mar-2013
     * Modified Reason  :  KYC verification flags commented before calling to sp_gen_pan
     * Modified For     :  Defect 0010608
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  21-Mar-2013
     * Build Number     :  RI0024_B0008

     * Modified By      :  Pankaj s
     * Modified Date    :  28-Mar-2013
     * Modified Reason  :  to handle CSR ¿ID check failed override¿ scenario
                           for Starter to GPR card of manual starter card type
     * Modified For     :  Defect 0010564
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  28-Mar-2013
     * Build Number     :  RI0024_B0012

     * Modified By      :  Sagar M.
     * Modified Date    :  29-Mar-2013
     * Modified Reason  :  To check startercard issue type before updating
                           cam_appl_stat to 'A' in CMS_APPL_MAST
     * Modified For     :  Defect 0010608
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  29-Mar-2013
     * Build Number     :  RI0024_B0014

     * Modified By      :  Arunprasath.C
     * Modified Date    :  07-May-2013
     * Modified Reason  :  Phantom card issue
     * Modified For     :
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  07-May-2013
     * Build Number     :  RI0024.1_B0017

     * Modified By      :  MageshKumar.S
     * Modified Date    :  05-June-2013
     * Modified Reason  :  Defect MVHOST-447(Replenishment Floor Limit issue)
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     :  RI0024.2_B0003

      * Modified By      : Santosh P
      * Modified Date    : 12-Jul-2013
      * Modified Reason  : Capture StoreId in transactionlog table
      * Modified for     : FSS-1146
      * Reviewer         :
      * Reviewed Date    :
      * Build Number     : RI0024.2_B0005

      * Modified By      : MageshKumar S.
      * Modified Date    : 26-Nov-2013
      * Modified Reason  : Response code not logged properly
      * Modified for     : MVHOST-479
      * Reviewer         : Dhiraj
      * Reviewed Date    : 05/DEC/2013
      * Build Number     : RI0024.7_B0001

      * Modified By      : Pankaj S.
      * Modified Date    : 19-Dec-2013
      * Modified Reason  : Logging issue changes(Mantis ID-13160)
      * Reviewer         : Dhiraj
      * Reviewed Date    :
      * Build Number     : RI0027_B0004

      * Modified by       : Pankaj S.
      * Modified for      : Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
      * Modified Date     : 24-MAR-2014
      * Reviewer          : Dhiraj
      * Reviewed Date     : 07-April-2014
      * Build Number      : RI0027.2_B0004

      * Modified by       : Ramesh
      * Modified for      : FSS-1691 Integration from 2.1.7 to 2.2.1 release
      * Modified Date     : 06-Jun-2014
      * Build Number      : RI0027.2.1_B0003

      * Modified by       : Dhinakaran B
      * Modified for      : MANTIS ID-12422
      * Modified Date     : 09-JUL-2014
      * Reviewer          : Spankaj
      * Reviewed Date     : RI0027.3_B0003

     * Modified by       : Abdul Hameed M.A
     * Modified for      : JH 3011
     * Modified Reason   : GPR  card should be generated for the starter card if GPROPTIN is "N" and starter to gpr is manual.
     * Modified Date     : 01-SEP-2014
     * Build Number      : RI0027.3.2_B0002
     
    * Modified by       : Ramesh.A
    * Modified Date     : 29-OCT-14
    * Modified For      : SPIL Serial Number changes    
    * Reviewer          : Saravanakumar
    * Build Number      :RI0027.4.3_B0002

    * Modified by       : Siva Kumar M
    * Modified Date     : 11-Nov-14
    * Modified For      : Mantis id:15747    
    * Reviewer          : Spankaj
    * Build Number      : RI0027.4.3_B0003
    
    * Modified by       : Ramesh A
    * Modified Date     : 12-DEC-14
    * Modified For      : FSS-1961(Melissa)
    * Reviewer          : Spankaj
    * Build Number      : RI0027.5_B0002
    
    * Modified by      : MAGESHKUMAR S.
    * Modified Date    : 03-FEB-2015
    * Modified For     : FSS-2072(2.4.2.4.1 & 2.4.3.1 integration)
    * Reviewer         : PANKAJ S.
    * Build Number     : RI0027.5_B0006
    
    * Modified by       : MAGESHKUMAR S
    * Modified Date     : 24-FEB-15
    * Modified For      : FSS-2225(2.4.2.4.4 and 2.4.3.3 integration)
    * Reviewer          : PANKAJ
    * Build Number      : RI0027.5_B0009
    
    * Modified by       : Siva Kumar M
    * Modified Date     : 05-Aug-15
    * Modified For      : FSS-2320
    * Reviewer          : PANKAJ
    * Build Number      : VMSGPRHOSTCSD_3.1_B0001
    
    * Modified by                  : MageshKumar S.
    * Modified Date                : 23-June-15
    * Modified For                 : MVCAN-77
    * Modified reason              : Canada account limit check
    * Reviewer                     : Spankaj
    * Build Number                 : VMSGPRHOSTCSD3.1_B0001
    
    * Modified by      : Pankaj S.
    * Modified for     : Transactionlog Functional Removal Phase-II changes
    * Modified Date    : 11-Aug-2015
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOAT_3.1
    
    * Modified by      : Abdul Hameed M.A
    * Modified for     : FSS-3614
    * Modified reason  : Amount is logged as zero for some failure cases
    * Modified Date    : 1-Sep-2015
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOAT_3.1_B0008
    
    * Modified by      : Siva Kumar M    
    * Modified for     : Mantis ID:16424
    * Modified reason  : Valins and Prevalins transaction not working for closed loop product
    * Modified Date    : 16-June-2016
    * Reviewer         : Saravanankumar
    * Build Number     : VMSGPRHOAT_4.2_B0002
    
    * Modified by      : Pankaj S.
    * Modified Date    : 09-Mar-17
    * Modified For     : FSS-4647
    * Modified reason  : Redemption Delay Changes
    * Reviewer         : Saravanakumar
    * Build Number     : VMSGPRHOST_17.3
    
    * Modified by      : T.Narayanaswamy.
    * Modified Date    : 20-June-17
    * Modified For     : FSS-5157 - B2B Gift Card - Phase 2
    * Modified reason  : B2B Gift Card - Phase 2
    * Reviewer         : Saravanakumar
    * Build Number     : VMSGPRHOST_17.07   
    
   * Modified By      : T.Narayanaswamy.
   * Modified Date    : 04/08/2017
   * Purpose          : FSS-5157 - B2B Gift Card - Phase 2
   * Reviewer         : Saravanan/Pankaj S. 
   * Release Number   : VMSGPRHOST17.08
   
   	 * Modified By      : Veneetha C
     * Modified Date    : 21-JAN-2019
     * Purpose          : VMS-622 Redemption delay for activations /reloads processed through ICGPRM
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST R11
	 
	 * Modified By      : Baskar Krishnan
    * Modified Date    : 02-MAR-2020
    * Modified For     : VMS-2015
    * Reviewer         : Saravanakumar
    * Release Number   : R27
	
	* Modified By      : Karthick
    * Modified Date    : 06-28-2022
    * Purpose          : Archival changes.
    * Reviewer         : Venkat Singamaneni
    * Release Number   : VMSGPRHOST65 for VMS-5739/FSP-991
	
	 * Modified By      : John G
     * Modified Date    : 20-OCT-2022
     * Purpose          : VMS-6499 Ph2: Enhance Redemption Delays by MID
     * Reviewer         : Pankaj S
     * Release Number   : VMSGPRHOST R71
  *************************************************************************************/

  V_CAP_PROD_CATG     CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
  V_CAP_CARD_STAT     CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_CAP_CAFGEN_FLAG   CMS_APPL_PAN.CAP_CAFGEN_FLAG%TYPE;
  --V_CAP_APPL_CODE     CMS_APPL_PAN.CAP_APPL_CODE%TYPE;
  V_FIRSTTIME_TOPUP   CMS_APPL_PAN.CAP_FIRSTTIME_TOPUP%TYPE;
  V_PROD_CODE         CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_CARD_TYPE         CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_PROFILE_CODE      CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
  V_VARPRODFLAG       cms_prod_cattype.CPC_RELOADABLE_FLAG%TYPE;
  V_CURRCODE          VARCHAR2(3);
  V_APPL_CODE         CMS_APPL_MAST.CAM_APPL_CODE%TYPE;
  V_RESONCODE         CMS_SPPRT_REASONS.CSR_SPPRT_RSNCODE%TYPE;
  V_RESPCODE          VARCHAR2(5);
  V_RESPMSG           VARCHAR2(500);
  V_CAPTURE_DATE      DATE;
  V_MBRNUMB           CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
 -- V_TXN_CODE          CMS_FUNC_MAST.CFM_TXN_CODE%TYPE;
  --V_TXN_MODE          CMS_FUNC_MAST.CFM_TXN_MODE%TYPE;
 -- V_DEL_CHANNEL       CMS_FUNC_MAST.CFM_DELIVERY_CHANNEL%TYPE;
  V_TXN_TYPE          CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
  V_TOPUP_AUTH_ID     TRANSACTIONLOG.AUTH_ID%TYPE;
  V_MIN_MAX_LIMIT     VARCHAR2(50);
  V_ACCT_TXN_DTL      CMS_TOPUPTRANS_COUNT.CTC_TOTAVAIL_DAYS%TYPE;
  V_TOPUP_FREQ        VARCHAR2(50);
  V_TOPUP_FREQ_PERIOD VARCHAR2(50);
 -- V_END_LUPD_DATE     CMS_TOPUPTRANS_COUNT.CTC_LUPD_DATE%TYPE;
  V_ACCT_TXN_DTL_1    CMS_TOPUPTRANS_COUNT.CTC_TOTAVAIL_DAYS%TYPE;
  V_END_DAY_UPDATE    CMS_TOPUPTRANS_COUNT.CTC_LUPD_DATE%TYPE;
  V_MIN_LIMIT         VARCHAR2(50);
  V_MAX_LIMIT         VARCHAR2(50);
  --V_RRN_COUNT         NUMBER;--Commented duplicate rrn check
  EXP_MAIN_REJECT_RECORD EXCEPTION;
  EXP_AUTH_REJECT_RECORD EXCEPTION;
  EXP_DUPLICATE_REQUEST EXCEPTION;
  V_HASH_PAN           CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN           CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_BUSINESS_DATE      DATE;
  V_TRAN_DATE          DATE;
  V_TOPUPREMRK         VARCHAR2(100);
  V_ACCT_BALANCE       NUMBER;
  V_LEDGER_BALANCE     NUMBER;
  V_TRAN_AMT           NUMBER;
 -- V_DELCHANNEL_CODE    VARCHAR2(2);
  V_CARD_CURR          VARCHAR2(5);
  V_DATE               DATE;
  --V_BASE_CURR          CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  --V_MMPOS_USAGEAMNT    CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
  --V_MMPOS_USAGELIMIT   CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_LIMIT%TYPE;
  V_TOTALTOPUPNAMOUNT  NUMBER;
  V_MAXDAILYLOAD       NUMBER;
  --V_BUSINESS_DATE_TRAN DATE;
  V_PROXUNUMBER        CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER        CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_TRANCDE            VARCHAR2(2);
  --V_AUTHID_DATE        VARCHAR2(8);
  --Modified by srinivasu on 20 feb 2012 for Stater card issuance
  --Begin
  V_CARDTYPE_FLAG    CMS_APPL_PAN.CAP_STARTERCARD_FLAG%TYPE;
  V_TRANCOUNT        VARCHAR2(5);
  V_APPLNO           CMS_APPL_PAN.CAP_APPL_CODE%TYPE;
  V_PANCODE          CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_PROCESSMSG       VARCHAR2(500);
  V_KYC_FLAG         VARCHAR2(10);
  V_APPLSTAT_COUNT   VARCHAR2(5);
 -- V_STATERMAXLOAD    CMS_PROD_CATTYPE.CPC_STARTER_MAXLOAD%TYPE; --commented by MageshKumar.S on 05-06-2013 for Defect Id:MVHOST-477
 -- V_STATERMINLOAD    CMS_PROD_CATTYPE.CPC_STARTER_MINLOAD%TYPE; --commented by MageshKumar.S on 05-06-2013 for Defect Id:MVHOST-477
  V_STATERISSUSETYPE CMS_PROD_CATTYPE.CPC_STARTERGPR_ISSUE%TYPE;

  -- ADDED ON 09-04-2012 START by RNK
  --V_MINRRNDATE      varchar2(20);--TRANSACTIONLOG.BUSINESS_DATE%TYPE; --Commented duplicate rrn check
  --V_MAXRRNDATE      varchar2(20);--TRANSACTIONLOG.BUSINESS_DATE%TYPE; --Commented duplicate rrn check
  V_DUPCHK_CARDSTAT TRANSACTIONLOG.CARDSTATUS%TYPE;
  V_DUPCHK_ACCTBAL  TRANSACTIONLOG.ACCT_BALANCE%TYPE;
  V_DUPCHK_COUNT    NUMBER;
  V_COUNT           NUMBER;
  --Sn Getting  RRN DETAILS
  V_TRANS_DESC   CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812

--Commented duplicate rrn check
  /*CURSOR C(CP_RRN IN VARCHAR2, CP_DELIV_CHNL IN VARCHAR2, --CP_TXN_CODE IN VARCHAR2, --Removeed txn code from duplicate rrn check
         CP_FRMDATE IN VARCHAR2, CP_ENDDATE IN VARCHAR2, CP_HASH_PAN IN CMS_APPL_PAN.CAP_PAN_CODE%TYPE) IS
    SELECT CARDSTATUS, ACCT_BALANCE
     FROM TRANSACTIONLOG
    WHERE RRN = CP_RRN AND CUSTOMER_CARD_NO = CP_HASH_PAN AND
         DELIVERY_CHANNEL = CP_DELIV_CHNL AND
         --Sn Modified for Removeed txn code from duplicate rrn check
         --TXN_CODE = CP_TXN_CODE AND
         TO_DATE(BUSINESS_DATE||BUSINESS_TIME, 'YYYYMMDDHH24MISS') >
         TO_DATE(CP_FRMDATE, 'YYYYMMDDHH24MISS') AND
         TO_DATE(BUSINESS_DATE||BUSINESS_TIME, 'YYYYMMDDHH24MISS') <=
         TO_DATE(CP_ENDDATE, 'YYYYMMDDHH24MISS') AND
         --En Modified for Removeed txn code from duplicate rrn check
         BUSINESS_DATE IS NOT NULL AND
         ACCT_BALANCE IS NOT NULL;*/

  v_dr_cr_flag  cms_transaction_mast.ctm_credit_debit_flag%TYPE; -- Added by MageshKumar.S on 26-11-2013 for Defect Id:MVHOST-479
  v_acct_type   cms_acct_mast.cam_type_code%TYPE; -- Added by MageshKumar.S on 26-11-2013 for Defect Id:MVHOST-479

  --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
   v_comb_hash              pkg_limits_check.type_hash;
   v_tran_type              cms_transaction_mast.ctm_tran_type%TYPE;
   v_prfl_code              cms_appl_pan.cap_prfl_code%TYPE;
   v_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE;
   --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
  V_SP_COUNT      NUMBER;   --Added for serial number changes on 29/10/14
  V_RESP_CDE      NUMBER; --Added for serial number changes on 29/10/14 
  V_RESP_MSG      VARCHAR2(500); --Added for serial number changes on 29/10/14 
   v_cust_code                 cms_appl_pan.cap_cust_code%TYPE;  --Added for FSS-1961(Melissa)
   p_pan_number   VARCHAR2(20); --Added for FSS-1961(Melissa)
  --Sn Added for FSS-4647
  v_redmption_delay_flag   cms_prod_cattype.cpc_redemption_delay_flag%TYPE;
  v_txn_redmption_flag  cms_transaction_mast.ctm_redemption_delay_flag%TYPE;
  --En Added for FSS-4647
  
   V_CPC_PROD_DENO        CMS_PROD_CATTYPE.CPC_PROD_DENOM%TYPE;   
   V_CPC_PDEN_MIN         CMS_PROD_CATTYPE.CPC_PDENOM_MIN%TYPE;
   V_CPC_PDEN_MAX         CMS_PROD_CATTYPE.CPC_PDENOM_MAX%TYPE;
   V_CPC_PDEN_FIX         CMS_PROD_CATTYPE.CPC_PDENOM_FIX%TYPE;
  V_BYPASS_LOADCHECK     CMS_PROD_CATTYPE.CPC_BYPASS_LOADCHECK%TYPE;
   v_toggle_value         cms_inst_param.cip_param_value%TYPE;
  v_Retperiod  date;  --Added for VMS-5739/FSP-991
  v_Retdate  date; --Added for VMS-5739/FSP-991

BEGIN
  P_ERRMSG     := 'OK';
  V_TOPUPREMRK := 'Online Card Topup';
  P_RESP_MSG   := 'Success';
   V_TRAN_AMT := P_AMOUNT;
  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(P_PANNO);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     P_ERRMSG := 'Error while converting hashpan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_PANNO);
  EXCEPTION
     WHEN OTHERS THEN
     V_RESPCODE := '21';
     P_ERRMSG := 'Error while converting endrpan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --EN create encr pan

  --Sn Getting the Transaction Description
    BEGIN
     SELECT CTM_TRAN_DESC,
            ctm_credit_debit_flag,  --Added by MageshKumar.S for MVHOST-479
            TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')), -- Added by MageshKumar.S for MVHOST-479
            ctm_prfl_flag,ctm_tran_type, --Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
            NVL(ctm_redemption_delay_flag,'N')
       INTO V_TRANS_DESC,
            v_dr_cr_flag,V_TXN_TYPE,  --Added by MageshKumar.S for MVHOST-479
            v_prfl_flag,v_tran_type, --Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
            v_txn_redmption_flag
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_TRANS_DESC := 'Transaction type' || P_TXN_CODE;
     WHEN EXP_MAIN_REJECT_RECORD THEN
        RAISE;
     WHEN OTHERS THEN
       V_TRANS_DESC := 'Transaction type ' || P_TXN_CODE;
    END;
--Commented duplicate rrn check
begin
 SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
                            INTO v_toggle_value
                            FROM vmscms.cms_inst_param
                           WHERE cip_inst_code = 1
                             AND cip_param_key = 'VMS_5549_TOGGLE';
							 
						EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              v_toggle_value := 'Y';

 END;

 IF v_toggle_value = 'Y' THEN

BEGIN
        sp_concurrent_check_log(v_hash_pan, p_delivery_channel, p_txn_code, p_errmsg);
        IF P_ERRMSG <> 'OK' THEN
           v_respcode         := '215';
           RAISE EXP_MAIN_REJECT_RECORD;
        END IF;
        EXCEPTION
        WHEN EXP_MAIN_REJECT_RECORD THEN
          RAISE;
        WHEN OTHERS THEN
          v_respcode := '12';
          p_errmsg  := 'Concurrent check Logging failed' || SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
    END;

END IF; 
  --Sn select Pan detail
  BEGIN
    SELECT CAP_CARD_STAT,
         CAP_PROD_CATG,
         CAP_CAFGEN_FLAG,
         CAP_APPL_CODE,
         CAP_FIRSTTIME_TOPUP,
         CAP_MBR_NUMB,
         CAP_PROD_CODE,
         CAP_CARD_TYPE,
         CAP_PROXY_NUMBER,
         CAP_ACCT_NO,
         CAP_STARTERCARD_FLAG, --Modified by srinivasu on 20 feb 2012 for Stater card issuance
         cap_prfl_code, --Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
         cap_cust_code   --Added for FSS-1961(Melissa)
     INTO V_CAP_CARD_STAT,
         V_CAP_PROD_CATG,
         V_CAP_CAFGEN_FLAG,
         V_APPL_CODE,
         V_FIRSTTIME_TOPUP,
         V_MBRNUMB,
         V_PROD_CODE,
         V_CARD_TYPE,
         V_PROXUNUMBER,
         V_ACCT_NUMBER,
         V_CARDTYPE_FLAG, --Modified by srinivasu on 20 feb 2012 for Stater card issuance
         v_prfl_code, --Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
         v_cust_code   --Added for FSS-1961(Melissa)
     FROM CMS_APPL_PAN
    WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = p_mbr_numb
         AND CAP_INST_CODE = P_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Invalid Card number ' || V_HASH_PAN;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Error while selecting card number ' || V_HASH_PAN;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  
  --Sn check the min and max limit for topup
  --Moved this block from bottom to top due to product category attribute fetching required
        BEGIN
          SELECT CPC_RELOADABLE_FLAG,CPC_PROD_DENOM, CPC_PDENOM_MIN, CPC_PDENOM_MAX,
          CPC_PDENOM_FIX,CPC_PROFILE_CODE,NVL(CPC_BYPASS_LOADCHECK,'N')
          INTO V_VARPRODFLAG,v_cpc_prod_deno, v_cpc_pden_min, v_cpc_pden_max,
          v_cpc_pden_fix,v_profile_code,V_BYPASS_LOADCHECK
          FROM cms_prod_cattype
          WHERE cpc_prod_code = v_prod_code
          AND cpc_card_type = V_CARD_TYPE
          AND cpc_inst_code = p_instcode;
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
          v_respcode := '12';
          P_ERRMSG :=
          'No data for this Product code and category type'
          || v_prod_code;
        RAISE exp_main_reject_record;
        WHEN OTHERS
        THEN
          v_respcode := '12';
          P_ERRMSG :=
          'Error while selecting data from CMS_PROD_CATTYPE for Product code'
          || v_prod_code
          || SQLERRM;
        RAISE exp_main_reject_record;
        END;

  --En select Pan detail
  
  
  
  IF V_BYPASS_LOADCHECK <> 'Y' THEN

  IF v_cardtype_flag = 'N' AND v_firsttime_topup = 'N' THEN
      v_respcode := '8';
      p_errmsg   := 'Topup is applicable only after initial load for this acctno ' ||v_hash_pan ;
     RAISE exp_main_reject_record;
  END IF;
  
  END IF;

--Sn added duplicate rrn check.
    begin
        SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
        INTO V_DUPCHK_CARDSTAT, V_DUPCHK_ACCTBAL
        from(SELECT CARDSTATUS, ACCT_BALANCE   FROM VMSCMS.TRANSACTIONLOG   --Added for VMS-5739/FSP-991
                WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
                DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                and ACCT_BALANCE is not null
                order by add_ins_date desc)
        where rownum=1;
		  IF SQL%ROWCOUNT = 0 THEN
		     SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
        INTO V_DUPCHK_CARDSTAT, V_DUPCHK_ACCTBAL
        from(SELECT CARDSTATUS, ACCT_BALANCE   FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST   --Added for VMS-5739/FSP-991
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
            V_RESPCODE := '21';
            P_ERRMSG   := 'Error while selecting card status and acct balance ' || substr(sqlerrm,1,200);
            RAISE EXP_MAIN_REJECT_RECORD;
    end;

    if V_DUPCHK_COUNT =1 then
        BEGIN
            SELECT CAM_ACCT_BAL
            INTO V_ACCT_BALANCE
            FROM CMS_ACCT_MAST
            --Sn Modified during Transactionlog Functional Removal Phase-II changes
            WHERE CAM_ACCT_NO = V_ACCT_NUMBER
            /*(SELECT CAP_ACCT_NO  FROM CMS_APPL_PAN
                                WHERE CAP_PAN_CODE = V_HASH_PAN
                                AND CAP_MBR_NUMB = P_MBR_NUMB
                                AND CAP_INST_CODE = P_INSTCODE) */AND
             --En Modified during Transactionlog Functional Removal Phase-II changes                    
            CAM_INST_CODE = P_INSTCODE;
        EXCEPTION
            WHEN OTHERS THEN
                V_RESPCODE := '12';
                P_ERRMSG   := 'Error while selecting acct balance ' ||substr(sqlerrm,1,200);
                RAISE EXP_MAIN_REJECT_RECORD;
        END;

        V_DUPCHK_COUNT:=0;

        if V_DUPCHK_CARDSTAT= V_CAP_CARD_STAT and V_DUPCHK_ACCTBAL=V_ACCT_BALANCE then
            V_DUPCHK_COUNT:=1;
            V_RESPCODE := '22';
            P_ERRMSG   := 'Duplicate Incomm Reference Number' ||P_RRN;
            RAISE EXP_DUPLICATE_REQUEST;
        end if;
    end if;
--En added duplicate rrn check.



  /*Check For Stater Card
  */
  --Modified by srinivasu on 20 feb 2012 for Stater card issuance
  --Begin

  /* Commented by sivapragasam M on 12-06-2012,card status checks and expiry date check done inside sp_status_check_gpr, and
  if we check here it will not allow transaction w.r.to GPR Card Status configuration */

  /* if V_CAP_CARD_STAT = 0 then

      IF V_CARDTYPE_FLAG <> 'Y' THEN
           V_RESPCODE := '8';
           P_ERRMSG   := 'INVALID CARD STAT';
            RAISE EXP_MAIN_REJECT_RECORD;
        END IF;
  END IF;*/

--ST:Added for serial number changes on 29/10/14
  IF P_SERIAL_NUMBER IS NOT NULL THEN    
    BEGIN
        select count(1) INTO V_SP_COUNT
        from CMS_SPILSERIAL_LOGGING 
        where CSL_INST_CODE=P_INSTCODE
        and CSL_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL and  CSL_TXN_CODE=P_TXN_CODE
        and CSL_MSG_TYPE=P_MSG and CSL_SERIAL_NUMBER=P_SERIAL_NUMBER AND CSL_RESPONSE_CODE='00';
        
        IF V_SP_COUNT > 0 THEN
         V_RESPCODE := '215';
         P_ERRMSG  := 'Duplicate Request';
         RAISE EXP_MAIN_REJECT_RECORD;             
        END IF;
        
      EXCEPTION      
       WHEN EXP_MAIN_REJECT_RECORD THEN
         RAISE;
       WHEN OTHERS THEN
         V_RESPCODE := '21';
         P_ERRMSG  := 'Error while validating serial number '||substr(sqlerrm,1,200);
         RAISE EXP_MAIN_REJECT_RECORD;      
    END;  
  END IF;
  --EMD:Added for serial number changes on 29/10/14
     
  --Sn Commented for Transactionlog Functional Removal Phase-II changes
  /*BEGIN

    IF V_CARDTYPE_FLAG = 'Y' THEN

     IF V_CAP_CARD_STAT = 1 THEN

       BEGIN

        SELECT COUNT(*), GPRCARDAPPLICATIONNO
          INTO V_TRANCOUNT, V_APPLNO
          FROM TRANSACTIONLOG
         WHERE RESPONSE_CODE = '00'
         AND (
              (TXN_CODE = '03' AND DELIVERY_CHANNEL in  ('03', '06')) or  -- Added on 25-Mar-2013 for defect 0010608
              (TXN_CODE in ('04','24') and DELIVERY_CHANNEL = '03')       -- Added txn code ''04' added on 28-Mar-2013 Defect 0010564
             or (TXN_CODE in ('68') and DELIVERY_CHANNEL = '04') --Added for JH 3011
             )
         AND CUSTOMER_STARTER_CARD_NO = V_ENCR_PAN
         AND INSTCODE = P_INSTCODE
         GROUP BY GPRCARDAPPLICATIONNO;

       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_TRANCOUNT := 0;
        WHEN EXP_DUPLICATE_REQUEST THEN
        RAISE;
       WHEN EXP_MAIN_REJECT_RECORD THEN
        RAISE;
        WHEN OTHERS THEN
          V_RESPCODE := '21';
          P_ERRMSG   := 'EXCEPTION OCCURED WHILE SELECTING DETAILS FROM TRANSACTIONLOG';
          RAISE EXP_MAIN_REJECT_RECORD;
       END;

     END IF;

    END IF;

  END;*/
  --En Commented for Transactionlog Functional Removal Phase-II changes
  --End

  --Sn check the min and max limit for topup
   
              
      IF V_VARPRODFLAG = 'Y' THEN
        IF v_cpc_prod_deno = 1
        THEN
          IF V_TRAN_AMT NOT BETWEEN v_cpc_pden_min AND v_cpc_pden_max
          THEN
          v_respcode := '43';
          P_ERRMSG := 'Invalid Amount';
          RAISE exp_main_reject_record;
        END IF;
        ELSIF v_cpc_prod_deno = 2
        THEN
          IF V_TRAN_AMT <> v_cpc_pden_fix
          THEN
            v_respcode := '43';
            P_ERRMSG := 'Invalid Amount';
            RAISE exp_main_reject_record;
          END IF;
        ELSIF v_cpc_prod_deno = 3
        THEN
          SELECT COUNT (*)
          INTO v_count
          FROM VMS_PRODCAT_DENO_MAST
          WHERE VPD_INST_CODE = p_instcode
          AND VPD_PROD_CODE = v_prod_code
          AND VPD_CARD_TYPE = V_CARD_TYPE
          AND VPD_PDEN_VAL = V_TRAN_AMT;
        
          IF v_count = 0
          THEN
            v_respcode := '43';
            P_ERRMSG := 'Invalid Amount';
            RAISE exp_main_reject_record;
          END IF;
      END IF;
    
    else
     V_RESPCODE := '17';
     --P_ERRMSG   := 'Top up is not applicable on this card number ' || commented for FSS-2320
          --      P_PANNO;
        P_ERRMSG   := 'Top up is not applicable on this card number ' ||V_HASH_PAN;
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
--  EXCEPTION
--    WHEN EXP_DUPLICATE_REQUEST THEN
--        RAISE;
--    WHEN EXP_MAIN_REJECT_RECORD THEN
--     RAISE;
--    WHEN NO_DATA_FOUND THEN
--     V_RESPCODE := '21';
--    -- P_ERRMSG   := 'Card type (fixed/variable ) not defined for the card ' ||
--      --          P_PANNO; commented for FSS-2320
--       P_ERRMSG   := 'Card type (fixed/variable ) not defined for the card ' ||V_HASH_PAN;
--     RAISE EXP_MAIN_REJECT_RECORD;
--    WHEN OTHERS THEN
--     V_RESPCODE := '21';
--   --  P_ERRMSG   := 'Error while selecting card number ' || P_PANNO; commented for FSS-2320
--    P_ERRMSG   := 'Error while selecting card number ' ||V_HASH_PAN ;
--     RAISE EXP_MAIN_REJECT_RECORD;
--  END;

  --Sn - Modified by MageshKumar.S on 05-06-2013 for Defect Id:MVHOST-447

  --Modified by srinivasu on 20 feb 2012 for Stater card issuance

 -- BEGIN

    --IF V_CARDTYPE_FLAG = 'Y' THEN

     BEGIN
       SELECT --NVL(CPC_STARTER_MAXLOAD, 0),
            --NVL(CPC_STARTER_MINLOAD, 0),
            CPC_STARTERGPR_ISSUE, NVL(cpc_redemption_delay_flag,'N')
        INTO --V_STATERMAXLOAD, V_STATERMINLOAD,
        V_STATERISSUSETYPE, v_redmption_delay_flag
        FROM CMS_PROD_CATTYPE
        WHERE CPC_PROD_CODE = V_PROD_CODE AND CPC_CARD_TYPE = V_CARD_TYPE and cpc_inst_code = P_INSTCODE;

     /*  IF V_STATERMAXLOAD = 0 THEN -- Sn commented by MageshKumar.S on 05-06-2013 for Defect Id:MVHOST-447
        V_RESPCODE := '21';
        P_ERRMSG   := ' Max load is not defined for the Stater prod cat type ';
        RAISE EXP_MAIN_REJECT_RECORD;

       END IF;

       IF V_STATERMAXLOAD = 0 THEN
        V_RESPCODE := '21';
        P_ERRMSG   := 'Minimum load is not defined for the prod cat type ';
        RAISE EXP_MAIN_REJECT_RECORD;

       END IF;

       IF V_STATERMAXLOAD = 0 THEN
        V_RESPCODE := '21';
        P_ERRMSG   := 'Stater Card Issue type  is not defined for the prod cat type ';
        RAISE EXP_MAIN_REJECT_RECORD;

       END IF; */ -- En commented by MageshKumar.S on 05-06-2013 for Defect Id:MVHOST-447

     EXCEPTION
--    WHEN EXP_DUPLICATE_REQUEST THEN
--        RAISE;
       WHEN NO_DATA_FOUND THEN
        V_RESPCODE := '21';
        --P_ERRMSG   := 'Minimum and Max load is not defined for the prod cat type ';
        P_ERRMSG   := 'Stater Card Issue type is not defined for the prod cat type';
        RAISE EXP_MAIN_REJECT_RECORD;
--     WHEN EXP_MAIN_REJECT_RECORD THEN
--        RAISE;
       WHEN OTHERS THEN
        V_RESPCODE := '21';
       -- P_ERRMSG   := 'Error while selecting Minimum and Max load  for the prod cat type';
        P_ERRMSG   := 'Error while selecting Stater Card Issue type is not defined for the prod cat type';
        RAISE EXP_MAIN_REJECT_RECORD;

     END;
   -- END IF;

 -- END;
  --End

-- En commented by MageshKumar.S on 05-06-2013 for Defect Id:MVHOST-447

  /*Modified by srinivasu on 20 feb 2012 for Stater card issuance
  If stater card first load transaction through spl load so noo need
  to check below caondition for stater card
  */
--This check moved immediate after cms_appl_pan query
--  IF V_CARDTYPE_FLAG <> 'Y' THEN
--    --En  select variable type detail
--    --Sn Check initial load
--    IF V_FIRSTTIME_TOPUP = 'N' THEN
--     V_RESPCODE := '8'; --Modified for FSS-1691
--   --  P_ERRMSG   := 'Topup is applicable only after initial load for this acctno ' ||
--     --           P_PANNO;  commented for FSS-2320
--      P_ERRMSG   := 'Topup is applicable only after initial load for this acctno ' ||V_HASH_PAN ;
--     RAISE EXP_MAIN_REJECT_RECORD;
--    END IF;
--  END IF;

  BEGIN
    V_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8), 'yyyymmdd');
  EXCEPTION
     WHEN EXP_MAIN_REJECT_RECORD THEN
        RAISE;
    WHEN EXP_DUPLICATE_REQUEST THEN
        RAISE;
    WHEN OTHERS THEN
     V_RESPCODE := '45'; -- Server Declined -220509
     P_ERRMSG   := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  BEGIN
    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8) || ' ' ||
                      SUBSTR(TRIM(P_TRANTIME), 1, 10),
                      'yyyymmdd hh24:mi:ss');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '32'; -- Server Declined -220509
     P_ERRMSG   := 'Problem while converting transaction time ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --Sn Getting the Currency cod efor the Currency name from Request

  BEGIN

    SELECT GCM_CURR_CODE
     INTO V_CURRCODE
     FROM GEN_CURR_MAST
    WHERE GCM_CURR_NAME = P_CURRCODE AND GCM_INST_CODE = P_INSTCODE;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN

     V_RESPCODE := '65';
     P_ERRMSG   := 'Invalid Currency Code';
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN

     V_RESPCODE := '21';
     P_ERRMSG   := 'Error while selecting the currency code for ' ||
                P_CURRCODE || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;

  END;

  --En Getting the Currency cod efor the Currency name from Request

  BEGIN
    IF (P_AMOUNT >= 0) THEN
     V_TRAN_AMT := P_AMOUNT;

     BEGIN
       SP_CONVERT_CURR(P_INSTCODE,
                    V_CURRCODE,
                    P_PANNO,
                    P_AMOUNT,
                    V_TRAN_DATE,
                    V_TRAN_AMT,
                    V_CARD_CURR,
                    P_ERRMSG,
                    V_PROD_CODE,
                    V_CARD_TYPE);

       IF P_ERRMSG <> 'OK' THEN
        V_RESPCODE := '21';
        RAISE EXP_MAIN_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN EXP_MAIN_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
        V_RESPCODE := '69'; -- Server Declined -220509
        P_ERRMSG   := 'Error from currency conversion ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
     END;
    ELSE
     -- If transaction Amount is zero - Invalid Amount -220509
     V_RESPCODE := '43';
     P_ERRMSG   := 'INVALID AMOUNT';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;

--Sn Added on 02-Apr-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
  IF P_TXN_CODE in ('21') then

            BEGIN
               SELECT ctm_tran_type,ctm_prfl_flag
                 INTO v_tran_type,v_prfl_flag
                 FROM cms_transaction_mast
                WHERE ctm_tran_code = '22'
                  AND ctm_delivery_channel = p_delivery_channel
                  AND ctm_inst_code = p_instcode;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_respcode := '12';                            --Ineligible Transaction
                  P_ERRMSG :=
                        'Transflag  not defined for txn code '
                     || p_txn_code
                     || ' and delivery channel '
                     || p_delivery_channel;
                  RAISE exp_main_reject_record;
               WHEN OTHERS
               THEN
                  v_respcode := '21';                            --Ineligible Transaction
                  P_ERRMSG := 'Error while selecting transaction details';
                  RAISE exp_main_reject_record;
            END;

  END IF;
  --En Added on 02-Apr-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
  --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
  IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y' THEN
        BEGIN
              pkg_limits_check.sp_limits_check (v_hash_pan,
                                                NULL,
                                                NULL,
                                                NULL, --p_mcc_code,
                                                --p_txn_code,
                                                case when p_txn_code in('22') then
                                                 p_txn_code
                                                when p_txn_code ='21' then '22' end,
                                                v_tran_type,
                                                NULL, --p_international_ind,
                                                NULL,  --p_pos_verfication,
                                                p_instcode,
                                                NULL,
                                                v_prfl_code,
                                                v_tran_amt,
                                                p_delivery_channel,
                                                v_comb_hash,
                                                v_respcode,
                                                p_errmsg
                                               );
           IF p_errmsg <> 'OK' THEN
              RAISE exp_main_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_main_reject_record THEN
              RAISE;
           WHEN OTHERS    THEN
              v_respcode := '21';
              p_errmsg :='Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_main_reject_record;
        END;
  END IF;
  --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)

  --Sn Check the Minimum,Maximum topup limit

  /*Modified by srinivasu on 20 feb 2012 for Stater card issuance
  incase of  Stater card product category  level configuration for max and minmum load limit ne need to check for below
  things
  */

  --IF V_CARDTYPE_FLAG <> 'Y' THEN -- commented by MageshKumar.S for Defect Id:MVHOST-447 since this condition for both 'Y' & 'N'
--Sn commented for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
 /*   BEGIN
     SELECT COUNT(1)
       INTO V_MIN_MAX_LIMIT
       FROM CMS_BIN_PARAM A, CMS_BIN_PARAM B
      WHERE A.CBP_PROFILE_CODE = V_PROFILE_CODE AND
           A.CBP_PROFILE_CODE = B.CBP_PROFILE_CODE AND
           A.CBP_PARAM_TYPE = 'Topup Parameter' AND
           A.CBP_PARAM_TYPE = B.CBP_PARAM_TYPE AND
           A.CBP_INST_CODE = P_INSTCODE AND
           A.CBP_INST_CODE = B.CBP_INST_CODE AND
           A.CBP_PARAM_NAME = 'Min Topup Limit' AND
           B.CBP_PARAM_NAME = 'Max Topup Limit' AND
           V_TRAN_AMT BETWEEN A.CBP_PARAM_VALUE AND B.CBP_PARAM_VALUE;

     IF V_MIN_MAX_LIMIT = 0 THEN
       SELECT A.CBP_PARAM_VALUE, B.CBP_PARAM_VALUE
        INTO V_MIN_LIMIT, V_MAX_LIMIT
        FROM CMS_BIN_PARAM A, CMS_BIN_PARAM B
        WHERE A.CBP_PROFILE_CODE = V_PROFILE_CODE AND
            A.CBP_PROFILE_CODE = B.CBP_PROFILE_CODE AND
            A.CBP_PARAM_TYPE = 'Topup Parameter' AND
            A.CBP_PARAM_TYPE = B.CBP_PARAM_TYPE AND
            A.CBP_INST_CODE = P_INSTCODE AND
            A.CBP_INST_CODE = B.CBP_INST_CODE AND
            A.CBP_PARAM_NAME = 'Min Topup Limit' AND
            B.CBP_PARAM_NAME = 'Max Topup Limit';

       P_ERRMSG   := 'Topup Limit Exceeded.Limit is between '  ||
                  V_MIN_LIMIT  ||  ' TO '  ||  V_MAX_LIMIT;
       V_RESPCODE := '34';
       RAISE EXP_MAIN_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_MAIN_REJECT_RECORD THEN
       RAISE;
    WHEN EXP_DUPLICATE_REQUEST THEN
        RAISE;
     WHEN NO_DATA_FOUND THEN
       V_RESPCODE := '21';
       P_ERRMSG   := 'Topup Amount is out of range ' || V_MIN_LIMIT ||
                  ' TO ' || V_MAX_LIMIT;
       RAISE EXP_MAIN_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESPCODE := '21';
       P_ERRMSG   := 'Topup Amount is out of range ' || V_MIN_LIMIT ||
                  ' TO ' || V_MAX_LIMIT;
       RAISE EXP_MAIN_REJECT_RECORD;
    END;
 -- END IF; -- commented by MageshKumar.S for Defect Id:MVHOST-447 since this condition for both 'Y' & 'N'

  --En Check the Minimum,Maximum topup limit

  --Sn Check The transaction availibillity in table
  BEGIN
    SELECT A.CBP_PARAM_VALUE, B.CBP_PARAM_VALUE
     INTO V_TOPUP_FREQ, V_TOPUP_FREQ_PERIOD
     FROM CMS_BIN_PARAM A, CMS_BIN_PARAM B
    WHERE A.CBP_PROFILE_CODE = V_PROFILE_CODE AND
         A.CBP_PROFILE_CODE = B.CBP_PROFILE_CODE AND
         A.CBP_PARAM_TYPE = 'Topup Parameter' AND
         A.CBP_PARAM_TYPE = B.CBP_PARAM_TYPE AND
         A.CBP_INST_CODE = P_INSTCODE AND
         A.CBP_INST_CODE = B.CBP_INST_CODE AND
         A.CBP_PARAM_NAME = 'Topup Freq Amount' AND
         B.CBP_PARAM_NAME = 'Topup Freq Period';
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;
     WHEN EXP_DUPLICATE_REQUEST THEN
        RAISE;
   WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Freq and period is not defined ' || V_TOPUP_FREQ;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Freq and period is not defined  ' ||
                V_TOPUP_FREQ_PERIOD;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
IF P_TXN_CODE <> '21' THEN --Added for JIRA defect FSS-814

  BEGIN
    SELECT COUNT(1)
     INTO V_ACCT_TXN_DTL
     FROM CMS_TOPUPTRANS_COUNT
    WHERE CTC_PAN_CODE = V_HASH_PAN AND CTC_INST_CODE = P_INSTCODE;

    IF V_ACCT_TXN_DTL = 0 THEN
     INSERT INTO CMS_TOPUPTRANS_COUNT
       (CTC_INST_CODE,
        CTC_PAN_CODE,
        CTC_TOTAVAIL_DAYS,
        CTC_INS_USER,
        CTC_INS_DATE,
        CTC_LUPD_USER,
        CTC_LUPD_DATE,
        CTC_PAN_CODE_ENCR)
     VALUES
       (P_INSTCODE,
        V_HASH_PAN,
        0,
        P_LUPDUSER,
        SYSDATE,
        P_LUPDUSER,
        SYSDATE,
        V_ENCR_PAN);
    END IF;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;
    WHEN EXP_DUPLICATE_REQUEST THEN
        RAISE;
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Topup Transaction Days are not specifid  ' ||
                V_ACCT_TXN_DTL;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Topup Transaction Days are not specifid  ' ||
                V_ACCT_TXN_DTL;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  BEGIN
    --Sn Week end Process Call
    IF V_TOPUP_FREQ_PERIOD = 'Week' THEN
     SELECT NEXT_DAY(TRUNC(CTC_LUPD_DATE), 'SUNDAY')
       INTO V_END_DAY_UPDATE
       FROM CMS_TOPUPTRANS_COUNT
      WHERE CTC_PAN_CODE = V_HASH_PAN AND CTC_INST_CODE = P_INSTCODE;

     IF TRUNC(SYSDATE) > V_END_DAY_UPDATE - 1 THEN
       UPDATE CMS_TOPUPTRANS_COUNT
         SET CTC_TOTAVAIL_DAYS = 0, CTC_LUPD_DATE = SYSDATE
        WHERE CTC_PAN_CODE = V_HASH_PAN AND CTC_INST_CODE = P_INSTCODE;
     END IF;

    END IF;

    --------THINK ON THAT----------------
    --Sn Month end Process Call
    IF V_TOPUP_FREQ_PERIOD = 'Month' THEN
     SELECT LAST_DAY(TRUNC(CTC_LUPD_DATE))
       INTO V_END_DAY_UPDATE
       FROM CMS_TOPUPTRANS_COUNT
      WHERE CTC_PAN_CODE = V_HASH_PAN AND CTC_INST_CODE = P_INSTCODE;

     IF TRUNC(SYSDATE) > (V_END_DAY_UPDATE) THEN
       UPDATE CMS_TOPUPTRANS_COUNT
         SET CTC_TOTAVAIL_DAYS = 0, CTC_LUPD_DATE = SYSDATE
        WHERE CTC_PAN_CODE = V_HASH_PAN AND CTC_INST_CODE = P_INSTCODE;
     END IF;
    END IF;

    --Sn Year end Process Call

    IF V_TOPUP_FREQ_PERIOD = 'Year' THEN
     SELECT ADD_MONTHS(TRUNC(CTC_LUPD_DATE, 'YEAR'), 12) - 1
       INTO V_END_DAY_UPDATE
       FROM CMS_TOPUPTRANS_COUNT
      WHERE CTC_PAN_CODE = V_HASH_PAN AND CTC_INST_CODE = P_INSTCODE;
     IF TRUNC(SYSDATE) > V_END_DAY_UPDATE THEN
       UPDATE CMS_TOPUPTRANS_COUNT
         SET CTC_TOTAVAIL_DAYS = 0, CTC_LUPD_DATE = SYSDATE
        WHERE CTC_PAN_CODE = V_HASH_PAN AND CTC_INST_CODE = P_INSTCODE;
     END IF;
    END IF;
  EXCEPTION
     WHEN EXP_MAIN_REJECT_RECORD THEN
        RAISE;
    WHEN EXP_DUPLICATE_REQUEST THEN
        RAISE;
    WHEN OTHERS THEN
     P_ERRMSG   := 'Error while Updating records into cms_topuptrans_count' ||
                SUBSTR(SQLERRM, 1, 200);
     V_RESPCODE := '21';
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En Last Day Process Call

  BEGIN
    SELECT CTC_TOTAVAIL_DAYS
     INTO V_ACCT_TXN_DTL_1
     FROM CMS_TOPUPTRANS_COUNT
    WHERE CTC_PAN_CODE = V_HASH_PAN AND CTC_INST_CODE = P_INSTCODE;

    IF V_ACCT_TXN_DTL_1 >= V_TOPUP_FREQ THEN
     V_RESPCODE := '50';--Modified for JIRA defect FSS-814
     P_ERRMSG   := 'Maximum Recharges Exceeded';  --modified for 9612
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;
    WHEN EXP_DUPLICATE_REQUEST THEN
        RAISE;
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Topup Transaction Days are not specifid  ' ||
                V_ACCT_TXN_DTL_1;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Topup Transaction Days are not specifid  ' ||
                V_ACCT_TXN_DTL_1;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  -- Sn Transaction availdays Count update
  BEGIN
    UPDATE CMS_TOPUPTRANS_COUNT
      SET CTC_TOTAVAIL_DAYS = CTC_TOTAVAIL_DAYS + 1
    WHERE CTC_PAN_CODE = V_HASH_PAN AND CTC_INST_CODE = P_INSTCODE;
  EXCEPTION
     WHEN EXP_MAIN_REJECT_RECORD THEN
        RAISE;
    WHEN EXP_DUPLICATE_REQUEST THEN
        RAISE;
    WHEN OTHERS THEN
     P_ERRMSG   := 'Error while inserting records into card support master' ||
                SUBSTR(SQLERRM, 1, 200);
     V_RESPCODE := '21';
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
END IF;--Added for JIRA defect FSS-814

  -- En Transaction availdays Count update

  BEGIN

    IF (P_TXN_CODE = '21') THEN
     V_TRANCDE := '22';
    ELSE
     V_TRANCDE := P_TXN_CODE;
    END IF;

    SELECT DECODE(A.TOT_SUM - B.RVSL_SUM,
               '',
               A.TOT_SUM,
               A.TOT_SUM - B.RVSL_SUM)
     INTO V_TOTALTOPUPNAMOUNT
     FROM (SELECT CUSTOMER_CARD_NO, SUM(TOTAL_AMOUNT) TOT_SUM
            FROM TRANSACTIONLOG
           WHERE TXN_CODE = V_TRANCDE AND MSGTYPE NOT IN ('0400') AND
                CUSTOMER_CARD_NO = V_HASH_PAN AND
                BUSINESS_DATE =
                TO_CHAR(TO_DATE(P_TRANDATE, 'yyyymmdd'), 'yyyymmdd') AND
                RESPONSE_CODE = '00'
           GROUP BY CUSTOMER_CARD_NO) A,
         (SELECT CUSTOMER_CARD_NO, SUM(TOTAL_AMOUNT) RVSL_SUM
            FROM TRANSACTIONLOG
           WHERE MSGTYPE IN ('0400') AND TRAN_REVERSE_FLAG = 'Y' AND
                TXN_CODE = V_TRANCDE AND CUSTOMER_CARD_NO = V_HASH_PAN AND
                BUSINESS_DATE =
                TO_CHAR(TO_DATE(P_TRANDATE, 'yyyymmdd'), 'yyyymmdd') AND
                RESPONSE_CODE = '00'
           GROUP BY CUSTOMER_CARD_NO) B
    WHERE A.CUSTOMER_CARD_NO = B.CUSTOMER_CARD_NO(+);

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_TOTALTOPUPNAMOUNT := 0;

    WHEN EXP_DUPLICATE_REQUEST THEN
        RAISE;
     WHEN EXP_MAIN_REJECT_RECORD THEN
        RAISE;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Error While getting total topup amount' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;

  END;

  BEGIN

    SELECT CBP_PARAM_VALUE
     INTO V_MAXDAILYLOAD
     FROM CMS_BIN_PARAM
    WHERE CBP_PROFILE_CODE = V_PROFILE_CODE AND
         CBP_PARAM_TYPE = 'Topup Parameter' AND
         CBP_INST_CODE = P_INSTCODE AND CBP_PARAM_NAME = 'Max Daily Load';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN

     V_RESPCODE := '21';
     P_ERRMSG   := 'Maximum Daily Load is not specifid for the Profile ' ||
                V_PROFILE_CODE;
     RAISE EXP_MAIN_REJECT_RECORD;
     WHEN EXP_DUPLICATE_REQUEST THEN
        RAISE;
    WHEN EXP_MAIN_REJECT_RECORD THEN
        RAISE;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Error While selecting the Maximum Daily Load' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;

  END;



  --Modified by srinivasu on 20 feb 2012 for Stater card issuance
  --begin

  /*IF V_CARDTYPE_FLAG = 'Y' THEN --Sn commented by MageshKumar.S on 05-06-2013 for Defect Id:MVHOST-477

    BEGIN

     IF ((V_TOTALTOPUPNAMOUNT + V_TRAN_AMT) > V_STATERMAXLOAD) THEN

       V_RESPCODE := '66';
       P_ERRMSG   := 'Stater card Maximum Daily Load Limit Exceeded';
       RAISE EXP_MAIN_REJECT_RECORD;

     END IF;

    END;

    BEGIN

     IF V_TRAN_AMT < V_STATERMINLOAD THEN

       V_RESPCODE := '66';
       P_ERRMSG   := 'Lesser than the minimum load amount';
       RAISE EXP_MAIN_REJECT_RECORD;

     END IF;

    END;

  END IF;*/ --En commented by MageshKumar.S on 05-06-2013 for Defect Id:MVHOST-477
/*
  BEGIN
   -- IF V_CARDTYPE_FLAG = 'N' THEN -- commented by MageshKumar.S on 05-06-2013 for Defect Id:MVHOST-477

     IF ((V_TOTALTOPUPNAMOUNT + V_TRAN_AMT) > V_MAXDAILYLOAD) THEN

       V_RESPCODE := '66';
       P_ERRMSG   := 'Maximum Daily Load Limit Exceeded';
       RAISE EXP_MAIN_REJECT_RECORD;

     END IF;
  --  END IF; -- commented by MageshKumar.S on 05-06-2013 for Defect Id:MVHOST-477

  END;
*/
--En commented for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)

  --En Modified by MageshKumar.S on 05-06-2013 for MVHOST-477

  --------------Sn For Debit Card No need using authorization -----------------------------------
 -- IF V_CAP_PROD_CATG = 'P' THEN
    --Sn call to authorize txn
    BEGIN
     SP_AUTHORIZE_TXN_CMS_AUTH(P_INSTCODE,
                          P_MSG,
                          P_RRN,
                          P_DELIVERY_CHANNEL,
                          P_TERMINALID,
                          P_TXN_CODE,
                          P_TXN_MODE,
                          P_TRANDATE,
                          P_TRANTIME,
                          P_PANNO,
                          NULL,
                          P_AMOUNT,
                          P_MERCHANT_NAME,
                          NULL,
                          NULL,
                          V_CURRCODE,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          P_STAN, -- P_stan
                          P_MBR_NUMB, --Ins User
                          P_RVSL_CODE, --INS Date
                          V_TRAN_AMT,
                          V_TOPUP_AUTH_ID,
                          V_RESPCODE,
                          V_RESPMSG,
                          V_CAPTURE_DATE,
                          'Y',
		          'N',
			  'N',
                          nuLL,
                          p_merchant_ZIP);-- added for VMS-622 (redemption_delay zip code validation)

     IF V_RESPCODE <> '00' AND V_RESPMSG <> 'OK' THEN
       P_ERRMSG := V_RESPMSG;
       RAISE EXP_AUTH_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_AUTH_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       P_ERRMSG := 'Error from Card authorization' ||
                SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_MAIN_REJECT_RECORD;
    END;
 -- END IF;

  --En call to authorize txn

  --Sn create a record in pan spprt
  BEGIN
    SELECT CSR_SPPRT_RSNCODE
     INTO V_RESONCODE
     FROM CMS_SPPRT_REASONS
    WHERE CSR_SPPRT_KEY = 'TOP UP' AND CSR_INST_CODE = P_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     P_ERRMSG   := 'Top up reason code is present in master';
     V_RESPCODE := '21';
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     P_ERRMSG   := 'Error while selecting reason code from master' ||
                SUBSTR(SQLERRM, 1, 200);
     V_RESPCODE := '21';
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  BEGIN
    INSERT INTO CMS_PAN_SPPRT
     (CPS_INST_CODE,
      CPS_PAN_CODE,
      CPS_MBR_NUMB,
      CPS_PROD_CATG,
      CPS_SPPRT_KEY,
      CPS_SPPRT_RSNCODE,
      CPS_FUNC_REMARK,
      CPS_INS_USER,
      CPS_LUPD_USER,
      CPS_CMD_MODE,
      CPS_PAN_CODE_ENCR)
    VALUES
     (P_INSTCODE,
      V_HASH_PAN,
      V_MBRNUMB,
      V_CAP_PROD_CATG,
      'TOP',
      V_RESONCODE,
      V_TOPUPREMRK,
      P_LUPDUSER,
      P_LUPDUSER,
      0,
      V_ENCR_PAN);
  EXCEPTION
    WHEN OTHERS THEN
     P_ERRMSG   := 'Error while inserting records into card support master' ||
                SUBSTR(SQLERRM, 1, 200);
     V_RESPCODE := '21';
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En create a record in pan spprt

  --Sn Last Day Process Call

  V_RESPCODE := 1; --Response code for successful txn

  --Sn select response code and insert record into txn log dtl
  BEGIN
    P_ERRMSG    := P_ERRMSG;
    P_RESP_CODE := V_RESPCODE;

    -- Assign the response code to the out parameter
    SELECT CMS_ISO_RESPCDE
     INTO P_RESP_CODE
     FROM CMS_RESPONSE_MAST
    WHERE CMS_INST_CODE = P_INSTCODE AND
         CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
         CMS_RESPONSE_ID = V_RESPCODE;
  EXCEPTION
    WHEN OTHERS THEN
     P_ERRMSG    := 'Problem while selecting data from response master ' ||
                 V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
     P_RESP_CODE := '69';
     ---ISO MESSAGE FOR DATABASE ERROR Server Declined
     ROLLBACK;
  END;

  --En select response code and insert record into txn log dtl
if  P_TXN_CODE = '22' then
  IF P_ERRMSG = 'OK' THEN
    BEGIN
     IF V_CARDTYPE_FLAG = 'Y' AND  V_CAP_CARD_STAT = 1 THEN --V_TRANCOUNT <> 0 THEN  -- Modified for Transactionlog Functional Removal Phase-II changes

       SELECT COUNT(*)
        INTO V_COUNT
        FROM CMS_APPL_PAN
        WHERE cap_inst_code=p_instcode AND CAP_ACCT_NO = V_ACCT_NUMBER AND CAP_STARTERCARD_FLAG = 'N';

       IF V_COUNT = 0 THEN

       --Sn Modified by MageshKumar.S on 20-MAR-2013 for GPR card Generation. Update application status as 'A' in appl_mast

         IF V_STATERISSUSETYPE ='M' --SN: Added on 29-Mar-2013 for Defect 0010608
         THEN

           UPDATE CMS_APPL_MAST
           SET CAM_APPL_STAT = 'A'
           WHERE CAM_APPL_CODE = V_APPL_CODE --V_APPLNO -- Modified for Transactionlog Functional Removal Phase-II changes
           AND   CAM_INST_CODE = P_INSTCODE;


       /*  END IF;                --EN: Added on 29-Mar-2013 for Defect 0010608

       --En Modified by MageshKumar.S on 20-MAR-2013 for GPR card Generation. Update application status as 'A' in appl_mast
        BEGIN

         SELECT C.CCI_KYC_FLAG, COUNT(A.CAM_APPL_STAT)
          INTO V_KYC_FLAG, V_APPLSTAT_COUNT
          FROM CMS_CAF_INFO_ENTRY C, CMS_APPL_MAST A
         WHERE C.CCI_APPL_CODE = to_char(V_APPL_CODE) --V_APPLNO -- Modified for Transactionlog Functional Removal Phase-II changes
         AND A.CAM_APPL_CODE = C.CCI_APPL_CODE AND
              A.CAM_APPL_STAT = 'A' AND A.CAM_INST_CODE = P_INSTCODE AND
              A.CAM_INST_CODE = C.CCI_INST_CODE
         GROUP BY C.CCI_KYC_FLAG;
         
          EXCEPTION
    WHEN NO_DATA_FOUND THEN
    if V_STATERISSUSETYPE <> 'N' Then
    
     P_ERRMSG   := 'Top up reason code is present in master';
     V_RESPCODE := '21';
     RAISE EXP_MAIN_REJECT_RECORD;
     End if;
      WHEN OTHERS THEN
     P_ERRMSG    := 'Problem while selecting data from caf info' ||
                 V_RESPCODE || SUBSTR(SQLERRM, 1, 200);
     P_RESP_CODE := '69';
     RAISE EXP_MAIN_REJECT_RECORD;
    END;

         --GENERATE PAN NUMBER FOR STATER CARD MANUAL FOR MANUAL TRANSACTION
         --KYC VERIFIED AT THE TIME OF GPR CARD REGISTRATION

         -- IF V_KYC_FLAG IN ('Y','P','O') THEN --Modified by MageshKumar.S on 20-MAR-2013 for GPR card issuance of KYC ID,IQ and Override Cases -- Commneted on 21-Mar-2013

          IF V_APPLSTAT_COUNT <> 0 THEN
            -- Need to Chec Card issuance type
            IF V_STATERISSUSETYPE = 'M' THEN*/

             BEGIN
               SP_GEN_PAN(P_INSTCODE,
                        V_APPL_CODE, --V_APPLNO -- Modified for Transactionlog Functional Removal Phase-II changes
                        1,
                        V_PANCODE,
                        V_PROCESSMSG,
                        V_RESPMSG);
            
             --Sn block moved from bottom to top for MVCAN-77 
             
          IF V_PROCESSMSG <> 'OK' THEN -- ADDED ON 07-05-2013
          V_RESPCODE := '21';

          P_ERRMSG := V_PROCESSMSG;  -- ADDED ON 07-05-2013
          RAISE EXP_AUTH_REJECT_RECORD;

        END IF;
        
        --En block moved from bottom to top for MVCAN-77
        
             EXCEPTION
             WHEN EXP_AUTH_REJECT_RECORD THEN
             RAISE;
               WHEN OTHERS THEN
                V_RESPCODE := '21';
                P_ERRMSG   := 'Error while calling SP_GEN_PAN ' ||
                            SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_MAIN_REJECT_RECORD;
             END;
             
             --AVQ Added for FSS-1961(Melissa)
              
            BEGIN
               SELECT fn_dmaps_main (cap_pan_code_encr)                    
                 INTO p_pan_number                     
                 FROM cms_appl_pan 
                WHERE cap_appl_code = V_APPL_CODE                
                  AND cap_inst_code = P_INSTCODE
                  AND cap_cust_code = v_cust_code
                  AND cap_startercard_flag = 'N';
              EXCEPTION
                 WHEN OTHERS
                 THEN
                    V_RESPCODE := '21';
                    P_ERRMSG := 'Error while selecting (gpr card)details from appl_pan :'
                       || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_MAIN_REJECT_RECORD;
            end;
            
                BEGIN
                    SP_LOGAVQSTATUS(
                          P_INSTCODE,
                          P_DELIVERY_CHANNEL,
                          p_pan_number,
                          V_PROD_CODE,
                          V_CUST_CODE,
                          V_RESPCODE,
                          p_errmsg,
                          V_CARD_TYPE
                          );
                  IF p_errmsg != 'OK' THEN
                     p_errmsg  := 'Exception while calling LOGAVQSTATUS-- ' || p_errmsg;
                     V_RESPCODE := '21';
                  RAISE EXP_MAIN_REJECT_RECORD;         
                  END IF;
                EXCEPTION WHEN EXP_MAIN_REJECT_RECORD
                THEN  RAISE;
                WHEN OTHERS THEN
                   p_errmsg  := 'Exception in LOGAVQSTATUS-- '  || SUBSTR (SQLERRM, 1, 200);
                   V_RESPCODE := '21';
                   RAISE EXP_MAIN_REJECT_RECORD;
              END;  
              --END Added for FSS-1961(Melissa)
             
            END IF;

          END IF;

         -- END IF; -- Commneted on 21-Mar-2013

       
       END IF;
     --END IF;
    EXCEPTION
     WHEN EXP_AUTH_REJECT_RECORD THEN
       RAISE;
    WHEN EXP_MAIN_REJECT_RECORD THEN
        RAISE;
     WHEN OTHERS THEN
       V_RESPCODE := '21';
       P_ERRMSG   := 'Error from Card authorization' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_MAIN_REJECT_RECORD;
    END;
  END IF;
  --IF errmsg is OK then balance amount will be returned
end if;
  IF P_ERRMSG = 'OK' THEN
    --Sn of Getting  the Acct Balannce
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =v_acct_number
           /*(SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
                 CAP_INST_CODE = P_INSTCODE) */AND
           CAM_INST_CODE = P_INSTCODE;
        --FOR UPDATE NOWAIT;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESPCODE := '14'; --Ineligible Transaction
       P_ERRMSG   := 'Invalid account ';
       RAISE EXP_MAIN_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESPCODE := '12';
       P_ERRMSG   := 'Error while selecting data from card Master for card number ' || SUBSTR(SQLERRM, 1, 200);
                 -- V_HASH_PAN;
       RAISE EXP_MAIN_REJECT_RECORD;
    END;

    --En of Getting  the Acct Balannce
    P_ACCT_BAL := V_Acct_Balance;

  End If;


 --SantoshP 12 JUL 13 : FSS-1146 : Block added to update  STORE_ID in transactionlog table
   Begin
     
	   --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_Trandate), 1, 8), 'yyyymmdd');
	
    IF (v_Retdate>v_Retperiod) THEN	              --Added for VMS-5739/FSP-991
	
       Update Transactionlog
         Set Store_Id = P_STORE_ID
         ,ACCT_BALANCE=V_ACCT_BALANCE      --Added For MANTIS ID-12422
         ,LEDGER_BALANCE=V_LEDGER_BALANCE
       Where Instcode = P_Instcode
        -- And Terminal_Id = P_Terminalid  -- commented for Mantis id:15747
         And Rrn = P_Rrn
         AND CUSTOMER_CARD_NO = V_HASH_PAN
         And Business_Date = P_Trandate
         AND TXN_CODE=p_txn_code
         AND delivery_channel = p_delivery_channel;
    ELSE
	
	     Update VMSCMS_HISTORY.TRANSACTIONLOG_HIST        --Added for VMS-5739/FSP-991
         Set Store_Id = P_STORE_ID
         ,ACCT_BALANCE=V_ACCT_BALANCE      --Added For MANTIS ID-12422
         ,LEDGER_BALANCE=V_LEDGER_BALANCE
       Where Instcode = P_Instcode
        -- And Terminal_Id = P_Terminalid  -- commented for Mantis id:15747
         And Rrn = P_Rrn
         AND CUSTOMER_CARD_NO = V_HASH_PAN
         And Business_Date = P_Trandate
         AND TXN_CODE=p_txn_code
         AND delivery_channel = p_delivery_channel;
		
	END IF;
	
    If Sql%Rowcount = 0 Then
       P_ERRMSG   := 'StoreId not updated in Transactionlog table'||P_Terminalid;
       V_RESPCODE := '21';
       Raise Exp_Main_Reject_Record;
     END IF;
   EXCEPTION
   WHEN Exp_Main_Reject_Record THEN
   RAISE;
       WHEN OTHERS THEN
        P_ERRMSG   := 'Error while Updating StoreId in Transactionlog table' ||
                    Substr(Sqlerrm, 1, 200);
        V_RESPCODE := '21';
        Raise Exp_Main_Reject_Record;
   END;

   --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
    IF p_txn_code='22' AND v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y' THEN
    BEGIN
          pkg_limits_check.sp_limitcnt_reset (p_instcode,
                                              v_hash_pan,
                                              v_tran_amt,
                                              v_comb_hash,
                                              v_respcode,
                                              p_errmsg
                                             );
       IF p_errmsg <> 'OK' THEN
          p_errmsg := 'From Procedure sp_limitcnt_reset' || p_errmsg;
          RAISE exp_main_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_main_reject_record THEN
          RAISE;
       WHEN OTHERS THEN
          v_respcode := '21';
          p_errmsg := 'Error from Limit Reset Count Process ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
    END;
    END IF;
    --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
   
   --Sn Added for FSS-4647
   IF v_txn_redmption_flag='Y' AND v_redmption_delay_flag='Y' THEN
        BEGIN
           vmsredemptiondelay.redemption_delay (v_acct_number,
                                p_rrn,
                                p_delivery_channel,
                                p_txn_code,
                                v_tran_amt,
                                v_prod_code,
                                v_card_type,
                                UPPER (p_merchant_name),
                                p_merchant_zip,-- added for VMS-622 (redemption_delay zip code validation)
                                p_errmsg,
                                'N',
                                p_merchant_id_in); --VMS-6499
            IF p_errmsg<>'OK' THEN
                 RAISE  exp_main_reject_record;
            END IF;                      
        EXCEPTION
           WHEN exp_main_reject_record THEN
             RAISE;
           WHEN OTHERS
           THEN
              p_errmsg :=
                 'Error while calling sp_log_delayed_load: '
                 || SUBSTR (SQLERRM, 1, 200);
              v_respcode := '21';
              RAISE exp_main_reject_record;
        END;
   END IF;
   --En Added for FSS-4647
   
    IF v_toggle_value = 'Y' THEN
   BEGIN
        sp_concurrent_check_logclear(v_hash_pan, p_delivery_channel, p_txn_code, p_errmsg);
        IF P_ERRMSG <> 'OK' THEN
           v_respcode         := '21';
           RAISE EXP_MAIN_REJECT_RECORD;
        END IF;
        EXCEPTION
        WHEN EXP_MAIN_REJECT_RECORD THEN
          RAISE;
        WHEN OTHERS THEN
          v_respcode := '12';
          p_errmsg  := 'Concurrent check clear failed' || SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
    END;
END IF;
   
--ST:Added for serial number changes on 29/10/14
    IF P_SERIAL_NUMBER IS NOT NULL THEN
      BEGIN
              SP_SPIL_SERIALNUMBER_LOGGING(             
                    p_instcode,
                    P_MSG ,                                               
                    P_DELIVERY_CHANNEL,                                               
                    P_TXN_CODE,
                    P_SERIAL_NUMBER,
                    V_TOPUP_AUTH_ID,
                    P_RESP_CODE,
                    V_HASH_PAN,
                    P_RRN,
                    systimestamp,
                    V_RESP_CDE,
                    V_RESP_MSG);
            
        IF V_RESP_CDE <> '00' OR V_RESP_MSG <> 'OK' THEN        
          v_respcode := '21';
          p_errmsg :=V_RESP_MSG;
          RAISE exp_main_reject_record;
        END IF;

       EXCEPTION      
        when exp_main_reject_record then
       raise;
         WHEN OTHERS THEN
          p_resp_code := '21';
          p_errmsg  := 'Error while calling SP_SPIL_SERIALNUMBER_LOGGING ' || SUBSTR(SQLERRM, 1, 300);                    
          RAISE exp_main_reject_record;   
      END;
   END IF;
  --END:Added for serial number changes on 29/10/14

EXCEPTION
  --<< MAIN EXCEPTION >>
  WHEN EXP_AUTH_REJECT_RECORD THEN
    ROLLBACK;
	
	IF v_toggle_value = 'Y' AND v_respcode  <> '215' THEN
    BEGIN
        sp_concurrent_check_logclear(v_hash_pan, p_delivery_channel, p_txn_code, P_RESP_MSG);
        IF P_RESP_MSG <> 'OK' THEN
           v_respcode         := '21';
           p_errmsg := P_RESP_MSG;
        END IF;
         EXCEPTION
         WHEN OTHERS THEN
          v_respcode := '12';
          p_errmsg  := 'Concurrent check clear failed' || SUBSTR(SQLERRM, 1, 200);
    END;
  end if;

    P_ERRMSG    := P_ERRMSG;
    P_RESP_CODE := V_RESPCODE;
    P_RESP_MSG  := P_ERRMSG;

     --Sn Added by MageshKumar S. for MVHOST-479
      --Sn selecting account balances
       BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,cam_type_code
           INTO v_acct_balance, v_ledger_balance,v_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no =v_acct_number
            AND cam_inst_code = p_instcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_balance := 0;
      END;
      --En selecting account balances
        P_ACCT_BAL := v_acct_balance;
      --Sn select response code
      BEGIN
        -- SELECT cms_response_id --Commented for FSS-2072 on 16-JAN-2015
        SELECT CMS_ISO_RESPCDE --Added for FSS-2072 on 16-JAN-2015
         --  INTO v_respcode  --Commented for FSS-2072 on 16-JAN-2015
        INTO P_RESP_CODE --Added for FSS-2072 on 16-JAN-2015
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = p_delivery_channel
           -- AND cms_iso_respcde = p_resp_code  --Commented for FSS-2072 on 16-JAN-2015
           AND CMS_RESPONSE_ID = V_RESPCODE --Added for FSS-2072 on 16-JAN-2015
           AND rownum<2;
      EXCEPTION
      
      -- Start added for FSS-2225(card status decline case)
      WHEN NO_DATA_FOUND THEN
      
      BEGIN
      
       SELECT cms_response_id 
           INTO v_respcode  
            FROM cms_response_mast
            WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = p_delivery_channel
            AND cms_iso_respcde = p_resp_code  
            AND rownum<2;  
            
        EXCEPTION
        WHEN OTHERS THEN
            p_errmsg :='Problem while selecting data from response master for card status '|| v_respcode|| SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
            
      END;
      
      -- End added for FSS-2225(card status decline case)
      
         WHEN OTHERS THEN
            p_errmsg :='Problem while selecting data from response master '|| v_respcode|| SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
            ROLLBACK;
      END;
      --En select response code
     --En Added by MageshKumar S. for MVHOST-479

 --ST:Added for serial number changes on 29/10/14
    IF P_SERIAL_NUMBER IS NOT NULL THEN
      BEGIN
              SP_SPIL_SERIALNUMBER_LOGGING(             
                    p_instcode,
                    P_MSG ,                                               
                    P_DELIVERY_CHANNEL,                                               
                    P_TXN_CODE,
                    P_SERIAL_NUMBER,
                    V_TOPUP_AUTH_ID,
                    P_RESP_CODE,
                    V_HASH_PAN,
                    P_RRN,
                    systimestamp,
                    V_RESP_CDE,
                    V_RESP_MSG);
        
         IF V_RESP_CDE <> '00' OR V_RESP_MSG <> 'OK' THEN        
          p_resp_code := '69';     
          P_Errmsg := V_RESP_MSG;
         END IF;

       EXCEPTION        
         WHEN OTHERS THEN
          p_resp_code := '69';
          p_errmsg  := 'Error while calling SP_SPIL_SERIALNUMBER_LOGGING ' || SUBSTR(SQLERRM, 1, 300);                           
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
        PRODUCTID,
        CATEGORYID,
        ATM_NAME_LOCATION,
        AUTH_ID,
        AMOUNT,
        PREAUTHAMOUNT,
        PARTIALAMOUNT,
        INSTCODE,
        CUSTOMER_CARD_NO_ENCR,
        TOPUP_CARD_NO_ENCR,
        PROXY_NUMBER,
        REVERSAL_CODE,
        CUSTOMER_ACCT_NO,
        ACCT_BALANCE,
        LEDGER_BALANCE,
        RESPONSE_ID,
        CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
        TRANS_DESC,
        Merchant_Name,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        Merchant_City,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        Merchant_State,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        Error_Msg,
        STORE_ID, --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
        --Sn Added by MageshKumar S. for MVHOST-479
        cr_dr_flag,
        acct_type,
        time_stamp,
        merchant_zip-- added for VMS-622 (redemption_delay zip code validation)
        --En Added by MageshKumar S. for MVHOST-479
        )
     VALUES
       (P_MSG,
        P_RRN,
        P_DELIVERY_CHANNEL,
        P_TERMINALID,
        V_BUSINESS_DATE,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_TXN_MODE,
        DECODE(P_RESP_CODE, '00', 'C', 'F'),
        P_RESP_CODE,
        P_TRANDATE,
        SUBSTR(P_TRANTIME, 1, 10),
        V_HASH_PAN,
        NULL,
        NULL,
        NULL,
        P_INSTCODE,
        TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')), --Modified during MVHOST-479
        P_CURRCODE,
        NULL,
        V_PROD_CODE,
        V_CARD_TYPE,
        P_TERMINALID,
        V_TOPUP_AUTH_ID,
        TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')), --Modified during MVHOST-479
        '0.00', -- NULL replaced by 0.00 during MVHOST-479
        '0.00', -- NULL replaced by 0.00 during MVHOST-479
        P_INSTCODE,
        V_ENCR_PAN,
        V_ENCR_PAN,
        V_PROXUNUMBER,
        P_RVSL_CODE,
        V_ACCT_NUMBER,
        V_ACCT_BALANCE,
        V_LEDGER_BALANCE,
        V_RESPCODE,
        V_CAP_CARD_STAT, --Added cardstatus insert in transactionlog by srinivasu.k
        V_TRANS_DESC,
        P_MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        Null,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        NULL, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        P_Errmsg,
        P_STORE_ID, --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
        --Sn Added by MageshKumar S. for MVHOST-479
        v_dr_cr_flag,
        v_acct_type,
        systimestamp,
        p_merchant_zip-- added for VMS-622 (redemption_delay zip code validation)
        --En Added by MageshKumar S. for MVHOST-479
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CODE := '69';
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
    END;

    --En create a entry in txn log
    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
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
        CTD_INST_CODE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER,
        CTD_TXN_TYPE) -- Added during MVHOST-479
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        P_MSG,
        P_TXN_MODE,
        P_TRANDATE,
        P_TRANTIME,
        V_HASH_PAN,
        P_AMOUNT,
        P_CURRCODE,
        P_AMOUNT,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        'E',
        P_ERRMSG,
        P_RRN,
        P_INSTCODE,
        V_ENCR_PAN,
        V_ACCT_NUMBER,
        V_TXN_TYPE); -- Added during MVHOST-479
     P_ERRMSG := P_ERRMSG;
     RETURN;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '22'; -- Server Declined
       ROLLBACK;
       RETURN;
    END;

    P_ERRMSG := P_ERRMSG;
  WHEN EXP_MAIN_REJECT_RECORD THEN
    ROLLBACK;
	
	 IF v_toggle_value = 'Y' AND v_respcode  <> '215' THEN
    BEGIN
        sp_concurrent_check_logclear(v_hash_pan, p_delivery_channel, p_txn_code, P_RESP_MSG);
        IF P_RESP_MSG <> 'OK' THEN
           v_respcode         := '21';
           p_errmsg := P_RESP_MSG;
        END IF;
         EXCEPTION
         WHEN OTHERS THEN
          v_respcode := '12';
          p_errmsg  := 'Concurrent check clear failed' || SUBSTR(SQLERRM, 1, 200);
    END;
    end if;

    --Sn Added by MageshKumar S. for MVHOST-479
    IF v_dr_cr_flag IS NULL THEN
     BEGIN
        SELECT ctm_credit_debit_flag,ctm_tran_desc,
         TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1'))
          INTO v_dr_cr_flag,v_trans_desc,V_TXN_TYPE
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delivery_channel
           AND ctm_inst_code = p_instcode;
     EXCEPTION
        WHEN OTHERS THEN
           NULL;
     END;
    END IF;

    IF v_prod_code IS NULL THEN
     BEGIN
        SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
          INTO v_prod_code, v_card_type, v_cap_card_stat, v_acct_number
          FROM cms_appl_pan
         WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
     EXCEPTION
        WHEN OTHERS THEN
           NULL;
     END;
    END IF;
    --En Added by MageshKumar S. for MVHOST-479

    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            cam_type_code    --Added by MageshKumar S.for MVHOST-479
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
            v_acct_type    --Added by MageshKumar S.for MVHOST-479
       FROM CMS_ACCT_MAST
      --Sn modified by Pankaj S. for logging changes(Mantis ID-13160)
      WHERE CAM_ACCT_NO =v_acct_number
           /*(SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
                 CAP_INST_CODE = P_INSTCODE)*/ AND
      --En modified by Pankaj S. for logging changes(Mantis ID-13160)
           CAM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;
    P_ACCT_BAL := V_ACCT_BALANCE;
    --Sn generate auth id
    BEGIN
     --SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;

     --   SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') ||
     SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
       INTO V_TOPUP_AUTH_ID
       FROM DUAL;

    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG   := 'Error while generating authid ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESPCODE := '21'; -- Server Declined
    END;

    --En generate auth id
    --Sn select response code and insert record into txn log dtl
    BEGIN
     P_ERRMSG    := P_ERRMSG;
     P_RESP_CODE := V_RESPCODE;
     P_RESP_MSG  := P_ERRMSG;

     -- Assign the response code to the out parameter
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INSTCODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = V_RESPCODE;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG    := 'Problem while selecting data from response master ' ||
                   V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '69';
       ---ISO MESSAGE FOR DATABASE ERROR Server Declined
       ROLLBACK;
    END;


--ST:Added for serial number changes on 29/10/14
   IF P_SERIAL_NUMBER IS NOT NULL THEN
      BEGIN
              SP_SPIL_SERIALNUMBER_LOGGING(             
                    p_instcode,
                    P_MSG ,                                               
                    P_DELIVERY_CHANNEL,                                               
                    P_TXN_CODE,
                    P_SERIAL_NUMBER,
                    V_TOPUP_AUTH_ID,
                    P_RESP_CODE,
                    V_HASH_PAN,
                    P_RRN,
                    systimestamp,
                    V_RESP_CDE,
                    V_RESP_MSG);
        
         IF V_RESP_CDE <> '00' OR V_RESP_MSG <> 'OK' THEN        
          p_resp_code := '69';     
          P_Errmsg := V_RESP_MSG;
         END IF;

       EXCEPTION        
         WHEN OTHERS THEN
          p_resp_code := '69';
          p_errmsg  := 'Error while calling SP_SPIL_SERIALNUMBER_LOGGING ' || SUBSTR(SQLERRM, 1, 300);                                
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
        PRODUCTID,
        CATEGORYID,
        ATM_NAME_LOCATION,
        AUTH_ID,
        AMOUNT,
        PREAUTHAMOUNT,
        PARTIALAMOUNT,
        INSTCODE,
        CUSTOMER_CARD_NO_ENCR,
        TOPUP_CARD_NO_ENCR,
        PROXY_NUMBER,
        REVERSAL_CODE,
        CUSTOMER_ACCT_NO,
        ACCT_BALANCE,
        LEDGER_BALANCE,
        RESPONSE_ID,
        CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
        TRANS_DESC,
        Merchant_Name,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        Merchant_City,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        Merchant_State , -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        Error_Msg,
        STORE_ID,  --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
        --Sn Added by Pankaj S. for Mantis ID 11587
        cr_dr_flag,
        acct_type,
        time_stamp,
        merchant_zip-- added for VMS-622 (redemption_delay zip code validation)
        --En Added by Pankaj S. for Mantis ID 11587
        )
     VALUES
       (P_MSG,
        P_RRN,
        P_DELIVERY_CHANNEL,
        P_TERMINALID,
        V_BUSINESS_DATE,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_TXN_MODE,
        DECODE(P_RESP_CODE, '00', 'C', 'F'),
        P_RESP_CODE,
        P_TRANDATE,
        SUBSTR(P_TRANTIME, 1, 10),
        V_HASH_PAN,
        NULL,
        NULL,
        NULL,
        P_INSTCODE,
        TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')),--Modified during MVHOST-479
        P_CURRCODE,
        NULL,
        V_PROD_CODE,
        V_CARD_TYPE,
        P_TERMINALID,
        V_TOPUP_AUTH_ID,
        TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')),  --Modified during MVHOST-479
        '0.00', -- NULL replaced by 0.00 during MVHOST-479
        '0.00', -- NULL replaced by 0.00 during MVHOST-479
        P_INSTCODE,
        V_ENCR_PAN,
        V_ENCR_PAN,
        V_PROXUNUMBER,
        P_RVSL_CODE,
        V_ACCT_NUMBER,
        V_ACCT_BALANCE,
        V_LEDGER_BALANCE,
        V_RESPCODE,
        V_CAP_CARD_STAT, --Added cardstatus insert in transactionlog by srinivasu.k
        V_TRANS_DESC,
        P_Merchant_Name, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        NULL,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        Null, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        P_Errmsg,
        P_STORE_ID, --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
        --Sn Added by MageshKumar S. for MVHOST-479
        v_dr_cr_flag,
        v_acct_type,
        systimestamp,
        p_merchant_zip-- added for VMS-622 (redemption_delay zip code validation)
        --En Added by MageshKumar S. for MVHOST-479
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CODE := '69';
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
    END;

    --En create a entry in txn log

    --Sn create a entry in cms_transaction_log_dtl
    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
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
        CTD_INST_CODE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER,
        CTD_TXN_TYPE) -- Added during MVHOST-479
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        P_MSG,
        P_TXN_MODE,
        P_TRANDATE,
        P_TRANTIME,
        V_HASH_PAN,
        P_AMOUNT,
        P_CURRCODE,
        P_AMOUNT,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        'E',
        P_ERRMSG,
        P_RRN,
        P_INSTCODE,
        V_ENCR_PAN,
        V_ACCT_NUMBER,
        V_TXN_TYPE); -- Added during MVHOST-479

     P_ERRMSG   := P_ERRMSG;
     P_RESP_MSG := P_ERRMSG;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '22'; -- Server Declined
       ROLLBACK;
       RETURN;
    END;

    P_ERRMSG   := P_ERRMSG;
    P_RESP_MSG := P_ERRMSG;
  WHEN EXP_DUPLICATE_REQUEST THEN
    ROLLBACK;
	
	IF v_toggle_value = 'Y' AND v_respcode  <> '215' THEN
    BEGIN
        sp_concurrent_check_logclear(v_hash_pan, p_delivery_channel, p_txn_code, P_RESP_MSG);
        IF P_RESP_MSG <> 'OK' THEN
           v_respcode         := '21';
           p_errmsg := P_RESP_MSG;
        END IF;
         EXCEPTION
         WHEN OTHERS THEN
          v_respcode := '12';
          p_errmsg  := 'Concurrent check clear failed' || SUBSTR(SQLERRM, 1, 200);
    END;
    end if;

    --Sn Added by MageshKumar S. for MVHOST-479
    IF v_dr_cr_flag IS NULL THEN
     BEGIN
        SELECT ctm_credit_debit_flag,ctm_tran_desc,
        TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1'))
          INTO v_dr_cr_flag,v_trans_desc,V_TXN_TYPE
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delivery_channel
           AND ctm_inst_code = p_instcode;
     EXCEPTION
        WHEN OTHERS THEN
           NULL;
     END;
    END IF;

    IF v_prod_code IS NULL THEN
     BEGIN
        SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
          INTO v_prod_code, v_card_type, v_cap_card_stat, v_acct_number
          FROM cms_appl_pan
         WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
     EXCEPTION
        WHEN OTHERS THEN
           NULL;
     END;
    END IF;
    --En Added by MageshKumar S. for MVHOST-479

    --Sn create a entry in txn log
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            cam_type_code    --Added by MageshKumar S. for MVHOST-479
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
            v_acct_type      --Added by MageshKumar S. for MVHOST-479
       FROM CMS_ACCT_MAST
       --Sn Modified by Pankaj S. for logging changes(Mantis ID-13160)
      WHERE CAM_ACCT_NO =v_acct_number
           /*(SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
                 CAP_INST_CODE = P_INSTCODE)*/ AND
      --En Modified by Pankaj S. for logging changes(Mantis ID-13160)
           CAM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;
    P_ACCT_BAL := V_ACCT_BALANCE;    
    --Sn select response code and insert record into txn log dtl
    
    --Sn generate auth id
    if V_TOPUP_AUTH_ID is null then     
      BEGIN            
       SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
         INTO V_TOPUP_AUTH_ID
         FROM DUAL;
  
      EXCEPTION
       WHEN OTHERS THEN
        null;
      END;       
    end if;
     --En generate auth id
     
    BEGIN
     P_ERRMSG    := P_ERRMSG;
     P_RESP_CODE := V_RESPCODE;
     P_RESP_MSG  := P_ERRMSG;

     -- Assign the response code to the out parameter
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INSTCODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = V_RESPCODE;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG    := 'Problem while selecting data from response master ' ||
                   V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '69';
       ---ISO MESSAGE FOR DATABASE ERROR Server Declined
       ROLLBACK;
    END;


--ST:Added for serial number changes on 29/10/14
   IF P_SERIAL_NUMBER IS NOT NULL THEN
      BEGIN
              SP_SPIL_SERIALNUMBER_LOGGING(             
                    p_instcode,
                    P_MSG ,                                               
                    P_DELIVERY_CHANNEL,                                               
                    P_TXN_CODE,
                    P_SERIAL_NUMBER,
                    V_TOPUP_AUTH_ID,
                    P_RESP_CODE,
                    V_HASH_PAN,
                    P_RRN,
                    systimestamp,
                    V_RESP_CDE,
                    V_RESP_MSG);
        
         IF V_RESP_CDE <> '00' OR V_RESP_MSG <> 'OK' THEN        
          p_resp_code := '69';     
          P_Errmsg := V_RESP_MSG;
         END IF;

       EXCEPTION        
         WHEN OTHERS THEN
          p_resp_code := '69';
          p_errmsg  := 'Error while calling SP_SPIL_SERIALNUMBER_LOGGING ' || SUBSTR(SQLERRM, 1, 300);                             
    END;
  END IF;
  --END:Added for serial number changes on 29/10/14
  
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
        PRODUCTID,
        CATEGORYID,
        ATM_NAME_LOCATION,
        AUTH_ID,
        AMOUNT,
        PREAUTHAMOUNT,
        PARTIALAMOUNT,
        INSTCODE,
        CUSTOMER_CARD_NO_ENCR,
        TOPUP_CARD_NO_ENCR,
        PROXY_NUMBER,
        REVERSAL_CODE,
        CUSTOMER_ACCT_NO,
        ACCT_BALANCE,
        LEDGER_BALANCE,
        RESPONSE_ID,
        CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
        TRANS_DESC,
        Merchant_Name,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        Merchant_City,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        Merchant_State,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        Error_Msg,
        STORE_ID,  --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
        --Sn Added by MageshKumar S. for MVHOST-479
        cr_dr_flag,
        acct_type,
        time_stamp,
        merchant_zip-- added for VMS-622 (redemption_delay zip code validation)
      
        --En Added by MageshKumar S. for MVHOST-479
        )
     VALUES
       (P_MSG,
        P_RRN,
        P_DELIVERY_CHANNEL,
        P_TERMINALID,
        V_BUSINESS_DATE,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_TXN_MODE,
        DECODE(P_RESP_CODE, '00', 'C', 'F'),
        P_RESP_CODE,
        P_TRANDATE,
        SUBSTR(P_TRANTIME, 1, 10),
        V_HASH_PAN,
        NULL,
        NULL,
        NULL,
        P_INSTCODE,
        TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')),--Modified during MVHOST-479
        P_CURRCODE,
        NULL,
        V_PROD_CODE,
        V_CARD_TYPE,
        P_TERMINALID,
        V_TOPUP_AUTH_ID,
        TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')),--Modified during MVHOST-479
        '0.00', -- NULL replaced by 0.00 during MVHOST-479
        '0.00', -- NULL replaced by 0.00 during MVHOST-479
        P_INSTCODE,
        V_ENCR_PAN,
        V_ENCR_PAN,
        V_PROXUNUMBER,
        P_RVSL_CODE,
        V_ACCT_NUMBER,
        V_ACCT_BALANCE,
        V_LEDGER_BALANCE,
        V_RESPCODE,
        V_CAP_CARD_STAT, --Added cardstatus insert in transactionlog by srinivasu.k
        V_TRANS_DESC,
        P_Merchant_Name, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        Null,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        Null ,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        P_Errmsg,
        P_STORE_ID,  --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
        --Sn Added by MageshKumar S. for MVHOST-479
        v_dr_cr_flag,
        v_acct_type,
        systimestamp,
        p_merchant_zip-- added for VMS-622 (redemption_delay zip code validation)
        --En Added by MageshKumar S. for MVHOST-479
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CODE := '69';
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
    END;

    --En create a entry in txn log
    --Sn create a entry in cms_transaction_log_dtl
    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
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
        CTD_INST_CODE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER,
        CTD_TXN_TYPE) -- Added during MVHOST-479
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        P_MSG,
        P_TXN_MODE,
        P_TRANDATE,
        P_TRANTIME,
        V_HASH_PAN,
        P_AMOUNT,
        P_CURRCODE,
        P_AMOUNT,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        'E',
        P_ERRMSG,
        P_RRN,
        P_INSTCODE,
        V_ENCR_PAN,
        V_ACCT_NUMBER,
        V_TXN_TYPE); -- Added during MVHOST-479

     P_ERRMSG := P_ERRMSG;

    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '89'; -- Server Declined
       ROLLBACK;
       RETURN;
    END;

    BEGIN

     SELECT RESPONSE_CODE
       INTO P_RESP_CODE --V_RESPCODE  --Modified by Pankaj S. on 26_Feb_2013
       FROM VMSCMS.TRANSACTIONLOG_VW A,         --Added for VMS-5739/FSP-991
           (SELECT MIN(ADD_INS_DATE) MINDATE
             FROM VMSCMS.TRANSACTIONLOG_VW     --Added for VMS-5739/FSP-991 
            WHERE RRN = P_RRN and ACCT_BALANCE is not null) B
      WHERE A.ADD_INS_DATE = MINDATE AND RRN = P_RRN and ACCT_BALANCE is not null;
	  

     -- P_RESP_CODE := V_RESPCODE;  --commented by Pankaj S. on 26_Feb_2013

    EXCEPTION
     WHEN OTHERS THEN

       P_ERRMSG    := 'Problem in selecting the response detail of Original transaction' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '89'; -- Server Declined
       ROLLBACK;
       RETURN;

    END;

     --Sn Commented by Pankaj S. on 26_Feb_2013 as its unused
    /*BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
                 CAP_INST_CODE = P_INSTCODE) AND
           CAM_INST_CODE = P_INSTCODE
        FOR UPDATE NOWAIT;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESPCODE := '14'; --Ineligible Transaction
       P_ERRMSG   := 'Invalid Card ';
       ROLLBACK;
       RETURN;
     WHEN OTHERS THEN
       V_RESPCODE := '12';
       P_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                  V_HASH_PAN;
       ROLLBACK;
       RETURN;
    END;*/
     --Sn Commented by Pankaj S. on 26_Feb_2013 as its unused

  --En of Getting  the Acct Balannce

  WHEN OTHERS THEN
    P_ERRMSG := ' Error from main ' || SUBSTR(SQLERRM, 1, 200);
END;
/
show error