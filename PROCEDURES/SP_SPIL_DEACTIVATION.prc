create or replace
PROCEDURE      VMSCMS.SP_SPIL_DEACTIVATION (P_INSTCODE         IN NUMBER,
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
                                        P_MBR_NUMB         IN VARCHAR2,
                                        P_RVSL_CODE        IN VARCHAR2,
                                        P_Merchant_Name    In Varchar2,
                                        P_STORE_ID         In varchar2, --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
                                        P_RESP_CODE        OUT VARCHAR2,
                                        P_ERRMSG           OUT VARCHAR2,
                                        P_RESP_MSG         OUT VARCHAR2,
                                        P_ACCT_BAL         OUT VARCHAR2,
                                        p_POSTBACK_URL_OUT OUT VARCHAR2
                                        ) AS
  /*************************************************
      * Created Date     :  28-Mar-2012
      * Created By       :  Srinivasu
      * PURPOSE          :  For Activation and load transaction in SPIL Delivery channel
      * Modified By      :  B.Dhinkaaran
      * Modified Date    :  10-Sep-2012
      * Modified Reason  : Loogging the merchant details in txn log table

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

     * Modified By      :  MageshKumar.S
     * Modified Date    :  18-June-2013
     * Modified Reason  :  Defect 0011272(De-Activation declined issue)
     * Reviewer         :   Dhiraj
     * Reviewed Date    :  19-JUN-2013
     * Build Number     :  RI0024.2_B0006

      * Modified By      : Santosh P
      * Modified Date    : 12-Jul-2013
      * Modified Reason  : Capture StoreId in transactionlog table
      * Modified for     : FSS-1146
      * Reviewer         :
      * Reviewed Date    :
      * Build Number     : RI0024.3_B0005

      * Modified By      : Anil Kumar
      * Modified Date    : 16-SEP-2013
      * Modified Reason  : To Update The Inventory Card Current Stock
      * Modified for     : DFCHOST-345
      * Reviewer         : SAGAR
      * Reviewed Date    : 16-SEP-2013
      * Build Number     : RI0024.4_B0015

      * Modified By      : Sai Prasad
      * Modified Date    : 23-SEP-2013
      * Modified Reason  : To handle DFCHOST-345 review
      * Modified for     : DFCHOST-345
      * Reviewer         : Dhiraj
      * Reviewed Date    : 23-SEP-2013
      * Build Number     : RI0024.4_B0018

      * Modified By      : MageshKumar S.
      * Modified Date    : 26-Nov-2013
      * Modified Reason  : Response code not logged properly
      * Modified for     : MVHOST-479
      * Reviewer         : Dhiraj
      * Reviewed Date    : 05/DEC/2013
      * Build Number     : RI0024.7_B0001

      * Modified Date    : 31-Jan-2014
      * Modified By      : Sagar More
      * Modified for     : Met-23 - Spil_3.0
      * Modified reason  : 1) merchant verified in target master and based on
                           the same appl_pan is updated
      * Reviewer         : Dhiraj
      * Reviewed Date    : 31-Jan-2014
      * Release Number   : RI0027.1_B0001

      * Modified by       : DHINAKARAN B
      * Modified for      : DFCHOST-344
      * Modified Date     : 5-MAR-2014
      * Reviewer          : Dhiraj
      * Reviewed Date     : 5-MAR-2014
      * Build Number      : RI0027.2_B0001

      * Modified by       : Pankaj S.
      * Modified for      : Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
      * Modified Date     : 24-MAR-2014
      * Reviewer          : Dhiraj
      * Reviewed Date     : 07-April-2014
      * Build Number      : RI0027.2_B0004

      * Modified by       : Ravi  N.
      * Modified for      : JIRA-1659 Modified for De-activation transaction should response with 10038 (card is redeemed)
      * Modified Date     : 26-MAY-2014
      * Build Number      : RI0027.2.1_B0003

      * Modified by       : Siva Kumar M
      * Modified for      : Mantis id(15668)   SPIL De-Activation, Account Balance & Ledger Balance not changing to "0"
      * Modified Date     : 18-Aug-2014
      * Reviewer          : Spankaj
      * Build Number      : RI0027.1.3_B0004

      * Modified Date     : 29-SEP-2014
       * Modified By      : Abdul Hameed M.A
       * Modified for     : FWR 70
       * Reviewer         : Spankaj
       * Release Number   : RI0027.4_B0002

       * Modified Date    : 11-Nov-2014
       * Modified By      : Siva Kumar M
       * Modified for     : Mantis ID:15747
       * Reviewer         : Spankaj
       * Release Number   : RI0027.4.3_B0003


    * Modified by       : Siva Kumar M
    * Modified Date     : 05-Aug-15
    * Modified For      : FSS-2320
    * Reviewer          : Pankaj S
    * Build Number      : RVMSGPRHOSTCSD_3.1_B0001

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
   * Modified Date    : 24/10/2017
   * Purpose          : FSS-5302:Retail Activation of Anonymous Products 
   * Reviewer         : Saravanan 
   * Release Number   : VMSGPRHOST17.10
     
   * Modified By      : DHINAKARAN B
   * Modified Date    : 10/01/2018
   * Purpose          : VMS-161
   * Reviewer         : Saravanan
   * Release Number   : VMSGPRHOST17.12.1
   
   * Modified By      : BASKAR KRISHNAN
   * Modified Date    : 04/03/2019
   * Purpose          : VMS-784
   * Reviewer         : Saravanan
   * Release Number   : VMSGPRHOST-R13
   
   * Modified By      : MAGESHKUMAR S
   * Modified Date    : 29/10/2019
   * Purpose          : SPIL Deactivation Issue- Duplicate RRN
   * Reviewer         : Saravanan
   * Release Number   : VMSGPRHOST-R20
   
   * Modified By      : BASKAR K
   * Modified Date    : 21/08/2020
   * Purpose          : VMS-2929
   * Reviewer         : Saravanan
   * Release Number   : VMSGPRHOST_R35_B0001
    
	* Modified By      : Karthick
    * Modified Date    : 06-28-2022
    * Purpose          : Archival changes.
    * Reviewer         : Venkat Singamaneni
    * Release Number   : VMSGPRHOST65 for VMS-5739/FSP-991
  *************************************************/
  V_CAP_PROD_CATG     CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
  V_CAP_CARD_STAT     CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_CAP_CAFGEN_FLAG   CMS_APPL_PAN.CAP_CAFGEN_FLAG%TYPE;
  V_FIRSTTIME_TOPUP   CMS_APPL_PAN.CAP_FIRSTTIME_TOPUP%TYPE;
  V_PROD_CODE         CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_CARD_TYPE         CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  v_profile_code      cms_prod_cattype.cpc_profile_code%type;
  V_CURRCODE          CMS_TRANSACTION_LOG_DTL.CTD_TXN_CURR%type;
  V_APPL_CODE         CMS_APPL_MAST.CAM_APPL_CODE%TYPE;
  V_RESONCODE         CMS_SPPRT_REASONS.CSR_SPPRT_RSNCODE%TYPE;
  V_RESPCODE          cms_response_mast.cms_response_id%type;
  V_CAPTURE_DATE      TRANSACTIONLOG.DATE_TIME%type;
  V_MBRNUMB           CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
  V_TXN_CODE          CMS_FUNC_MAST.CFM_TXN_CODE%TYPE;
  V_TXN_TYPE          CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
  V_TOPUP_AUTH_ID     TRANSACTIONLOG.AUTH_ID%TYPE;
  V_HASH_PAN           CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN           CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_BUSINESS_DATE      TRANSACTIONLOG.DATE_TIME%type;
  v_tran_date          transactionlog.date_time%type;
  V_TOPUPREMRK         CMS_PAN_SPPRT.CPS_FUNC_REMARK%type;
  V_ACCT_BALANCE       cms_acct_mast.cam_acct_bal%TYPE;
  V_LEDGER_BALANCE     cms_acct_mast.cam_acct_bal%TYPE;
  V_TRAN_AMT           TRANSACTIONLOG.TOTAL_AMOUNT%type;
  V_CARD_CURR          cms_bin_param.cbp_param_value%type;
  V_DATE               TRANSACTIONLOG.DATE_TIME%type;
  v_proxunumber        cms_appl_pan.cap_proxy_number%type;
  V_ACCT_NUMBER        CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_DUPCHK_CARDSTAT TRANSACTIONLOG.CARDSTATUS%TYPE;
  V_DUPCHK_ACCTBAL  TRANSACTIONLOG.ACCT_BALANCE%TYPE;
  V_TRANS_DESC   CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812
  V_ACTV_ACCT_BALANCE cms_acct_mast.cam_acct_bal%TYPE; -- Added by MageshKumar.S on 18-06-2013 for defect id : 0011272
  --Sn Getting  RRN DETAILS
  -- SN Added for DFCHOST-345
  V_Cmm_Merprodcat_Id Cms_Merinv_Merpan.Cmm_Merprodcat_Id%Type;
  V_CMM_MER_ID        CMS_MERINV_MERPAN.CMM_MER_ID%TYPE;
  V_CMM_LOCATION_ID   CMS_MERINV_MERPAN.CMM_LOCATION_ID%TYPE;
--END Added for DFCHOST-345

  v_dr_cr_flag  cms_transaction_mast.ctm_credit_debit_flag%TYPE; -- Added by MageshKumar.S on 26-11-2013 for Defect Id:MVHOST-479
  v_acct_type   cms_acct_mast.cam_type_code%TYPE;  -- Added by MageshKumar.S on 26-11-2013 for Defect Id:MVHOST-479
  

  v_cap_acct_id               CMS_APPL_PAN.CAP_ACCT_ID%TYPE;
  v_cap_cust_code             CMS_APPL_PAN.CAP_CUST_CODE%TYPE;
  v_gpr_pan                   CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  v_gpr_encr_pan              CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  v_cap_pin_off               CMS_APPL_PAN.CAP_PIN_OFF%TYPE;

  --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
  v_prfl_code                cms_appl_pan.cap_prfl_code%TYPE;
  v_prfl_flag                cms_transaction_mast.ctm_prfl_flag%type;
  v_orgnl_txn_code           transactionlog.txn_code%type;
  v_orgnl_trantype           transactionlog.txn_type%type;
  v_orgnl_mcccode            transactionlog.mccode%type;
  v_orgnl_txn_amnt           transactionlog.amount%type;
  v_pos_verification         transactionlog.pos_verification%type;
  v_internation_ind_response transactionlog.internation_ind_response %type;
  v_add_ins_date             transactionlog.add_ins_date %type;
  --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
  -- SN Added for FWR 70
   V_CURRENCY_CODE   cms_bin_param.cbp_param_value%type;
  v_upd_card_stat cms_appl_pan.cap_card_stat%type;
  --EN Added for 4.2 CL changes
   v_retail_activation  cms_prod_cattype.cpc_retail_activation%TYPE;
      v_VALINS_ACT_FLAG  cms_prod_cattype.cpc_VALINS_ACT_FLAG%TYPE;
   v_DEACTIVATION_CLOSED  cms_prod_cattype.cpc_DEACTIVATION_CLOSED%TYPE;
    v_cap_old_cardstat cms_appl_pan.cap_old_cardstat%type;
    V_Reason_Code  Cms_Spprt_Reasons.Csr_Spprt_Rsncode%Type;
    v_reason_desc  Cms_Spprt_Reasons.CSR_REASONDESC%Type;
    v_remarks TRANSACTIONLOG.remark%type;
    v_product_funding      CMS_PROD_CATTYPE.CPC_PRODUCT_FUNDING%TYPE;
    v_prod_fund            CMS_PROD_CATTYPE.CPC_PRODUCT_FUNDING%TYPE;
    v_order_prod_fund       vms_order_lineitem.vol_product_funding%type;
    v_respmsg           varchar2(500);
    exp_main_reject_record exception;
    exp_auth_reject_record exception;
    exp_duplicate_request exception;
    v_dupchk_count    number;
   v_actcount        number;
   v_deactcount      number;
   v_redem_txn_xount number;
   v_err_set           number(2) := 0;
   v_chk_target_mer   varchar2(1);    --Added for Spil_3.0
   v_gpr_chk                    varchar2(1);
   v_starter_canada varchar2(1):='N';
   v_count                number;
    v_b2b_cardFlag   VARCHAR2(10) :='N';
	v_Retperiod  date;  --Added for VMS-5739/FSP-991
    v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN
  P_ERRMSG     := 'OK';
  V_TOPUPREMRK := 'Online Card Topup';
  P_RESP_MSG   := 'Success';
  p_POSTBACK_URL_OUT :='0~0~0~0~0~0';
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
     SELECT CTM_TRAN_DESC, ctm_credit_debit_flag, -- Added by MageshKumar.S for MVHOST-479
     TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')) -- Added by MageshKumar.S for MVHOST-479
     INTO V_TRANS_DESC,v_dr_cr_flag,V_TXN_TYPE  --Added by MageshKumar S. for MVHOST-479
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

        select 1
        into   v_chk_target_mer
        from   cms_targetmerch_mast
        where  ctm_inst_code = P_INSTCODE
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
         CAP_ACCT_NO
         ,cap_acct_id,cap_cust_code,cap_pin_off,
         cap_prfl_code --Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
         ,cap_old_cardstat
     INTO V_CAP_CARD_STAT,
         V_CAP_PROD_CATG,
         V_CAP_CAFGEN_FLAG,
         V_APPL_CODE,
         V_FIRSTTIME_TOPUP,
         V_MBRNUMB,
         V_PROD_CODE,
         V_CARD_TYPE,
         V_PROXUNUMBER,
         V_ACCT_NUMBER
         ,v_cap_acct_id, v_cap_cust_code,v_cap_pin_off,
          v_prfl_code --Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)
          ,v_cap_old_cardstat
     FROM CMS_APPL_PAN
    WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INSTCODE;
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
     begin
    SELECT DECODE(UPPER(ordr.VOD_POSTBACK_RESPONSE),'TRUE','1','1','1','0')
      ||'~'
      ||litem.VLI_ORDER_ID
      ||'~'
      ||litem.VLI_LINEITEM_ID
      ||'~'
      ||ordr.vod_partner_id
      ||'~'
      ||NVL(ordr.VOD_POSTBACK_URL,'0')
      ||'~'
      ||ordr.vod_channel_id,oitem.VOL_PRODUCT_FUNDING
    into p_postback_url_out,v_order_prod_fund
    from vms_order_details ordr,
      vms_line_item_dtl litem,
      vms_order_lineitem oitem
    where ordr.vod_order_id=litem.vli_order_id
    and ordr.vod_partner_id=litem.vli_partner_id
    and ordr.vod_order_id=oitem.vol_order_id
    and ordr.vod_partner_id=oitem.vol_partner_id
    and oitem.vol_line_item_id=litem.vli_lineitem_id
    AND litem.vli_pan_code  =V_HASH_PAN;
    v_b2b_cardFlag   :='Y';
  EXCEPTION
  WHEN OTHERS THEN
    NULL;
  END;
  
  --SN: Added for VMS-6477 Fraud issue
  BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM cms_acct_mast
     WHERE cam_inst_code = p_instcode
       AND cam_acct_no = v_acct_number
       AND cam_acct_bal != cam_ledger_bal;
  EXCEPTION
    WHEN OTHERS THEN
        v_respcode := '89';
        p_errmsg := 'Error while selecting the BALANCE FROM ACCT_MAST '|| substr(sqlerrm,1,200);
        RAISE exp_main_reject_record;
  END;

  IF v_count > 0 THEN
    v_respcode := '18';
    p_errmsg := ' Card is Redeemed ';
    RAISE exp_main_reject_record;
  END IF;
  --EN: Added for VMS-6477 Fraud issue

  BEGIN
    --Profile Code of Product
    SELECT CPC_PROFILE_CODE, decode(nvl(cpc_b2b_flag,'N'),'N', cpc_retail_activation,0),nvl(CPC_VALINS_ACT_FLAG,'N'),nvl(CPC_DEACTIVATION_CLOSED,'N'),CPC_PRODUCT_FUNDING
        INTO v_profile_code, v_retail_activation,v_VALINS_ACT_FLAG,v_DEACTIVATION_CLOSED,v_prod_fund
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
      RAISE EXP_MAIN_REJECT_RECORD;
      END;
   if v_VALINS_ACT_FLAG='N' then -- Duplicate rrn check not required if First valins act flag is Y
--Sn added duplicate rrn check.
    begin
        SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
        INTO V_DUPCHK_CARDSTAT, V_DUPCHK_ACCTBAL
        from(SELECT CARDSTATUS, ACCT_BALANCE   FROM VMSCMS.TRANSACTIONLOG      --Added for VMS-5739/FSP-991
                WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
                DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                AND TXN_CODE IN ( '28', '36')         --- 28-DEACTIVATION AND UNLOAD , 36-DEACTIVATION
                and ACCT_BALANCE is not null
                order by add_ins_date desc)
        where rownum=1;
		IF SQL%ROWCOUNT = 0 THEN
		  SELECT nvl(CARDSTATUS,0), ACCT_BALANCE
        INTO V_DUPCHK_CARDSTAT, V_DUPCHK_ACCTBAL
        from(SELECT CARDSTATUS, ACCT_BALANCE   FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST     --Added for VMS-5739/FSP-991
                WHERE RRN = P_RRN AND CUSTOMER_CARD_NO = V_HASH_PAN AND
                DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                AND TXN_CODE IN ( '28', '36')         --- 28-DEACTIVATION AND UNLOAD , 36-DEACTIVATION
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
            WHERE CAM_ACCT_NO =V_ACCT_NUMBER
          
                                AND
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
end if;

  BEGIN
    --Added by srinivasuk for spildefect fix on 03-05-2012
    SELECT COUNT(*)
     INTO V_ACTCOUNT
     FROM VMSCMS.TRANSACTIONLOG                   --Added for VMS-5739/FSP-991
    WHERE CUSTOMER_CARD_NO = V_HASH_PAN AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND RESPONSE_CODE = '00' AND
         ((MSGTYPE in('0200','1200') AND TXN_CODE IN ('26','35','45')) OR -- msg type 1200 Added for Spil_3.0
          (MSGTYPE in('0400','1400') AND TXN_CODE IN ( '28', '36')));    -- msg type 1400 Added for Spil_3.0
		    IF SQL%ROWCOUNT = 0 THEN
			SELECT COUNT(*)
     INTO V_ACTCOUNT
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                   --Added for VMS-5739/FSP-991
    WHERE CUSTOMER_CARD_NO = V_HASH_PAN AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND RESPONSE_CODE = '00' AND
         ((MSGTYPE in('0200','1200') AND TXN_CODE IN ('26','35','45')) OR -- msg type 1200 Added for Spil_3.0
          (MSGTYPE in('0400','1400') AND TXN_CODE IN ( '28', '36')));    -- msg type 1400 Added for Spil_3.0
			END IF;

    SELECT COUNT(*)
     INTO V_DEACTCOUNT
     FROM VMSCMS.TRANSACTIONLOG                   --Added for VMS-5739/FSP-991
    WHERE CUSTOMER_CARD_NO = V_HASH_PAN AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND RESPONSE_CODE = '00' AND
         ((MSGTYPE in ('0200','1200') AND TXN_CODE IN('28','36')) OR -- msg type 1200 Added for Spil_3.0
          (MSGTYPE in ('0400','1400') AND TXN_CODE IN ( '26', '35')));   -- tmsg type 1400 Added for Spil_3.0
		  IF SQL%ROWCOUNT = 0 THEN
		      SELECT COUNT(*)
     INTO V_DEACTCOUNT
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                 --Added for VMS-5739/FSP-991
    WHERE CUSTOMER_CARD_NO = V_HASH_PAN AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND RESPONSE_CODE = '00' AND
         ((MSGTYPE in ('0200','1200') AND TXN_CODE IN('28','36')) OR -- msg type 1200 Added for Spil_3.0
          (MSGTYPE in ('0400','1400') AND TXN_CODE IN ( '26', '35')));   -- tmsg type 1400 Added for Spil_3.0
		  END IF;

    

    BEGIN
     IF V_ACTCOUNT <= V_DEACTCOUNT THEN
       V_RESPCODE := '8'; --Modified By Srinivasu.k for Reponse code Changes on 16-May-2012
       P_ERRMSG   := 'Deactivation not allowed for this card ';
       RAISE EXP_MAIN_REJECT_RECORD;
     END IF;

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

  END;
  --Sn redemption transaction Check
  --Add by deepa on Apr-13-2012 to restrict the de-activation transaction after redemption transaction

  BEGIN

    BEGIN

     SELECT COUNT(*)
       INTO V_REDEM_TXN_XOUNT
       FROM VMSCMS.TRANSACTIONLOG               --Added for VMS-5739/FSP-991
      WHERE CUSTOMER_CARD_NO = V_HASH_PAN AND RESPONSE_CODE = '00' AND
           INSTCODE = P_INSTCODE AND
           (TXN_CODE IN (SELECT CTM_TRAN_CODE
                        FROM CMS_TRANSACTION_MAST
                       WHERE CTM_DELIVERY_CHANNEL IN ('01', '02') AND
                            CTM_CREDIT_DEBIT_FLAG IN ('CR', 'DR') AND
                            CTM_INST_CODE = P_INSTCODE) AND
           DELIVERY_CHANNEL IN ('01', '02') OR
           (DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND TXN_CODE ='22' )); -- txn code 40 Added for Spil_3.0
		   IF SQL%ROWCOUNT = 0 THEN
		    SELECT COUNT(*)
       INTO V_REDEM_TXN_XOUNT
       FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST               --Added for VMS-5739/FSP-991
      WHERE CUSTOMER_CARD_NO = V_HASH_PAN AND RESPONSE_CODE = '00' AND
           INSTCODE = P_INSTCODE AND
           (TXN_CODE IN (SELECT CTM_TRAN_CODE
                        FROM CMS_TRANSACTION_MAST
                       WHERE CTM_DELIVERY_CHANNEL IN ('01', '02') AND
                            CTM_CREDIT_DEBIT_FLAG IN ('CR', 'DR') AND
                            CTM_INST_CODE = P_INSTCODE) AND
           DELIVERY_CHANNEL IN ('01', '02') OR
           (DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND TXN_CODE ='22' )); -- txn code 40 Added for Spil_3.0
		   END IF;
		   

    EXCEPTION
     WHEN OTHERS THEN
       V_RESPCODE := '21';
       P_ERRMSG   := 'Error while selecting the activation details ';
       RAISE EXP_MAIN_REJECT_RECORD;
    END;

    IF V_REDEM_TXN_XOUNT > 0 THEN

    -- V_RESPCODE := '21';
     V_RESPCODE := '18';-- Modified for De-activation transaction should response with 10038 (card is redeemed)
    -- P_ERRMSG   := 'De-Activation is not possible after Redemption transaction for the card ';
     P_ERRMSG   :=' Card is Redeemed ';
     RAISE EXP_MAIN_REJECT_RECORD;

    END IF;

  END;
  --En redemption transaction Check

    --Sn Added on 24-Mar-2014 during MVHOST_756 & MVCSD-4113 for getting original txn dtls
     BEGIN
       SELECT txn_code, txn_type, mccode, amount,
              pos_verification, internation_ind_response, add_ins_date
         INTO v_orgnl_txn_code, v_orgnl_trantype, v_orgnl_mcccode, v_orgnl_txn_amnt,
              v_pos_verification, v_internation_ind_response, v_add_ins_date from (
              SELECT txn_code, DECODE (txn_type, '1', 'F', '0', 'N') as txn_type, mccode, amount,
              pos_verification, internation_ind_response, add_ins_date
         --INTO v_orgnl_txn_code, v_orgnl_trantype, v_orgnl_mcccode, v_orgnl_txn_amnt,
           --   v_pos_verification, v_internation_ind_response, v_add_ins_date
         FROM VMSCMS.TRANSACTIONLOG              --Added for VMS-5739/FSP-991
        WHERE -- rrn = p_rrn
          --AND
          customer_card_no = v_hash_pan
          AND instcode = p_instcode
          AND response_code = '00'
          AND msgtype IN ('0200', '1200')
          AND txn_code IN ( '26','35','45')
          AND delivery_channel = p_delivery_channel order by add_ins_date desc) where rownum=1;
		  IF SQL%ROWCOUNT = 0 THEN
		    SELECT txn_code, txn_type, mccode, amount,
              pos_verification, internation_ind_response, add_ins_date
         INTO v_orgnl_txn_code, v_orgnl_trantype, v_orgnl_mcccode, v_orgnl_txn_amnt,
              v_pos_verification, v_internation_ind_response, v_add_ins_date from (
              SELECT txn_code, DECODE (txn_type, '1', 'F', '0', 'N') as txn_type, mccode, amount,
              pos_verification, internation_ind_response, add_ins_date
         --INTO v_orgnl_txn_code, v_orgnl_trantype, v_orgnl_mcccode, v_orgnl_txn_amnt,
           --   v_pos_verification, v_internation_ind_response, v_add_ins_date
         FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST              --Added for VMS-5739/FSP-991
        WHERE -- rrn = p_rrn
          --AND
          customer_card_no = v_hash_pan
          AND instcode = p_instcode
          AND response_code = '00'
          AND msgtype IN ('0200', '1200')
          AND txn_code IN ( '26','35','45')
          AND delivery_channel = p_delivery_channel order by add_ins_date desc) where rownum=1;
		  END IF;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          v_respcode := '53';
          p_errmsg := 'Matching transaction not found';
          RAISE exp_main_reject_record;
       WHEN OTHERS THEN
          v_respcode := '21';
          p_errmsg :='Error while selecting original txn dtls-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
    END;
   --En Added on 24-Mar-2014 during MVHOST_756 & MVCSD-4113 for getting original txn dtls

  --Sn check the min and max limit for topup


  
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

  --Sn Added by MageshKumar.S on 18-06-2013 for defect id : 0011272

    BEGIN
            SELECT CAM_ACCT_BAL
            INTO V_ACTV_ACCT_BALANCE
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =V_ACCT_NUMBER
         
                                AND
            CAM_INST_CODE = P_INSTCODE;

        EXCEPTION

        WHEN NO_DATA_FOUND THEN
        V_RESPCODE := '21';
        P_ERRMSG   := 'Invalid Card number ' || V_HASH_PAN;

        RAISE EXP_MAIN_REJECT_RECORD;

            WHEN OTHERS THEN
                V_RESPCODE := '12';
                P_ERRMSG   := 'Error while selecting acct balance ' ||substr(sqlerrm,1,200);
                RAISE EXP_MAIN_REJECT_RECORD;
        END;

  BEGIN

  IF P_AMOUNT <> V_ACTV_ACCT_BALANCE AND  v_retail_activation<>1  AND v_b2b_cardFlag='N' THEN

     V_RESPCODE := '43';
     P_ERRMSG   := 'Amount is not equal to account balance';
     RAISE EXP_MAIN_REJECT_RECORD;
  END IF;

    EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;

  END;

 --En Added by MageshKumar.S on 18-06-2013 for defect id : 0011272

--SN Added for FWR 70
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
if(V_CURRENCY_CODE='124') then
V_STARTER_CANADA:='Y';
end if;
--EN Added for FWR 70

--SN Added for 4.2 CL changes

IF v_retail_activation =1 OR v_retail_activation=2  THEN
     v_upd_card_stat :=0;
ELSE
     v_upd_card_stat :=v_cap_card_stat;
END IF;
--EN Added for 4.2 CL changes


  --------------Sn For Debit Card No need using authorization -----------------------------------
  IF V_CAP_PROD_CATG = 'P' THEN
    --Sn call to authorize txn
    BEGIN
     SP_AUTHORIZE_TXN_CMS_AUTH(P_INSTCODE,
                          P_MSG,
                          P_RRN,
                          P_DELIVERY_CHANNEL,
                          P_TERMINALID,
                          CASE WHEN v_retail_activation=1 THEN '36' WHEN v_b2b_cardFlag='Y' AND v_orgnl_txn_code='26' THEN '28'  WHEN v_b2b_cardFlag='Y' AND v_orgnl_txn_code='35' THEN '36' ELSE P_TXN_CODE END,
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
                          CASE WHEN (v_retail_activation=1 OR (v_b2b_cardFlag='Y' AND v_orgnl_txn_code='35')) THEN 0 ELSE V_TRAN_AMT END,
                          V_TOPUP_AUTH_ID,
                          V_RESPCODE,
                          V_RESPMSG,
                          V_Capture_Date,'Y','N',
                          v_VALINS_ACT_FLAG);

     IF V_RESPCODE <> '00' AND V_RESPMSG <> 'OK' THEN
       P_ERRMSG := V_RESPMSG;
       RAISE EXP_AUTH_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_AUTH_REJECT_RECORD THEN
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

  IF v_order_prod_fund is not null THEN
        v_product_funding := v_order_prod_fund;
  ELSE
        v_product_funding := v_prod_fund;
  END IF; 
  --En create a record in pan spprt
  --Added by srinivasu for Stater card issuance defect fix on 19-June-2012
  IF P_ERRMSG = 'OK' THEN

    BEGIN
     UPDATE CMS_APPL_PAN
        set CAP_FIRSTTIME_TOPUP = (CASE WHEN (v_b2b_cardFlag='Y' AND v_product_funding='1') THEN CAP_FIRSTTIME_TOPUP ELSE 'N' END),
            --cap_card_stat = decode(v_chk_target_mer,'1','0',cap_card_stat), --Added for Spil_3.0
             CAP_CARD_STAT  = DECODE (v_chk_target_mer,'1','0',decode(V_STARTER_CANADA,'Y','0',DECODE (v_b2b_cardFlag,'Y',v_cap_old_cardstat,V_UPD_CARD_STAT))), --Modified for 4.2 Changes
            cap_pin_flag  = decode(v_chk_target_mer,'1','Y',cap_pin_flag),   --Added for Spil_3.0
            CAP_PIN_OFF   = DECODE(V_CHK_TARGET_MER,'1',null,decode(V_UPD_CARD_STAT,'0',null,null)), --Added for 4.2 CL changes
            cap_active_date=decode(V_UPD_CARD_STAT,'0',null,null) --Added for 4.2 CL changes
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
       RAISE EXP_MAIN_REJECT_RECORD;
     WHEN OTHERS THEN
       P_ERRMSG   := 'Error while Updating first time topup flag' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESPCODE := '21';
       RAISE EXP_MAIN_REJECT_RECORD;
    END;




   /* Start  Added for DFCHOST-345*/
    BEGIN
     SELECT  CMM_MER_ID, CMM_LOCATION_ID, CMM_MERPRODCAT_ID
       INTO
           V_CMM_MER_ID,
           V_CMM_LOCATION_ID,
           V_CMM_MERPRODCAT_ID
       FROM CMS_MERINV_MERPAN
      WHERE CMM_PAN_CODE = V_HASH_PAN
      AND CMM_INST_CODE = P_INSTCODE;
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
            SELECT cap_pan_code,cap_pan_code_encr
            INTO v_gpr_pan,v_gpr_encr_pan
            FROM (
            SELECT cap_pan_code,cap_pan_code_encr
              FROM cms_appl_pan
             WHERE cap_inst_code = p_instcode
               AND cap_cust_code = v_cap_cust_code
               AND cap_acct_id = v_cap_acct_id
               AND cap_startercard_flag = 'N'
               ORDER BY CAP_ins_date DESC)
               WHERE ROWNUM=1;

            v_gpr_chk := 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
               v_gpr_chk := 'N';
         WHEN OTHERS
         THEN
               p_errmsg :=
                     'Problem while fetching GPR card '
                  || SUBSTR (SQLERRM, 1, 100);
               v_respcode := '21';
               RAISE exp_main_reject_record;
      END;

      IF v_gpr_chk = 'N'
         THEN

            BEGIN
               UPDATE cms_appl_pan
                  SET cap_card_stat = 0,
                      cap_firsttime_topup = 'N',
                      cap_pin_off = '',
                      cap_pin_flag = 'Y'
                WHERE cap_inst_code = p_instcode
                      AND cap_pan_code = v_hash_pan;

               IF SQL%ROWCOUNT = 0
               THEN
                  p_errmsg := 'Starer card not updated to inactive status';
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
               END IF;

               IF v_cap_pin_off is not null THEN
                INSERT INTO cms_cardiss_pin_hist
                        (ccp_pan_code, ccp_mbr_numb, ccp_pin_off, ccp_ins_date, ccp_rrn,
                         ccp_pan_code_encr
                        )
                 VALUES (v_hash_pan, p_mbr_numb, v_cap_pin_off, SYSDATE, p_rrn,
                         v_encr_pan
                        );
               END IF;

            EXCEPTION
               WHEN exp_main_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Problem while updating starter card to inactive '|| SUBSTR (SQLERRM, 1, 100);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;

             BEGIN
                sp_log_cardstat_chnge (p_instcode,
                                       v_hash_pan,
                                       v_encr_pan,
                                       v_topup_auth_id,
                                       '08',
                                       p_rrn,
                                       p_trandate,
                                       p_trantime,
                                       v_respcode,
                                       p_errmsg
                                      );

                IF v_respcode <> '00' AND p_errmsg <> 'OK'
                THEN
                   RAISE exp_main_reject_record;
                END IF;
            EXCEPTION
                WHEN exp_main_reject_record
                THEN
                   RAISE;
                WHEN OTHERS
                THEN
                   v_respcode := '21';
                   p_errmsg :=
                         'Error while logging system initiated card status change '
                      || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_main_reject_record;
            END;

            BEGIN
               UPDATE cms_merinv_merpan
                  SET cmm_activation_flag = 'M'
                WHERE cmm_pan_code = v_hash_pan
                AND cmm_inst_code = p_instcode;

               IF SQL%ROWCOUNT = 0
               THEN
                  p_errmsg :=
                        'Error while Updating Card Activation Flag in MERPAN '|| SUBSTR (SQLERRM, 1, 200);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while Updating Card Activation Flag in MERPAN '|| SUBSTR (SQLERRM, 1, 200);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;

            BEGIN
               UPDATE cms_merinv_stock
                  SET cms_curr_stock = (cms_curr_stock + 1)
                WHERE cms_inst_code = p_instcode
                  AND cms_merprodcat_id = v_cmm_merprodcat_id
                  AND cms_location_id = v_cmm_location_id;

               IF SQL%ROWCOUNT = 0
               THEN
                  p_errmsg :=
                        'Error while Updating Stock Value in invStock'|| SUBSTR (SQLERRM, 1, 200);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while Updating Stock Value in invStock'|| SUBSTR (SQLERRM, 1, 200);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;
      ELSIF v_gpr_chk = 'Y'
         THEN
            BEGIN
               UPDATE cms_appl_pan
                  SET cap_card_stat = 9
                WHERE cap_inst_code = p_instcode
                      AND cap_pan_code = v_hash_pan;

               IF SQL%ROWCOUNT = 0
               THEN
                  p_errmsg := 'Starer card not updated to close status';
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_main_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Problem while updating starter card '|| SUBSTR (SQLERRM, 1, 100);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;

            BEGIN
                sp_log_cardstat_chnge (p_instcode,
                                       v_hash_pan,
                                       v_encr_pan,
                                       v_topup_auth_id,
                                       '02',
                                       p_rrn,
                                       p_trandate,
                                       p_trantime,
                                       v_respcode,
                                       p_errmsg
                                      );

                IF v_respcode <> '00' AND p_errmsg <> 'OK'
                THEN
                   RAISE exp_main_reject_record;
                END IF;
            EXCEPTION
                WHEN exp_main_reject_record
                THEN
                   RAISE;
                WHEN OTHERS
                THEN
                   v_respcode := '21';
                   p_errmsg :=
                         'Error while logging system initiated card status change '
                      || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_main_reject_record;
            END;

            BEGIN
               UPDATE cms_appl_pan
                  SET cap_card_stat = 9
                WHERE cap_inst_code = p_instcode AND cap_pan_code = v_gpr_pan;

               IF SQL%ROWCOUNT = 0
               THEN
                  p_errmsg := 'GPR card not updated to close status';
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_main_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Problem while updating GPR card '|| SUBSTR (SQLERRM, 1, 100);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;

            BEGIN
                sp_log_cardstat_chnge (p_instcode,
                                       v_gpr_pan,
                                       v_gpr_encr_pan,
                                       v_topup_auth_id,
                                       '02',
                                       p_rrn,
                                       p_trandate,
                                       p_trantime,
                                       v_respcode,
                                       p_errmsg
                                      );

                IF v_respcode <> '00' AND p_errmsg <> 'OK'
                THEN
                   RAISE exp_main_reject_record;
                END IF;
            EXCEPTION
                WHEN exp_main_reject_record
                THEN
                   RAISE;
                WHEN OTHERS
                THEN
                   v_respcode := '21';
                   p_errmsg :=
                         'Error while logging system initiated card status change '
                      || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_main_reject_record;
            END;

      END IF;
    END IF;
      --Added for VMS18.03
    IF v_VALINS_ACT_FLAG ='Y' AND v_DEACTIVATION_CLOSED ='Y'
    then
    BEGIN
               UPDATE cms_appl_pan
                  SET cap_card_stat = 9
                WHERE cap_inst_code = p_instcode AND cap_pan_code = V_HASH_PAN;
               IF SQL%ROWCOUNT = 0
               THEN
                  p_errmsg := ' card not updated to close status';
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_main_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Problem while updating  card '|| SUBSTR (SQLERRM, 1, 100);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;
            BEGIN
                sp_log_cardstat_chnge (p_instcode,
                                       V_HASH_PAN,
                                       v_encr_pan,
                                       v_topup_auth_id,
                                       '02',
                                       p_rrn,
                                       p_trandate,
                                       p_trantime,
                                       v_respcode,
                                       p_errmsg
                                      );
                IF v_respcode <> '00' AND p_errmsg <> 'OK'
                THEN
                   RAISE exp_main_reject_record;
                END IF;
            EXCEPTION
                WHEN exp_main_reject_record
                THEN
                   RAISE;
                WHEN OTHERS
                THEN
                   v_respcode := '21';
                   p_errmsg :=
                         'Error while logging system initiated card status change '
                      || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_main_reject_record;
            END;
            BEGIN
               SELECT CSR_SPPRT_RSNCODE,CSR_REASONDESC
               INTO v_reason_code,v_reason_desc
               FROM cms_spprt_reasons
               WHERE CSR_INST_CODE = p_instcode
               AND CSR_SPPRT_KEY = 'DEACTCLOSE';
            v_remarks :='Merchant request to Void the card';
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                P_ERRMSG   := 'DEACTIVATION CLOSE reason code is not present in master';
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
      'DEACTCLOSE',
      v_reason_code,
      v_reason_desc,
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
      END IF;
  


  END IF;

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

  --IF errmsg is OK then balance amount will be returned
  IF P_ERRMSG = 'OK' THEN
    --Sn of Getting  the Acct Balannce
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =V_ACCT_NUMBER
          
                 AND
           CAM_INST_CODE = P_INSTCODE
        FOR UPDATE NOWAIT;
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

    --En of Getting  the Acct Balannce
    P_ACCT_BAL := V_ACCT_BALANCE;

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
	   
	IF (v_Retdate>v_Retperiod)  THEN                             --Added for VMS-5739/FSP-991
	
       Update Transactionlog
         Set Store_Id = P_STORE_ID, reason_code=v_reason_code, reason=v_reason_desc, remark=v_remarks
       Where Instcode = P_Instcode
         --And Terminal_Id = P_Terminalid       -- commented for Mantis id:15747.
         And Rrn = P_Rrn
         AND CUSTOMER_CARD_NO = V_HASH_PAN
         And Business_Date = P_Trandate
         AND TXN_CODE=(CASE WHEN v_retail_activation=1 THEN '36' WHEN v_b2b_cardFlag='Y' THEN decode(v_orgnl_txn_code,'26','28','35','36',p_txn_code) ELSE p_txn_code END)
         AND delivery_channel = p_delivery_channel;
	
	ELSE
	
	 Update VMSCMS_HISTORY.TRANSACTIONLOG_HIST         --Added for VMS-5739/FSP-991
         Set Store_Id = P_STORE_ID, reason_code=v_reason_code, reason=v_reason_desc, remark=v_remarks
       Where Instcode = P_Instcode
         --And Terminal_Id = P_Terminalid       -- commented for Mantis id:15747.
         And Rrn = P_Rrn
         AND CUSTOMER_CARD_NO = V_HASH_PAN
         And Business_Date = P_Trandate
         AND TXN_CODE=(CASE WHEN v_retail_activation=1 THEN '36' WHEN v_b2b_cardFlag='Y' THEN decode(v_orgnl_txn_code,'26','28','35','36',p_txn_code) ELSE p_txn_code END)
         AND delivery_channel = p_delivery_channel;
		 
	END IF;

    If Sql%Rowcount = 0 Then
       P_ERRMSG   := 'Error while Updating StoreId in Transactionlog table' ||
                  Substr(Sqlerrm, 1, 200);
       V_RESPCODE := '21';
       Raise Exp_Main_Reject_Record;
     END IF;
   EXCEPTION
       WHEN OTHERS THEN
        P_ERRMSG   := 'Error while Updating StoreId in Transactionlog table' ||
                    Substr(Sqlerrm, 1, 200);
        V_RESPCODE := '21';
        Raise Exp_Main_Reject_Record;
   END;

   --Sn Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)

    BEGIN
     SELECT  CTM_PRFL_FLAG
       INTO v_prfl_flag
      FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = v_orgnl_txn_code AND --'26' AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_TRANS_DESC := 'Transaction type' || P_TXN_CODE;
     WHEN OTHERS THEN
       V_TRANS_DESC := 'Transaction type ' || P_TXN_CODE;
    END;


    BEGIN
       IF v_add_ins_date IS NOT NULL AND v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y' THEN
          pkg_limits_check.sp_limitcnt_rever_reset
                              (p_instcode,
                               NULL,
                               NULL,
                               v_orgnl_mcccode,
                               v_orgnl_txn_code,
                               v_orgnl_trantype,
                               v_internation_ind_response,
                               v_pos_verification,
                               v_prfl_code,
                               v_tran_amt,
                               v_orgnl_txn_amnt,
                               p_delivery_channel,
                               v_hash_pan,
                               v_add_ins_date,
                               v_respcode,
                               p_errmsg
                              );

                           -- added for mantis id:15668
               IF p_errmsg <> 'OK' THEN
                  RAISE exp_main_reject_record;
               END IF;
       END IF;

      /* IF p_errmsg <> 'OK' THEN  commented for mantis id:15668
          RAISE exp_main_reject_record;
       END IF;*/
    EXCEPTION
       WHEN exp_main_reject_record THEN
          RAISE;
       WHEN OTHERS THEN
          v_respcode := '21';
          p_errmsg := 'Error from Limit count reveer Process ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
    END;
   --En Added on 24-Mar-2014 for Enabling Limit configuration and validation (MVHOST_756 & MVCSD-4113)

EXCEPTION
  --<< MAIN EXCEPTION >>
  WHEN EXP_AUTH_REJECT_RECORD THEN
    ROLLBACK;

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
        P_ACCT_BAL := V_ACCT_BALANCE;
      --Sn select response code
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
            p_errmsg :='Problem while selecting data from response master '|| v_respcode|| SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
            ROLLBACK;
      END;
      --En select response code
     --En Added by MageshKumar S. for MVHOST-479


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
        STORE_ID,    --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
        --Sn Added by MageshKumar S. for MVHOST-479
        cr_dr_flag,
        acct_type,
        time_stamp
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
        TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')),--Modified during MVOST-479
        P_CURRCODE,
        NULL,
        V_PROD_CODE,
        V_CARD_TYPE,
        P_TERMINALID,
        V_TOPUP_AUTH_ID,
        TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')),--Modified during MVOST-479
        '0.00', -- NULL replaced by 0.00 during MVOST-479
        '0.00', -- NULL replaced by 0.00 during MVOST-479
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
        Null, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        P_Errmsg,
        P_STORE_ID, --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
        --Sn Added by MageshKumar S. for MVHOST-479
        v_dr_cr_flag,
        v_acct_type,
        systimestamp
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

    --Sn generate auth id
    BEGIN
     --     SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;

     --     SELECT V_AUTHID_DATE || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
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
       P_ERRMSG    := 'Problem while selecting data from response response master ' ||
                   V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '69';
       ---ISO MESSAGE FOR DATABASE ERROR Server Declined
       ROLLBACK;
    END;

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
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,cam_type_code    --Added by MageshKumar S. for MVHOST-479
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,v_acct_type  --Added by MageshKumar S. for MVHOST-479
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO = V_ACCT_NUMBER
          
                 AND
           CAM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;
    P_ACCT_BAL := V_ACCT_BALANCE;
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
        STORE_ID,   --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
        --Sn Added by MageshKumar S. for MVHOST-479
        cr_dr_flag,
        acct_type,
        time_stamp
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
         TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')),--Modified during MVOST-479
        P_CURRCODE,
        NULL,
        V_PROD_CODE,
        V_CARD_TYPE,
        P_TERMINALID,
        V_TOPUP_AUTH_ID,
        TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')),--Modified during MVOST-479
        '0.00', -- NULL replaced by 0.00 during MVOST-479
        '0.00', -- NULL replaced by 0.00 during MVOST-479
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
        P_STORE_ID,     --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
        --Sn Added by MageshKumar S. for MVHOST-479
        v_dr_cr_flag,
        v_acct_type,
        systimestamp
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

    --Sn select response code and insert record into txn log dtl
    BEGIN
   
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
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,cam_type_code   --Added by MageshKumar S. for MVHOST-479
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,v_acct_type --Added by MageshKumar S. for MVHOST-479
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =v_acct_number
           
                 AND
           CAM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;
    P_ACCT_BAL := V_ACCT_BALANCE;
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
        MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        Merchant_City,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        MERCHANT_STATE,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        Error_Msg,
        STORE_ID,   --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
        --Sn Added by MageshKumar S. for MVHOST-479
        cr_dr_flag,
        acct_type,
        time_stamp
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
        TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')),--Modified during MVOST-479
        P_CURRCODE,
        NULL,
        V_PROD_CODE,
        V_CARD_TYPE,
        P_TERMINALID,
        V_TOPUP_AUTH_ID,
        TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '999999999999999990.99')),--Modified during MVOST-479
        '0.00', -- NULL replaced by 0.00 during MVOST-479
        '0.00', -- NULL replaced by 0.00 during MVOST-479
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
        NULL,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        NULL, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        P_Errmsg,
        P_STORE_ID,  --SantoshP 12 JUL 13 : FSS-1146 : STORE_ID CAPTURE CHANGES
        --Sn Added by MageshKumar S. for MVHOST-479
        v_dr_cr_flag,
        v_acct_type,
        systimestamp
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
       INTO P_RESP_CODE --V_RESPCODE --Modified by Pankaj S. on 26_Feb_2013
       FROM VMSCMS.TRANSACTIONLOG_VW A,                           --Added for VMS-5739/FSP-991
           (SELECT MIN(ADD_INS_DATE) MINDATE
             FROM VMSCMS.TRANSACTIONLOG_VW                       --Added for VMS-5739/FSP-991
            WHERE RRN = P_RRN and ACCT_BALANCE is not null) B
      WHERE A.ADD_INS_DATE = MINDATE AND RRN = P_RRN and ACCT_BALANCE is not null;
	 
	 

     

    EXCEPTION
     WHEN OTHERS THEN

       P_ERRMSG    := 'Problem in selecting the response detail of Original transaction' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '89'; -- Server Declined
       ROLLBACK;
       RETURN;

    END;

  WHEN OTHERS THEN
    P_ERRMSG := ' Error from main ' || SUBSTR(SQLERRM, 1, 200);
END;
/
show error