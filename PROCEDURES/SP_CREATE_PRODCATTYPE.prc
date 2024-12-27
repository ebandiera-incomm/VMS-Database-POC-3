create or replace
PROCEDURE  VMSCMS.SP_CREATE_PRODCATTYPE(P_INSTCODE          IN NUMBER,
                                        P_PRODCODE         IN VARCHAR2,
                                        P_TYPEDESC         IN VARCHAR2,
                                        P_STRINGOFCUSTCATG IN VARCHAR2, --string of customer category code, can be null if the user doesn't want to create a relation at the same time when he creates a prod cattype
                                        P_SEP              IN CHAR,
                                        P_VENDOR           IN VARCHAR2,
                                        P_STOCK            IN VARCHAR2,
                                        P_SNAME          IN VARCHAR2,
                                        P_PREFIX         IN VARCHAR2,
                                        P_ACCT_PREFIX IN VARCHAR2, -- added by Trivikram on 06-05-2012 , For Account Prefix
                                        P_PROFILECODE    IN VARCHAR2, --Vikrant 11june08
                                        P_PRODID         IN VARCHAR2,
                                        P_PACKAGEID      IN VARCHAR2,
                                        P_ACHTXN_FLG     IN VARCHAR2,
                                        P_SERNO_FLG     IN NUMBER,   -- Added by Santosh on 21 Aug 2012 for Shuffle PAN Serial Number
                                        P_CPC_ODFI_TAXREFUNDNO IN VARCHAR2,
                                        P_CPC_ACHTXN_DAYCNT IN NUMBER,
                                        P_CPC_ACHTXN_DAYMINAMT IN NUMBER,
                                        P_CPC_ACHTXN_DAYMAXAMT IN NUMBER,
                                        P_CPC_ACHTXN_WEEKCNT IN NUMBER,
                                        P_CPC_ACHTXN_WEEKMAXAMT IN NUMBER,
                                        P_CPC_ACHTXN_MONMAXAMT IN NUMBER,
                                        P_CPC_ACHTXN_DAYMAXTRANAMT IN NUMBER,
                                        P_CPC_ACHTXN_MONCNT IN NUMBER,
                                        P_ACH_MIN_AGE    IN NUMBER,
                                        P_PASSIVE_PERIOD IN NUMBER,
          --Added by Sivapragasam on Feb 20 2012 for Starter Card Configuration Changes
                                        P_STARTER_CARD IN VARCHAR2,
                                        P_MINSPIL_LOADAMT NUMBER,
                                        P_MAXSPIL_LOADAMT NUMBER,
                                        P_STARTER_GPRISSUE VARCHAR2,
                                        P_Starter_Gpr_Cardtype Number,
                                        P_MIN_INIT_LOADAMT NUMBER,--Added for JIRA - 749 For release 23.1.1
                                        P_URL IN VARCHAR2, -- Parameter added By Santosh on 0& Aug 13 for MVHOST-314
                                        P_DFLTPIN_FLAG IN VARCHAR2, -- Added on 09-10-2013 for JH-3
                                        P_PINAPPL_FLAG IN VARCHAR2, -- Added on 09-10-2013 for JH-3
                                        P_STORLOCFLAG  IN VARCHAR2, --Added on 23/10/13 for  JH-8
                                        P_Del_Met  IN NUMBER,--Added for CR:038 DFG CCF changes on 26-Dec-2012
                                        P_CardEXPPENDING IN NUMBER, --Added for MVCSD-4121
                                        P_CardRplPeroid IN  NUMBER, --Added for MVCSD-4121
                                        P_ACHINITLOADAMNTCHECK VARCHAR2, --Added for FSS-1701
					                              P_INVCHECK_FLAG IN VARCHAR2, --Added for fss-1785
                                        P_STRCRD_DISPNAME   IN VARCHAR2,
                                        P_STRREPLACE_OPTION IN VARCHAR,
                                        P_REPLACE_PRODCATG  IN VARCHAR,
                                        P_TOKENELIGIBLESTATU IN VARCHAR,
                                        P_TOKENPRORETRYMAX   IN VARCHAR2,
                                        P_TOKENRETPERIOD IN VARCHAR2,
                                        p_custdtlupdPeriod in varchar2,
                                      -- p_custdtlupdPeriodFrncy in varchar2,
                                        p_lastfour_digitpin in varchar2,
                                        P_EXP_DATE_EXEMPTION IN VARCHAR2,
                                        P_REDEMPTION_FLAG IN VARCHAR2,--added for FSS-4647
                                        P_CVVCheck in VARCHAR2,--added for cvv+
                                        P_CVVPlusShort_Name in varchar2,--added for cvv+
                                        P_SWEEP_FLAG IN varchar2,--ADDED FOR SWEEP PROGRAM
                                        P_SWEEP_PERIOD IN  NUMBER,--ADDED FOR SWEEP PROGRAM
                                        P_INACTTOKENRETPERIOD IN VARCHAR2,--Added for master card tokenization
                                        P_B2BFLAG IN VARCHAR2,--ADDED FOR B2B CONFIG
                                        P_B2BCARDSTATUS IN VARCHAR2,--ADDED FOR B2B CONFIG
                                        P_B2BACTIVATIONCODE IN VARCHAR2,--ADDED FOR B2B CONFIG
                                        P_B2BLIMIT_PROFILECODE IN VARCHAR2,--ADDED FOR B2B CONFIG
                                        P_B2BREG_NAME_MATCH IN VARCHAR2,--ADDED FOR B2B CONFIG
                                        P_KYCCHECK IN VARCHAR2, --ADDED FOR FSS-5058
                                        P_CVV2VERIFICATION IN VARCHAR2,
                                        P_EXPDATEVALIDATION IN VARCHAR2,
                                        P_ACCTBALVALIDATION IN VARCHAR2,
                                        P_REPLACEMENT_PROVISION_FLAG IN VARCHAR2,
                                        P_ACCTBALCHECKTYPE IN VARCHAR2,
                                        P_ACCTBALCHECKVALUE IN NUMBER,
                                        P_ISSUPRODCONFIGID IN VARCHAR2,
                                        P_CONSUMEDFLAG IN VARCHAR2,
                                        P_CONSUMEDSTATUS IN VARCHAR2,
                                        P_RENEWREPLACEOPTION IN VARCHAR2,
                                        P_RENEWREPLACEPRODCODE IN VARCHAR2,
                                        P_RENEWREPLACECARDTYPE IN VARCHAR2,
                                       -- P_PRODUCTTYPE IN VARCHAR2,
                                        P_REGISTRATION_CHECK IN VARCHAR2,
                                        P_RELOADABLE_CHECK IN VARCHAR2,
                                        --P_RETAIL_SALE IN VARCHAR2,
                                        P_PROD_SUFFIX IN VARCHAR2,
                                        P_START_CARDNO IN VARCHAR2,
                                        P_END_CARDNO IN VARCHAR2,
                                        P_CCFFORMAT_VER IN VARCHAR2,
                                        P_DCMSID IN VARCHAR2,
                                        P_PROD_UPC IN VARCHAR2,
                                        P_PACKING_UPC IN VARCHAR2,
                                        P_CARD_PROD_ACCEPTANCE IN VARCHAR2,
                                        P_STATE_LAW IN VARCHAR2,
                                        P_VISAPIF_OR_MC IN VARCHAR2,
                                        P_CASH_ACCESS IN VARCHAR2,
                                        P_DISABLE_REPLACEMENT IN VARCHAR2,
                                        P_PRIOR_TOEXPIRATION_CHECK IN NUMBER,
                                        P_MIN_BAL_REPLACEMENT IN NUMBER,
                                        P_DISABLE_REPLACEMENT_MSG IN VARCHAR2,
                                        P_ISSUING_BANK IN VARCHAR2,
                                        P_ICA IN VARCHAR2,
                                        P_ISSUING_BANK_ADDRESS IN VARCHAR2,
                                        P_PRODUCT_DENO IN VARCHAR2,
                                        P_OPEN_MIN IN VARCHAR2,
                                        P_OPEN_MAX IN VARCHAR2,
                                        P_FIXED_VALUE IN VARCHAR2,
                                        P_FROMDATE IN DATE,
                                        P_ROUTING_NUM IN VARCHAR2,
                                        P_INST_ID IN VARCHAR2,
                                        P_TRANSIT_NUM IN VARCHAR2,
                                        P_PROD_EMAIL IN VARCHAR2,
                                        P_FRMEMAILFRALERTS IN VARCHAR2,
                                        P_APP_NAME IN VARCHAR2,
                                        P_APP_NOTIFY_TYPE IN VARCHAR2,
                                        P_SMS_SHORT IN VARCHAR2,
                                        P_AUTHWEBALT_LOG IN NUMBER,
                                        P_NETWORKACQ_FLAG IN VARCHAR2,
                                        P_KYCVERIFICATION_FLAG IN VARCHAR2,
                                        P_BANK_ADDRESS IN VARCHAR2,
                                        P_EXPIRY_FLAG IN VARCHAR2,
                                        P_OLS_RESP_FLAG IN VARCHAR2,
                                        P_EMV_FLAG IN VARCHAR2,
                                        P_RANDOM_PIN IN VARCHAR2,
                                        P_PINCHANGE IN NUMBER,
                                        P_POA IN VARCHAR2,
                                        P_ACCT_LOCK_COUNT IN VARCHAR2,
                                        P_ACCT_UNLOCK IN VARCHAR2,
                                        P_DUP_TIME IN VARCHAR2,
                                        P_DUP_SSN IN VARCHAR2,
                                        P_TIME_PERIOD IN VARCHAR2,
                                        P_ACHBLOCK_EXP IN VARCHAR2,
                                        P_FEDERAL_CHECK IN VARCHAR2,
                                        P_TCVERSION IN VARCHAR2,
                                        P_CLAWBACK IN VARCHAR2,
                                        P_AUTHIVR_ALT IN NUMBER,
                                        P_ONUSPRE_EXP IN VARCHAR2,
                                        P_KYC_INTERVAL IN VARCHAR2,
                                        P_PIN_MIGRATION IN VARCHAR2,
                                        P_GPRACH_CHECK IN VARCHAR2,
                                        P_PANINV_FLAG IN VARCHAR2,
                                      	P_CCF_SERIAL_FLAG IN VARCHAR2,
                                        P_CHK_DIGIT_REQ in varchar2,
                                        P_PRG_ID_REQ IN VARCHAR2,
                                        P_PROXY_NUMBER_LENGTH IN NUMBER,
                                        P_PRG_ID IN VARCHAR2,
                                        P_DEF_COND_APPR IN VARCHAR2,
                                        P_CUST_CARE_NUM IN VARCHAR2,
                                        P_UPGRADE_ELIGIBLE_FLAG IN VARCHAR2,
                                        P_CCF_3DIGCSCREQ IN VARCHAR2,
                                        P_PARTIAL_INDR_FLAG IN VARCHAR2,
                                        P_SERIALNO_FILEPATH IN VARCHAR2,
                                        P_RETAILACTIVATION IN VARCHAR2,
                                        P_AVSREQUIRED IN VARCHAR2,
                                        P_RECURRING_TRAN_FLAG IN VARCHAR2,
                                        P_INTERNATIONAL_TRAN IN VARCHAR2,
                                        P_emvfallback_flag  in varchar2,
                                        p_fundmcc  in varchar2,
                                        p_settlemcc in varchar2,
                                        p_badcrd_flag in varchar2,
                                        P_Badcrd_Trans_Grpid In Varchar2,
                                        P_ENCRYPT_ENABLE IN VARCHAR2,
                                        P_ALERT_AMOUNT IN VARCHAR2,
                                        P_ALERT_DURATION IN VARCHAR2,
                                        P_ALERT_STAT IN VARCHAR2,

                                        P_Src_App In Varchar2,
                                        P_Avsresp_Code In Varchar2,
                                        P_Valinasactivation In Varchar2,
                                        P_Closecard_Deact In Varchar2,
                                        P_DOUBLE_OPTIN_NTYTYPE IN VARCHAR2,
                                        P_PRODUCT_FUNDING IN VARCHAR2,
                                        P_FUNDING_AMOUNT IN VARCHAR2,
                                        P_Instore_Replacement In Varchar2,
                                        P_packageid_check  in varchar2,
                                        p_ofac_check in varchar2,
                                        p_partner_id in varchar2,
                                        p_Dob_Mandatory in varchar2,
                                        p_mall_id    in varchar2,
                                        p_malllocation_id in varchar2,
                                        P_STANDING_AUTH_FLAG in varchar2,
                                        P_BYPASS_INITIAL_LOADCHK in varchar2,
									    p_scorecard_id in number, -- Added for JH-2133 on 08/01/14
										P_EVENT_NOTIFY in varchar2,
										P_PARTNER_NAME IN VARCHAR2,
                                        P_ISSUING_BANK_ID number,
                                        P_PIN_RESET_OPTION IN VARCHAR2,
                                        P_PENDING_THRESHOLD IN VARCHAR2,
                                        P_MAXIMUM_THRESHOLD IN VARCHAR2,
										P_FLOOR_LIMIT number,
                                        P_SLGPINTRYBYPASSFLAG IN VARCHAR2,
                                        P_INSTALLMENT_FLAG IN VARCHAR2,
										P_LUPDUSER       IN NUMBER, -- This should be the Last input Parameters
										P_CARDTYPE OUT NUMBER,
                                        P_ERRMSG   OUT VARCHAR2) AS
/*************************************************
     * Created Date     : 10-Dec-2011
     * Created By       : Sivapragasam
     * PURPOSE          : Prodcattype
     * Modified By      : Saravanakumar
     * Modified Date    : 11-Feb-2013
     * Modified Reason  : For JIRA - 749
     * Reviewer         : Sachin
     * Reviewed Date    : 12-Feb-2013
     * Build Number     : CMS3.5.1_RI0023.1.1_B0003

     * Modified By      : Shweta
     * Modified Date    : 25-Apr-2013
     * Modified For     : DFCHOST-308
     * Reviewer         : Sagar
     * Reviewed Date    : 25-Apr-2013
     * Build Number     : RI0024.0.1_B0002

      * Modified By     :  Santosh P
     * Modified Date    :  06-Aug-2013
     * Modified For     :  MVHOST-314
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  06-Aug-2013
     * Build Number     :  RI0024.4_B0001

     * Modified By      : MageshKumar.S
     * Modified Date    : 09-OCT-2013
     * Modified For     : JH-3 : Default PIN flag at product category level
     * Reviewer         : Dhiraj
     * Reviewed Date    : 17-Oct-2013
     * Build Number     : RI0024.6_B0001

     * Modified By      : Ravi.N
     * Modified Date    : 23-OCT-2013
     * Modified For     : JH-8  (additional changes)
     * Reviewer         : Dhiraj
     * Reviewed Date    : 25-Oct-2013
     * Build Number     : RI0024.6_B0003

     * Modified By      : Sivakuamr
     * Modified Date    : 08-Dec-2014
     * Modified For     : JH-2133
     * Reviewer         : DHIRAJ
     * Reviewed Date    : 08-Dec-2014
     * Build Number     : RI0027_B0003

     * Modified By      : Kaleeswaran P
     * Modified Date    : 10-Mar-2014
     * Modified For     : MVCSD-4121
     * Reviewer         : Dhiraj
     * Reviewed Date    : 10-Mar-2014
     * Build Number     : RI0027.2_B0002

     * Modified By      : Ramesh.A
     * Modified Date    : 01-July-2014
     * Modified For     : FSS-1701
     * Reviewer         : Spankaj
     * Build Number     : RI0027.3_B0002

     * Modified by      : MageshKumar S
     * Modified For     : FSS-1785
     * Modified Date    : 08-August-2014
     * Modified reason  : 2.2.5 integration of FSS-1785 into 2.3.1
     * Reviewer         : Spankaj
     * Build Number     : RI0027.3.1_B0003

     * Modified by      : Siva Kumar M
     * Modified For     : FSS-4370
     * Modified Date    : 25-May-2016
     * Modified reason  : Changes in Inventory Card Generation
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     : VMSGPRHOST4.1_B0001

     * Modified by      : MageshKumar S
     * Modified For     : CLVMS-124
     * Modified Date    : 08-JUNE-2016
     * Reviewer         : Saravanan/Spankaj
     * Build Number     : VMSGPRHOSTCSD4.2_B0001


     * Modified by      : Siva Kumar M
     * Modified For     : FSS-4423
     * Modified Date    : 25-May-2016
     * Modified reason  : Changes for tokenization
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     : VMSGPRHOST4.4_B0001

      * Modified by      : Siva Kumar M
     * Modified For     : FSS-4423
     * Modified Date    : 07-July-2016
     * Modified reason  : Tokenization Changes
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     : VMSGPRHOST4.5_B0002

     * Modified by      : MageshKumar S
     * Modified For     : FSS-4782
     * Modified Date    : 29-SEP-2016
     * Reviewer         : Saravanan/Spankaj
     * Build Number     : VMSGPRHOSTCSD4.2.5_B0001

     * Modified by      : Saravana Kumar A
     * Modified Date    : 07-Jan-17
     * Modified reason  : Card Expiry date logic changes
     * Reviewer         : Spankaj
     * Build Number     : VMSGPRHOST17.1

     * Modified by      : Veneetha C
     * Modified Date    : 09-MAR-17
     * Modified reason  : FSS-4647
     * Reviewer         : Saravanan/Spankaj
     * Build Number     : VMSGPRHOST17.03

     * Modified by      : Veneetha C
     * Modified Date    : 06-APR-17
     * Modified reason  : CVVPLUS
     * Reviewer         : Saravanan/Spankaj
     * Build Number     : VMSGPRHOST17.04

     * Modified by      : T.Narayanaswamy
     * Modified Date    : 07-APR-17
     * Modified reason  : FSS-4619 (SWEEP CHANGES)
     * Reviewer         : Saravanan/Spankaj
     * Build Number     : VMSGPRHOST17.07

	 * Modified by      : T.Narayanaswamy
     * Modified Date    : 21-July-17
     * Modified reason  : FSS-5157 - B2B Gift Card - Phase 2
     * Reviewer         : Saravanan/Spankaj
     * Build Number     : VMSGPRHOST 17.07

	 * Modified by      : T.Narayanaswamy
     * Modified Date    : 18-August-17
     * Modified reason  : FSS-5157 - B2B Gift Card - Phase 2
     * Reviewer         : Saravanan/Spankaj
     * Build Number     : VMSGPRHOST 17.07

     * Modified by      : T.Narayanaswamy
     * Modified Date    : 28-August-17
     * Modified reason  : FSS-5157 - B2B Gift Card - Phase 2 -- Program ID changes
     * Reviewer         : Saravanan/Spankaj
     * Build Number     : VMSGPRHOST 17.08

     * Modified by      : Siva Kumar M
     * Modified For     : FSS-5199
     * Modified Date    : 05-Sep-2017
     * Modified reason  : Customer care number Changes
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     :  VMSGPRHOSTCSD17.08_B0003

     * Modified by      : Renuka T
     * Modified For     : VMS-36
     * Modified Date    : 09-nov-2017
     * Modified reason  : Partial Approval flag changes
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     : VMSGPRHOST 17.09.04
     * Modified by      : Sreeja T
     * Modified For     : FSS-5323
     * Modified Date    : 10-nov-2017
     * Modified reason  : Recurring Transaction Flag
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     : VMSGPRHOSTCSD17.11_B0001
     * Modified by      : Maharasankari 
     * Modified For     : VMS-180
     * Modified Date    : 23-JAN-2018
     * Reviewer         : Saravankumar
     * Build Number     : VMSGPRHOSTCSD18.01

     * Modified by      : Siva Kumar M
     * Modified For     : VMS-354
     * Modified Date    : 02-July-2018
     * Reviewer         : Saravankumar
     * Build Number     : R03

	 * Modified by       : Baskar Krishnan
       * Modified Date     : 10-Sep-19
       * Modified Reason   : VMS-1081 - Enhance Sweep Job for Amex products.
       * Reviewer          : SarvanaKumar
       * Build Number      : R20_B0003

	   * Modified by       : Tanmay Bansal
       * Modified Date     : 11-Sep-19
       * Modified Reason   : VMS-55 
       * Reviewer          : SarvanaKumar
       * Build Number      : R20_B0003
	   
	   * Modified by       : Ayodeji Filegbe
       * Modified Date     : 1-Oct-19
       * Modified Reason   : VMS-1127 
       * Reviewer          : Saravana Kumar A
       * Build Number      : R21_B003
	   
	   * Modified by       : Baskar Krishnan
       * Modified Date     : 17-Dec-19
       * Modified Reason   : VMS-1605 
       * Reviewer          : Saravana Kumar A
       * Build Number      : R24_B001
	   
       * Modified by       : Baskar Krishnan
       * Modified Date     : 02-Oct-2020
       * Modified Reason   : VMS-3066 
       * Reviewer          : Saravana Kumar A
       * Build Number      : VMSGPRHOST_R36_B0003
	   
       * Modified by       : Baskar Krishnan
       * Modified Date     : 30-NOV-2020
       * Modified Reason   : VMS-3288
       * Reviewer          : Saravana Kumar A
       * Build Number      : VMSGPRHOST_R39_B0002
       
       * Modified by       : MageshKumar S
       * Modified Date     : 21-Dec-2020
       * Modified Reason   : VMS-3401
       * Reviewer          : Saravana Kumar A
       * Build Number      : VMSGPRHOST_R40_B0002
       
       * Modified by       : Ravi N
       * Modified Date     : 06-Jan-2021
       * Modified Reason   : VMS-3596
       * Reviewer          : Saravana Kumar A
       * Build Number      : VMSGPRHOST_R41_B0002

       * Modified by       : MageshKumar S
       * Modified Date     : 10-May-2021
       * Modified Reason   : VMS-4204
       * Reviewer          : Saravana Kumar A
       * Build Number      : VMSGPRHOST_R46_B0002
*************************************************/
    V_CCT_CTRL_NUMB NUMBER;
  V_RULEGROURPID VARCHAR2(50);
  V_PROD_PREFIX  NUMBER;
  V_ACCT_PROD_PREFIX NUMBER;
  V_PROD_CATTYPE_SNAME VARCHAR2(50);
  V_SEQ_NO        NUMBER(10);
  V_GET_SEQ_QUERY   VARCHAR2(500);

BEGIN
    BEGIN
        SELECT CCT_CTRL_NUMB
        INTO V_CCT_CTRL_NUMB
        FROM CMS_CTRL_TABLE
        WHERE CCT_CTRL_CODE = P_INSTCODE || LTRIM(RTRIM(P_PRODCODE)) AND
        CCT_CTRL_KEY = 'PROD CATTYPE'
        FOR UPDATE;
        P_CARDTYPE := V_CCT_CTRL_NUMB;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_CARDTYPE := 1;
            INSERT INTO CMS_CTRL_TABLE
                        (CCT_CTRL_CODE,
                        CCT_CTRL_KEY,
                        CCT_CTRL_NUMB,
                        CCT_CTRL_DESC,
                        CCT_INS_USER,
                        CCT_LUPD_USER)
                        VALUES
                        (P_INSTCODE || LTRIM(RTRIM(P_PRODCODE)),
                        'PROD CATTYPE',
                        2,
                        'Latest card type for Inst ' || P_INSTCODE || ' and interchange ' ||
                        P_PRODCODE || '.',
                        P_LUPDUSER,
                        P_LUPDUSER);
            P_ERRMSG := 'OK';
        WHEN OTHERS THEN
            P_ERRMSG:='Error while selecting CMS_CTRL_TABLE '||SQLERRM;
            RETURN;
    END;

/*    BEGIN
  --Changed by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
        SELECT COUNT(1)
        INTO V_PROD_PREFIX
        FROM CMS_PROD_CATTYPE,CMS_PROD_BIN
        WHERE CPC_INST_CODE = P_INSTCODE AND CPC_PROD_PREFIX = P_PREFIX AND
        CPC_PROD_CODE =CPB_PROD_CODE AND
        CPB_INST_CODE = P_INSTCODE AND CPB_PROD_CODE = P_PRODCODE;
    END;

    IF V_PROD_PREFIX > 0 OR V_PROD_PREFIX IS NULL THEN
        P_ERRMSG := 'Prefix is already attached with the product';
        RETURN;
    END IF;
*/
    -- Added by Trivikram on 06-05-2012, For Account Prefix
     BEGIN

        SELECT COUNT(1)
        INTO V_ACCT_PROD_PREFIX
        FROM CMS_PROD_CATTYPE,CMS_PROD_BIN
        WHERE CPC_INST_CODE = P_INSTCODE AND CPC_ACCT_PROD_PREFIX = P_ACCT_PREFIX AND
        CPC_PROD_CODE =CPB_PROD_CODE AND
        --CPB_INST_CODE = P_INSTCODE AND CPB_PROD_CODE = P_PRODCODE;
       CPB_INST_CODE = P_INSTCODE AND CPB_PROD_CODE <> P_PRODCODE;--Shweta on 24April13 for DFCHOST-308 Account Number (Pseudo DDA) prefix is unique at Product Category Level
    END;

    IF V_ACCT_PROD_PREFIX > 0 OR V_ACCT_PROD_PREFIX IS NULL THEN
        --P_ERRMSG := 'Account Prefix is already attached with the product';
        P_ERRMSG := 'Account Prefix is already attached with another product';--Shweta on 24April13 for DFCHOST-308 Account Number (Pseudo DDA) prefix is unique at Product Category Level
        RETURN;
    END IF;


    BEGIN
--Exception added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
        INSERT INTO CMS_PROD_CATTYPE
                  (CPC_INST_CODE,
                  CPC_PROD_CODE,
                  CPC_CARD_TYPE,
                  CPC_CARDTYPE_DESC,
                  CPC_VENDOR,
                  CPC_STOCK,
                  CPC_CARDTYPE_SNAME,
                  CPC_PROD_PREFIX,
                  CPC_RULEGROUP_CODE,
                  CPC_PROFILE_CODE, --Vikrant 11june08
                  CPC_INS_USER,
                  CPC_LUPD_USER,
                  CPC_PROD_ID,
                  CPC_PACKAGE_ID, -- Added  ProdID and PackageID on 15-sep-2011
                  CPC_ACHTXN_FLG,
                 -- CPC_ODFI_TAXREFUNDNO, Commented by Besky on 26/11/12
                  CPC_ACHTXN_DAYCNT,
                  CPC_ACHTXN_MINTRANAMT,
                  CPC_ACHTXN_DAYMAXAMT,
                  CPC_ACHTXN_WEEKCNT,
                  CPC_ACHTXN_WEEKMAXAMT,
                  CPC_ACHTXN_MONCNT,
                  CPC_ACHTXN_MONMAXAMT,
                  CPC_ACHTXN_MAXTRANAMT,
                  CPC_MIN_AGE_KYC,
                  CPC_PASSIVE_TIME,
                  CPC_STARTER_CARD,
                  CPC_STARTER_MINLOAD,     --Modified by Sivapragasam on Feb 20 2012 for Starter Card Configuration Changes
                  CPC_STARTER_MAXLOAD,
                  CPC_STARTERGPR_CRDTYPE,
                  CPC_STARTERGPR_ISSUE,
                  CPC_ACCT_PROD_PREFIX, -- Added by Trivikram on 06 june 2012, For Insert Account Prefix
                   CPC_SERL_FLAG,-- Added by Santosh on 21 Aug 2012 for Shuffle PAN Serial Number
                   CPC_DEL_MET, --Added for CR:038 DFG CCF changes on 26-Dec-2012
                   CPC_ACHMIN_INITIAL_LOAD,--Added for JIRA - 749 For release 23.1.1
                   CPC_URL,  -- Column added By Santosh on 06 Aug 13 for MVHOST-314
                   CPC_DFLTPIN_FLAG, -- Column added on 09-10-2013 for JH-3
                   CPC_PIN_APPLICABLE,-- Column added on 09-10-2013 for JH-3
                   CPC_LOCCHECK_FLAG, --Column added on 23/10/13 for   JH-8
                   CPC_CRDEXP_PENDING,   --Added for MVCSD-4121
                   CPC_REPL_PERIOD,  --Added for MVCSD-4121
                   CPC_SCORECARD_ID,    -- Added for JH-2133 on 08/01/14
                   CPC_ACH_LOADAMNT_CHECK, --Added for FSS-1701
                   CPC_INVCHECK_FLAG, --Added for fss-1785
                   CPC_STARTERCARD_DISPNAME,
                   CPC_STARTER_REPLACEMENT,
                   CPC_REPLACEMENT_CATTYPE,
                   CPC_TOKEN_ELIGIBILITY,
                   CPC_TOKEN_PROVISION_RETRY_MAX,
                   CPC_TOKEN_RETAIN_PERIOD,
                   CPC_TOKEN_CUST_UPD_DURATION,
                 --  CPC_TOKEN_CUST_UPD_FREQUENCY,
                   CPC_DEFAULT_PIN_OPTION,
                   cpc_exp_date_exemption,
                  cpc_redemption_delay_flag, --Added for FSS-4647,
                   CPC_CVVPLUS_ELIGIBILITY,--added for CVVPlus
                   cpc_cvvplus_short_name,--added for CVVPlus
                   CPC_SWEEP_FLAG,--ADDED FOR SWEEP CHANGES
                   CPC_ADDL_SWEEP_PERIOD, ---ADDED FOR SWEEP CHANGES
                   cpc_inactivetoken_retainperiod,--added for master card
                   cpc_b2b_flag,
                   cpc_b2bcard_stat,
                   cpc_b2b_activation_code,
                   cpc_b2b_lmtprfl,
                   cpc_b2bflname_flag,
                   cpc_kyc_flag,
                   cpc_cvv2_verification_flag,
                   cpc_expiry_date_check_flag,
                   cpc_acct_balance_check_flag,
                   cpc_replacement_provision_flag,
                   cpc_acct_bal_check_type,
                   cpc_acct_bal_check_value,
                   cpc_issu_prodconfig_id,
                   cpc_consumed_flag,
                   cpc_consumed_card_stat,
                   cpc_renew_replace_option,
                   cpc_renew_replace_prodcode,
                   CPC_RENEW_REPLACE_CARDTYPE,
                   --CPC_PRODUCT_TYPE,
                   CPC_USER_IDENTIFY_TYPE,
                   CPC_RELOADABLE_FLAG,
                  -- CPC_RETAIL_SALE_FLAG,
                   CPC_PROD_SUFFIX,
                   CPC_START_CARD_NO,
                   CPC_END_CARD_NO,
                   CPC_CCF_FORMAT_VERSION,
                   CPC_DCMS_ID,
                   CPC_PRODUCT_UPC,
                   CPC_PACKING_UPC,
                   CPC_CARDPROD_ACCEPT,
                   CPC_STATE_RESTRICT,
                   CPC_PIF_SIA_CASE ,
                   CPC_CASH_ACCESS,
                   CPC_DISABLE_REPL_FLAG,
                   CPC_DISABLE_REPL_EXPRYDAYS,
                   CPC_DISABLE_REPL_MINBAL,
                   CPC_DISABLE_REPL_MESSAGE,
                   CPC_ISSU_BANK ,
                   CPC_ICA ,
                   CPC_ISSU_BANK_ADDR,
                   CPC_PROD_DENOM,
                   CPC_PDENOM_MIN,
                   CPC_PDENOM_MAX,
                   CPC_PDENOM_FIX,
                  -- CPC_REPL_PACKAGE_ID,
                  -- CPC_REPL_VENDOR,
                   CPC_FROM_DATE,
                   CPC_ROUT_NUM,
                   CPC_INSTITUTION_ID,
                   CPC_TRANSIT_NUMBER,
                   CPC_EMAIL_ID,
                   CPC_FROMEMAIL_ID,
                   CPC_APP_NAME,
                   CPC_APPNTY_TYPE,
                   CPC_SHORT_CODE,
                   CPC_WEBAUTHMAPPING_ID,
                   CPC_NETWORKACQID_FLAG,
                   CPC_KYCVERIFY_FLAG,
                   CPC_STATEMENT_FOOTER,
                   CPC_OLS_EXPIRY_FLAG,
                   CPC_OLSRESP_FLAG,
                   CPC_EMV_FLAG,
                   CPC_RANDOM_PIN,
                   CPC_PINCHANGE_FLAG,
                   CPC_POA_PROD,
                   CPC_WRONG_LOGONCOUNT,
                   CPC_ACCTUNLOCK_DURATION,
                   CPC_DUP_TIMEPERIOD,
                   CPC_DUP_SSNCHK,
                   CPC_DUP_TIMEUNT,
                   CPC_ACHBLCKEXPRY_PERIOD,
                   CPC_FEDERALCHECK_FLAG,
                   CPC_TANDC_VERSION,
                   CPC_CLAWBACK_DESC,
                   CPC_IVRAUTHMAPPING_ID,
                   CPC_ONUS_AUTH_EXPIRY,
                   CPC_CIP_INTVL,
                   CPC_RENEWAL_PINMIGRATION,
                   CPC_GPRFLAG_ACHTXN,
                   CPC_PAN_INVENTORY_FLAG,
                   CPC_PRODUCT_ID,
                   CPC_CCF_SERIAL_FLAG,
                   CPC_PROGRAM_ID,
                   CPC_PROXY_LENGTH,
                   CPC_CHECK_DIGIT_REQ,
                   CPC_PROGRAMID_REQ,
				           CPC_DEF_COND_APPR,
                   CPC_CUSTOMER_CARE_NUM,
                   CPC_UPGRADE_ELIGIBLE_FLAG,
                   CPC_CCF_3DIGCSCREQ,
                   cpc_default_partial_indr,
                   CPC_RETAIL_ACTIVATION,
                   CPC_ADDR_VERIFICATION_CHECK,
                   CPC_SERIALNO_FILEPATH,
                   CPC_RECURRING_TRAN_FLAG,
				           CPC_INTERNATIONAL_CHECK,
                   Cpc_Emv_Fallback,Cpc_Fund_Mcc,Cpc_Settl_Mcc ,Cpc_Badcredit_Flag ,Cpc_Badcredit_Transgrpid,
                   CPC_ENCRYPT_ENABLE,
                    CPC_ALERT_CARD_AMOUNT,
                    CPC_ALERT_CARD_DURATION,
                    cpc_alert_card_stat,
                    Cpc_Src_App,
                    CPC_ADDR_VERIFICATION_RESPONSE,
                    Cpc_Valins_Act_Flag ,
                    Cpc_Deactivation_Closed,
                    CPC_DOUBLEOPTINNTY_TYPE,
                    CPC_PRODUCT_FUNDING,
                    CPC_FUND_AMOUNT,
                    Cpc_Instore_Replacement,
                    Cpc_Packageid_Check,
                    cpc_OFAC_CHECK,
                    CPC_PARTNER_ID,
                    CPC_DOB_MANDATORY,
                    CPC_MALLID_CHECK,
                    CPC_MALLLOCATION_CHECK,
                    CPC_STNGAUTH_FLAG,
                    CPC_BYPASS_LOADCHECK,
                    CPC_ISSUBANK_ID,
					CPC_EVENT_NOTIFICATION,
					CPC_PARTNER_NAME,
                    CPC_PIN_RESET_OPTION,
                    CPC_INV_REPL_THRESHOLD,
                    CPC_INV_THRESHOLD,
					CPC_FLOOR_LIMIT,
                    CPC_PINTRYBYPASS_FLAG,
                    CPC_INSTALLMENT_FLAG
                   )
                   VALUES
                  (P_INSTCODE,
                  P_PRODCODE,
                  P_CARDTYPE,
                  P_TYPEDESC,
                  P_VENDOR,
                  P_STOCK,
                  P_SNAME,
                  P_PREFIX,
                  V_RULEGROURPID,
                  P_PROFILECODE,
                  P_LUPDUSER,
                  P_LUPDUSER,
                  P_PRODID,
                  P_PACKAGEID,
                  P_ACHTXN_FLG,
                 -- P_CPC_ODFI_TAXREFUNDNO,Commented by Besky on 26/11/12
                  P_CPC_ACHTXN_DAYCNT,
                  P_CPC_ACHTXN_DAYMINAMT,
                  P_CPC_ACHTXN_DAYMAXAMT,
                  P_CPC_ACHTXN_WEEKCNT,
                  --CPC_ACHTXN_WEEKMINAMT,
                  P_CPC_ACHTXN_WEEKMAXAMT,
                  P_CPC_ACHTXN_MONCNT,
                  -- CPC_ACHTXN_MONMINAMT,
                  P_CPC_ACHTXN_MONMAXAMT,
                  P_CPC_ACHTXN_DAYMAXTRANAMT,
                  P_ACH_MIN_AGE,
                  P_PASSIVE_PERIOD,
                  P_STARTER_CARD,
                  P_MINSPIL_LOADAMT,  --Modified by Sivapragasam on Feb 20 2012 for Starter Card Configuration Changes
                  P_MAXSPIL_LOADAMT,
                  P_STARTER_GPR_CARDTYPE,
                  P_STARTER_GPRISSUE,
                  P_ACCT_PREFIX, -- Added by Trivikram on 06 june 2012 ,
                  P_SERNO_FLG, -- Added by Santosh on 21 Aug 2012 for Shuffle PAN Serial Number ,
                  P_DEL_MET,--Added for CR:038 DFG CCF changes on 26-Dec-2012
                  P_MIN_INIT_LOADAMT,--Added for JIRA - 749 For release 23.1.1
                  P_URL, -- Column added By Santosh on 06 Aug 13 for MVHOST-314
                  P_DFLTPIN_FLAG, -- Column added on 09-10-2013 for JH-3
                  P_PINAPPL_FLAG,-- Column added on 09-10-2013 for JH-3
                  P_STORLOCFLAG,  --Column added on 23/10/13 for   JH-8
                  P_CardEXPPENDING, --Added for MVCSD-4121
                  P_CardRplPeroid, --Added for MVCSD-4121
                  P_SCORECARD_ID, -- Added for JH-2133 on 08/01/14
                  P_ACHINITLOADAMNTCHECK, --Added for FSS-1701
		              P_INVCHECK_FLAG, --Added for fss-1785
                  P_STRCRD_DISPNAME,
                  P_STRREPLACE_OPTION,
                  P_REPLACE_PRODCATG,
                  P_TOKENELIGIBLESTATU,
                  P_TOKENPRORETRYMAX,
                  P_TOKENRETPERIOD,
                  P_CUSTDTLUPDPERIOD,
                  --p_custdtlupdPeriodFrncy,
                  P_LASTFOUR_DIGITPIN,
                  p_exp_date_exemption,
                  P_REDEMPTION_FLAG, --added for FSS-4647
                  P_CVVCheck,-- added for cvv+
                  P_CVVPlusShort_Name,--added for cvv+
                  P_SWEEP_FLAG,--ADDED FOR SWEEP CHANGES
                  P_SWEEP_PERIOD,--ADDED FOR SWEEP CHANGES
                  P_INACTTOKENRETPERIOD, -- added for master card
                  P_B2BFLAG,
                  P_B2BCARDSTATUS,
                  P_B2BACTIVATIONCODE,
                  P_B2BLIMIT_PROFILECODE,
                  P_B2BREG_NAME_MATCH,
                  P_KYCCHECK,
                  P_CVV2VERIFICATION,
                  P_EXPDATEVALIDATION,
                  P_ACCTBALVALIDATION,
                  P_REPLACEMENT_PROVISION_FLAG,
                  P_ACCTBALCHECKTYPE,
                  P_ACCTBALCHECKVALUE,
                  P_ISSUPRODCONFIGID,
                  P_CONSUMEDFLAG,
                  P_CONSUMEDSTATUS,
                  P_RENEWREPLACEOPTION,
                  P_RENEWREPLACEPRODCODE,
                  P_RENEWREPLACECARDTYPE,
               --   P_PRODUCTTYPE,
                  P_REGISTRATION_CHECK,
                  P_RELOADABLE_CHECK,
                 -- P_RETAIL_SALE,
                  P_PROD_SUFFIX,
                  P_START_CARDNO,
                  P_END_CARDNO,
                  P_CCFFORMAT_VER,
                  P_DCMSID,
                  P_PROD_UPC ,
                  P_PACKING_UPC,
                  P_CARD_PROD_ACCEPTANCE,
                  P_STATE_LAW ,
                  P_VISAPIF_OR_MC ,
                  P_CASH_ACCESS ,
                  P_DISABLE_REPLACEMENT,
                  P_PRIOR_TOEXPIRATION_CHECK,
                  P_MIN_BAL_REPLACEMENT ,
                  P_DISABLE_REPLACEMENT_MSG,
                  P_ISSUING_BANK,
                  P_ICA,
                  P_ISSUING_BANK_ADDRESS,
                  P_PRODUCT_DENO ,
                  P_OPEN_MIN ,
                  P_OPEN_MAX ,
                  P_FIXED_VALUE ,
                --  P_REPLACEMENT_PACKAGEID,
                --  P_REPLACEMENT_VENDOR,
                  P_FROMDATE ,
                  P_ROUTING_NUM ,
                  P_INST_ID ,
                  P_TRANSIT_NUM ,
                  P_PROD_EMAIL ,
                  P_FRMEMAILFRALERTS,
                  P_APP_NAME ,
                  P_APP_NOTIFY_TYPE,
                  P_SMS_SHORT ,
                  P_AUTHWEBALT_LOG ,
                  P_NETWORKACQ_FLAG ,
                  P_KYCVERIFICATION_FLAG,
                  P_BANK_ADDRESS ,
                  P_EXPIRY_FLAG ,
                  P_OLS_RESP_FLAG ,
                  P_EMV_FLAG,
                  P_RANDOM_PIN ,
                  P_PINCHANGE ,
                  P_POA ,
                  P_ACCT_LOCK_COUNT ,
                  P_ACCT_UNLOCK ,
                  P_DUP_TIME ,
                  P_DUP_SSN ,
                  P_TIME_PERIOD ,
                  P_ACHBLOCK_EXP ,
                  P_FEDERAL_CHECK ,
                  P_TCVERSION ,
                  P_CLAWBACK ,
                  P_AUTHIVR_ALT,
                  P_ONUSPRE_EXP,
                  P_KYC_INTERVAL,
                  P_PIN_MIGRATION,
                  P_GPRACH_CHECK,
                  P_PANINV_FLAG,
                  lpad(SEQ_PRODUCT_ID.nextval,5,0),
                  P_CCF_SERIAL_FLAG,
                  NVL(P_PRG_ID,''),
                  P_PROXY_NUMBER_LENGTH,
                  DECODE(P_PRG_ID_REQ,'Y',P_CHK_DIGIT_REQ,'N'),
                  P_PRG_ID_REQ,
                  P_DEF_COND_APPR,
                  P_CUST_CARE_NUM,
                  P_UPGRADE_ELIGIBLE_FLAG,
                  P_CCF_3DIGCSCREQ,
                  P_PARTIAL_INDR_FLAG,
                  P_RETAILACTIVATION,
                  P_AVSREQUIRED,
                  P_SERIALNO_FILEPATH,
                  P_RECURRING_TRAN_FLAG,
                  P_INTERNATIONAL_TRAN,
                  P_emvfallback_flag,
                  p_fundmcc,
                  p_settlemcc,
                  p_badcrd_flag ,
                  P_Badcrd_Trans_Grpid ,
                  P_ENCRYPT_ENABLE,
                  P_ALERT_AMOUNT ,
                  p_alert_duration ,
                  p_alert_stat,
                  P_Src_App,
                  P_AVSRESP_CODE,
                  P_Valinasactivation,
                  P_Closecard_Deact,
                  P_DOUBLE_OPTIN_NTYTYPE,
                  P_PRODUCT_FUNDING,
		  P_FUNDING_AMOUNT,
		  P_Instore_Replacement,
      P_packageid_check,
      p_ofac_check,
      p_partner_id,
      p_Dob_Mandatory,
      p_mall_id,
      p_malllocation_id,
      P_STANDING_AUTH_FLAG,
      P_BYPASS_INITIAL_LOADCHK,
      P_ISSUING_BANK_ID,
	  P_EVENT_NOTIFY,
	  P_PARTNER_NAME,
      P_PIN_RESET_OPTION,
      P_PENDING_THRESHOLD,
      P_MAXIMUM_THRESHOLD,
	  P_FLOOR_LIMIT,
      p_slgpintrybypassflag,
      P_INSTALLMENT_FLAG
                );
         IF SQL%ROWCOUNT = 0 THEN
              P_ERRMSG := 'Error While inserting record in prod cattype' || SQLERRM;
              RETURN;
         END IF;
     EXCEPTION
        WHEN OTHERS THEN
             p_errmsg := 'Error While inserting record in prod cattype' || sqlerrm;
              RETURN;

     end;

     BEGIN
     V_GET_SEQ_QUERY := 'SELECT COUNT(*)  FROM CMS_PROGRAM_ID_CNT CPI WHERE CPI.CPI_PROGRAM_ID=' ||
                   CHR(39) || P_PRG_ID || CHR(39) || ' AND CPI_INST_CODE=' ||
                   P_INSTCODE;
     EXECUTE IMMEDIATE V_GET_SEQ_QUERY
       INTO V_SEQ_NO;
     IF V_SEQ_NO = 0 THEN
       INSERT INTO CMS_PROGRAM_ID_CNT
        (CPI_INST_CODE,
         CPI_PROGRAM_ID,
         CPI_SEQUENCE_NO,
         CPI_INS_USER,
         CPI_INS_DATE,
         CPI_LUPD_DATE,
         CPI_LUPD_USER)
       VALUES
        (P_INSTCODE, P_PRG_ID, 0, '', SYSDATE,SYSDATE,P_LUPDUSER);
     END IF;
    EXCEPTION
     WHEN OTHERS THEN
       p_errmsg := 'Error when inserting into  CMS_PROGRAM_ID_CNT ' ||
               SQLERRM;
    END;

     begin
          for i in 1..12 loop
                insert into vms_expiry_mast(
                                  Vem_PROD_CODE,
                                  Vem_PROD_CATTYPE,
                                  Vem_MONTH_ID,
                                  Vem_MONTH_VALUE,
                                  Vem_INS_USER,
                                  vem_ins_date)
                      select P_PRODCODE,P_CARDTYPE,Vem_MONTH_ID,
                             vem_month_value,P_LUPDUSER,sysdate
                             from vms_expiry_mast
                             where vem_month_id=lpad(i,2,'0')
                             and vem_prod_code='0' and vem_prod_cattype=0;
          end loop;
     exception
        when others then
           p_errmsg := 'Error While inserting record in vms_expiry_mast' || sqlerrm;
           RETURN;
     end;


    UPDATE CMS_CTRL_TABLE
    SET CCT_CTRL_NUMB = CCT_CTRL_NUMB + 1, CCT_LUPD_USER = P_LUPDUSER
    WHERE CCT_CTRL_CODE = P_INSTCODE || LTRIM(RTRIM(P_PRODCODE)) AND
    CCT_CTRL_KEY = 'PROD CATTYPE';

    --Start Added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj
    IF SQL%ROWCOUNT = 0 THEN
        P_ERRMSG := 'Error While updating CMS_CTRL_TABLE ' || SQLERRM;
        RETURN;
    END IF;
    --End Added by Saravanakumar on 08-Feb-2012 as per codereview document given by Dhiraj

    P_ERRMSG := 'OK';
EXCEPTION
    WHEN OTHERS THEN
        P_ERRMSG := 'Excp 1 ' || SQLCODE || '---' || SQLERRM;
END;
/
show error