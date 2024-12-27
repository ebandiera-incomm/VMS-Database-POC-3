create or replace PROCEDURE        vmscms.SP_CHW_ORDER_REPLACE(P_INST_CODE        IN NUMBER,
                                        P_MSG                IN  VARCHAR2,
                                        P_RRN                IN  VARCHAR2,
                                        P_DELIVERY_CHANNEL   IN  VARCHAR2,
                                        P_TERM_ID            IN  VARCHAR2,
                                        P_TXN_CODE           IN  VARCHAR2,
                                        P_TXN_MODE           IN  VARCHAR2,
                                        P_TRAN_DATE          IN  VARCHAR2,
                                        P_TRAN_TIME          IN  VARCHAR2,
                                        P_CARD_NO            IN  VARCHAR2,
                                        P_BANK_CODE          IN  VARCHAR2,
                                        P_TXN_AMT            IN  NUMBER,
                                        P_MCC_CODE           IN  VARCHAR2,
                                        P_CURR_CODE          IN  VARCHAR2,
                                        P_PROD_ID            IN  VARCHAR2,
                                        P_EXPRY_DATE         IN  VARCHAR2,
                                        P_STAN               IN  VARCHAR2,
                                        P_MBR_NUMB           IN  VARCHAR2,
                                        P_RVSL_CODE          IN  NUMBER,
                                        P_IPADDRESS          IN  VARCHAR2,
                                        P_AUTH_ID            OUT VARCHAR2,
                                        P_RESP_CODE          OUT VARCHAR2,
                                        P_RESP_MSG           OUT VARCHAR2,
                                        P_CAPTURE_DATE       OUT DATE,
                                        p_closed_card        OUT VARCHAR2,
                                        --Sn Added for FSS-5135
                                        p_oldcard_expry      OUT DATE,
                                        p_newcard_expry      OUT DATE,
                                        p_replacement_option OUT VARCHAR2,
                                        --En Added for FSS-5135
                                        P_FEE_FLAG           IN  VARCHAR2 DEFAULT 'Y',  -- Added by sagar for Fee_Flag Changes on 28Aug2012
                                        prm_np_flag          IN  VARCHAR2 DEFAULT 'N'   -- Added for VMS-104
                                                                                        -- Always keep this variable at last position since its declared as default
                                        ) IS

  /*****************************************************************************
   * modified by          : SAGAR
   * modified Date        : 04-Jan-13
   * Modified For         : CR-037 (To restrict replacement for Starter Card)
   * modified reason      : Validation added to restrict replacement for starter card
                          (Response id corrected from 155 to 156)
   * Reviewer             : Dhiarj
   * Reviewed Date        : 04-Jan-13
   * Build Number         : CMS3.5.1_RI0023_B0008

   * modified by         : Pankaj S.
   * modified for        : Card Replacement Changes
   * modified Date       : 12-Feb-2013
   * modified reason     : To check for Duplicate card replacemetn request (FSS-391)
   * Reviewer            : Dhiarj
   * Reviewed Date       :
   * Build Number        :

   * modified by         : Sachin P.
   * modified for        : FSS-1034
   * modified Date       : 13-Mar-2013
   * modified reason     : To identify that card replacement done  as normal or expedited shipping.
   * Reviewer            : Dhiraj
   * Reviewed Date       :
   * Build Number        :

   * Modified By          : Pankaj S.
   * Modified Date        : 19-Mar-2013
   * Modified Reason      : Logging of system initiated card status change(FSS-390)
   * Reviewer             : Dhiraj
   * Reviewed Date        :
   * Build Number         : CSR3.5.1_RI0024_B0007

   * Modified By          : Arunprasath
   * Modified Date        : 29-Mar-2013
   * Modified for         : Defect 10762
   * Modified Reason      : To update IPADDRESS for sucessfull transaction 0010762
   * Reviewer             : Dhiraj
   * Reviewed Date        : 29-Mar-2013
   * Build Number         : RI0024_B0015

   * Modified By          : Sagar M.
   * Modified Date        : 18-Apr-2013
   * Modified for         : Defect 10871
   * Modified Reason      : Logging of below details in tranasctionlog and statementlog table
                              1) ledger balance in statementlog
                              2) Product code,Product category code,Card status,Acct Type,drcr flag
                              3) Timestamp and Amount values logging correction
   * Reviewer             : Dhiraj
   * Reviewed Date        : 18-Apr-2013
   * Build Number         : RI0024.1_B0010

   * Modified By          : Sagar M.
   * Modified Date        : 17-Apr-2013
   * Modified for         : 10871
   * Modified Reason      : Logging of below details in tranasctionlog
                              1) Product code,Product category code,Acct Type,drcr flag
                              2) Timestamp and Amount values logging correction
   * Reviewer             : Dhiraj
   * Reviewed Date        : 18-Apr-2013
   * Build Number         : RI0024.1_B0007

   * Modified by      : MageshKumar.S
   * Modified Reason  : JH-6(Fast50 && Fedral And State Tax Refund Alerts)
   * Modified Date    : 19-09-2013
   * Reviewer         : Dhiraj
   * Reviewed Date    : 19-Sep-2013
   * Build Number     : RI0024.5_B0001

   * Modified by        : Kaleeswaran P
   * Modified Reason    : MVCSD-4121
   * Modified Date      : 07-MAR-2014
   * Reviewer           : Dhiraj
   * Reviewed Date      : 10-Mar-2014
   * Build Number       : RI0027.2_B0002

   * Modified by        : Dinesh
   * Modified Reason    : Review changes done for MVCSD-4121
   * Modified Date      : 25-MAR-2014
   * Reviewer           : Pankaj S.
   * Reviewed Date      : 01-April-2014
   * Build Number       : RI0027.2_B0003

   * Modified By      : Raja Gopal G
   * Modified Date    : 30-Jul-2014
   * Modified Reason  : Check Deposit Pending ,Accepted And Rejected Alerts(FR 3.2)
   * Reviewer         : Spankaj
   * Build Number     : RI0027.3.1_B0002

   * Modified By      : Ramesh A
   * Modified Date    : 01-Dec-2014
   * Modified Reason  : JH-3043
   * Reviewer         : Spankaj
   * Build Number     : RI0027.4.3_B0008
   * Modified By      : Siva Kumar M
   * Modified Date    : 10-Dec-2014
   * Modified Reason  : JH-3043
   * Reviewer         : Spankaj
   * Build Number     : RI0027.4.3_B0010

   * Modified By      : Ramesh A
   * Modified Date    : 12-Dec-2014
   * Modified Reason  : FSS-1961(Melissa)
   * Reviewer         : Spankaj
   * Build Number     : RI0027.5_B0002

   * Modified by      : Ramesh A.
   * Modified for     : FWR-59 : SMA and Email Alerts
   * Modified Date    : 13-Aug-2015
   * Reviewer         : Pankaj S
   * Build Number     : VMSGPRHOST_3.1

   * Modified by      : Pankaj S.
   * Modified for     : Transactionlog Functional Removal Phase-II changes
   * Modified Date    : 11-Aug-2015
   * Reviewer         : Saravanankumar
   * Build Number     : VMSGPRHOAT_3.1

    * Modified by       : Abdul Hameed M.A
    * Modified Date     : 27-Aug-15
    * Modified For      : MVHOST-1185
      * Reviewer          : Pankaj S
    * Build Number      : VMSGPRHOSTCSD_3.1_B0006

    * Modified by       : Ramesh A
    * Modified Date     : 03-MAY-16
    * Modified For      : FSS-4290
    * Reviewer          : SaravanaKumar A
    * Build Number      : VMSGPRHOSTCSD_4.0.2_B0001

    * Modified by          : MageshKumar S.
    * Modified Date        : 19-July-16
    * Modified For         : FSS-4423
    * Modified reason      : Token LifeCycle Changes
    * Reviewer             : Saravanan/Spankaj
    * Build Number         : VMSGPRHOSTCSD4.6_B0001

    * Modified by          : MageshKumar S.
    * Modified Date        : 02-Aug-16
    * Modified For         : FSS-4423 Additional Changes
    * Modified reason      : Token LifeCycle Changes
    * Reviewer             : Saravanan/Spankaj
    * Build Number         : VMSGPRHOSTCSD4.6_B0002

    * Modified by          : Pankaj S.
    * Modified Date        : 16-May-17
    * Modified For         : FSS-5135 -Changes in Card replacement / renewal logic
    * Reviewer             : Saravanan
    * Build Number         : VMSGPRHOST_17.05

    * Modified by          : T.Narayanaswamy
    * Modified Date        : 29-Aug-17
    * Modified For         : FSS-5157 - Disable replacement changes.
    * Reviewer             : Saravanan
    * Build Number         : VMSGPRHOST_17.08 Build II

    * Modified by          : Pankaj S.
    * Modified Date        : 29-Aug-17
    * Modified For         : VMS-104:Card Replacement with Incoming Amount Logic
    * Reviewer             : Saravanan
    * Build Number         : VMSGPRHOST_17.12

	 * Modified By      : Pankaj S.
     * Modified Date    : 05/01/2018
     * Purpose          : VMS-104
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST17.12
     
     * Modified By      : Ubaidur Rahman H.
     * Modified Date    : 03/04/2019
     * Purpose          : VMS-846 (Replacement must not be allowed for Digital Products)
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R14_B0004
	 
     * Modified By      : Ubaidur Rahman H.
     * Modified Date    : 03/04/2020
     * Purpose          : VMS-2332 (On migrate/update to new product,card level fee plan should not be carry forward).
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R28.1 - Interim release.
     
     * Modified by       : Mageshkumar  S
     * Modified Date     : 01-June-20
     * Modified For      : VMS-2253
     * Reviewer          : Saravanakumar A
     * Build Number      : R31_build_3

     * Modified by       : Santhosh C
     * Modified Date     : 28-April-21
     * Modified For      : VMS-3820 - Card Replacement - Virtual Replacement
     * Reviewer          : Ubaidur Rahman H.
     * Build Number      : R45_build_2	 
     
     * Modified by       : Santhosh C
     * Modified Date     : 28-April-21
     * Modified For      : VMS-3820 - Card Replacement - Virtual Replacement
     * Reviewer          : Ubaidur Rahman H.
     * Build Number      : R45_build_2
     
    * Modified by      : UBAIDUR RAHMAN.H
    * Modified Date    : 06-May-2021
    * Modified For     : VMS-4223 - B2B Replace card for virtual product is not creating card in Active status 
    * Reviewer         : Saravanankumar
    * Build Number     : VMSR46_B0002
	
	* Modified by      : Saravanankumar
    * Modified Date    : 07-June-2021
    * Modified For     : VMS-4543 Amex Escheatment Record Type 4 - card replacement
    * Reviewer         : Saravanankumar
    * Build Number     : VMSR47_B0003

   * Modified By      : venkat Singamaneni
    * Modified Date    : 3-18-2022
    * Purpose          : Archival changes.
     * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
	
	 * Modified By      :  Mohan Kumar.E
     * Modified Date    :  09-Feb-2023
     * Modified Reason  :  VMS-6026  - Replacement Cards Persisting Original PackID Values.
     * Reviewer         :  Pankaj S.
  ******************************************************************************/
  V_ACCT_BALANCE                  NUMBER;
  V_LEDGER_BAL                    NUMBER;
  V_TRAN_AMT                      NUMBER;
  V_AUTH_ID                       TRANSACTIONLOG.AUTH_ID%TYPE;
  V_TOTAL_AMT                     NUMBER;
  V_TRAN_DATE                     DATE;
  V_FUNC_CODE                     CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_PROD_CODE                     CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE                  CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_FEE_AMT                       NUMBER;
  V_TOTAL_FEE                     NUMBER;
  V_UPD_AMT                       NUMBER;
  V_UPD_LEDGER_AMT                NUMBER;
  V_NARRATION                     VARCHAR2(50);
  V_FEE_OPENING_BAL               NUMBER;
  V_RESP_CDE                      VARCHAR2(5);
  V_EXPRY_DATE                    DATE;
  V_DR_CR_FLAG                    VARCHAR2(2);
  V_OUTPUT_TYPE                   VARCHAR2(2);
  V_APPLPAN_CARDSTAT              CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_ATMONLINE_LIMIT               CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  V_POSONLINE_LIMIT               CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  V_ERR_MSG                       VARCHAR2(500);
  V_PRECHECK_FLAG                 NUMBER;
  V_PREAUTH_FLAG                  NUMBER;
  --V_AVAIL_PAN                   CMS_AVAIL_TRANS.CAT_PAN_CODE%TYPE;
  V_GL_UPD_FLAG                   TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
  V_GL_ERR_MSG                    VARCHAR2(500);
  V_SAVEPOINT                     NUMBER := 0;
  V_TRAN_FEE                      NUMBER;
  V_ERROR                         VARCHAR2(500);
  V_BUSINESS_DATE_TRAN            DATE;
  V_BUSINESS_TIME                 VARCHAR2(5);
  V_CUTOFF_TIME                   VARCHAR2(5);
  V_CARD_CURR                     VARCHAR2(5);
  V_FEE_CODE                      CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  V_FEE_CRGL_CATG                 CMS_PRODCATTYPE_FEES.CPF_CRGL_CATG%TYPE;
  V_FEE_CRGL_CODE                 CMS_PRODCATTYPE_FEES.CPF_CRGL_CODE%TYPE;
  V_FEE_CRSUBGL_CODE              CMS_PRODCATTYPE_FEES.CPF_CRSUBGL_CODE%TYPE;
  V_FEE_CRACCT_NO                 CMS_PRODCATTYPE_FEES.CPF_CRACCT_NO%TYPE;
  V_FEE_DRGL_CATG                 CMS_PRODCATTYPE_FEES.CPF_DRGL_CATG%TYPE;
  V_FEE_DRGL_CODE                 CMS_PRODCATTYPE_FEES.CPF_DRGL_CODE%TYPE;
  V_FEE_DRSUBGL_CODE              CMS_PRODCATTYPE_FEES.CPF_DRSUBGL_CODE%TYPE;
  V_FEE_DRACCT_NO                 CMS_PRODCATTYPE_FEES.CPF_DRACCT_NO%TYPE;
  --st AND cess
  V_SERVICETAX_PERCENT            CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_CESS_PERCENT                  CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_SERVICETAX_AMOUNT             NUMBER;
  V_CESS_AMOUNT                   NUMBER;
  V_ST_CALC_FLAG                  CMS_PRODCATTYPE_FEES.CPF_ST_CALC_FLAG%TYPE;
  V_CESS_CALC_FLAG                CMS_PRODCATTYPE_FEES.CPF_CESS_CALC_FLAG%TYPE;
  V_ST_CRACCT_NO                  CMS_PRODCATTYPE_FEES.CPF_ST_CRACCT_NO%TYPE;
  V_ST_DRACCT_NO                  CMS_PRODCATTYPE_FEES.CPF_ST_DRACCT_NO%TYPE;
  V_CESS_CRACCT_NO                CMS_PRODCATTYPE_FEES.CPF_CESS_CRACCT_NO%TYPE;
  V_CESS_DRACCT_NO                CMS_PRODCATTYPE_FEES.CPF_CESS_DRACCT_NO%TYPE;
  --
  V_WAIV_PERCNT                   CMS_PRODCATTYPE_WAIV.CPW_WAIV_PRCNT%TYPE;
  V_ERR_WAIV                      VARCHAR2(300);
  V_LOG_ACTUAL_FEE                NUMBER;
  V_LOG_WAIVER_AMT                NUMBER;
  V_AUTH_SAVEPOINT                NUMBER DEFAULT 0;
  V_BUSINESS_DATE                 DATE;
  V_TXN_TYPE                      NUMBER(1);
  V_MINI_TOTREC                   NUMBER(2);
  V_MINISTMT_ERRMSG               VARCHAR2(500);
  V_MINISTMT_OUTPUT               VARCHAR2(900);
  EXP_REJECT_RECORD               EXCEPTION;
  V_ATM_USAGEAMNT                 CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_AMT%TYPE;
  V_POS_USAGEAMNT                 CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_AMT%TYPE;
  V_ATM_USAGELIMIT                CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_LIMIT%TYPE;
  V_POS_USAGELIMIT                CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_LIMIT%TYPE;
  V_MMPOS_USAGEAMNT               CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
  V_MMPOS_USAGELIMIT              CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_LIMIT%TYPE;
  V_PREAUTH_DATE                  DATE;
  V_PREAUTH_HOLD                  VARCHAR2(1);
  V_PREAUTH_PERIOD                NUMBER;
  V_PREAUTH_USAGE_LIMIT           NUMBER;
  V_CARD_ACCT_NO                  VARCHAR2(20);
  V_HOLD_AMOUNT                   NUMBER;
  V_HASH_PAN                      CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN                      CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_RRN_COUNT                     NUMBER;
  V_TRAN_TYPE                     VARCHAR2(2);
  V_DATE                          DATE;
  V_TIME                          VARCHAR2(10);
  V_MAX_CARD_BAL                  NUMBER;
  V_CURR_DATE                     DATE;
  V_PREAUTH_EXP_PERIOD            VARCHAR2(10);
  V_INTERNATIONAL_FLAG            CHARACTER(1);
  V_PROXUNUMBER                   CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER                   CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_CAP_CARD_STAT                 VARCHAR2(10);
  CRDSTAT_CNT                     VARCHAR2(10);
  V_CRO_OLDCARD_REISSUE_STAT      VARCHAR2(10);
  V_MBRNUMB                       VARCHAR2(10);
  NEW_DISPNAME                    CMS_APPL_PAN.CAP_DISP_NAME%TYPE;--VARCHAR2(50);
  NEW_CARD_NO                     VARCHAR2(100);
  V_CAP_PROD_CATG                 VARCHAR2(100);
  V_CUST_CODE                     VARCHAR2(100);
  P_REMRK                         VARCHAR2(100);
  V_RESONCODE                     CMS_SPPRT_REASONS.CSR_SPPRT_RSNCODE%TYPE;
  V_STATUS_CHK                    NUMBER;
  --Added by Deepa On June 19 2012 for Fees Changes
  V_FEEAMNT_TYPE                  CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
  V_PER_FEES                      CMS_FEE_MAST.CFM_PER_FEES%TYPE;
  V_FLAT_FEES                     CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_CLAWBACK                      CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
  V_FEE_PLAN                      CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;
  V_FREETXN_EXCEED                VARCHAR2(1); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_DURATION                      VARCHAR2(20); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
  V_STARTERCARD_FLAG              CMS_APPL_PAN.CAP_STARTERCARD_FLAG%TYPE;  -- Added on 13-Dec-2012 to restrict replacement for starter card
  v_dup_check                     NUMBER (3); --Added by Pankaj S. on 13-Feb-2013 for Card replacement changes(FSS-391)
  v_cam_lupd_date                 cms_addr_mast.cam_lupd_date%TYPE;--Added by Pankaj S. on 13-Feb-2013 for Card replacement changes(FSS-391)
  V_NEW_HASH_PAN                  CMS_APPL_PAN.CAP_PAN_CODE%TYPE; --Added on 13.03.2013 for FSS-1034
  V_APPL_CODE                     CMS_APPL_PAN.CAP_APPL_CODE%TYPE; --Added on 18.03.2013
  v_cam_type_code                 cms_acct_mast.cam_type_code%type; -- Added on 18-Apr-2013 for defect 10871
  v_timestamp                     timestamp;                         -- Added on 18-Apr-2013 for defect 10871
  V_NEW_CARDTYPE                  CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;  --Added for MVCSD-4121 on 07-Mar-2014
  V_NEW_PRODUCT                   CMS_APPL_PAN.CAP_PROD_CODE%TYPE;  --Added for MVCSD-4121 on 07-Mar-2014
  v_lmtprfl                       cms_prdcattype_lmtprfl.cpl_lmtprfl_id%TYPE;
  v_profile_level                 cms_appl_pan.cap_prfl_levl%TYPE;
  --Sn Added for FSS-5135
  v_profile_code                  cms_prod_cattype.cpc_profile_code%TYPE;
  v_expryparam                    cms_bin_param.cbp_param_value%TYPE;
  v_validity_period               cms_bin_param.cbp_param_value%TYPE;
  V_REPL_FLAG                     CMS_APPL_PAN.CAP_REPL_FLAG%type:=0;
  V_DISABLE_REPL_FLAG             CMS_PROD_CATTYPE.CPC_DISABLE_REPL_FLAG%type;
  V_DISABLE_REPL_EXPDAYS          CMS_PROD_CATTYPE.CPC_DISABLE_REPL_EXPRYDAYS%type;
  V_DISABLE_REPL_MINBAL           CMS_PROD_CATTYPE.CPC_DISABLE_REPL_MINBAL%type;
  V_DISABLE_REPL_MESSAGE          CMS_PROD_CATTYPE.CPC_DISABLE_REPL_MESSAGE%type;
  l_user_type                     CMS_PROD_CATTYPE.CPC_USER_IDENTIFY_TYPE%type;
  v_cardpack_id                   CMS_APPL_PAN.CAP_CARDPACK_ID%TYPE;
  --v_card_id                       CMS_PROD_CATTYPE.CPC_CARD_ID%TYPE;--- Modified for VMS-6026
  v_replace_shipmethod            vms_packageid_mast.vpm_replace_shipmethod%TYPE;
  v_exp_replaceshipmethod         vms_packageid_mast.vpm_exp_replaceshipmethod%type;
  v_form_factor                   cms_appl_pan.cap_form_factor%type;  --Added for VMS-846 (Replacement not allowed for digital products)
  v_multiple_replacement          NUMBER (3); --Added for VMS-2253(Replacement is not allowed on a printer pending card)
  v_Retperiod  date; --Added for VMS-5733/FSP-991
  v_Retdate  date; --Added for VMS-5733/FSP-991
  v_pan_prm6                     cms_appl_pan.cap_panmast_param6%TYPE;

  --En Added for FSS-5135
BEGIN
  SAVEPOINT V_AUTH_SAVEPOINT;
  V_RESP_CDE := '1';
  V_ERR_MSG  := 'OK';
  P_RESP_MSG := 'OK';
  P_REMRK    := 'Online Order Replacement Card';



  BEGIN
        --SN CREATE HASH PAN
        --Gethash is used to hash the original Pan no
        BEGIN
         V_HASH_PAN := GETHASH(P_CARD_NO);
        EXCEPTION
         WHEN OTHERS THEN
           V_ERR_MSG := 'Error while converting into hash value ' ||fn_mask(P_CARD_NO,'X',7,6)
                     ||' '||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;

        --EN CREATE HASH PAN
        --SN create encr pan
        --Fn_Emaps_Main is used for Encrypt the original Pan no
        BEGIN
         V_ENCR_PAN := FN_EMAPS_MAIN(P_CARD_NO);
        EXCEPTION
         WHEN OTHERS THEN
           V_ERR_MSG := 'Error while converting into encrypted value '||fn_mask(P_CARD_NO,'X',7,6)
                     ||' '||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;

        --EN create encr pan

        -------------------------------------------------------------------
        --SN: Added on 13-Dec-2012 to restrict replacement for starter card
        -------------------------------------------------------------------

        BEGIN
        SELECT CAP_PROD_CATG, CAP_CARD_STAT, CAP_ACCT_NO, CAP_CUST_CODE,
                CAP_APPL_CODE, CAP_STARTERCARD_FLAG, CAP_DISP_NAME, CAP_PROD_CODE, CAP_CARD_TYPE  --Added on 18.03.2013
                ,cap_prfl_code,cap_prfl_levl, cap_expry_date, cap_cardpack_id, cap_form_factor,cap_repl_flag,   --Added for VMS-846 (Replacement not allowed for digital products)
                cap_panmast_param6
           INTO V_CAP_PROD_CATG, V_CAP_CARD_STAT, V_ACCT_NUMBER, V_CUST_CODE,
                V_APPL_CODE,V_STARTERCARD_FLAG,NEW_DISPNAME, V_PROD_CODE, V_PROD_CATTYPE          --Added on 18.03.2013
                ,v_lmtprfl,v_profile_level,  p_oldcard_expry, v_cardpack_id ,v_form_factor,v_repl_flag,        --Added for VMS-846 (Replacement not allowed for digital products)
                v_pan_prm6
          FROM CMS_APPL_PAN
          WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERR_MSG  := 'Pan not found in master';
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while selecting CMS_APPL_PAN' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;
                --Sn Added for FSS-5135
        BEGIN
           SELECT NVL (cpc_renew_replace_option, 'NP'),
                  cpc_profile_code,
                  CPC_RENEW_REPLACE_PRODCODE,
                  CPC_RENEW_REPLACE_CARDTYPE,
                  CPC_DISABLE_REPL_FLAG,
                  NVL(CPC_DISABLE_REPL_EXPRYDAYS,0),
                  NVL(CPC_DISABLE_REPL_MINBAL,0),
                  CPC_DISABLE_REPL_MESSAGE,
                  nvl(CPC_USER_IDENTIFY_TYPE,0)
             INTO p_replacement_option,
                  v_profile_code,
                  v_new_product,
                  v_new_cardtype,
                  V_DISABLE_REPL_FLAG,
                  V_DISABLE_REPL_EXPDAYS,
                  V_DISABLE_REPL_MINBAL,
                  v_disable_repl_message,
                  l_user_type
             FROM cms_prod_cattype
            WHERE     cpc_inst_code = p_inst_code
                  AND cpc_prod_code = v_prod_code
                  AND cpc_card_type = v_prod_cattype;
        EXCEPTION
           WHEN OTHERS
           THEN
              v_err_msg :=
                 'Error while selecting replacement param '
                 || SUBSTR (SQLERRM, 1, 200);
              v_resp_cde := '21';
              RAISE exp_reject_record;
        END;
        if  V_STARTERCARD_FLAG = 'Y' and l_user_type <> '1'
        then

           V_RESP_CDE := '156';
           V_ERR_MSG  := 'Replacement Not Allowed For Starter Card '||fn_mask(P_CARD_NO,'X',7,6);
           RAISE EXP_REJECT_RECORD;

        end if;
        
        -------------------------------------------------------------------
        --EN: Added on 13-Dec-2012 to restrict replacement for starter card
        -------------------------------------------------------------------
        /*-- VMS-3820: Allowing card replacement for the virtual cards.
        --SN : Added for VMS-846 (Replacement not allowed for digital products)
        IF v_form_factor = 'V'
        THEN
        
            V_RESP_CDE := '145';
            V_ERR_MSG  := 'Replacement Not Allowed For Digital Card';
            RAISE EXP_REJECT_RECORD;  
        
        END IF;
        --EN : Added for VMS-846 (Replacement not allowed for digital products)
		*/




          --Sn Duplicate RRN Check
        BEGIN
--Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

IF (v_Retdate>v_Retperiod)
    THEN
         SELECT COUNT(1)
           INTO V_RRN_COUNT
           FROM TRANSACTIONLOG
          WHERE RRN = P_RRN AND --Changed for admin dr cr.
               BUSINESS_DATE = P_TRAN_DATE AND
               DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; --Added by ramkumar.Mk on 25 march 2012
      ELSE
         SELECT COUNT(1)
           INTO V_RRN_COUNT
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE RRN = P_RRN AND --Changed for admin dr cr.
               BUSINESS_DATE = P_TRAN_DATE AND
               DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
         END IF;             
             IF V_RRN_COUNT > 0 THEN
               V_RESP_CDE := '22';
               V_ERR_MSG  := 'Duplicate RRN from the Terminal on ' || P_TRAN_DATE;
               RAISE EXP_REJECT_RECORD;
             END IF;

        END;
        --En Duplicate RRN Check


        BEGIN
         V_BUSINESS_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
                            SUBSTR(TRIM(P_TRAN_TIME), 1, 10),
                            'yyyymmdd hh24:mi:ss');
        EXCEPTION
         WHEN OTHERS THEN
           V_RESP_CDE := '32'; -- Server Declined -220509
           V_ERR_MSG  := 'Problem while converting transaction date time ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;



    /*
       --Added by Deepa for Authid generation
        --Sn generate auth id
        BEGIN

         --SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
         SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;

        EXCEPTION
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while generating authid ' ||
                      SUBSTR(SQLERRM, 1, 300);
           V_RESP_CDE := '21'; -- Server Declined
           RAISE EXP_REJECT_RECORD;
        END;

        --En generate auth id
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

        --EN CHECK INST CODE

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
               CTM_TRAN_TYPE
           INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE
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
      */


        --Sn find debit and credit flag
        BEGIN
         SELECT CTM_CREDIT_DEBIT_FLAG,
               CTM_OUTPUT_TYPE,
               TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
               CTM_TRAN_TYPE
           INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE
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
       --Sn Added by Pankaj S. on 12-Feb-2013 for Duplicate card Replacement check (FSS-391)
      BEGIN
         SELECT COUNT (1)
           INTO v_dup_check
           FROM cms_htlst_reisu
          WHERE chr_inst_code = p_inst_code
            AND chr_pan_code = v_hash_pan
            AND chr_reisu_cause = 'R'
            AND chr_new_pan IS NOT NULL;

         IF v_dup_check > 0
         THEN
            v_resp_cde := '159';
            v_err_msg := 'Card already Replaced';
            RAISE exp_reject_record;
         END IF;
      END;

      --En Added by Pankaj S. on 12-Feb-2013 for Duplicate card Replacement check (FSS-391)
       --Sn added by Pankaj S. comment same block used below n put here(Fss-391)
    /*
        BEGIN
         SELECT CAP_PROD_CATG, CAP_CARD_STAT, CAP_ACCT_NO, CAP_CUST_CODE,
                CAP_APPL_CODE --Added on 18.03.2013
           INTO V_CAP_PROD_CATG, V_CAP_CARD_STAT, V_ACCT_NUMBER, V_CUST_CODE,
                V_APPL_CODE --Added on 18.03.2013
          FROM CMS_APPL_PAN
          WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERR_MSG  := 'Pan not found in master';
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while selecting CMS_APPL_PAN' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;
        --En added by Pankaj S. comment same block used below n put here(Fss-391)
        */
        --Sn added for card replacement changes(Fss-391)
    
      --- Modified for VMS-4223 - B2B Replace card for virtual product is not creating card in Active status 
      
   IF P_DELIVERY_CHANNEL NOT IN ('03','17') THEN
        BEGIN
          SELECT CAM_LUPD_DATE
          INTO V_CAM_LUPD_DATE
          FROM CMS_ADDR_MAST
          WHERE CAM_INST_CODE=P_INST_CODE
          AND CAM_CUST_CODE=V_CUST_CODE
          AND CAM_ADDR_FLAG='P';

          IF v_cam_lupd_date > sysdate-1 THEN
            V_ERR_MSG  := 'Card replacement is not allowed to customer who changed address in last 24 hr';
           V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
             END IF;

        EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
        RAISE;
        WHEN OTHERS THEN
        V_ERR_MSG  := 'Error while selecting customer address details' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;
    END IF;
        --En added for card replacement changes(Fss-391)



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
                     V_PROD_CATTYPE);

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

      /*
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
       *


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

        --En find card detail
      */

      /*
        --Sn GPR Card status check
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
            IF (V_RESP_CDE = '70' OR TRIM(V_ERR_MSG) <> 'OK') THEN
                V_RESP_CDE := '70';
                RAISE EXP_REJECT_RECORD;
              ELSE
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
              END IF;
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

        --Sn find function code attached to txn code
        BEGIN
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
           V_ERR_MSG  := 'Error while selecting CMS_FUNC_MAST' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;

        --En find function code attached to txn code
        --Sn find prod code and card type and available balance for the card number
        BEGIN
         SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO
           INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO
           FROM CMS_ACCT_MAST
          WHERE CAM_ACCT_NO =
               (SELECT CAP_ACCT_NO
                 FROM CMS_APPL_PAN
                WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
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

        BEGIN

         SP_TRAN_FEES_CMSAUTH(P_INST_CODE,
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
                          NULL, --Added by Deepa for Fees Changes
                          NULL, --Added by Deepa for Fees Changes
                          V_RESP_CDE, --Added by Deepa for Fees Changes
                          P_MSG, --Added by Deepa for Fees Changes
                          P_RVSL_CODE, --Added by Deepa on June 25 2012 for Reversal txn Fee
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
                          V_DURATION -- Added by Trivikram for logging fee of free transaction
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
       */





         /*
            --Sn check balance
            IF V_DR_CR_FLAG NOT IN ('NA', 'CR') AND P_TXN_CODE <> '93' -- For credit transaction or Non-Financial transaction Insufficient Balance Check is not required. -- 29th June 2011
            THEN

                 IF V_UPD_AMT < 0 THEN
                   V_RESP_CDE := '15'; --Ineligible Transaction
                   V_ERR_MSG  := 'Insufficent Balance ';
                   RAISE EXP_REJECT_RECORD;
                 END IF;

            END IF;
            --En check balance
          */

        -- Check for maximum card balance configured for the product profile.

  --SN : Added for VMS-2253(Replacement is not allowed on a printer pending card)
    IF v_repl_flag <> 0
        THEN
        
          --Sn Check application status as printer pending for replacement card
          BEGIN
             SELECT  COUNT (1)
           INTO v_multiple_replacement FROM cms_cardissuance_status
              WHERE ccs_inst_code = p_inst_code AND ccs_pan_code = v_hash_pan  AND (ccs_card_status = '2' OR ccs_card_status = '20');
              
           IF v_multiple_replacement > 0
           THEN
              v_resp_cde := '271';
              v_err_msg := 'Replacement is not allowed on a card yet to be fulfilled';
              RAISE exp_reject_record;
           END IF;
           
      EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
        RAISE;
        WHEN OTHERS THEN
        V_ERR_MSG  := 'Error while selecting card application status' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;
        

    END IF;
  --EN : Added for VMS-2253(Replacement is not allowed on a printer pending card)

          BEGIN                                  -- Added by sagar on 28-Aug-2012
             sp_authorize_txn_cms_auth (P_INST_CODE,
                                        P_MSG,
                                        P_RRN,
                                        P_DELIVERY_CHANNEL,
                                        P_TERM_ID,                          --P_TERM_ID
                                        P_TXN_CODE,
                                        P_TXN_MODE,
                                        P_TRAN_DATE,
                                        P_TRAN_TIME,
                                        P_CARD_NO,
                                        P_INST_CODE,
                                        P_TXN_AMT,                           --AMT
                                        NULL,                      --MERCHANT NAME
                                        NULL,                      --MERCHANT CITY
                                        P_MCC_CODE,                         --P_MCC_CODE
                                        P_CURR_CODE,
                                        NULL,                          --P_PROD_ID
                                        NULL,                          --P_CATG_ID
                                        NULL,                          --P_TIP_AMT
                                        NULL,                       --P_TO_ACCT_NO
                                        NULL,                      --P_ATMNAME_LOC
                                        NULL,                  --P_MCCCODE_GROUPID
                                        NULL,                 --P_CURRCODE_GROUPID
                                        NULL,                --P_TRANSCODE_GROUPID
                                        NULL,                            --P_RULES
                                        NULL,                     --P_PREAUTH_DATE
                                        NULL,                   --P_CONSODIUM_CODE
                                        NULL,                     --P_PARTNER_CODE
                                        P_EXPRY_DATE,                       --P_EXPRY_DATE
                                        P_STAN,
                                        P_MBR_NUMB,
                                        P_RVSL_CODE,
                                        P_TXN_AMT,                --P_CURR_CONVERT_AMNT
                                        P_AUTH_ID,
                                        V_RESP_CDE,
                                        V_ERR_MSG,
                                        P_CAPTURE_DATE,
                                        P_FEE_FLAG
                                       );

             IF V_RESP_CDE <> '00' AND V_ERR_MSG <> 'OK'
             THEN
                --V_RESP_CDE := '21'; Commented by Besky on 06-nov-12

                P_RESP_CODE := V_RESP_CDE;

                P_RESP_MSG := 'Error from auth process' || V_ERR_MSG;

                return;
             END IF;

          EXCEPTION WHEN OTHERS
             THEN
                V_RESP_CDE := '21';
                V_ERR_MSG :=
                      'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
          END;


      /*
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
       */


        --En check balance
        --Sn Commented by Pankaj S. to used same block before authorizaion(Fss-391)
       /* BEGIN
         SELECT CAP_PROD_CATG, CAP_CARD_STAT, CAP_ACCT_NO, CAP_CUST_CODE
           INTO V_CAP_PROD_CATG, V_CAP_CARD_STAT, V_ACCT_NUMBER, V_CUST_CODE
           FROM CMS_APPL_PAN
          WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERR_MSG  := 'Pan not found in master';
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while selecting CMS_APPL_PAN' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;*/
        --Sn Commented by Pankaj S. to used same block before authorizaion(Fss-391)


        BEGIN
         SELECT COUNT(*)
           INTO CRDSTAT_CNT
           FROM CMS_REISSUE_VALIDSTAT
          WHERE CRV_INST_CODE = P_INST_CODE AND
               CRV_VALID_CRDSTAT = V_CAP_CARD_STAT AND CRV_PROD_CATG IN ('P');
         IF CRDSTAT_CNT = 0 THEN
           V_ERR_MSG  := 'Not a valid card status. Card cannot be reissued';
           V_RESP_CDE := '09';
           RAISE EXP_REJECT_RECORD;
         END IF;

        END;


        --Sn:Added for VMS-104
        IF prm_np_flag='Y' AND p_replacement_option='SP' THEN
             p_replacement_option:='NP';
        END IF;
        --En:Added for VMS-104

  -- Added for Disable replacement config changes beg

         BEGIN
           SELECT CAM_ACCT_BAL
            INTO V_ACCT_BALANCE
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
         end;

    BEGIN
        if V_DISABLE_REPL_FLAG = 'Y' then
          if sysdate between (P_OLDCARD_EXPRY-V_DISABLE_REPL_EXPDAYS) and P_OLDCARD_EXPRY then
            v_err_msg := v_disable_repl_message;
            v_resp_cde := '269';
            RAISE EXP_REJECT_RECORD;
          ELSIF NVL(V_ACCT_BALANCE,0) <= V_DISABLE_REPL_MINBAL  then
              v_err_msg := v_disable_repl_message;
              V_RESP_CDE := '269';
              RAISE EXP_REJECT_RECORD;
          end if;
        end if;
    EXCEPTION
      WHEN exp_reject_record
        then
        RAISE;
       WHEN OTHERS
       THEN
          V_ERR_MSG :=
             'Error while selecting replacement param '
             || SUBSTR (SQLERRM, 1, 200);
          v_resp_cde := '21';
          RAISE EXP_REJECT_RECORD;
    END;
   -- Added for Disable replacement config changes end
   
   
				--SN:Added for VMS-6026 
                
            if v_cardpack_id is null then
                
                    select  cap_cardpack_id
                    into v_cardpack_id
                    from ( select  cap_cardpack_id
                    from cms_appl_pan
                    where cap_inst_code = P_INST_CODE
                    and cap_acct_no = V_ACCT_NUMBER
                    and  cap_repl_flag = 0
                    ORDER BY cap_ins_date
                    )
                where rownum =1;
				     
                    
            end if;
                    
                --EN:Added for VMS-6026

   begin
     SELECT vpm_replace_shipmethod, vpm_exp_replaceshipmethod
        INTO v_replace_shipmethod, v_exp_replaceshipmethod
        FROM vms_packageid_mast
       WHERE vpm_package_id IN
          (SELECT vpm_replacement_package_id
             FROM vms_packageid_mast
            WHERE vpm_package_id IN
               (SELECT cpc_card_details
                  FROM cms_prod_cardpack
                 WHERE cpc_prod_code = v_prod_code
                   AND cpc_card_id = v_cardpack_id));-- NVL(v_cardpack_id,v_card_id)));--- Modified for VMS-6026
    exception
      when others then
        v_replace_shipmethod :=6;
        v_exp_replaceshipmethod:=7;
    end;

     IF (p_txn_code IN('21','22') AND p_delivery_channel IN ('03','17'))
              OR (p_txn_code = '11' AND p_delivery_channel = '10')
     THEN
              v_repl_flag := NVL(v_replace_shipmethod,6);
     ELSIF (p_txn_code = '29' AND p_delivery_channel IN ('03','17'))
                 OR (p_txn_code = '99' AND p_delivery_channel = '10')
     THEN
              v_repl_flag := NVL(v_exp_replaceshipmethod,7);
     end if;
     
     IF p_replacement_option = 'SP' AND v_cap_card_stat  NOT IN ( '2', '15') THEN  --Added cardstatus '15' for VMS-104 changes
          IF v_profile_code IS NULL
          THEN
             v_err_msg := 'Profile is not Attached to Product CatType';
             v_resp_cde := '21';
             RAISE exp_reject_record;
          END IF;

          BEGIN
            vmsfunutilities.get_expiry_date(P_INST_CODE,v_prod_code,
            v_prod_cattype,V_PROFILE_CODE,v_expry_date,v_err_msg);

            if v_err_msg<>'OK' then
                RAISE exp_reject_record;
             END IF;


          EXCEPTION
              WHEN EXP_REJECT_RECORD THEN
                RAISE;
              WHEN OTHERS THEN
                v_err_msg:='Error while calling vmsfunutilities.get_expiry_date'||substr(sqlerrm,1,200);
                RAISE exp_reject_record;
          END;


          --Sn Update new expry
           BEGIN
             UPDATE cms_appl_pan
                SET cap_replace_exprydt = v_expry_date,
                        cap_repl_flag =  v_repl_flag
              WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;

             IF SQL%ROWCOUNT <> 1
             THEN
                v_err_msg := 'Error while updating appl_pan ';
                v_resp_cde := '21';
                RAISE exp_reject_record;
             END IF;
          EXCEPTION
             WHEN exp_reject_record
             THEN
                RAISE;
             WHEN OTHERS
             THEN
                v_err_msg :=
                   'Error while updating Expiry Date' || SUBSTR (SQLERRM, 1, 200);
                v_resp_cde := '21';
                RAISE exp_reject_record;
          END;
          --En Update new expry

          --Sn Update application status as printer pending
          BEGIN
             UPDATE cms_cardissuance_status
                SET ccs_card_status = '20'
              WHERE ccs_inst_code = p_inst_code AND ccs_pan_code = v_hash_pan;

             IF SQL%ROWCOUNT <> 1
             THEN
                v_err_msg := 'Error while updating CMS_CARDISSUANCE_STATUS ';
                v_resp_cde := '21';
                RAISE exp_reject_record;
             END IF;
          EXCEPTION
             WHEN exp_reject_record
             THEN
                RAISE;
             WHEN OTHERS
             THEN
                v_err_msg :=
                   'Error while updating Application Card Issuance Status'
                   || SUBSTR (SQLERRM, 1, 200);
                v_resp_cde := '21';
                RAISE exp_reject_record;
          END;
       --En Update application status as printer pending
     ELSE
          IF p_replacement_option='NPP' THEN
               v_prod_code:=v_new_product;
               v_prod_cattype:=v_new_cardtype;
          END IF;
      --En Added for FSS-5135
        BEGIN
         SELECT CRO_OLDCARD_REISSUE_STAT
           INTO V_CRO_OLDCARD_REISSUE_STAT
           FROM CMS_REISSUE_OLDCARDSTAT
          WHERE CRO_INST_CODE = P_INST_CODE AND
               CRO_OLDCARD_STAT = V_CAP_CARD_STAT AND CRO_SPPRT_KEY = 'R';
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERR_MSG  := 'Default old card status nor defined for institution ' ||
                      P_INST_CODE;
           V_RESP_CDE := '09';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while getting default old card status for institution ' ||
                      P_INST_CODE;
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;

        BEGIN
         --begin 5 starts
         UPDATE CMS_APPL_PAN
            SET CAP_CARD_STAT = V_CRO_OLDCARD_REISSUE_STAT,
               CAP_LUPD_USER = P_BANK_CODE
          WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;
         IF SQL%ROWCOUNT != 1 THEN
           V_ERR_MSG  := 'Problem in updation of status for pan ' ||
                      V_HASH_PAN;
           V_RESP_CDE := '09';
           RAISE EXP_REJECT_RECORD;
         END IF;

         if V_CRO_OLDCARD_REISSUE_STAT='9' then
         p_closed_card :=P_CARD_NO;
         end if;

        EXCEPTION
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while updating CMS_APPL_PAN' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;
        --Sn find member number

        IF V_CRO_OLDCARD_REISSUE_STAT='9' THEN
        --Sn Addded by Pankaj S. for FSS-390
        BEGIN
           sp_log_cardstat_chnge (p_inst_code,
                                  v_hash_pan,
                                  v_encr_pan,
                                  p_auth_id,
                                  '02',
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
        --En Added by Pankaj S. for FSS-390
          END IF;

        BEGIN
         SELECT CIP_PARAM_VALUE
           INTO V_MBRNUMB
           FROM CMS_INST_PARAM
          WHERE CIP_INST_CODE = P_INST_CODE AND CIP_PARAM_KEY = 'MBR_NUMB';
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERR_MSG  := 'Member number not defined for the institute';
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while selecting member number from institute';
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;

        END;

  /*      BEGIN

        SELECT CAP_DISP_NAME,CAP_PROD_CODE,CAP_CARD_TYPE --Added for MVCSD-4121
         INTO NEW_DISPNAME,V_PROD_CODE,V_PROD_CATTYPE
         FROM CMS_APPL_PAN
        WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;

         EXCEPTION
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while getting appl_pan details ' ||SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;*/


        --Block added for MVCDS-4121
       /*  BEGIN
                SELECT CPP_RENEW_PRODCODE,CPP_RENEW_CARDTYPE
                    INTO V_NEW_PRODUCT,V_NEW_CARDTYPE
                FROM cms_product_param
                WHERE CPP_PROD_CODE= V_PROD_CODE
                AND CPP_INST_CODE  = P_INST_CODE;

         EXCEPTION
         WHEN NO_DATA_FOUND THEN
         /*
           V_ERR_MSG  := 'No Data found in product param table ';
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
           */
        /*   V_NEW_PRODUCT := null ;
           V_NEW_CARDTYPE := null;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while getting product param details ' ||SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
          END;


          IF TRIM(V_NEW_PRODUCT) IS NOT NULL AND TRIM(V_NEW_CARDTYPE) IS NOT NULL  THEN

                V_PROD_CODE :=V_NEW_PRODUCT;
                V_PROD_CATTYPE :=V_NEW_CARDTYPE;
            END IF;*/

       -----END Block for MVCDS-4121--

        BEGIN
         SP_ORDER_REISSUEPAN_CMS(P_INST_CODE,
                            P_CARD_NO,
                            V_PROD_CODE,
                            V_PROD_CATTYPE,
                            NEW_DISPNAME,
                            P_BANK_CODE,
                            NEW_CARD_NO,
                            V_ERR_MSG);
                
         IF V_ERR_MSG != 'OK' THEN
           V_ERR_MSG  := 'From reissue pan generation process-- ' || V_ERR_MSG;
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;

         END IF;
        EXCEPTION WHEN EXP_REJECT_RECORD
        THEN
            RAISE;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'From reissue pan generation process-- ' || V_ERR_MSG;
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;

        END;

    --SN Added on 13.03.2013 for FSS-1034
        --SN CREATE HASH PAN
        --Gethash is used to hash the new Pan no
        BEGIN
         V_NEW_HASH_PAN := GETHASH(NEW_CARD_NO);
        EXCEPTION
         WHEN OTHERS THEN
           V_ERR_MSG := 'Error while converting new pan. into hash value ' ||fn_mask(NEW_CARD_NO,'X',7,6)
                     ||' '||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
       --EN CREATE HASH PAN

         BEGIN
           SELECT cap_expry_date
             INTO v_expry_date
             FROM cms_appl_pan
            WHERE cap_pan_code = v_new_hash_pan AND cap_inst_code = p_inst_code;
        EXCEPTION
           WHEN OTHERS
           THEN
              v_err_msg :=
                 'Error while selecting new expry date' || SUBSTR (SQLERRM, 1, 200);
              v_resp_cde := '21';
              RAISE exp_reject_record;
        END;

--       IF (P_TXN_CODE ='22' AND P_DELIVERY_CHANNEL ='03') OR
--          (P_TXN_CODE ='11' AND P_DELIVERY_CHANNEL ='10') THEN
--
            BEGIN
               UPDATE cms_appl_pan
                  SET cap_repl_flag = v_repl_flag,--6-- 3  --Modified for JH-3043
                      cap_panmast_param6=v_pan_prm6
                WHERE cap_inst_code = p_inst_code AND cap_pan_code = V_NEW_HASH_PAN;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_err_msg :=
                        'Problem in updation of replacement flag for pan '
                     || fn_mask (new_card_no, 'X', 7, 6);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_err_msg :=
                          'Error while updating CMS_APPL_PAN' || SUBSTR (SQLERRM, 1, 200);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
            END;
--       ELSIF  (P_TXN_CODE ='29' AND P_DELIVERY_CHANNEL ='03') OR
--          (P_TXN_CODE ='99' AND P_DELIVERY_CHANNEL ='10') THEN
--
--            BEGIN
--               UPDATE cms_appl_pan
--                  SET cap_repl_flag =7-- 4  --Modified for JH-3043
--                WHERE cap_inst_code = p_inst_code AND cap_pan_code = V_NEW_HASH_PAN;
--
--               IF SQL%ROWCOUNT =  0
--               THEN
--                  v_err_msg :=
--                    'Problem in updation of replacement flag for pan '
--                     || fn_mask (new_card_no, 'X', 7, 6);
--                  v_resp_cde := '21';
--                  RAISE exp_reject_record;
--               END IF;
--            EXCEPTION
--               WHEN OTHERS
--               THEN
--                  v_err_msg :=
--                          'Error while updating CMS_APPL_PAN' || SUBSTR (SQLERRM, 1, 200);
--                  v_resp_cde := '21';
--                  RAISE exp_reject_record;
--            END;
--
--       END IF;

       --EN Added on 13.03.2013 for FSS-1034

   --ST Added for Monthly Fee issue(FSS-4290) on 03/05/2016
   
   
   ---- Modified for VMS-2332 - On migrate/update to new product,
   ----			card level fee plan should not be carry forward.
   
   IF P_REPLACEMENT_OPTION <> 'NPP' 			--- Added for VMS-2332
   THEN  
    --Added for VMS-4543
    BEGIN
              INSERT INTO CMS_CARD_EXCPFEE(CCE_INST_CODE,CCE_PAN_CODE,CCE_INS_DATE,cce_ins_user,CCE_LUPD_USER,CCE_LUPD_DATE,CCE_FEE_PLAN,CCE_FLOW_SOURCE,
              CCE_VALID_FROM,CCE_VALID_TO,CCE_PAN_CODE_ENCR,CCE_MBR_NUMB)
              (SELECT  CCE_INST_CODE,GETHASH(NEW_CARD_NO),sysdate,cce_ins_user,CCE_LUPD_USER,sysdate,NVL(CCE_OLD_FEEPLAN,CCE_FEE_PLAN),CCE_FLOW_SOURCE,
              (case when cce_valid_from>=trunc(sysdate) then cce_valid_from else sysdate end)cce_valid_from,
               CCE_VALID_TO,FN_EMAPS_MAIN(NEW_CARD_NO),CCE_MBR_NUMB
               FROM CMS_CARD_EXCPFEE WHERE CCE_PAN_CODE=GETHASH(P_CARD_NO) AND CCE_INST_CODE=P_INST_CODE
               AND ((CCE_VALID_TO IS NOT NULL AND (trunc(sysdate) between cce_valid_from and CCE_VALID_TO))
               OR (CCE_VALID_TO IS NULL AND trunc(sysdate) >= cce_valid_from)  or (cce_valid_from >=trunc(sysdate))));

      EXCEPTION
           WHEN OTHERS THEN
            V_ERR_MSG  := 'Error while attaching fee plan to reissuue card ' ||SUBSTR(SQLERRM, 1, 200);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
    END;
	
    END IF;						--- Added for VMS-2332
	
	 
    --End Added for Monthly Fee issue(FSS-4290) on 03/05/2016

    IF V_ERR_MSG = 'OK' THEN

         BEGIN
           INSERT INTO CMS_HTLST_REISU
            (CHR_INST_CODE,
             CHR_PAN_CODE,
             CHR_MBR_NUMB,
             CHR_NEW_PAN,
             CHR_NEW_MBR,
             CHR_REISU_CAUSE,
             CHR_INS_USER,
             CHR_LUPD_USER,
             CHR_PAN_CODE_ENCR,
             CHR_NEW_PAN_ENCR)
           VALUES
            (P_INST_CODE,
             V_HASH_PAN,
             V_MBRNUMB,
             GETHASH(NEW_CARD_NO),
             V_MBRNUMB,
             'R',
             P_BANK_CODE,
             P_BANK_CODE,
             V_ENCR_PAN,
             FN_EMAPS_MAIN(NEW_CARD_NO));
         EXCEPTION
           --excp of begin 4
           WHEN OTHERS THEN
            V_ERR_MSG  := 'Error while creating  reissuue record ' ||
                        SUBSTR(SQLERRM, 1, 200);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
         END;

         BEGIN
           INSERT INTO CMS_CARDISSUANCE_STATUS
            (CCS_INST_CODE,
             CCS_PAN_CODE,
             CCS_CARD_STATUS,
             CCS_INS_USER,
             CCS_INS_DATE,
             CCS_PAN_CODE_ENCR,
             CCS_APPL_CODE--Added on 18.03.2013
             )
           VALUES
            (P_INST_CODE,
             GETHASH(NEW_CARD_NO),
             '2',
             P_BANK_CODE,
             SYSDATE,
             FN_EMAPS_MAIN(NEW_CARD_NO),
             V_APPL_CODE --Added on 18.03.2013
             );
         EXCEPTION
           WHEN OTHERS THEN
            V_ERR_MSG  := 'Error while Inserting CCF table ' ||
                        SUBSTR(SQLERRM, 1, 200);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
         END;

         BEGIN
           INSERT INTO CMS_SMSANDEMAIL_ALERT
            (CSA_INST_CODE,
             CSA_PAN_CODE,
             CSA_PAN_CODE_ENCR,
             CSA_CELLPHONECARRIER,
             CSA_LOADORCREDIT_FLAG,
             CSA_LOWBAL_FLAG,
             CSA_LOWBAL_AMT,
             CSA_NEGBAL_FLAG,
             CSA_HIGHAUTHAMT_FLAG,
             CSA_HIGHAUTHAMT,
             CSA_DAILYBAL_FLAG,
             CSA_BEGIN_TIME,
             CSA_END_TIME,
             CSA_INSUFF_FLAG,
             CSA_INCORRPIN_FLAG,
             CSA_FAST50_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
             CSA_FEDTAX_REFUND_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
             CSA_DEPPENDING_FLAG,  -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
             CSA_DEPACCEPTED_FLAG,  -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
             CSA_DEPREJECTED_FLAG,  -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
             CSA_INS_USER,
             CSA_INS_DATE,
             CSA_LUPD_USER,
             CSA_LUPD_DATE,
             csa_alert_lang_id) --Added for FWR-59
            (SELECT P_INST_CODE,
                   GETHASH(NEW_CARD_NO),
                   FN_EMAPS_MAIN(NEW_CARD_NO),
                   NVL(CSA_CELLPHONECARRIER, 0),
                   CSA_LOADORCREDIT_FLAG,
                   CSA_LOWBAL_FLAG,
                   NVL(CSA_LOWBAL_AMT, 0),
                   CSA_NEGBAL_FLAG,
                   CSA_HIGHAUTHAMT_FLAG,
                   NVL(CSA_HIGHAUTHAMT, 0),
                   CSA_DAILYBAL_FLAG,
                   NVL(CSA_BEGIN_TIME, 0),
                   NVL(CSA_END_TIME, 0),
                   CSA_INSUFF_FLAG,
                   CSA_INCORRPIN_FLAG,
                   CSA_FAST50_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
                   CSA_FEDTAX_REFUND_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
                   CSA_DEPPENDING_FLAG,  -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
                   CSA_DEPACCEPTED_FLAG,  -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
                   CSA_DEPREJECTED_FLAG,  -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
                   P_BANK_CODE,
                   SYSDATE,
                   P_BANK_CODE,
                   SYSDATE,
                   csa_alert_lang_id --Added for FWR-59
               FROM CMS_SMSANDEMAIL_ALERT
              WHERE CSA_INST_CODE = P_INST_CODE AND CSA_PAN_CODE = V_HASH_PAN);
           IF SQL%ROWCOUNT != 1 THEN
            V_ERR_MSG  := 'Error while Entering sms email alert detail ' ||
                        SUBSTR(SQLERRM, 1, 200);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
           end if;
         exception
         WHEN DUP_VAL_ON_INDEX THEN null;

           WHEN OTHERS THEN
            V_ERR_MSG  := 'Error while Entering sms email alert detail ' ||
                        SUBSTR(SQLERRM, 1, 200);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
         END;

    --AVQ Added for FSS-1961(Melissa)
       BEGIN
              SP_LOGAVQSTATUS(
              P_INST_CODE,
              P_DELIVERY_CHANNEL,
              NEW_CARD_NO,
              V_PROD_CODE,
              V_CUST_CODE,
              V_RESP_CDE,
              V_ERR_MSG,
              V_PROD_CATTYPE
              );
            IF V_ERR_MSG != 'OK' THEN
               V_ERR_MSG  := 'Exception while calling LOGAVQSTATUS-- ' || V_ERR_MSG;
               V_RESP_CDE := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;
        EXCEPTION WHEN EXP_REJECT_RECORD
        THEN  RAISE;
        WHEN OTHERS THEN
           V_ERR_MSG  := 'Exception in LOGAVQSTATUS-- '  || SUBSTR (SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;
    --End  Added for FSS-1961(Melissa)
 --Sn Added by Abdul

        IF v_lmtprfl IS NULL OR v_profile_level IS NULL
   THEN

      BEGIN
         SELECT cpl_lmtprfl_id
           INTO v_lmtprfl
           FROM cms_prdcattype_lmtprfl
          WHERE cpl_inst_code = P_INST_CODE
            AND cpl_prod_code = V_PROD_CODE
            AND cpl_card_type = V_PROD_CATTYPE;

         v_profile_level := 2;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT cpl_lmtprfl_id
                 INTO v_lmtprfl
                 FROM cms_prod_lmtprfl
                WHERE cpl_inst_code = P_INST_CODE
                  AND cpl_prod_code = V_PROD_CODE;

               v_profile_level := 3;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Error while selecting Limit Profile At Product Level'||
                     SUBSTR(SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while selecting Limit Profile At Product Catagory Level'
               || SUBSTR(SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;

   IF v_lmtprfl IS NOT NULL
   THEN
      BEGIN
         UPDATE cms_appl_pan
            SET cap_prfl_code = v_lmtprfl,
                cap_prfl_levl = v_profile_level
         WHERE  cap_inst_code = P_INST_CODE AND cap_pan_code = v_new_hash_pan;

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Limit Profile not updated for :' || v_hash_pan;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
               'Error while Limit profile Update '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;

    --En Added by Abdul

    END IF;

--    P_RESP_MSG :=NEW_CARD_NO;

    --En create gl entries and acct update

    /*
        --Sn find narration
        BEGIN
         SELECT CTM_TRAN_DESC
           INTO V_NARRATION
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = P_TXN_CODE AND
               CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
               CTM_INST_CODE = P_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_NARRATION := 'Transaction type ' || P_TXN_CODE;
         WHEN OTHERS THEN
           V_NARRATION := 'Transaction type ' || P_TXN_CODE;
        END;


        --En find narration
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
                 CSL_PANNO_LAST4DIGIT) --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number

               VALUES
                (V_HASH_PAN,
                 V_ACCT_BALANCE,
                 V_TRAN_AMT,
                 V_DR_CR_FLAG,
                 V_TRAN_DATE,
                 DECODE(V_DR_CR_FLAG,
                       'DR',
                       V_ACCT_BALANCE - V_TRAN_AMT,
                       'CR',
                       V_ACCT_BALANCE + V_TRAN_AMT,
                       'NA',
                       V_ACCT_BALANCE),
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
                 (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO)))); --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
             EXCEPTION
               WHEN OTHERS THEN
                V_RESP_CDE := '21';
                V_ERR_MSG  := 'Problem while inserting into statement log for tran amt ' ||
                            SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
             END
             ;
        END IF;

        --En create a entry in statement log



            --Sn find fee opening balance
        IF V_TOTAL_FEE <> 0 OR V_FREETXN_EXCEED = 'N' THEN -- Modified by Trivikram on 26-July-2012 for logging fee of free transaction

             BEGIN
               SELECT DECODE(V_DR_CR_FLAG,
                          'DR',
                          V_ACCT_BALANCE - V_TRAN_AMT,
                          'CR',
                          V_ACCT_BALANCE + V_TRAN_AMT,
                          'NA',
                          V_ACCT_BALANCE)
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
                   CSL_PANNO_LAST4DIGIT) --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                VALUES
                  (V_HASH_PAN,
                   V_FEE_OPENING_BAL,
                   V_TOTAL_FEE,
                   'DR',
                   V_TRAN_DATE,
                   V_FEE_OPENING_BAL - V_TOTAL_FEE,
                   'Complimentary ' || V_DURATION ||' '|| V_NARRATION, -- Modified by Trivikram  on 27-July-2012
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
                   (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO)))); --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
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
                     CSL_PANNO_LAST4DIGIT)
                   VALUES
                    (V_HASH_PAN,
                     V_FEE_OPENING_BAL,
                     V_FLAT_FEES,
                     'DR',
                     V_TRAN_DATE,
                     V_FEE_OPENING_BAL - V_FLAT_FEES,
                     'Fixed Fee debited for ' || V_NARRATION,
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
                     (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))));
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
                     CSL_PANNO_LAST4DIGIT) --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                   VALUES
                    (V_HASH_PAN,
                     V_FEE_OPENING_BAL,
                     V_PER_FEES,
                     'DR',
                     V_TRAN_DATE,
                     V_FEE_OPENING_BAL - V_PER_FEES,
                     'Percetage Fee debited for ' || V_NARRATION,
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
                     (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))));

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
                       CSL_PANNO_LAST4DIGIT) --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                    VALUES
                      (V_HASH_PAN,
                       V_FEE_OPENING_BAL,
                       V_TOTAL_FEE,
                       'DR',
                       V_TRAN_DATE,
                       V_FEE_OPENING_BAL - V_TOTAL_FEE,
                       'Fee debited for ' || V_NARRATION,
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
                       (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO)))); --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
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

    --END LOOP;
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
            CTD_CUST_ACCT_NUMBER)
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
            V_ACCT_NUMBER);
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
         --SELECT CAT_PAN_CODE
           --INTO V_AVAIL_PAN
           --FROM CMS_AVAIL_TRANS
          --WHERE CAT_PAN_CODE = V_HASH_PAN
            --   AND CAT_TRAN_CODE = P_TXN_CODE AND
              -- CAT_TRAN_MODE = P_TXN_MODE;

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


         -- IF SQL%ROWCOUNT = 0 THEN
           -- V_ERR_MSG := 'Problem while updating data in avail trans ' ||
             --           SUBSTR(SQLERRM, 1, 300);
            --V_RESP_CDE  := '21';
            --RAISE EXP_REJECT_RECORD;
          --END IF;

        EXCEPTION
         WHEN EXP_REJECT_RECORD THEN
           P_RESP_MSG := V_ERR_MSG;
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

        -- added for mini statement
        --En create detail fro response message
        --Sn mini statement
       */
     END IF;

    p_newcard_expry:=v_expry_date;

    p_resp_msg := new_card_no;

    BEGIN
     --Add for PreAuth Transaction of CMSAuth;
     --Sn creating entries for preauth txn
     --if incoming message not contains checking for prod preauth expiry period
     --if preauth expiry period is not configured checking for instution expirty period
         BEGIN

           IF P_TXN_CODE = '11' AND P_MSG = '0100'
           THEN

            IF NULL IS NULL THEN
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

            /*
              --Sn find business date
               V_BUSINESS_TIME := TO_CHAR(V_TRAN_DATE, 'HH24:MI');

               IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
                V_BUSINESS_DATE := TRUNC(V_TRAN_DATE) + 1;
               ELSE
                V_BUSINESS_DATE := TRUNC(V_TRAN_DATE);
               END IF;
               P_RESP_MSG := NEW_CARD_NO;
               --En find businesses date

               BEGIN
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
               END;
             */

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
           IF V_OUTPUT_TYPE = 'N' THEN
            NULL;
           END IF;
         END IF;

        --En create GL ENTRIES

        --Sn create a record in pan spprt

         --Sn Selecting Reason code for Initial Load
         BEGIN
           SELECT CSR_SPPRT_RSNCODE
            INTO V_RESONCODE
            FROM CMS_SPPRT_REASONS
            WHERE CSR_INST_CODE = P_INST_CODE AND CSR_SPPRT_KEY = 'REISSUE' AND
                ROWNUM < 2;

         EXCEPTION
           WHEN NO_DATA_FOUND THEN
            V_RESP_CDE := '21';
            V_ERR_MSG  := 'Order Replacement card reason code is present in master';
            RAISE EXP_REJECT_RECORD;
           WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERR_MSG  := 'Error while selecting reason code from master' ||
                        SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
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
            (P_INST_CODE,
             V_HASH_PAN,
             P_MBR_NUMB,
             V_CAP_PROD_CATG,
             'REISSUE',
             V_RESONCODE,
             P_REMRK,
             P_BANK_CODE,
             P_BANK_CODE,
             0,
             V_ENCR_PAN);
         EXCEPTION
           WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERR_MSG  := 'Error while inserting records into card support master' ||
                        SUBSTR(SQLERRM, 1, 200);

            RAISE EXP_REJECT_RECORD;
         END;
         --En create a record in pan spprt

         ---Sn Updation of Usage limit and amount
       /*  BEGIN
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
            WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN --P_card_no
                AND CTC_MBR_NUMB = P_MBR_NUMB;
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
            V_ERR_MSG  := 'Cannot get the Transaction Limit Details of the Card' ||
                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
           WHEN OTHERS THEN
            V_ERR_MSG  := 'Error while selecting 1 CMS_TRANSLIMIT_CHECK' ||
                        SUBSTR(SQLERRM, 1, 200);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
         END;

         BEGIN

               IF P_DELIVERY_CHANNEL = '01' THEN

                    IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN THEN

                          IF P_TXN_AMT IS NULL THEN
                            V_ATM_USAGEAMNT := TRIM(TO_CHAR(0, '99999999999999999.99'));
                          ELSE
                            V_ATM_USAGEAMNT := TRIM(TO_CHAR(V_TRAN_AMT,
                                                     '99999999999999999.99'));
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
                                           TRIM(TO_CHAR(0, '99999999999999999.99'));
                          ELSE
                            V_ATM_USAGEAMNT := V_ATM_USAGEAMNT +
                                           TRIM(TO_CHAR(V_TRAN_AMT,
                                                     '99999999999999999.99'));
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

                    IF V_TRAN_DATE > V_BUSINESS_DATE_TRAN
                    THEN

                          IF P_TXN_AMT IS NULL THEN
                            V_POS_USAGEAMNT := TRIM(TO_CHAR(0, '99999999999999999.99'));
                          ELSE
                            V_POS_USAGEAMNT := TRIM(TO_CHAR(V_TRAN_AMT,
                                                     '99999999999999999.99'));
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
                                                TRIM(TO_CHAR(0, '99999999999999999.99'));
                                ELSE

                                     IF V_DR_CR_FLAG = 'CR' THEN

                                       V_POS_USAGEAMNT := V_POS_USAGEAMNT;
                                     ELSE
                                       V_POS_USAGEAMNT := V_POS_USAGEAMNT +
                                                      TRIM(TO_CHAR(V_TRAN_AMT,
                                                                '99999999999999999.99'));
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
                            V_MMPOS_USAGEAMNT := TRIM(TO_CHAR(0, '99999999999999999.99'));
                          ELSE
                            V_MMPOS_USAGEAMNT := TRIM(TO_CHAR(V_TRAN_AMT,
                                                       '99999999999999999.99'));
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
                                                       '99999999999999999.99'));
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

         END;*/
    END;


    V_RESP_CDE := '1';

    ---En Updation of Usage limit and amount
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
    --0010762
    BEGIN
IF (v_Retdate>v_Retperiod) --Added for VMS-5733/FSP-991
    THEN
       UPDATE TRANSACTIONLOG
         SET IPADDRESS = P_IPADDRESS
        WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
            TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG AND
            BUSINESS_TIME = P_TRAN_TIME AND
            DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
     ELSE
     UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
         SET IPADDRESS = P_IPADDRESS
        WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
            TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG AND
            BUSINESS_TIME = P_TRAN_TIME AND
            DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;   
        END IF;
     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '69';
        V_ERR_MSG  := 'Problem while inserting data into transaction log' ||
                    SUBSTR(SQLERRM, 1, 300);
     END;

  EXCEPTION
    --<< MAIN EXCEPTION >>
    WHEN EXP_REJECT_RECORD THEN
     P_RESP_MSG := V_ERR_MSG;
     ROLLBACK TO V_AUTH_SAVEPOINT;


         BEGIN
           SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
                  CAM_TYPE_CODE,CAM_ACCT_NO     -- Added on 18-Apr-2013 for defect 10871
            INTO V_ACCT_BALANCE, V_LEDGER_BAL,
                  V_CAM_TYPE_CODE,V_ACCT_NUMBER -- Added on 18-Apr-2013 for defect 10871
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
IF (v_Retdate>v_Retperiod) --Added for VMS-5733/FSP-991
    THEN
           UPDATE TRANSACTIONLOG
             SET IPADDRESS = P_IPADDRESS
            WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
                TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG AND
                BUSINESS_TIME = P_TRAN_TIME AND
                DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
  ELSE
                 UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
             SET IPADDRESS = P_IPADDRESS
            WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
                TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG AND
                BUSINESS_TIME = P_TRAN_TIME AND
                DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
            END IF;

         EXCEPTION
           WHEN OTHERS THEN
            V_RESP_CDE := '69';
            V_ERR_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                        SUBSTR(SQLERRM, 1, 300);
         END;

        /* BEGIN
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

         END;*/


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


         --Sn Commented for Transactionlog Functional Removal Phase-II changes
         /*BEGIN
           IF V_RRN_COUNT > 0 THEN
            IF TO_NUMBER(P_DELIVERY_CHANNEL) = 8 THEN
              BEGIN
                SELECT RESPONSE_CODE
                 INTO V_RESP_CDE
                 FROM TRANSACTIONLOG A,
                     (SELECT MIN(ADD_INS_DATE) MINDATE
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
                       WHERE CAP_PAN_CODE = V_HASH_PAN AND
                            CAP_MBR_NUMB = P_MBR_NUMB AND
                            CAP_INST_CODE = P_INST_CODE) AND
                     CAM_INST_CODE = P_INST_CODE
                  FOR UPDATE NOWAIT;
                V_ERR_MSG := TO_CHAR(V_ACCT_BALANCE);

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
         END;*/
          --En Commented for Transactionlog Functional Removal Phase-II changes



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
             CTD_CUST_ACCT_NUMBER)
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
             V_ACCT_NUMBER);

           P_RESP_MSG := V_ERR_MSG;
         EXCEPTION
           WHEN OTHERS THEN
            P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                        SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '69'; -- Server Declined
            ROLLBACK;
            RETURN;
         END;

     -----------------------------------------------
     --SN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------

         v_timestamp := systimestamp;         -- Added on 18-Apr-2013 for defect 10871

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


     -----------------------------------------------
     --EN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------


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
          IPADDRESS,
          CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
          FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
          CSR_ACHACTIONTAKEN,
          error_msg,
          PROCESSES_FLAG,
          ACCT_TYPE,         -- Added on 18-Apr-2013 for defect 10871
          TIME_STAMP         -- Added on 18-Apr-2013 for defect 10871
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
          TRIM(TO_CHAR(NVL(V_TOTAL_AMT,0), '99999999999999990.99')),  -- NVL added on 18-Apr-2013 for defect 10871 , 99999999999999999.99 changed to 99999999999999990.99
          '',
          '',
          P_MCC_CODE,
          P_CURR_CODE,
          NULL, -- P_add_charge,
          V_PROD_CODE,
          V_PROD_CATTYPE,
          0,                                -- NULL replaced by 0,on 18-Apr-2013 for defect 10871
          '',
          '',
          V_AUTH_ID,
          V_NARRATION,
          TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '99999999999999990.99')),   -- NVL added on 18-Apr-2013 for defect 10871, 99999999999999999.99 changed to 99999999999999990.99
          '0.00',   -- NULL replaced by 0.00 , on 18-Apr-2013 for defect 10871
          '0.00', -- Partial amount (will be given for partial txn)  -- NULL replaced by 0.00 , on 18-Apr-2013 for defect 10871
          '',
          '',
          '',
          '',
          '',
          V_GL_UPD_FLAG,
          P_STAN,
          P_INST_CODE,
          V_FEE_CODE,
          NVL(V_FEE_AMT,0),
          NVL(V_SERVICETAX_AMOUNT,0),
          NVL(V_CESS_AMOUNT,0),
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
          NVL(V_ACCT_BALANCE,0),
          NVL(V_LEDGER_BAL,0),
          V_RESP_CDE,
          P_IPADDRESS,
          V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
          V_FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
          P_FEE_FLAG,
          V_ERR_MSG,
          'E',
           v_cam_type_code,   -- Added on 18-Apr-2013 for defect 10871
           v_timestamp        -- Added on 18-Apr-2013 for defect 10871
          );

        P_CAPTURE_DATE := V_BUSINESS_DATE;
        P_AUTH_ID      := V_AUTH_ID;
      EXCEPTION
        WHEN OTHERS THEN
         ROLLBACK;
         P_RESP_CODE := '69'; -- Server Declione
         P_RESP_MSG  := 'Problem while inserting data into transaction log  ' ||
                     SUBSTR(SQLERRM, 1, 300);
         return;
      END;

      --En create a entry in txn log

  WHEN OTHERS THEN
  ROLLBACK TO V_AUTH_SAVEPOINT;


         BEGIN
           SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
                  CAM_TYPE_CODE,CAM_ACCT_NO     -- Added on 18-Apr-2013 for defect 10871
            INTO V_ACCT_BALANCE, V_LEDGER_BAL,
                  V_CAM_TYPE_CODE,V_ACCT_NUMBER -- Added on 18-Apr-2013 for defect 10871
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


    /* BEGIN
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
        V_ERR_MSG  := 'Error while selecting 3 CMS_TRANSLIMIT_CHECK' ||
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

     END;*/

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
            -- RETURN;
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
             CTD_CUST_ACCT_NUMBER)
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
             V_ACCT_NUMBER);
         EXCEPTION
           WHEN OTHERS THEN
            P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                        SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '69'; -- Server Decline Response 220509
            ROLLBACK;
            RETURN;
         END;
         --En select response code and insert record into txn log dtl

    -----------------------------------------------
     --SN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------

         v_timestamp := systimestamp;         -- Added on 18-Apr-2013 for defect 10871

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

     -----------------------------------------------
     --EN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------

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
          IPADDRESS,
          CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
          FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
          CSR_ACHACTIONTAKEN,
          ERROR_MSG,
          PROCESSES_FLAG,
          ACCT_TYPE,        -- Added on 18-Apr-2013 for defect 10871
          TIME_STAMP        -- Added on 18-Apr-2013 for defect 10871
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
          TRIM(TO_CHAR(NVL(V_TOTAL_AMT,0), '99999999999999999.99')),    -- NVL added on 18-Apr-2013 for defect 10871
          '',
          '',
          P_MCC_CODE,
          P_CURR_CODE,
          NULL, -- P_add_charge,
          V_PROD_CODE,
          V_PROD_CATTYPE,
          0,                -- NULL replaced by 0,on 18-Apr-2013 for defect 10871
          '',
          '',
          V_AUTH_ID,
          V_NARRATION,
          TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '99999999999999999.99')),      -- NVL added on 18-Apr-2013 for defect 10871
          '0.00', -- NULL replaced by 0.00 , on 18-Apr-2013 for defect 10871
          '0.00', -- Partial amount (will be given for partial txn) -- NULL replaced by 0.00 , on 18-Apr-2013 for defect 10871
          '',
          '',
          '',
          '',
          '',
          V_GL_UPD_FLAG,
          P_STAN,
          P_INST_CODE,
          V_FEE_CODE,
          NVL(V_FEE_AMT,0),             -- NVL added on 18-Apr-2013 for defect 10871
          NVL(V_SERVICETAX_AMOUNT,0),   -- NVL added on 18-Apr-2013 for defect 10871
          NVL(V_CESS_AMOUNT,0),         -- NVL added on 18-Apr-2013 for defect 10871
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
          NVL(V_ACCT_BALANCE,0),    -- NVL added on 18-Apr-2013 for defect 10871
          NVL(V_LEDGER_BAL,0),      -- NVL added on 18-Apr-2013 for defect 10871
          V_RESP_CDE,
          P_IPADDRESS,
          V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
          V_FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
          P_FEE_FLAG,
          V_ERR_MSG,
          'E',
          v_cam_type_code,   -- Added on 18-Apr-2013 for defect 10871
          v_timestamp        -- Added on 18-Apr-2013 for defect 10871
          );

        P_CAPTURE_DATE := V_BUSINESS_DATE;
        P_AUTH_ID      := V_AUTH_ID;
      EXCEPTION
        WHEN OTHERS THEN
         ROLLBACK;
         P_RESP_CODE := '69'; -- Server Declione
         P_RESP_MSG  := 'Problem while inserting data into transaction log  ' ||
                     SUBSTR(SQLERRM, 1, 300);
         return;

      END;

      --En create a entry in txn log
  END;

  --- Sn create GL ENTRIES

    /*
      --Sn generate auth id
      BEGIN
        SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') ||
             LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
         INTO V_AUTH_ID
         FROM DUAL;
      EXCEPTION
        WHEN OTHERS THEN
         P_RESP_MSG  := 'Error while generating authid ' ||
                     SUBSTR(SQLERRM, 1, 300);
         P_RESP_CODE := '89'; -- Server Declined
         ROLLBACK;
      END;
      --En generate auth id
    */




EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    P_RESP_CODE := '69'; -- Server Declined
    P_RESP_MSG  := 'Main exception from  authorization ' ||
                SUBSTR(SQLERRM, 1, 300);
END;
/
show error