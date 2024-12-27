create or replace PROCEDURE                            VMSCMS.SP_SPIL_CARD_ACTIVATION (P_INSTCODE IN NUMBER,
                                          P_RRN      		 IN VARCHAR2,
                                          P_TERMINALID       IN VARCHAR2,
                                          P_STAN             IN VARCHAR2,
                                          P_TRANDATE         IN VARCHAR2,
                                          P_TRANTIME         IN VARCHAR2,
                                          P_PANNO            IN VARCHAR2,
                                          P_AMOUNT           IN NUMBER,
                                          P_CURRCODE         IN VARCHAR2,
                                          P_LUPDUSER         IN NUMBER,
                                          P_MSG              IN VARCHAR2,
                                          P_TXN_CODE         IN OUT VARCHAR2,
                                          P_TXN_MODE         IN VARCHAR2,
                                          P_DELIVERY_CHANNEL IN VARCHAR2,
                                          P_MBR_NUMB         in varchar2,
                                          P_RVSL_CODE        in varchar2,
                                          P_Merchant_Name    In Varchar2,
                                          P_STORE_ID         in varchar2, 
                                          P_VERIFICATION_ID  in varchar2, 
                                          P_RESP_CODE        OUT VARCHAR2,
                                          P_ERRMSG           OUT VARCHAR2,
                                          P_RESP_MSG         OUT VARCHAR2,
                                          P_ACCT_BAL         OUT VARCHAR2,
                                          p_POSTBACK_URL_OUT OUT VARCHAR2,
                                          P_Activation_Code  In Varchar2 Default Null,
                                          P_Merchant_id      in varchar2 default null,
                                          P_location_id      in varchar2 default null,
                                          p_merchant_zip     in varchar2 default null,-- added for VMS-622 (redemption_delay zip code validation)
                                          p_merchant_address     in varchar2 default null,
                                          p_merchant_city     in varchar2 default null,
                                          p_merchant_state     in varchar2 default null
                                          ) AS
  /*************************************************
     * Created Date      :  28-Mar-2012
     * Created By        :  Srinivasu
     * PURPOSE           :  For Activation and load transaction in SPIL Delivery channel
     * Modified By      :  Ramkumar.mK
     * Modified Date    :  03-Jan-2013
     * Modified Reason  :  Update the First time flag when txn code as 16


     * Modified By      :  Pankaj S.
     * Modified Date    :  26-Feb-2013
     * Modified Reason  : Modified for SPIL RRN Check changes
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     :

     * Modified By      :  Saravanakumar
     * Modified Date    :  04-Mar-2013
     * Modified Reason  : Removeed txn code from duplicate rrn check
     * Reviewer         : Dhiraj
     * Reviewed Date    : 07-Mar-2013
     * Build Number     : CMS3.5.1_RI0023.2_B0016

     * Modified By      :  MageshKumar.S
     * Modified Date    :  05-June-2013
     * Modified Reason  :  Defect MVHOST-447(Replenishment Floor Limit issue)
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     :  RI0024.2_B0003

      * Modified By      : Santosh P
      * Modified Date    : 15-Jul-2013
      * Modified Reason  : Capture StoreId in transactionlog table
      * Modified for     : FSS-1146
      * Reviewer         :
      * Reviewed Date    :
      * Build Number     : RI0024.3_B0005

      * Modified By      : Pankaj S.
      * Modified Date    : 18-Sep-2013
      * Modified Reason  : SPIL target registraton(to handle preauth req )
      * Modified for     : FWR-39
      * Reviewer         : Dhiraj
      * Reviewed Date    :
      * Build Number     : RI0024.4_B0016

      * Modified By      : MageshKumar S.
      * Modified Date    : 26-Nov-2013
      * Modified Reason  : Response code not logged properly
      * Modified for     : MVHOST-479
      * Reviewer         : Dhiraj
      * Reviewed Date    : 05/DEC/2013
      * Build Number     : RI0024.7_B0001

      * Modified By       : Pankaj S.
      * Modified Date     : 10-Dec-2013
      * Modified Reason   : Logging issue changes(Mantis ID-13160)
      * Reviewer          : Dhiraj
      * Reviewed Date     :
      * Build Number      : RI0027_B0004

      * Modified Date    : 31-Jan-2014
      * Modified By      : Sagar More
      * Modified for     : Spil 3.0 Changes
      * Modified reason  : 1) input parameter added for verification id
                           2) Check input merchant in target master
                           3) Check for null verification id
                           4) Check for combination of verfication id and card number in transaction_log_dtl table
                           5) update card status as spendown if its a target merchant
      * Reviewer         : Dhiraj
      * Reviewed Date    : 31-Jan-2014
      * Release Number   : RI0027.1_B0001

      * Modified Date    : 19-Feb-2014
      * Modified By      : Sagar More
      * Modified for     : 13705
      * Modified reason  : 1) Transaction code condition added with mshtype check
      * Reviewer         : Dhiraj
      * Reviewed Date    : 19-Feb-2014
      * Release Number   : RI0027.1_B0004

     * Modified Date         : 25.03.2014
     * Modified By           : Sachin P.
     * Purpose               : Enabling Limit configuration and validation (MVHOST_756 -4113)
     * Reviewer              : spankaj
     * Reviewed Date         : 07-April-2014
     * Release Number        : RI0027.2_B0004

     * Modified Date         : 26.05.14
     * Modified By           : Ravi N.
     * Purpose               : MET-114 -Initial Load via In-Lane Merchant Registration - Change Card Status to "Active Unregistered" not "Spend Down"
     * Release Number        : RI0027.2.1_B0003

     * Modified By           : MageshKumar S.
     * Modified Date         : 17-jun-2014
     * Modified Reason       : Limit check not happening for Prod/prodcatg level
     * Modified for          : MVHOST-756
     * Reviewer              : spankaj
     * Build Number          : RI0027.2.1_B0003

     * Modified by           : MageshKumar.S
     * Modified Date         : 26-August-14
     * Modified For          : FSS-1802
     * Modified reason       : For SPIL act duplicate attempt needs to echo back of original
     * Build Number          : RI0027.3.2_B0002

     * Modified Date         : 29-SEP-2014
     * Modified By           : Abdul Hameed M.A
     * Modified for          : FWR 70
     * Reviewer              : Spankaj
     * Release Number        : RI0027.4_B0002

     * Modified Date         : 11-Nov-2014
     * Modified By           : Siva Kumar M
     * Modified for          : Mantis ID:15747
     * Reviewer              : Spankaj
     * Release Number        : RI0027.4.3_B0003

     * Modified Date         : 07-June-2016
     * Modified By           : Ramesh A
     * Modified for          : Closed Loop Changes
     * Reviewer              : Saravanakumar
     * Release Number        : 4.2_B0001

     * Modified By          :  Pankaj S.
     * Modified Date      :  12-Sep-2016
     * Modified Reason  : Modified for 4.2.2 changes
     * Reviewer              : Saravanakumar
     * Build Number      :   4.2.2

     * Modified By          :  Mageshkumar S.
     * Modified Date        :  30-Sep-2016
     * Modified Reason      :  FSS-4782
     * Reviewer             :  Saravanakumar/SPankaj
     * Build Number         :  VMSGPRHOSTCSD4.2.5_B0001

     * Modified by          : Pankaj S.
     * Modified Date        : 09-Mar-17
     * Modified For         : FSS-4647
     * Modified reason      : Redemption Delay Changes
     * Reviewer             : Saravanakumar
     * Build Number         : VMSGPRHOST_17.3

     * Modified by          : T.Narayanaswamy
     * Modified Date        : 05-May-17
     * Modified For         : B2B config moved to Category Level beg
     * Modified reason      : B2B config moved to Category Level beg
     * Reviewer             : Saravanakumar
     * Build Number         : VMSGPRHOST_17.05

     * Modified by      : T.Narayanaswamy.
     * Modified Date    : 20-June-17
     * Modified For     : FSS-5157 - B2B Gift Card - Phase 2
     * Modified reason  : B2B Gift Card - Phase 2
     * Reviewer         : Saravanakumar
     * Build Number     : VMSGPRHOST_17.06

     * Modified By      : MageshKumar S
    * Modified Date    : 18/07/2017
    * Purpose          : FSS-5157
    * Reviewer         : Saravanan/Pankaj S.
    * Release Number   : VMSGPRHOST17.07

   * Modified By      : T.Narayanaswamy.
   * Modified Date    : 04/08/2017
   * Purpose          : FSS-5157 - B2B Gift Card - Phase 2
   * Reviewer         : Saravanan/Pankaj S.
   * Release Number   : VMSGPRHOST17.08

   * Modified By      :Pankaj S.
   * Modified Date    : 23/10/2017
   * Purpose          : FSS-5302:Retail Activation of Anonymous Products
   * Reviewer         : Saravanan
   * Release Number   : VMSGPRHOST17.10

     * Modified By      : Akhil
     * Modified Date    : 05/01/2018
     * Purpose          : VMS-78
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST17.12

     * Modified By      : DHINAKARAN B
     * Modified Date    : 09/01/2018
     * Purpose          : VMS-161
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST17.12.1
     * Modified By      : DHINAKARAN B
     * Modified Date    : 09/01/2018
     * Purpose          : B2B SPIL ACTIVATION CHANGES
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST17.12.6

	 * Modified By      : Veneetha C
     * Modified Date    : 21-JAN-2019
     * Purpose          : VMS-622 Redemption delay for activations /reloads processed through ICGPRM
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST R11

     * Modified By      : sivakumar M
     * Modified Date    : 04-APR-2019
     * Purpose          : VMS-850
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST R14

     * Modified by      : UBAIDUR RAHMAN.H
    * Modified Date    : 23-APRIL-2019
    * Modified For     : VMS-874.
    * Reviewer         : Saravanankumar A
    * Build Number     : VMSR15_B0002.

     * Modified By      : Sivakumar M
     * Modified Date    : 23-May-2019
     * Purpose          : VMS-930
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST R16

     * Modified By      : A.Sivakaminathan
     * Modified Date    : 17-Jun-2019
     * Purpose          : VMS-966
     * Reviewer         : Saravanankumar A
     * Release Number   : VMSGPRHOST R17

	 * Modified By      : Ulagan
     * Modified Date    : 30-Aug-2019
     * Purpose          : VMS-1050
     * Reviewer         : Saravanankumar A
     * Release Number   : VMSGPRHOST R20

     * Modified By      : Puvanesh.N
     * Modified Date    : 28-DEC-2020
     * Purpose          : VMS-3508
     * Reviewer         : Saravanankumar A
     * Release Number   : VMSGPRHOST R40

     * Modified By      : Raj Devkota
     * Modified Date    : 10-MAY-2021
     * Purpose          : VMS-4337 - modifed to make P_TXN_CODE argument IN OUT mode
     * Reviewer         : Ubaidur
     * Release Number   : VMSGPRHOST R46

     * Modified By      : Mageshkumar.S
     * Modified Date    : 22-MARCH-2022
     * Purpose          : VMS-5743 - Reroute SPIL-PRE ACTIVATION Audit Transactions
     * Reviewer         : Saravanakumar.A
     * Release Number   : VMSGPRHOST R60

     * Modified By      : Mageshkumar.S
     * Modified Date    : 22-03-2022
     * Purpose          : VMS-5673:Delay access to funds
     * Reviewer         : Saravanakumar A.
     * Build Number     : R60 - BUILD 2

	* Modified By      : Karthick/Jey
    * Modified Date    : 05-23-2022
    * Purpose          : Archival changes.
    * Reviewer         : venkat Singamaneni
    * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991
    
     * Modified By      : Bhavani E
     * Modified Date    : 06-APR-2023
     * Purpose          : VMS-7215 Unexpected SPIL Activation CARD
     * Reviewer         : Pankaj S
     * Release Number   : VMSGPRHOST R78
     
     * Modified By      : Pankaj S.
     * Modified Date    : 10-Jul-2023
     * Purpose          : VMS-7592 : Pre Activation transactions are declined for Fund on Order Fulfilment orders
     * Reviewer         : Venkat S.
     * Release Number   : VMSGPRHOST R83
*************************************************/
  V_CAP_PROD_CATG     CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
  V_CAP_CARD_STAT     CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_CAP_CAFGEN_FLAG   CMS_APPL_PAN.CAP_CAFGEN_FLAG%TYPE;
  V_CAP_APPL_CODE     CMS_APPL_PAN.CAP_APPL_CODE%TYPE;
  V_FIRSTTIME_TOPUP   CMS_APPL_PAN.CAP_FIRSTTIME_TOPUP%TYPE;
  V_PROD_CODE         CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_CARD_TYPE         CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_PROFILE_CODE      CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
  V_VARPRODFLAG       cms_prod_cattype.CPC_RELOADABLE_FLAG%TYPE;
  V_CURRCODE          GEN_CURR_MAST.GCM_CURR_CODE%TYPE;
  V_APPL_CODE         CMS_APPL_MAST.CAM_APPL_CODE%TYPE;
  V_RESONCODE         CMS_SPPRT_REASONS.CSR_SPPRT_RSNCODE%TYPE;
  V_RESPCODE          TRANSACTIONLOG.RESPONSE_ID%TYPE;
  V_RESPMSG           VARCHAR2(500);
  V_CAPTURE_DATE      DATE;
  V_MBRNUMB           CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;

  V_TXN_TYPE          CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
  V_TOPUP_AUTH_ID     TRANSACTIONLOG.AUTH_ID%TYPE;


  V_HASH_PAN           CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN           CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_BUSINESS_DATE      DATE;
  V_TRAN_DATE          DATE;
  V_TOPUPREMRK         VARCHAR2(100);
  V_ACCT_BALANCE       TRANSACTIONLOG.ACCT_BALANCE%TYPE;
  V_LEDGER_BALANCE     TRANSACTIONLOG.LEDGER_BALANCE%TYPE;
  V_TRAN_AMT           CMS_TRANSACTION_LOG_DTL.CTD_TXN_AMOUNT%TYPE;

  V_CARD_CURR          PCMS_EXCHANGERATE_MAST.PEM_CURR_CODE%TYPE;
  V_DATE               DATE;

  V_PROXUNUMBER        CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER        CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_TRANCDE            CMS_TRANSACTION_LOG_DTL.CTD_TXN_CODE%TYPE;

  V_DUPCHK_CARDSTAT TRANSACTIONLOG.CARDSTATUS%TYPE;
  V_DUPCHK_ACCTBAL  TRANSACTIONLOG.ACCT_BALANCE%TYPE;
  V_DUPCHK_COUNT    PLS_INTEGER;

  V_ERR_SET         PLS_INTEGER := 0;
  V_TRANS_DESC      CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; 
  V_CMM_INST_CODE     CMS_MERINV_MERPAN.CMM_INST_CODE%TYPE;
  V_CMM_MER_ID        CMS_MERINV_MERPAN.CMM_MER_ID%TYPE;
  V_CMM_LOCATION_ID   CMS_MERINV_MERPAN.CMM_LOCATION_ID%TYPE;
  V_CMM_MERPRODCAT_ID CMS_MERINV_MERPAN.CMM_MERPRODCAT_ID%TYPE;

  V_INST_CODE     CMS_APPL_PAN.CAP_INST_CODE%TYPE;
  V_LMTPRFL       CMS_PRDCATTYPE_LMTPRFL.CPL_LMTPRFL_ID%TYPE;
  V_PROFILE_LEVEL cms_appl_pan.cap_prfl_levl%TYPE;  
  V_CARDTYPE_FLAG    CMS_APPL_PAN.CAP_STARTERCARD_FLAG%TYPE; 


  v_dr_cr_flag  cms_transaction_mast.ctm_credit_debit_flag%TYPE; 
  v_acct_type   cms_acct_mast.cam_type_code%TYPE; 

  v_chk_target_mer   varchar2(1);    
  v_chk_txn_det      varchar2(1);    
  v_dup_verif_id_chk varchar2(1);    

   v_comb_hash              pkg_limits_check.type_hash;
   v_tran_type              cms_transaction_mast.ctm_tran_type%TYPE;
   v_prfl_flag              cms_transaction_mast.ctm_prfl_flag%TYPE;
   V_STARTER_CANADA varchar2(1):='N';
   V_CURRENCY_CODE           CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;


V_UPD_CARD_STAT CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
V_CUST_CODE CMS_APPL_PAN.CAP_CUST_CODE%TYPE;
l_b2bcard_status        CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
v_redmption_delay_flag   cms_prod_cattype.cpc_redemption_delay_flag%TYPE;
v_txn_redmption_flag  cms_transaction_mast.ctm_redemption_delay_flag%TYPE;

   V_CPC_PROD_DENO        CMS_PROD_CATTYPE.CPC_PROD_DENOM%TYPE;
   V_CPC_PDEN_MIN         CMS_PROD_CATTYPE.CPC_PDENOM_MIN%TYPE;
   V_CPC_PDEN_MAX         CMS_PROD_CATTYPE.CPC_PDENOM_MAX%TYPE;
   V_CPC_PDEN_FIX         CMS_PROD_CATTYPE.CPC_PDENOM_FIX%TYPE;
   V_COUNT                NUMBER;
   v_retail_activation  cms_prod_cattype.cpc_retail_activation%TYPE;
   v_product_funding      CMS_PROD_CATTYPE.CPC_PRODUCT_FUNDING%TYPE;
   v_fund_amount          CMS_PROD_CATTYPE.CPC_FUND_AMOUNT%TYPE;
   v_prod_fund            CMS_PROD_CATTYPE.CPC_PRODUCT_FUNDING%TYPE;
   v_fund_amt             CMS_PROD_CATTYPE.CPC_FUND_AMOUNT%TYPE;
   v_b2b_cardFlag         VARCHAR2(10)   :='N';
   v_lineitem_denom        NUMBER;
   v_order_prod_fund       vms_order_lineitem.VOL_PRODUCT_FUNDING%TYPE;
   v_order_fund_amt        vms_order_lineitem.VOL_FUND_AMOUNT%TYPE;
   V_ACTIVATION_CODE       CMS_APPL_PAN.CAP_ACTIVATION_CODE%TYPE;
   V_USER_IDENTIFICATION_TYPE  CMS_PROD_CATTYPE.CPC_USER_IDENTIFY_TYPE%TYPE;
   v_cap_order_type   cms_appl_pan.cap_order_type%type;
   V_STATUS_CHECK        varchar2(1);
   v_defund_flag            cms_acct_mast.cam_defund_flag%type;
   l_audit_flag		    cms_transaction_mast.ctm_txn_log_flag%TYPE;
   v_delayed_accessto_firstload_flag CMS_PROD_CATTYPE.CPC_DELAYED_FIRSTLOAD_ACCESS%TYPE;
   v_order_delayed_access_date VMS_ORDER_LINEITEM.VOL_DELAYEDACCESS_DATE%TYPE;
   --SN: Added for VMS-6071
	v_toggle_value  cms_inst_param.cip_param_value%TYPE;
	v_prd_chk       NUMBER :=0;
   --EN: Added for VMS-6071
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
   v_Retdate  date; --Added for VMS-5739/FSP-991
   v_initialload_amt cms_acct_mast.cam_initialload_amt%TYPE; --Added for Unexpected SPIL Activation CARD VMS-7215

  EXP_MAIN_REJECT_RECORD EXCEPTION;
  EXP_DUPLICATE_REQUEST EXCEPTION;
  EXP_ALREADY_INSERTED EXCEPTION;


BEGIN
  P_ERRMSG     := 'OK';
  V_TOPUPREMRK := 'Online Card Topup';
  P_RESP_MSG   := 'Success';
  p_POSTBACK_URL_OUT :='0~0~0~0~0~0';
  V_TRAN_AMT := P_AMOUNT;
  V_STATUS_CHECK:='Y';
  V_TRANCDE := P_TXN_CODE;  
  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(P_PANNO);
  EXCEPTION
    WHEN OTHERS THEN
     P_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_PANNO);
  EXCEPTION
    WHEN OTHERS THEN
     P_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --EN create encr pan





  --Sn Getting the Transaction Description
  BEGIN
    SELECT CTM_TRAN_DESC,
    ctm_credit_debit_flag,
    TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
    ctm_prfl_flag,ctm_tran_type,
    NVL(ctm_redemption_delay_flag,'N'),nvl(ctm_txn_log_flag,'T')
    INTO V_TRANS_DESC,v_dr_cr_flag,V_TXN_TYPE ,
    v_prfl_flag,v_tran_type,
    v_txn_redmption_flag,l_audit_flag
     FROM CMS_TRANSACTION_MAST
    WHERE CTM_TRAN_CODE = P_TXN_CODE AND
         CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
         CTM_INST_CODE = P_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_TRANS_DESC := 'Transaction type' || P_TXN_CODE;
    WHEN OTHERS THEN
     V_TRANS_DESC := 'Transaction type ' || P_TXN_CODE;
  END;

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
         CAP_INST_CODE, 
         CAP_PRFL_CODE, 
         CAP_PRFL_LEVL, 
         CAP_STARTERCARD_FLAG, 
        CAP_CUST_CODE, 
        CAP_ACTIVATION_CODE,nvl(cap_order_type,'F')
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
         V_INST_CODE ,
          v_lmtprfl , 
         v_profile_level, 
         V_CARDTYPE_FLAG, 
        V_CUST_CODE,      
        V_ACTIVATION_CODE,v_cap_order_type
     FROM CMS_APPL_PAN
    WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB
        AND CAP_INST_CODE = P_INSTCODE;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Invalid Card number ' || V_HASH_PAN;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Error while selecting card number ' || V_HASH_PAN;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  BEGIN
  SELECT DECODE(UPPER(ordr.VOD_POSTBACK_RESPONSE),'TRUE','1','1','1','0')
    ||'~'
    ||detail.VLI_ORDER_ID
    ||'~'
    ||detail.VLI_LINEITEM_ID
    ||'~'
    ||ordr.vod_partner_id
    ||'~'
    ||NVL(ordr.VOD_POSTBACK_URL,'0')
    ||'~'
    ||ordr.Vod_Channel_Id,To_Number(Nvl(lineitem.Vol_Denomination,'0')),
    lineitem.VOL_PRODUCT_FUNDING,lineitem.VOL_FUND_AMOUNT,lineitem.VOL_DELAYEDACCESS_DATE
  INTO p_POSTBACK_URL_OUT,v_lineitem_denom,v_order_prod_fund,v_order_fund_amt,v_order_delayed_access_date
  FROM vms_order_details ordr,
    vms_line_item_dtl detail,
    vms_order_lineitem lineitem
  WHERE ordr.VOD_ORDER_ID=detail.vli_order_id
  AND ordr.VOD_PARTNER_ID=detail.VLI_PARTNER_ID
  AND ordr.VOD_ORDER_ID=lineitem.vol_order_id
  AND ordr.VOD_PARTNER_ID=lineitem.VOL_PARTNER_ID
  AND lineitem.VOL_LINE_ITEM_ID=detail.VLI_LINEITEM_ID
  AND detail.vli_pan_code  =V_HASH_PAN;
  v_b2b_cardFlag   :='Y';
EXCEPTION
WHEN OTHERS THEN
  NULL;
END; 
  IF v_b2b_cardFlag='N' THEN 
      IF V_FIRSTTIME_TOPUP = 'Y' THEN
        V_RESPCODE := '9'; -- response for invalid transaction
        P_ERRMSG   := 'Card Activation Already Done For this Card';
        RAISE EXP_MAIN_REJECT_RECORD;
      END IF;
        IF TRIM(V_FIRSTTIME_TOPUP) IS NULL THEN
         P_ERRMSG := 'Invalid Card status first time topup is null ';
         RAISE EXP_MAIN_REJECT_RECORD;
        END IF;

  ELSIF V_CAP_CARD_STAT <> '0' AND v_b2b_cardFlag = 'Y' THEN
      IF V_FIRSTTIME_TOPUP = 'Y' THEN
        V_RESPCODE := '9'; -- response for invalid transaction
        P_ERRMSG   := 'Card Activation Already Done For this Card';
        RAISE EXP_MAIN_REJECT_RECORD;
      END IF;
        IF TRIM(V_FIRSTTIME_TOPUP) IS NULL THEN
         P_ERRMSG := 'Invalid Card status first time topup is null ';
         RAISE EXP_MAIN_REJECT_RECORD;
        END IF;

END IF;
    if P_MSG = '1200' and p_txn_code = '26'
     then
              BEGIN

                select 1
                into   v_chk_target_mer
                from   cms_targetmerch_mast
                where  ctm_inst_code = p_instcode
                and    upper(ctm_merchant_name) = upper(p_merchant_name);


              EXCEPTION WHEN NO_DATA_FOUND
              THEN
                  v_chk_target_mer := NULL;
              WHEN OTHERS
              THEN
                 V_RESPCODE := '21';
                 P_ERRMSG   := 'Error while verfying target merchant ';
                 RAISE EXP_MAIN_REJECT_RECORD;
              END;
      end if;


IF l_audit_flag = 'T' THEN
--Sn added duplicate rrn check.
    begin
        SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
        INTO V_DUPCHK_CARDSTAT, V_DUPCHK_ACCTBAL
        from(SELECT CARDSTATUS, ACCT_BALANCE   FROM VMSCMS.TRANSACTIONLOG                 --Added for VMS-5739/FSP-991
                WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
                DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                and ACCT_BALANCE is not null
                order by add_ins_date desc)
        where rownum=1;
		IF SQL%ROWCOUNT = 0 THEN
		SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
        INTO V_DUPCHK_CARDSTAT, V_DUPCHK_ACCTBAL
        from(SELECT CARDSTATUS, ACCT_BALANCE   FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                --Added for VMS-5739/FSP-991
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

END IF;

        BEGIN
            SELECT CAM_ACCT_BAL,NVL(cam_defund_flag,'N'),cam_initialload_amt --Added for Unexpected SPIL Activation CARD VMS-7215
            INTO V_ACCT_BALANCE,v_defund_flag,v_initialload_amt --Added for Unexpected SPIL Activation CARD VMS-7215
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO = V_ACCT_NUMBER
            AND  CAM_INST_CODE = P_INSTCODE;

        EXCEPTION
            WHEN OTHERS THEN
                V_RESPCODE := '12';
                P_ERRMSG   := 'Error while selecting acct balance ' ||substr(sqlerrm,1,200);
                RAISE EXP_MAIN_REJECT_RECORD;
        END;

IF l_audit_flag = 'T' THEN

    if V_DUPCHK_COUNT =1 then

        V_DUPCHK_COUNT:=0;
            if v_chk_target_mer = 1 then

            if V_DUPCHK_CARDSTAT= V_CAP_CARD_STAT OR V_DUPCHK_ACCTBAL=V_ACCT_BALANCE then

            V_DUPCHK_COUNT:=1;
            V_RESPCODE := '22';
            P_ERRMSG   := 'Duplicate Incomm Reference Number' ||P_RRN;
            RAISE EXP_DUPLICATE_REQUEST;

        end if;

        elsif V_DUPCHK_CARDSTAT= V_CAP_CARD_STAT and V_DUPCHK_ACCTBAL=V_ACCT_BALANCE then
            V_DUPCHK_COUNT:=1;
            V_RESPCODE := '22';
            P_ERRMSG   := 'Duplicate Incomm Reference Number' ||P_RRN;
            RAISE EXP_DUPLICATE_REQUEST;
        end if;

    end if;

    end if;
--En added duplicate rrn check.

              if v_chk_target_mer = 1
              then

                 if p_verification_id is null
                 then

                     V_RESPCODE := '210';
                     P_ERRMSG   := 'Invalid verfication id for target merchant';
                     RAISE EXP_MAIN_REJECT_RECORD;

                 END IF;

                      begin
                            select 1
                            into   v_dup_verif_id_chk
                            from CMS_SPIL_KYCQUE
                            where csk_inst_code = p_instcode
                            and   csk_verification_id = p_verification_id;

                            if v_dup_verif_id_chk = 1
                            then

                             V_RESPCODE := '212';
                             P_ERRMSG   := 'Duplicate Verification Id';
                             RAISE EXP_MAIN_REJECT_RECORD;

                            end if;


                      exception when EXP_MAIN_REJECT_RECORD
                      then
                          raise;

                      when no_data_found
                      then
                            v_dup_verif_id_chk := null;

                      WHEN OTHERS
                      THEN
                         V_RESPCODE := '21';
                         P_ERRMSG   := 'Error while validating verification id for target merchant ';
                         RAISE EXP_MAIN_REJECT_RECORD;


                      end;

                      BEGIN

                          select 1
                          into   v_chk_txn_det
                          from   VMSCMS.CMS_TRANSACTION_LOG_DTL               --Added for VMS-5739/FSP-991
                          where  ctd_inst_code = p_instcode
                          and    ctd_customer_card_no = v_hash_pan
                          and    ctd_auth_id = p_verification_id
                          and    ctd_delivery_channel = '08'
                          and    ctd_txn_code = '30'
                          and    ctd_process_flag = 'Y';
						  IF SQL%ROWCOUNT = 0 THEN
						  select 1
                          into   v_chk_txn_det
                          from   VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST               --Added for VMS-5739/FSP-991
                          where  ctd_inst_code = p_instcode
                          and    ctd_customer_card_no = v_hash_pan
                          and    ctd_auth_id = p_verification_id
                          and    ctd_delivery_channel = '08'
                          and    ctd_txn_code = '30'
                          and    ctd_process_flag = 'Y';
						  END IF;

                      EXCEPTION WHEN NO_DATA_FOUND
                      THEN
                         V_RESPCODE := '210';
                         P_ERRMSG   := 'Transaction details not found for verfication id '||p_verification_id;
                         RAISE EXP_MAIN_REJECT_RECORD;

                      WHEN OTHERS
                      THEN
                         V_RESPCODE := '21';
                         P_ERRMSG   := 'Error while validating pan code and verification id for target merchant ';
                         RAISE EXP_MAIN_REJECT_RECORD;

                      end;




              END IF;



IF v_lmtprfl IS NULL OR v_profile_level IS NULL 
   THEN
  BEGIN
    SELECT CPL_LMTPRFL_ID
     INTO V_LMTPRFL
     FROM CMS_PRDCATTYPE_LMTPRFL
    WHERE CPL_INST_CODE = V_INST_CODE AND CPL_PROD_CODE = V_PROD_CODE AND
         CPL_CARD_TYPE = V_CARD_TYPE;

    V_PROFILE_LEVEL := 2;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     BEGIN
       SELECT CPL_LMTPRFL_ID
        INTO V_LMTPRFL
        FROM CMS_PROD_LMTPRFL
        WHERE CPL_INST_CODE = V_INST_CODE AND CPL_PROD_CODE = V_PROD_CODE;

       V_PROFILE_LEVEL := 3;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        NULL;
       WHEN OTHERS THEN
        V_RESPCODE := '21';
        P_ERRMSG   := 'Error while selecting Limit Profile At Product Level' ||
                    SQLERRM;
        RAISE EXP_MAIN_REJECT_RECORD;
     END;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Error while selecting Limit Profile At Product Catagory Level' ||
                SQLERRM;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
END IF  ;  

  --Sn check the min and max limit for topup
  BEGIN
    BEGIN
    --Profile Code of Product
    SELECT CPC_RELOADABLE_FLAG,CPC_PROD_DENOM, CPC_PDENOM_MIN, CPC_PDENOM_MAX,
        CPC_PDENOM_FIX,CPC_PROFILE_CODE, cpc_b2bcard_stat,  decode(nvl(cpc_b2b_flag,'N'),'N', cpc_retail_activation,0),
        CPC_PRODUCT_FUNDING,CPC_FUND_AMOUNT,cpc_user_identify_type,CPC_DELAYED_FIRSTLOAD_ACCESS
        INTO V_VARPRODFLAG,v_cpc_prod_deno, v_cpc_pden_min, v_cpc_pden_max,
        v_cpc_pden_fix,v_profile_code, l_b2bcard_status, v_retail_activation,v_prod_fund,v_fund_amt,V_USER_IDENTIFICATION_TYPE,
        v_delayed_accessto_firstload_flag
        FROM cms_prod_cattype
        WHERE cpc_prod_code = v_prod_code
        AND cpc_card_type = V_CARD_TYPE
        AND CPC_INST_CODE = P_INSTCODE;
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
     IF v_b2b_cardFlag='Y' AND nvl(V_TRAN_AMT,0) > 0 AND V_ACCT_BALANCE<>0 THEN
            v_retail_activation:=1;
     END IF; 

     IF v_order_prod_fund is not null THEN
        v_product_funding := v_order_prod_fund; 
        v_fund_amount := v_order_fund_amt;
     ELSE
        v_product_funding := v_prod_fund; 
        v_fund_amount := v_fund_amt;
     END IF;   

     IF v_b2b_cardFlag='Y'  AND v_product_funding='2' AND v_fund_amount = '1'  THEN
           IF v_lineitem_denom <> V_TRAN_AMT 
             THEN
             v_respcode := '293';
             P_ERRMSG := 'Invalid Amount';
             RAISE exp_main_reject_record;
             END IF;
           V_TRAN_AMT :=v_lineitem_denom;
      ELSIF v_b2b_cardFlag = 'Y' AND v_product_funding = '1' AND v_defund_flag = 'Y' AND V_ACCT_BALANCE = 0 THEN
            V_TRAN_AMT := v_lineitem_denom;
     END IF; 

  IF ( v_retail_activation<>1 AND v_b2b_cardFlag='N' ) OR
      (v_b2b_cardFlag='Y' AND v_product_funding='2' AND v_fund_amount='2') THEN

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

 END IF;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'profile_code not defined ' || V_PROFILE_CODE;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Error while selecting profile  flag ' || V_PROFILE_CODE;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  BEGIN
    V_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8), 'yyyymmdd');
  EXCEPTION
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
    IF (V_TRAN_AMT >= 0) THEN

     BEGIN
       SP_CONVERT_CURR(P_INSTCODE,
                    V_CURRCODE,
                    P_PANNO,
                    V_TRAN_AMT,
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
        V_RESPCODE := '69'; -- Server Declined 
        P_ERRMSG   := 'Error from currency conversion ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
     END;
    ELSE
     V_RESPCODE := '43';
     P_ERRMSG   := 'INVALID AMOUNT';
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;

  BEGIN
    select CBP_PARAM_VALUE
     INTO v_currency_code
     FROM CMS_BIN_PARAM
    WHERE CBP_PROFILE_CODE = V_PROFILE_CODE AND
         CBP_INST_CODE = P_INSTCODE AND CBP_PARAM_NAME = 'Currency';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Currency code is  not specified for the Profile ' ||
                V_PROFILE_CODE;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     P_ERRMSG   := 'Error While selecting the Currency code' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  end;
if(V_CURRENCY_CODE='124')   then

   IF V_USER_IDENTIFICATION_TYPE IN('1','4') THEN
      V_STARTER_CANADA:='N';

  ELSE
      V_STARTER_CANADA:='Y';
      END IF;
end if;


IF v_retail_activation =1 OR v_retail_activation=2  THEN
     v_upd_card_stat :=1;
ELSE
      v_upd_card_stat :=v_cap_card_stat;
END IF;


 IF l_b2bcard_status IS NOT NULL THEN
 V_UPD_CARD_STAT := l_b2bcard_status;
 END IF;

    IF (P_TXN_CODE = '25') THEN
     V_TRANCDE := '26';
    ELSE
     V_TRANCDE := P_TXN_CODE;
    END IF;
    if v_cap_order_type='P'  then
     if V_TRANCDE ='26' and  v_retail_activation=1 then
     V_TRANCDE :='44'; -- PRINT ORDER - ACTIVATION
     elsif V_TRANCDE ='26'  then          --- Added for VMS -874.
     V_TRANCDE :='45';  -- PRINT ORDER - ACTIVATION AND LOAD
     end if;
  else
  if v_retail_activation=1 THEN 
     V_TRANCDE :='35';
  else
    V_TRANCDE:=P_TXN_CODE;
   end if;
  end if;
-- SN Added for Unexpected SPIL Activation CARD VMS-7215
IF v_b2b_cardFlag = 'Y' AND v_product_funding = '1' AND v_defund_flag = 'N' AND V_ACCT_BALANCE = 0 AND v_initialload_amt<>0 THEN
 V_TRANCDE :='35';
END IF;
-- EN Added for Unexpected SPIL Activation CARD VMS-7215
 IF v_b2b_cardFlag = 'Y' AND V_ACTIVATION_CODE IS NOT NULL AND ( P_ACTIVATION_CODE IS NULL OR
       (P_ACTIVATION_CODE IS NOT NULL AND V_ACTIVATION_CODE <> P_ACTIVATION_CODE ))
       THEN
          v_respcode := '292';
          P_ERRMSG := 'Activation Code check is failed';
          RAISE exp_main_reject_record; 
 END IF;

 IF  v_retail_activation =1 THEN
    BEGIN
       SELECT ctm_prfl_flag, NVL (ctm_redemption_delay_flag, 'N')
         INTO v_prfl_flag, v_txn_redmption_flag
         FROM cms_transaction_mast
        WHERE     ctm_tran_code = '35'
              AND ctm_delivery_channel = p_delivery_channel
              AND ctm_inst_code = p_instcode;
    EXCEPTION
       WHEN OTHERS
       THEN
          NULL;
    END;
 END IF;

  IF v_lmtprfl IS NOT NULL AND v_prfl_flag = 'Y'  THEN 

    BEGIN
          pkg_limits_check.sp_limits_check (v_hash_pan,
                                            NULL,
                                            NULL,
                                            NULL,--p_mcc_code,
                                            V_TRANCDE,
                                            v_tran_type,
                                            NULL,--p_international_ind,
                                            NULL,--p_pos_verfication,
                                            P_INSTCODE,
                                            NULL,
                                            v_lmtprfl, 
                                            v_tran_amt,
                                            P_DELIVERY_CHANNEL,
                                            v_comb_hash,
                                            v_respcode,
                                            P_ERRMSG
                                           );
       IF P_ERRMSG <> 'OK' THEN
          RAISE EXP_MAIN_REJECT_RECORD;
       END IF;
    EXCEPTION
       WHEN EXP_MAIN_REJECT_RECORD THEN
          RAISE;
       WHEN OTHERS    THEN
          v_respcode := '21';
          P_ERRMSG :='Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_MAIN_REJECT_RECORD;
    END;
    END IF;
 IF v_b2b_cardFlag = 'Y' THEN

  begin
  VMSCOMMON.CHECK_ORDER_STATUS(P_INSTCODE,P_DELIVERY_CHANNEL,V_TRANCDE,v_hash_pan,V_PROD_CODE,
                                        V_CARD_TYPE,V_CAP_CARD_STAT,P_MSG,
                                          V_STATUS_CHECK, v_respcode,
                                            P_ERRMSG);
               IF (v_respcode <> '00' OR P_ERRMSG <> 'OK')
                THEN
                    RAISE EXP_MAIN_REJECT_RECORD;
                END IF;
                  EXCEPTION
                WHEN EXP_MAIN_REJECT_RECORD
                THEN
                    RAISE;
                WHEN OTHERS
                THEN
                    v_respcode := '21';
                    P_ERRMSG :=
                        'Error from order status check process ' || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_MAIN_REJECT_RECORD;

    end;
 end if;



  --------------Sn For Debit Card No need using authorization -----------------------------------
  IF V_CAP_PROD_CATG = 'P' THEN
    --Sn call to authorize txn
    BEGIN
     SP_AUTHORIZE_TXN_CMS_AUTH(P_INSTCODE,
                          P_MSG,
                          P_RRN,
                          P_DELIVERY_CHANNEL,
                          P_TERMINALID,
                          CASE WHEN P_TXN_CODE=25 THEN '25' ELSE V_TRANCDE END,
                          P_TXN_MODE,
                          P_TRANDATE,
                          P_TRANTIME,
                          P_PANNO,
                          NULL,
                          V_TRAN_AMT,
                          P_MERCHANT_NAME,
                          p_merchant_city,
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
                          --SN: Modified for VMS-7592
                          CASE WHEN P_TXN_CODE=25 THEN V_TRAN_AMT ELSE  
                          CASE WHEN v_retail_activation=1 THEN 0 ELSE V_TRAN_AMT END 
                          END,
                          --EN: Modified for VMS-7592
                          V_TOPUP_AUTH_ID,
                          V_RESPCODE,
                          V_RESPMSG,
                          V_CAPTURE_DATE,
                          'Y',
                          'N',
                          'N',
                          NULL,
                          p_merchant_zip,-- added for VMS-622 (redemption_delay zip code validation)
                          V_STATUS_CHECK,
                          p_merchant_address,
                          P_Merchant_id,
                          p_merchant_state
                          );

     IF V_RESPCODE <> '00' AND V_RESPMSG <> 'OK' THEN
       P_ERRMSG := V_RESPMSG;
       RAISE EXP_ALREADY_INSERTED;
     END IF;
    EXCEPTION
     WHEN EXP_ALREADY_INSERTED THEN
       RAISE;
     WHEN EXP_MAIN_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       P_ERRMSG := 'Error from Card authorization' ||
                SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_MAIN_REJECT_RECORD;
    END;
  END IF;

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


  IF P_ERRMSG = 'OK' and (P_TXN_CODE = 26
      OR P_TXN_CODE = '32')  
   THEN
    BEGIN
     UPDATE CMS_APPL_PAN
        SET CAP_FIRSTTIME_TOPUP = (CASE WHEN (v_b2b_cardFlag='N' OR (v_b2b_cardFlag='Y' AND v_product_funding='2'))  THEN 'Y' ELSE CAP_FIRSTTIME_TOPUP END),
           CAP_PRFL_CODE       = V_LMTPRFL,
           CAP_PRFL_LEVL = V_PROFILE_LEVEL,
     CAP_CARD_STAT  = DECODE (v_chk_target_mer,'1','13',decode(V_STARTER_CANADA,'Y','13',V_UPD_CARD_STAT)),
     cap_pin_off=decode(V_UPD_CARD_STAT,'1','0000',cap_pin_off), 
     Cap_Active_Date=Decode(V_Upd_Card_Stat,'1',Sysdate,Decode(Nvl(L_B2bcard_Status,'0'),'1',Sysdate,Cap_Active_Date)), 
     cap_merchant_name=P_Merchant_Name,cap_terminal_id=P_TERMINALID,cap_store_id=P_STORE_ID,Cap_Merchant_Id=P_Merchant_id,cap_location_id=P_location_id
      WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
           CAP_INST_CODE = P_INSTCODE;

     IF SQL%ROWCOUNT = 0 THEN
       P_ERRMSG   := 'Error while Updating first time topup flag' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESPCODE := '21';
       RAISE EXP_MAIN_REJECT_RECORD;
     END IF;
    EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
    RAISE;
     WHEN OTHERS THEN
       P_ERRMSG   := 'Error while Updating first time topup flag' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESPCODE := '21';
       RAISE EXP_MAIN_REJECT_RECORD;
    END;
  END IF;

  IF v_delayed_accessto_firstload_flag='Y' AND v_order_prod_fund = '2' AND v_order_delayed_access_date IS NULL

  THEN

  BEGIN

                        UPDATE cms_cust_mast
                           SET ccm_delayedaccess_date = LAST_DAY(SYSDATE)
                         WHERE ccm_inst_code = P_INSTCODE
						   AND ccm_cust_code = V_CUST_CODE;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        P_ERRMSG :=
                           'Error While Updating delayed access date in CMS_CUST_MAST:'
                           || SUBSTR (SQLERRM, 1, 200);

                  END;
END IF;


  IF P_ERRMSG = 'OK' AND P_TXN_CODE <>'31' THEN  
    BEGIN
     SELECT CMM_INST_CODE, CMM_MER_ID, CMM_LOCATION_ID, CMM_MERPRODCAT_ID
       INTO V_CMM_INST_CODE,
           V_CMM_MER_ID,
           V_CMM_LOCATION_ID,
           V_CMM_MERPRODCAT_ID
       FROM CMS_MERINV_MERPAN
      WHERE CMM_PAN_CODE = V_HASH_PAN;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_ERR_SET := 1;
     WHEN OTHERS THEN
       P_ERRMSG   := 'Error while Fetching Pan From MERPAN ' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESPCODE := '21';
       RAISE EXP_MAIN_REJECT_RECORD;
    END;

    IF V_ERR_SET <> 1 THEN
     BEGIN
       UPDATE CMS_MERINV_MERPAN
         SET CMM_ACTIVATION_FLAG = 'C'
        WHERE CMM_PAN_CODE = V_HASH_PAN;

       IF SQL%ROWCOUNT = 0 THEN
        P_ERRMSG   := 'Error while Updating Card Activation Flag in MERPAN ' ||
                    SUBSTR(SQLERRM, 1, 200);
        V_RESPCODE := '21';
        RAISE EXP_MAIN_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN OTHERS THEN
        P_ERRMSG   := 'Error while Updating first time topup flag' ||
                    SUBSTR(SQLERRM, 1, 200);
        V_RESPCODE := '21';
        RAISE EXP_MAIN_REJECT_RECORD;
     END;

     BEGIN
       UPDATE CMS_MERINV_STOCK
         SET CMS_CURR_STOCK = (CMS_CURR_STOCK - 1)
        WHERE CMS_INST_CODE = V_CMM_INST_CODE AND
            CMS_MERPRODCAT_ID = V_CMM_MERPRODCAT_ID AND
            CMS_LOCATION_ID = V_CMM_LOCATION_ID;

       IF SQL%ROWCOUNT = 0 THEN
        P_ERRMSG   := 'Error while Updating Card Activation Flag in MERPAN ' ||
                    SUBSTR(SQLERRM, 1, 200);
        V_RESPCODE := '21';
        RAISE EXP_MAIN_REJECT_RECORD;
       END IF;

     EXCEPTION when EXP_MAIN_REJECT_RECORD
     then
          raise;

     WHEN OTHERS THEN
        P_ERRMSG   := 'Error while Updating first time topup flag' ||
                    SUBSTR(SQLERRM, 1, 200);
        V_RESPCODE := '21';
        RAISE EXP_MAIN_REJECT_RECORD;
     END;
    END IF;
  END IF;

  ----------------------------------------------------------------------------------------------------------
  V_RESPCODE := 1;


  BEGIN
    P_ERRMSG    := P_ERRMSG;
    P_RESP_CODE := V_RESPCODE;

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
     ROLLBACK;
  END;

  IF P_ERRMSG = 'OK' THEN
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =V_ACCT_NUMBER

                 AND
           CAM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESPCODE := '14'; --Ineligible Transaction
       P_ERRMSG   := 'Invalid Card ';
       RAISE EXP_MAIN_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESPCODE := '12';
       P_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                  V_HASH_PAN;
       RAISE EXP_MAIN_REJECT_RECORD;
    END;

    P_ACCT_BAL := V_ACCT_BALANCE;
  End If;
  IF l_audit_flag='T' THEN
   Begin

       --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';

       v_Retdate := TO_DATE(SUBSTR(TRIM(P_Trandate), 1, 8), 'yyyymmdd');

	IF (v_Retdate>v_Retperiod) THEN                                                --Added for VMS-5739/FSP-991

       Update Transactionlog
         Set Store_Id = P_Store_Id
        Where Instcode = P_Instcode
         And Rrn = P_Rrn
         And Customer_Card_No = V_Hash_Pan
         And Business_Date = P_Trandate
         And Txn_Code=CASE WHEN P_TXN_CODE=25 THEN '25' ELSE V_TRANCDE END
         AND delivery_channel = p_delivery_channel;

	ELSE

	     Update VMSCMS_HISTORY.TRANSACTIONLOG_HIST    --Added for VMS-5739/FSP-991
         Set Store_Id = P_Store_Id
        Where Instcode = P_Instcode
         And Rrn = P_Rrn
         And Customer_Card_No = V_Hash_Pan
         And Business_Date = P_Trandate
         And Txn_Code=CASE WHEN P_TXN_CODE=25 THEN '25' ELSE V_TRANCDE END
         AND delivery_channel = p_delivery_channel;

	END IF;

    If Sql%Rowcount = 0 Then
       P_ERRMSG   := 'Error while Updating StoreId in Transactionlog table' ||
                  Substr(Sqlerrm, 1, 200);
       V_RESPCODE := '21';
       Raise Exp_Main_Reject_Record;
     END IF;

   EXCEPTION when Exp_Main_Reject_Record
   then
       raise;

   WHEN OTHERS THEN
        P_ERRMSG   := 'Error while Updating StoreId in Transactionlog table' ||
                    Substr(Sqlerrm, 1, 200);
        V_RESPCODE := '21';
        Raise Exp_Main_Reject_Record;
   END;
END IF;

   IF v_lmtprfl IS NOT NULL AND v_prfl_flag = 'Y' THEN 
    BEGIN
          pkg_limits_check.sp_limitcnt_reset (p_instcode,
                                              v_hash_pan,
                                              v_tran_amt,
                                              v_comb_hash,
                                              v_respcode,
                                              P_ERRMSG
                                             );
       IF P_ERRMSG <> 'OK' THEN
          P_ERRMSG := 'From Procedure sp_limitcnt_reset' || P_ERRMSG;
          RAISE Exp_Main_Reject_Record;
       END IF;
    EXCEPTION
       WHEN Exp_Main_Reject_Record THEN
          RAISE;
       WHEN OTHERS THEN
          v_respcode := '21';
          P_ERRMSG := 'Error from Limit Reset Count Process ' || SUBSTR (SQLERRM, 1, 200);
          RAISE Exp_Main_Reject_Record;
    END;
    END IF;

    BEGIN
       SELECT NVL(cpc_redemption_delay_flag,'N')
         INTO v_redmption_delay_flag
         FROM cms_prod_cattype
        WHERE     cpc_prod_code = v_prod_code
              AND cpc_card_type = v_card_type
              AND cpc_inst_code = p_instcode;
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          p_errmsg := 'Product category not found';
          v_respcode := '21';
          RAISE exp_main_reject_record;
       WHEN OTHERS
       THEN
          p_errmsg :=
             'Error while fetching redemption delay flag from prodcattype: '
             || SUBSTR (SQLERRM, 1, 200);
          v_respcode := '21';
          RAISE exp_main_reject_record;
    END;

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
                            P_Merchant_id); --VMS-6499

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
    /* passes transactionlog transCode back */
    P_TXN_CODE := V_TRANCDE;
EXCEPTION
  --<< MAIN EXCEPTION >>
  WHEN EXP_MAIN_REJECT_RECORD THEN
    ROLLBACK;
   If v_respcode  <> '215' then
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
     BEGIN
        SELECT ctm_credit_debit_flag,ctm_tran_desc,
        TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1'))
          INTO v_dr_cr_flag,v_trans_desc,V_TXN_TYPE
          FROM cms_transaction_mast
         WHERE ctm_tran_code = CASE WHEN P_TXN_CODE=25 THEN '25' ELSE V_TRANCDE END
           AND ctm_delivery_channel = p_delivery_channel
           AND ctm_inst_code = p_instcode;
     EXCEPTION
        WHEN OTHERS THEN
           NULL;
     END;

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

    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,cam_type_code 
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,v_acct_type 
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =v_acct_number
        AND CAM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;

    P_ACCT_BAL := V_ACCT_BALANCE;
    BEGIN

     SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
       INTO V_TOPUP_AUTH_ID
       FROM DUAL; 
    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG   := 'Error while generating authid ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESPCODE := '21'; -- Server Declined
    END;

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
       P_ERRMSG    := 'Problem while selecting data from response response master ' ||
                   V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '69';
       ---ISO MESSAGE FOR DATABASE ERROR Server Declined
       ROLLBACK;
    END;


IF l_audit_flag='T' THEN

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
        CARDSTATUS,
        TRANS_DESC,
        MERCHANT_NAME, 
        MERCHANT_CITY, 
        MERCHANT_STATE,
        Error_Msg,
        STORE_ID, 
        cr_dr_flag,
        acct_type,
        time_stamp,
        Merchant_zip-- added for VMS-622 (redemption_delay zip code validation)
        )
     VALUES
       (P_MSG,
        P_RRN,
        P_DELIVERY_CHANNEL,
        P_TERMINALID,
        V_BUSINESS_DATE,
        CASE WHEN P_TXN_CODE=25 THEN '25' ELSE V_TRANCDE END,
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
        TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')),
        P_CURRCODE,
        NULL,
        V_PROD_CODE,
        V_CARD_TYPE,
        P_TERMINALID,
        V_TOPUP_AUTH_ID,
        TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')),
        '0.00', 
        '0.00', 
        P_INSTCODE,
        V_ENCR_PAN,
        V_ENCR_PAN,
        V_PROXUNUMBER,
        P_RVSL_CODE,
        V_ACCT_NUMBER,
        V_ACCT_BALANCE,
        V_LEDGER_BALANCE,
        V_RESPCODE,
        V_CAP_CARD_STAT,
        V_TRANS_DESC,
        P_MERCHANT_NAME, 
        NULL,
        NULL,
        P_Errmsg,
        P_STORE_ID,   
        v_dr_cr_flag,
        v_acct_type,
        systimestamp,
        p_merchant_zip-- added for VMS-622 (redemption_delay zip code validation)
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CODE := '69';
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
    END;

ELSIF l_audit_flag = 'A'
    THEN
    BEGIN


                INSERT INTO transactionlog_audit (
                    msgtype,
                    rrn,
                    delivery_channel,
                    terminal_id,
                    date_time,
                    txn_code,
                    txn_type,
                    txn_mode,
                    txn_status,
                    response_code,
                    business_date,
                    business_time,
                    customer_card_no,
                    bank_code,
                    total_amount,
                    currencycode,
                    productid,
                    categoryid,
                    atm_name_location,
                    auth_id,
                    trans_desc,
                    amount,
                    system_trace_audit_no,
                    instcode,
                    cr_dr_flag,
                    customer_card_no_encr,
                    proxy_number,
                    reversal_code,
                    customer_acct_no,
                    acct_balance,
                    ledger_balance,
                    response_id,
                    add_ins_date,
                    add_ins_user,
                    cardstatus,
                    error_msg,
                    merchant_name,
                    merchant_city,
                    merchant_state,
                    acct_type,
                    time_stamp,
                    merchant_zip,
                    MERCHANT_STREET,
                    merchant_id
                ) VALUES (
                    p_msg,
                    p_rrn,
                    p_delivery_channel,
                    P_TERMINALID,
                    v_business_date,
                    p_txn_code,
                    v_txn_type,
                    p_txn_mode,
                    decode(p_resp_code, '00', 'C', 'F'),
                    p_resp_code,
                    P_TRANDATE,
                    SUBSTR(P_TRANTIME, 1, 10),
                    v_hash_pan,
                    P_INSTCODE,
                    TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')),
                    P_CURRCODE,
                    v_prod_code,
                    V_CARD_TYPE,
                    P_TERMINALID,
                    V_TOPUP_AUTH_ID,
                    v_trans_desc,
                    TRIM(to_char(nvl(v_tran_amt, 0), '999999999999999990.99')),
                    p_stan,
                    p_instcode,
                    v_dr_cr_flag,
                    v_encr_pan,
                    v_proxunumber,
                    p_rvsl_code,
                    v_acct_number,
                    V_ACCT_BALANCE,
                    V_LEDGER_BALANCE,
                    V_RESPCODE,
                    sysdate,
                    1,
                    V_CAP_CARD_STAT,
                    P_Errmsg,
                    p_merchant_name,
                    p_merchant_city,
                    p_merchant_state,
                    v_acct_type,
                    systimestamp,
                    p_merchant_zip,
                    p_merchant_address,
                    p_merchant_id
                );
				
         --SN: Added for VMS-6071
         BEGIN
          SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
            INTO v_toggle_value
            FROM cms_inst_param
           WHERE cip_inst_code = 1
             AND cip_param_key = 'VMS_5657_TOGGLE';
         EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
              v_toggle_value := 'Y';
         END;

         IF v_toggle_value = 'Y' THEN
           BEGIN
            SELECT COUNT(1)
              INTO v_prd_chk
              FROM vms_dormantfee_txns_config
             WHERE vdt_prod_code = v_prod_code
               AND vdt_card_type = v_card_type
               AND vdt_is_active = 1;
           EXCEPTION
            WHEN OTHERS THEN
              NULL;
           END;
         END IF;
         --EN: Added for VMS-6071


		IF NOT (P_DELIVERY_CHANNEL = '05' AND P_TXN_CODE IN ('04','06','07','13', '16', '17', '18', '97')
                    OR (P_DELIVERY_CHANNEL = '17' AND P_TXN_CODE ='04'))
					AND v_prd_chk = 0 --Added for VMS-6071
		THEN

			UPDATE CMS_APPL_PAN
	                SET CAP_LAST_TXNDATE = SYSDATE
			WHERE CAP_PAN_CODE = V_HASH_PAN
	                     AND TRUNC(NVL(CAP_LAST_TXNDATE,SYSDATE-1))<TRUNC(SYSDATE)
	                     AND CAP_PROXY_NUMBER IS NOT NULL;


		END IF;

    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            P_RESP_CODE := '99';
            P_RESP_MSG :=
                'Problem while inserting data into transaction log  AUDIT'
                || SUBSTR (SQLERRM, 1, 300);
    END;


    END IF;

    --En create a entry in txn log
IF l_audit_flag = 'T' THEN
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
        CTD_TXN_TYPE) 
     VALUES
       (P_DELIVERY_CHANNEL,
       CASE WHEN P_TXN_CODE=25 THEN '25' ELSE V_TRANCDE END,
        P_MSG,
        P_TXN_MODE,
        P_TRANDATE,
        P_TRANTIME,
        V_HASH_PAN,
        V_TRAN_AMT,
        P_CURRCODE,
        V_TRAN_AMT,
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
        V_TXN_TYPE); 

     P_ERRMSG   := P_ERRMSG;
     P_RESP_MSG := P_ERRMSG;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '22'; -- Server Declined
       /* passes transactionlog transCode back */
       P_TXN_CODE := V_TRANCDE;
       ROLLBACK;
       RETURN;
    END;
END IF;

    P_ERRMSG   := P_ERRMSG;
    P_RESP_MSG := P_ERRMSG;
    /* passes transactionlog transCode back */
    P_TXN_CODE := V_TRANCDE;
  WHEN EXP_DUPLICATE_REQUEST THEN
    ROLLBACK;
    If v_respcode  <> '215' then
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

    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,cam_type_code 	 
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,v_acct_type 
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =v_acct_number
        AND CAM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;
    P_ACCT_BAL := V_ACCT_BALANCE;
    BEGIN
     P_RESP_MSG  := P_ERRMSG;

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
       ROLLBACK;
    END;

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
        CARDSTATUS,
        TRANS_DESC,
        MERCHANT_NAME, 
        MERCHANT_CITY, 
        MERCHANT_STATE,
        Error_Msg,
        STORE_ID,  
        cr_dr_flag,
        acct_type,
        time_stamp,
        merchant_zip-- added for VMS-622 (redemption_delay zip code validation)
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
        TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')),
        P_CURRCODE,
        NULL,
        V_PROD_CODE,
        V_CARD_TYPE,
        P_TERMINALID,
        V_TOPUP_AUTH_ID,
        TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')),
        '0.00', 
        '0.00', 
        P_INSTCODE,
        V_ENCR_PAN,
        V_ENCR_PAN,
        V_PROXUNUMBER,
        P_RVSL_CODE,
        V_ACCT_NUMBER,
        V_ACCT_BALANCE,
        V_LEDGER_BALANCE,
        V_RESPCODE,
        V_CAP_CARD_STAT,
        V_TRANS_DESC,
        P_MERCHANT_NAME,  
        NULL, 
        NULL, 
        P_Errmsg,
        P_STORE_ID, 
        v_dr_cr_flag,
        v_acct_type,
        systimestamp,
        p_merchant_zip-- added for VMS-622 (redemption_delay zip code validation)
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CODE := '69';
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
    END;

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
        CTD_TXN_TYPE) 
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        P_MSG,
        P_TXN_MODE,
        P_TRANDATE,
        P_TRANTIME,
        V_HASH_PAN,
        V_TRAN_AMT,
        P_CURRCODE,
        V_TRAN_AMT,
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
        V_TXN_TYPE); 

    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '89'; -- Server Declined
       /* passes transactionlog transCode back */
       P_TXN_CODE := V_TRANCDE;
       ROLLBACK;
       RETURN;
    END;

    BEGIN
     SELECT A.RESPONSE_CODE
       INTO P_RESP_CODE
       FROM VMSCMS.TRANSACTIONLOG_VW A,                                --Added for VMS-5739/FSP-991
           (SELECT MIN(ADD_INS_DATE) MINDATE
             FROM VMSCMS.TRANSACTIONLOG_VW                    --Added for VMS-5739/FSP-991
            WHERE RRN = P_RRN and ACCT_BALANCE is not null) B
      WHERE A.ADD_INS_DATE = MINDATE AND RRN = P_RRN and ACCT_BALANCE is not null;


    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG    := 'Problem in selecting the response detail of Original transaction' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '89'; -- Server Declined
       /* passes transactionlog transCode back */
       P_TXN_CODE := V_TRANCDE;
       ROLLBACK;
       RETURN;
    END;

  WHEN EXP_ALREADY_INSERTED THEN
  If v_respcode  <> '215' then
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
    P_RESP_CODE := V_RESPCODE;
    P_RESP_MSG  := P_ERRMSG;
    /* passes transactionlog transCode back */
    P_TXN_CODE := V_TRANCDE;
    RETURN; 

  WHEN OTHERS THEN
  If v_respcode  <> '215' then
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
    P_ERRMSG := ' Error from main ' || SUBSTR(SQLERRM, 1, 200);
    /* passes transactionlog transCode back */
    P_TXN_CODE := V_TRANCDE;
END;
/
show error