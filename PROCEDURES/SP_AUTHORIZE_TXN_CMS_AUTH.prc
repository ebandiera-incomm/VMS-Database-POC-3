create or replace PROCEDURE        vmscms.SP_AUTHORIZE_TXN_CMS_AUTH (
    P_INST_CODE              IN      NUMBER,
    P_MSG                      IN      VARCHAR2,
    P_RRN                               VARCHAR2,
    P_DELIVERY_CHANNEL              VARCHAR2,
    P_TERM_ID                          VARCHAR2,
    P_TXN_CODE                          VARCHAR2,
    P_TXN_MODE                          VARCHAR2,
    P_TRAN_DATE                       VARCHAR2,
    P_TRAN_TIME                       VARCHAR2,
    P_CARD_NO                          VARCHAR2,
    P_BANK_CODE                       VARCHAR2,
    P_TXN_AMT                          NUMBER,
    P_MERCHANT_NAME                  VARCHAR2,
    P_MERCHANT_CITY                  VARCHAR2,
    P_MCC_CODE                          VARCHAR2,
    P_CURR_CODE                       VARCHAR2,
    P_PROD_ID                          VARCHAR2,
    P_CATG_ID                          VARCHAR2,
    P_TIP_AMT                          VARCHAR2,
    P_TO_ACCT_NO                      VARCHAR2, --Added for card to card transfer by removing the P_DECLINE_RULEID as the rule id is not passed
    P_ATMNAME_LOC                      VARCHAR2,
    P_MCCCODE_GROUPID               VARCHAR2,
    P_CURRCODE_GROUPID              VARCHAR2,
    P_TRANSCODE_GROUPID              VARCHAR2,
    P_RULES                              VARCHAR2,
    P_PREAUTH_DATE                   DATE,
    P_CONSODIUM_CODE         IN      VARCHAR2,
    P_PARTNER_CODE          IN      VARCHAR2,
    P_EXPRY_DATE             IN      VARCHAR2,
    P_STAN                     IN      VARCHAR2,
    P_MBR_NUMB                 IN      VARCHAR2,
    P_RVSL_CODE              IN      VARCHAR2,
    P_CURR_CONVERT_AMNT     IN      VARCHAR2,
    P_AUTH_ID                     OUT VARCHAR2,
    P_RESP_CODE                  OUT VARCHAR2,
    P_RESP_MSG                     OUT VARCHAR2,
    p_capture_date              out date,
    P_Fee_Flag                 In      Varchar2 Default 'Y', -- Added by sagar for Fee_Flag Changes on 27Aug2012
    prm_admin_flag             in      varchar2 default 'N',
    prm_valins_act_flag        in      varchar2 default 'N',
    P_funding_account           in      varchar2 Default null,
    P_MERCHANT_ZIP          in      varchar2 Default null,-- added for VMS-622 (redemption_delay zip code validation)
    P_status_check          in      varchar2 Default 'Y',
    p_merchant_address     in varchar2 default null,
    p_merchant_id     in varchar2 default null,
    p_merchant_state     in varchar2 default null
    

     --Always keep this variable at last position since its declared as default
    )
IS
    /*************************************************************************************************************

         * Created Date      : 10-Dec-2012
         * Created By          : Srinivasu.k
         * Modified By       : Ramkumar.MK
         * Modified Date      : 03-Jan-2013
         * Modified Reason  : both delivery channel and transaction code condition check
         * Reviewer           : Saravanakumar
         * Reviewed Date      : 04-Jan-2013
         * Build Number      : CMS3.5.1_RI0023_B0008

         * Modified By       : Pankaj S.
         * Modified Date      : 09-Feb-2013
         * Modified Reason  : Product Category spend limit not being adhered to by VMS
         * Reviewer           : Dhiraj
         * Reviewed Date      :
         * Build Number      :

         * Modified By       : Pankaj S.
         * Modified Date      : 09-Apr-2013
         * Modified Reason  : Max Card Balance Check (MVCSD-4077 )
         * Reviewer           : Dhiraj
         * Reviewed Date      : 10-Apr-2013
         * Build Number      : CMS3.5.1_RI0024.1_B0003

         * Modified By       : Deepa T
         * Modified Date      : 23-Apr-2013
         * Modified Reason  : MVHOST-346
         * Reviewer           : Dhiarj
         * Reviewed Date      : 10-Apr-2013
         * Build Number      : CMS3.5.1_RI0024.1_B0010

         * Modified By       : Sagar M.
         * Modified Date      : 17-Apr-2013
         * Modified for      : Defect 10871
         * Modified Reason  : Logging of below details in tranasctionlog and statementlog table
                                        1) ledger balance in statementlog
                                        2) Product code,Product category code,Card status,Acct Type,drcr flag
                                        3) Timestamp and Amount values logging correction
         * Reviewer           : Dhiraj
         * Reviewed Date      : 17-Apr-2013
         * Build Number      : RI0024.1_B0013

         * Modified by       : Dhinakaran B
         * Modified Reason  : MVHOST - 346
         * Modified Date      : 14-MAY-2013
         * Reviewer           : Dhiraj
         * Reviewed Date      : 14-MAY-2013
         * Build Number      : RI0024.1_B0023

         * Modified by       : Ravi N
         * Modified for        : Mantis ID 0011282
         * Modified Reason  : Correction of Insufficient balance spelling mistake
         * Modified Date      : 20-Jun-2013
         * Reviewer           : Dhiraj
         * Reviewed Date      : 20-Jun-2013
         * Build Number      : RI0024.2_B0006

         * modified by         :    MageshKumar.S
         * modified Date        :    29-AUG-13
         * modified reason    :    FSS-1144
         * Reviewer             :    Dhiraj
         * Reviewed Date        :    30-AUG-13
         * Build Number        :    RI0024.4_B0006

         * modified by         :    Santosh K
         * modified Date        :    13-Nov-13
         * modified reason    :    PROD FIX for Replacement of MIO Expired Card
         * Reviewer             :    Dhiraj
         * Reviewed Date        :    13-Nov-13
         * Build Number        :    RI0024.3.10_B0002

         * Modified By       : Pankaj S.
         * Modified Date      : 20-Nov-2013
         * Modified Reason  : LYFEHOST-64
         * Reviewer           : Dhiraj
         * Reviewed Date      :
         * Build Number      : RI0024.6.1_B0001

         * Modified By       : Dnyaneshwar J
         * Modified Date      : 14-Jan-2014
         * Modified Reason  : MVCSD-4637
         * Reviewer           : Dhiraj
         * Reviewed Date      : 15-Jan-14
         * Build Number      : RI0027_B0003

        * Modified Date     : 10-Dec-2013
        * Modified By         : Sagar More
        * Modified for      : Defect ID 13160
        * Modified reason  : To log below details in transactinlog if applicable
                                    added NVL for fee , service tax,cess amount while logging
        * Reviewer             : Dhiraj
        * Reviewed Date     : 10-Dec-2013
        * Release Number     : RI0027_B0004

        * Modified By         : Dnyaneshwar J
        * Modified Date     : 11-Feb-2014
        * Modified Reason  : Mantis-13655
        * Release Number     : RI0027_B0007

        * modified by          : Ramesh A
        * modified Date      : FEB-05-14
        * modified reason   : MVCSD-4471
        * modified reason   : logging fee_description for fee entry in statemenst_log
        * Reviewer              : Dhiraj
        * Reviewed Date      :
        * Build Number       : RI0027.1_B0001

        * modified by          : RAVI N
        * modified Date      : FEB-21-14
        * modified For       : 0013542
        * Reviewer              : Dhiraj
        * Reviewed Date      : FEB-21-14
        * Build Number       : RI0027.1_B0004

        * Modified by          : Sagar
        * Modified for       :
        * Modified Reason   : Concurrent Processsing Issue
                                     (1.7.6.7 changes integarted)
        * Modified Date      : 04-Mar-2014
        * Reviewer              : Dhiarj
        * Reviewed Date      : 06-Mar-2014
        * Build Number       : RI0027.1.1_B0001

        * Modified by         : Abdul Hameed M.A
        * Modified for         : Mantis ID 13893
        * Modified Reason     : Added card number for duplicate RRN check
        * Modified Date      : 06-Mar-2014
        * Reviewer             : Dhiraj
        * Reviewed Date      : 10-Mar-2014
        * Build Number         : RI0027.2_B0002

        * Modified By        : Sankar S
        * Modified Date     : 08-APR-2014
        * Modified for        :
        * Modified Reason    : 1.Round functions added upto 2nd decimal for amount columns in CMS_CHARGE_DTL,CMS_ACCTCLAWBACK_DTL,
                                                                CMS_STATEMENTS_LOG,TRANSACTIONLOG.
                                                                2.V_TRAN_AMT initial value assigned as zero.
        * Reviewer            : Pankaj S.
        * Reviewed Date         : 08-APR-2014
        * Build Number        : CMS3.5.1_RI0027.2_B0005

        * modified by       : Amudhan S
        * modified Date     : 23-may-14
        * modified for      : FWR 64
        * modified reason   : To restrict clawback fee entries as per the configuration done by user.
        * Reviewer          : Spankaj
        * Build Number      : RI0027.3_B0001

        * modified by       : Siva Kumar M
        * modified Date     : 08-july-14
        * modified for      : Mantis Id:13000
        * modified reason   : CR entry has logged with zero tran amount in the STATEMENT LOG for SAVINGS ACCOUNT CLOSED WITH BALANCE TRANSFER
        * Reviewer          : Spankaj
        * Build Number      : RI0027.3_B0003

        * Modified by       : Dhinakaran B
        * Modified for      : MANTIS ID-12422
        * Modified Date     : 08-JUL-2014
        * Build Number      : RI0027.3_B0003

         * Modified by       : MageshKumar S.
        * Modified Date     : 25-July-14
        * Modified For      : FWR-48
        * Modified reason   : GL Mapping removal changes
        * Reviewer          : Spankaj
        * Build Number      : RI0027.3.1_B0001

        * Modified by       : Ramesh A
        * Modified Date     : 12-MAR-15
        * Modified For      : FSS-2264
        * Modified reason   : For reconciliation of daily balance, the balancing orders for some concurrent transactions statement entries are not proper.
        * Reviewer          : Spankaj
        * Build Number      : RI0027.4.3.4

    * Modified by       : Siva Kumar M
    * Modified Date     : 05-Aug-15
    * Modified For      : FSS-2320
    * Reviewer          : Pankaj S
    * Build Number      : RVMSGPRHOSTCSD_3.1_B0001

     * Modified by       : A.Sivakaminathan
     * Modified Date     : 28-Aug-2015
     * Modified For      : FSS-3615 VMS should allow address changes even after the card expired
     * Reviewer          : Pankaj S
     * Build Number      : VMSGPRHOSTCSD_3.1

     * Modified By      : Siva Kumar M
     * Modified Date    : 24-Sep-2015
     * Modified Reason  : Card Status changes
     * Reviewer         : Saravana kumar
     * Reviewed Date    : 25-Sep-2015
     * Build Number     : VMSGPRHOSTCSD3.2_B0002

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

    * Modified By      : Siva Kumar M
    * Modified Date    : 18/07/2017
    * Purpose          : FSS-5217
    * Reviewer         : Saravanan/Pankaj S.
    * Release Number   : VMSGPRHOST17.09

        * Modified by       : Akhil
     * Modified Date     : 05-JAN-18
     * Modified For      : VMS-103
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.12

       * Modified by       : Baskar K
     * Modified Date     : 21-AUG-18
     * Modified For      : VMS-454
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_R05
	 
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
    * Modified Date    : 06-May-2021
    * Modified For     : VMS-4223 - B2B Replace card for virtual product is not creating card in Active status 
    * Reviewer         : Saravanankumar
    * Build Number     : VMSR46_B0002
    
     * Modified by       : UBaidur Rahman.H
     * Modified Date     : 26-Oct-21
     * Modified For      : VMS-4379- Remove Account Statement Txn log logging into Transactionlog
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_R53B3
     
     * Modified By      : Mageshkumar.S
     * Modified Date    : 29-MARCH-2022
     * Purpose          : VMS-5743 - Reroute SPIL-PRE ACTIVATION Audit Transactions
     * Reviewer         : Saravanakumar.A
     * Release Number   : VMSGPRHOST R60
    ****************************************************************************************************************/
    V_ERR_MSG                  VARCHAR2 (900) := 'OK';
    V_ACCT_BALANCE           NUMBER;
    V_TRAN_AMT                  NUMBER := 0; --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
    V_AUTH_ID                  TRANSACTIONLOG.AUTH_ID%TYPE;
    V_TOTAL_AMT               NUMBER;
    V_TRAN_DATE               DATE;
    V_FUNC_CODE               CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
    V_PROD_CODE               CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
    V_PROD_CATTYPE           CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
    V_FEE_AMT                  NUMBER;
    V_TOTAL_FEE               NUMBER;
    V_UPD_AMT                  NUMBER;
    V_NARRATION               VARCHAR2 (300);
    V_FEE_OPENING_BAL       NUMBER;
    V_RESP_CDE                  VARCHAR2 (3);
    V_EXPRY_DATE              DATE;
    V_DR_CR_FLAG              VARCHAR2 (2);
    V_OUTPUT_TYPE              VARCHAR2 (2);
    V_APPLPAN_CARDSTAT      CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
    V_ATMONLINE_LIMIT       CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
    V_POSONLINE_LIMIT       CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
    V_PRECHECK_FLAG          NUMBER;
    V_PREAUTH_FLAG           NUMBER;
    --V_AVAIL_PAN            CMS_AVAIL_TRANS.CAT_PAN_CODE%TYPE;
    V_GL_UPD_FLAG              TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
    V_GL_ERR_MSG              VARCHAR2 (500);
    V_SAVEPOINT               NUMBER := 0;
    V_TRAN_FEE                  NUMBER;
    V_ERROR                      VARCHAR2 (500);
    V_BUSINESS_DATE          DATE;
    V_BUSINESS_TIME          VARCHAR2 (5);
    V_CUTOFF_TIME              VARCHAR2 (5);
    V_CARD_CURR               VARCHAR2 (5);
    V_FEE_CODE                  CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
    V_FEE_CRGL_CATG          CMS_PRODCATTYPE_FEES.CPF_CRGL_CATG%TYPE;
    V_FEE_CRGL_CODE          CMS_PRODCATTYPE_FEES.CPF_CRGL_CODE%TYPE;
    V_FEE_CRSUBGL_CODE      CMS_PRODCATTYPE_FEES.CPF_CRSUBGL_CODE%TYPE;
    V_FEE_CRACCT_NO          CMS_PRODCATTYPE_FEES.CPF_CRACCT_NO%TYPE;
    V_FEE_DRGL_CATG          CMS_PRODCATTYPE_FEES.CPF_DRGL_CATG%TYPE;
    V_FEE_DRGL_CODE          CMS_PRODCATTYPE_FEES.CPF_DRGL_CODE%TYPE;
    V_FEE_DRSUBGL_CODE      CMS_PRODCATTYPE_FEES.CPF_DRSUBGL_CODE%TYPE;
    V_FEE_DRACCT_NO          CMS_PRODCATTYPE_FEES.CPF_DRACCT_NO%TYPE;
    --st AND cess
    V_SERVICETAX_PERCENT   CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
    V_CESS_PERCENT           CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
    V_SERVICETAX_AMOUNT      NUMBER;
    V_CESS_AMOUNT              NUMBER;
    V_ST_CALC_FLAG           CMS_PRODCATTYPE_FEES.CPF_ST_CALC_FLAG%TYPE;
    V_CESS_CALC_FLAG          CMS_PRODCATTYPE_FEES.CPF_CESS_CALC_FLAG%TYPE;
    V_ST_CRACCT_NO           CMS_PRODCATTYPE_FEES.CPF_ST_CRACCT_NO%TYPE;
    V_ST_DRACCT_NO           CMS_PRODCATTYPE_FEES.CPF_ST_DRACCT_NO%TYPE;
    V_CESS_CRACCT_NO          CMS_PRODCATTYPE_FEES.CPF_CESS_CRACCT_NO%TYPE;
    V_CESS_DRACCT_NO          CMS_PRODCATTYPE_FEES.CPF_CESS_DRACCT_NO%TYPE;
    --
    V_WAIV_PERCNT              CMS_PRODCATTYPE_WAIV.CPW_WAIV_PRCNT%TYPE;
    V_ERR_WAIV                  VARCHAR2 (300);
    V_LOG_ACTUAL_FEE          NUMBER;
    V_LOG_WAIVER_AMT          NUMBER;
    V_AUTH_SAVEPOINT          NUMBER DEFAULT 0;
    V_ACTUAL_EXPRYDATE      DATE;
    V_TXN_TYPE                  NUMBER (1);
    V_MINI_TOTREC              NUMBER (2);
    V_MINISTMT_ERRMSG       VARCHAR2 (500);
    V_MINISTMT_OUTPUT       VARCHAR2 (900);
    V_FEE_ATTACH_TYPE       VARCHAR2 (1);
    EXP_REJECT_RECORD       EXCEPTION;
    V_LEDGER_BAL              NUMBER;
    V_CARD_ACCT_NO           VARCHAR2 (20);
    V_HASH_PAN                  CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
    V_ENCR_PAN                  CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
    V_MAX_CARD_BAL           NUMBER;
    V_MIN_ACT_AMT              NUMBER;  --added for minimum activation amount check
    V_CURR_DATE               DATE;
    V_UPD_LEDGER_BAL          NUMBER;
    V_PROXUNUMBER              CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
    V_ACCT_NUMBER              CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
    V_TRANS_DESC              VARCHAR2 (50);
    V_STATUS_CHK              NUMBER;
    V_TRANSFER_FLAG          CMS_TRANSACTION_MAST.CTM_AMNT_TRANSFER_FLAG%TYPE;
    V_TOACCT_NO               CMS_STATEMENTS_LOG.CSL_TO_ACCTNO%TYPE;
    V_LOGIN_TXN               CMS_TRANSACTION_MAST.CTM_LOGIN_TXN%TYPE;
    V_INTERNATION_IND       CMS_FEE_MAST.CFM_INTL_INDICATOR%TYPE;
    V_POS_VERFICATION       CMS_FEE_MAST.CFM_PIN_SIGN%TYPE;

    V_FEEAMNT_TYPE           CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
    V_PER_FEES                  CMS_FEE_MAST.CFM_PER_FEES%TYPE;
    V_FLAT_FEES               CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
    V_CLAWBACK                  CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
    V_FEE_PLAN                  CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;
    V_CLAWBACK_AMNT          CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
    V_ACTUAL_FEE_AMNT       NUMBER;
    V_CLAWBACK_COUNT          NUMBER;
    V_FREETXN_EXCEED          VARCHAR2 (1); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
    V_DURATION                  VARCHAR2 (20); -- Added by Trivikram on 26-July-2012 for logging fee of free transactions
    V_FEEATTACH_TYPE          VARCHAR2 (2); -- Added by Trivikram on 5th Sept 2012
    v_cam_type_code          cms_acct_mast.cam_type_code%TYPE; -- Added on 17-Apr-2013 for defect 10871
    v_timestamp               TIMESTAMP;  -- Added on 17-Apr-2013 for defect 10871
    V_HASHKEY_ID              CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; -- Added    on 29-08-2013 for  FSS-1144
    v_fee_desc                  cms_fee_mast.cfm_fee_desc%TYPE; -- Added for MVCSD-4471
    V_RRN_COUNT               NUMBER; --Added for Concurrent Processsing Issue  on 25-FEB-2014 By Revathi
  v_tot_clwbck_count CMS_FEE_MAST.cfm_clawback_count%TYPE; -- Added for FWR 64
  v_chrg_dtl_cnt    NUMBER;     -- Added for FWR 64
    V_PROFILE_CODE       CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
v_badcredit_flag             cms_prod_cattype.cpc_badcredit_flag%TYPE;
   v_badcredit_transgrpid       vms_group_tran_detl.vgd_group_id%TYPE;
     v_cnt       number;
         v_card_stat                  cms_appl_pan.cap_card_stat%TYPE   := '12';
         v_enable_flag varchar2(20):='Y';
   v_initialload_amt         cms_acct_mast.cam_new_initialload_amt%type;
   v_audit_flag		    cms_transaction_mast.ctm_txn_log_flag%TYPE;
   --SN: Added for VMS-6071
	v_toggle_value  cms_inst_param.cip_param_value%TYPE;
	v_prd_chk       NUMBER :=0;
   --EN: Added for VMS-6071
BEGIN
    SAVEPOINT V_AUTH_SAVEPOINT;
    V_RESP_CDE := '1';
    P_RESP_MSG := 'OK';
    V_TRAN_AMT := NVL (P_CURR_CONVERT_AMNT, 0); -- NVL added by sagar on 27Aug2012
    v_timestamp := SYSTIMESTAMP;                 -- Added on 29-08-2013 for FSS-1144

    BEGIN
        --SN CREATE HASH PAN
        BEGIN
            V_HASH_PAN := GETHASH (P_CARD_NO);
        EXCEPTION
            WHEN OTHERS
            THEN
                V_ERR_MSG :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --EN CREATE HASH PAN

        --SN create encr pan
        BEGIN
            V_ENCR_PAN := FN_EMAPS_MAIN (P_CARD_NO);
        EXCEPTION
            WHEN OTHERS
            THEN
                V_ERR_MSG :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --EN create encr pan

        -- Start Generate HashKEY value for FSS-1144
        BEGIN
            V_HASHKEY_ID :=
                GETHASH (
                        P_DELIVERY_CHANNEL
                    || P_TXN_CODE
                    || P_CARD_NO
                    || P_RRN
                    || TO_CHAR (v_timestamp, 'YYYYMMDDHH24MISSFF5'));
        EXCEPTION
            WHEN OTHERS
            THEN
                V_ERR_MSG :=
                    'Error while converting master data '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --End Generate HashKEY value for FSS-1144

        --Sn find debit and credit flag
        BEGIN
            SELECT CTM_CREDIT_DEBIT_FLAG, CTM_OUTPUT_TYPE, TO_NUMBER (DECODE (CTM_TRAN_TYPE,  'N', '0',  'F', '1')), CTM_AMNT_TRANSFER_FLAG, CTM_TRAN_DESC
                     , CTM_LOGIN_TXN,nvl(ctm_txn_log_flag,'T')
              INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRANSFER_FLAG, --Modified by Deepa on 8th May 2012 to get the transaction mast details in a single query
                                                                                                 V_TRANS_DESC
                     , V_LOGIN_TXN,v_audit_flag
              FROM CMS_TRANSACTION_MAST
             WHERE      CTM_TRAN_CODE = P_TXN_CODE
                     AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                     AND CTM_INST_CODE = P_INST_CODE;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '21';                       --Ineligible Transaction
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
                    'Error while selecting transflag ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En find debit and credit flag

        --Sn generate auth id
        BEGIN
            --  SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
            SELECT LPAD (SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;
        EXCEPTION
            WHEN OTHERS
            THEN
                V_ERR_MSG :=
                    'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
                V_RESP_CDE := '21';                             -- Server Declined
                RAISE EXP_REJECT_RECORD;
        END;

        --En generate auth id

        --sN CHECK INST CODE
        BEGIN
            IF P_INST_CODE IS NULL
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG := 'Institute code cannot be null ';
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
                    'Error while selecting Institute code '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --eN CHECK INST CODE

        --Sn check txn currency
        BEGIN
            IF TRIM (P_CURR_CODE) IS NULL
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG := 'Transaction currency  cannot be null ';
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
                    'Error while selecting Transcurrency  '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En check txn currency

        --Sn get date
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
                V_RESP_CDE := '21';
                V_ERR_MSG :=
                    'Problem while converting transaction date '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En get date
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
                V_ERR_MSG := 'Error while selecting service tax from system ';
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
                V_ERR_MSG := 'Error while selecting cess from system ';
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
                V_ERR_MSG := 'Error while selecting cutoff  dtl  from system ';
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
                V_RESP_CDE := '21';                       --only for master setups
                V_ERR_MSG := 'Master set up is not done for Authorization Process';
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';                       --only for master setups
                V_ERR_MSG :=
                    'Error while selecting preauth flag'
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En select authorization process    flag
        --Sn find card detail
        BEGIN
            SELECT CAP_PROD_CODE, CAP_CARD_TYPE, TO_CHAR (CAP_EXPRY_DATE, 'DD-MON-YY'), CAP_CARD_STAT, CAP_ATM_ONLINE_LIMIT
                     , CAP_POS_ONLINE_LIMIT, CAP_PROXY_NUMBER, CAP_ACCT_NO
              INTO V_PROD_CODE, V_PROD_CATTYPE, V_EXPRY_DATE, V_APPLPAN_CARDSTAT, V_ATMONLINE_LIMIT
                     , V_POSONLINE_LIMIT, V_PROXUNUMBER, V_ACCT_NUMBER
              FROM CMS_APPL_PAN
             WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN; --P_card_no;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '16';                       --Ineligible Transaction
                V_ERR_MSG := 'Card number not found ' || V_HASH_PAN;
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '12';
                V_ERR_MSG :=
                    'Problem while selecting card detail'
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En find card detail
         -- this condition added for print order activation transactions
  IF P_status_check='Y' THEN

    --  IF NOT (P_DELIVERY_CHANNEL ='13' AND (P_TXN_CODE='37' OR P_TXN_CODE='36' ) ) THEN
        --Sn GPR Card status check
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
            -- Expiry Check
            IF P_DELIVERY_CHANNEL <> '11'
            THEN
                BEGIN
                    -- SN:Added by Santosh K 13-Nov-2013 : PROD FIX for Replacement of MIO Expired Card
                    IF P_DELIVERY_CHANNEL = '03'
                        And P_Txn_Code In
                                 ('22', '29', '75', '13', '14', '38', '39', '83', '17','27','37','35','21','79','18','74','98','78')
                    THEN --Modified by Dnyaneshwar J on 14 Jan 2014 for MVCSD-4637--Modified by Dnyaneshwar J on 11 Feb 2014 Mantis-13655
                        V_RESP_CDE := '1';
                    
					ELSIF P_DELIVERY_CHANNEL = '17' AND  P_Txn_Code In('22', '29')
					THEN
					      V_RESP_CDE := '1';

				    ELSE
                        -- EN:Added by Santosh K 13-Nov-2013 : PROD FIX for Replacement of MIO Expired Card
                        IF TO_DATE (P_TRAN_DATE, 'YYYYMMDD') >
                                LAST_DAY (TO_CHAR (V_EXPRY_DATE, 'DD-MON-YY'))
                        THEN
                            V_RESP_CDE := '13';
                            V_ERR_MSG := 'EXPIRED CARD';
                            RAISE EXP_REJECT_RECORD;
                        END IF;
                    END IF; --Added by Santosh K 13-Nov-2013 : PROD FIX for Replacement of MIO Expired Card
                EXCEPTION
                    WHEN EXP_REJECT_RECORD
                    THEN
                        RAISE;
                    WHEN OTHERS
                    THEN
                        V_RESP_CDE := '21';
                        V_ERR_MSG :=
                                'ERROR IN EXPIRY DATE CHECK : Tran Date - '
                            || P_TRAN_DATE
                            || ', Expiry Date - '
                            || V_EXPRY_DATE
                            || ','
                            || SUBSTR (SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
                END;
            END IF;

            -- End Expiry Check

            --Sn check for precheck
            IF  prm_admin_flag <> 'Y' THEN
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
                            'Error from precheck processes '
                            || SUBSTR (SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
                END;
                END IF;
            END IF;
        END IF;
      --  END IF;
        --En check for Precheck
        --Sn check for Preauth
        
end if;
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
                                            P_TXN_AMT,
                                            P_DELIVERY_CHANNEL,
                                            V_RESP_CDE,
                                            V_ERR_MSG);

                IF (V_RESP_CDE <> '1' OR V_ERR_MSG <> 'OK')
                THEN
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
                        'Error from pre_auth process ' || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
            END;
        END IF;

        --En check for preauth

    --SN - Commented for fwr-48

      /*  BEGIN
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
                    'Error while selecting func code' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END; */

        --En find function code attached to txn code

        --EN - Commented for fwr-48

        --Get the card no
        BEGIN
            SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO, CAM_TYPE_CODE,
            nvl(cam_new_initialload_amt,cam_initialload_amt) -- Added on 17-Apr-2013 for defect 10871
              INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO, V_CAM_TYPE_CODE,
              v_initialload_amt-- Added on 17-Apr-2013 for defect 10871
              FROM CMS_ACCT_MAST
             WHERE CAM_ACCT_NO = V_ACCT_NUMBER   --Added for perf changes
                AND CAM_INST_CODE = P_INST_CODE
            FOR UPDATE; --Added for Concurrent Processsing Issue    on 25-FEB-2014 By Revathi
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '14';                       --Ineligible Transaction
                V_ERR_MSG := 'Invalid Card ';
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '12';
               -- V_ERR_MSG :=
                    --'Error while selecting data from card Master for card number '
                    --|| P_CARD_NO;  commented for FSS-2320
                     V_ERR_MSG :='Error while selecting data from card Master for card number ';

                RAISE EXP_REJECT_RECORD;
        END;
      --ST: Added for perf changes FSS-2264
       v_timestamp := systimestamp;

       BEGIN
            V_HASHKEY_ID :=
                GETHASH (
                        P_DELIVERY_CHANNEL
                    || P_TXN_CODE
                    || P_CARD_NO
                    || P_RRN
                    || TO_CHAR (v_timestamp, 'YYYYMMDDHH24MISSFF5'));
        EXCEPTION
            WHEN OTHERS
            THEN
                V_ERR_MSG :=
                    'Error while converting master data '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;
        --END: Added for perf changes FSS-2264
        ------------------------------------------------------
        --Sn Added for Concurrent Processsing Issue
        ------------------------------------------------------

        /* BEGIN
              SELECT COUNT(1)
                INTO V_RRN_COUNT
                FROM TRANSACTIONLOG
              WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
                     DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
             --Added by ramkumar.Mk on 25 march 2012


            IF V_RRN_COUNT > 0 THEN
             V_RESP_CDE := '22';
             V_ERR_MSG     := 'Duplicate RRN ' || 'on ' || P_TRAN_DATE;
             RAISE EXP_REJECT_RECORD;
            END IF;
         EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
             V_RESP_CDE := '21';
             V_ERR_MSG     := 'Duplicate RRN ' || 'on ' || P_TRAN_DATE;
             RAISE EXP_REJECT_RECORD;
         END;
 */
        -- MODIFIED BY ABDUL HAMEED M.A ON 06-3-2014
	--- Modified for VMS-4379- Remove Account Statement Txn log
        if (prm_valins_act_flag='N' AND v_audit_flag = 'T') then
        BEGIN
            sp_dup_rrn_check (v_hash_pan,
                                    p_rrn,
                                    p_tran_date,
                                    p_delivery_channel,
                                    p_msg,
                                    p_txn_code,
                                    v_err_msg);

            IF v_err_msg <> 'OK'
            THEN
                v_resp_cde := '22';
                RAISE EXP_REJECT_RECORD;
            END IF;
        EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
                RAISE;
            WHEN OTHERS
            THEN
                v_resp_cde := '22';
                v_err_msg :=
                    'Error while checking RRN' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;
        end if;

        --En Duplicate RRN Check
        ------------------------------------------------------
        --Sn Added for Concurrent Processsing Issue
        ------------------------------------------------------

        --      IF P_FEE_FLAG ='Y'
        --      then  -- Added by sagar for Fee_Flag Changes on 27Aug2012



        ---Sn dynamic fee calculation .
        BEGIN
            SP_TRAN_FEES_CMSAUTH (P_INST_CODE,
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
                                         V_INTERNATION_IND,
                                         V_POS_VERFICATION,
                                         V_RESP_CDE,
                                         P_MSG,
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
                                         V_FEEAMNT_TYPE,
                                         V_CLAWBACK,
                                         V_FEE_PLAN,
                                         V_PER_FEES,
                                         V_FLAT_FEES,
                                         V_FREETXN_EXCEED, -- Added by Trivikram for logging fee of free transaction
                                         V_DURATION, -- Added by Trivikram for logging fee of free transaction
                                         V_FEEATTACH_TYPE, -- Added by Trivikram on Sep 05 2012
                                         v_fee_desc                  -- Added for MVCSD-4471
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
                                        V_TRAN_DATE, --Added Deepa on Aug-23-2012 to calculate the waiver based on tran date
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

        IF P_FEE_FLAG = 'N'  -- Added by sagar for Fee_Flag Changes on 27Aug2012
        THEN
            V_FEE_AMT := 0;
            V_LOG_WAIVER_AMT := 0;
            V_SERVICETAX_AMOUNT := 0;
            V_CESS_AMOUNT := 0;
            V_TOTAL_FEE := 0;
            V_ST_CALC_FLAG := 0;
            V_CESS_CALC_FLAG := 0;
            V_LOG_ACTUAL_FEE := 0;
        --V_FEE_CODE             := NULL;
        --V_FEE_CRACCT_NO      := NULL;
        --V_FEE_DRACCT_NO      := NULL;
        --V_ST_CRACCT_NO         := NULL;
        --V_ST_DRACCT_NO         := NULL;
        --V_CESS_CRACCT_NO     := NULL;
        --V_CESS_DRACCT_NO     := NULL;

        END IF;                    -- Added by sagar for Fee_Flag Changes on 27Aug2012

        --En find fees amount attached to func code, prod code and card type
        BEGIN
        SELECT cpc_profile_code,cpc_badcredit_flag,cpc_badcredit_transgrpid
        INTO V_PROFILE_CODE,v_badcredit_flag,v_badcredit_transgrpid FROM cms_prod_cattype
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
        IF --(P_TXN_CODE = '68' AND P_DELIVERY_CHANNEL = '04') OR ----commented by amit on 30-Jul-2012 for limits
            (P_TXN_CODE IN ('26', '25') AND P_DELIVERY_CHANNEL = '08')
        THEN
            --Modified by Deepa on Apr 13 for SPIL Card Activation limit
            BEGIN
                SELECT TO_NUMBER (CBP_PARAM_VALUE)
                  INTO V_MIN_ACT_AMT
                  FROM CMS_BIN_PARAM
                 WHERE CBP_INST_CODE = P_INST_CODE
                         AND CBP_PARAM_NAME = 'Min Card Balance'
                         AND CBP_PROFILE_CODE = V_PROFILE_CODE;

                IF V_TRAN_AMT < V_MIN_ACT_AMT
                THEN
                    V_RESP_CDE := '39';
                    V_ERR_MSG :=
                            'Amount should be = or > than '
                        || V_MIN_ACT_AMT
                        || ' for Card Activation';
                    RAISE EXP_REJECT_RECORD;
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    V_RESP_CDE := '39';
                    V_ERR_MSG :=
                            'Amount should be = or > than '
                        || V_MIN_ACT_AMT
                        || ' for Card Activation ';
                    RAISE EXP_REJECT_RECORD;
            END;
        END IF;

        --added for minimum activation amount check beg

        --Sn added cr flag for SPIL non financial transactions Moved up on 14-May-2013 for MVHOST 346
        IF (p_delivery_channel = '08' AND p_txn_code IN ('21', '23', '25'))
        THEN
            v_dr_cr_flag := 'CR';
            v_txn_type := '1';
        END IF;

        --En added cr flag for SPIL non financial transactions

        --Sn find total transaction    amount
        IF V_DR_CR_FLAG = 'CR'
        THEN
            V_TOTAL_AMT := V_TRAN_AMT - V_TOTAL_FEE;
            V_UPD_AMT := V_ACCT_BALANCE + V_TOTAL_AMT;
            V_UPD_LEDGER_BAL := V_LEDGER_BAL + V_TOTAL_AMT;
        ELSIF V_DR_CR_FLAG = 'DR'
        THEN
            V_TOTAL_AMT := V_TRAN_AMT + V_TOTAL_FEE;
            V_UPD_AMT := V_ACCT_BALANCE - V_TOTAL_AMT;
            V_UPD_LEDGER_BAL := V_LEDGER_BAL - V_TOTAL_AMT;
        ELSIF V_DR_CR_FLAG = 'NA'
        THEN
            V_TOTAL_AMT := V_TOTAL_FEE;
            V_UPD_AMT := V_ACCT_BALANCE - V_TOTAL_AMT;
            V_UPD_LEDGER_BAL := V_LEDGER_BAL - V_TOTAL_AMT;
        ELSE
            V_RESP_CDE := '12';                          --Ineligible Transaction
            V_ERR_MSG := 'Invalid transflag    txn code ' || P_TXN_CODE;
            RAISE EXP_REJECT_RECORD;
        END IF;

        --En find total transaction    amout

        -- Check for maximum card balance configured for the product profile. Moved up on 14-May-2013 for MVHOST 346
        IF (v_dr_cr_flag = 'CR' AND p_rvsl_code = '00')
            OR (v_dr_cr_flag = 'DR' AND p_rvsl_code <> '00')
        THEN                            --if condition added by Pankaj S. for MVCSD-4077
            BEGIN
                --Sn Added on 09-Feb-2013 for max card balance check based on product category
                SELECT TO_NUMBER (cbp_param_value)
                  INTO v_max_card_bal
                  FROM cms_bin_param
                 WHERE cbp_inst_code = p_inst_code
                         AND cbp_param_name = 'Max Card Balance'
                         AND cbp_profile_code = V_PROFILE_CODE;

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
                WHEN OTHERS
                THEN
                    V_RESP_CDE := '21';
                    V_ERR_MSG := SQLERRM;
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
               IF    ((V_UPD_AMT  ) > v_initialload_amt
                     )                                     --initialloadamount
                  OR ((V_UPD_LEDGER_BAL ) > v_initialload_amt
                     )
               THEN                                        --initialloadamount
                  UPDATE cms_appl_pan
                     SET cap_card_stat = '18'
                   WHERE cap_inst_code = P_INST_CODE
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
            IF    ((V_UPD_AMT ) > v_max_card_bal)
               OR ((V_UPD_LEDGER_BAL ) > v_max_card_bal)
            THEN
                V_RESP_CDE := '30';
                V_ERR_MSG := 'EXCEEDING MAXIMUM CARD BALANCE';
                RAISE EXP_REJECT_RECORD;
            END IF;
            END IF;
        END IF;

        IF (p_delivery_channel = '08' AND p_txn_code IN ('21', '23', '25'))
            OR (p_delivery_channel = '11' AND p_txn_code IN ('23', '33'))
        THEN
            v_dr_cr_flag := 'NA';
            v_txn_type := '0';
        END IF;

        --Sn check balance
        IF (V_DR_CR_FLAG NOT IN ('NA', 'CR') OR (V_TOTAL_FEE <> 0))
        THEN
            IF V_UPD_AMT < 0
            THEN
                --Sn IVR ClawBack amount updation
                IF V_LOGIN_TXN = 'Y' AND V_CLAWBACK = 'Y'
                THEN
                    V_ACTUAL_FEE_AMNT := V_TOTAL_FEE;

                    --  V_CLAWBACK_AMNT     := V_TOTAL_FEE - V_ACCT_BALANCE;
                    --     V_FEE_AMT            := V_ACCT_BALANCE;
                    --Added on 21/02/14 for regarding 0013542
                    IF (V_ACCT_BALANCE > 0)
                    THEN
                        V_CLAWBACK_AMNT := V_TOTAL_FEE - V_ACCT_BALANCE;
                        V_FEE_AMT := V_ACCT_BALANCE;
                    ELSE
                        V_CLAWBACK_AMNT := V_TOTAL_FEE;
                        V_FEE_AMT := 0;
                    END IF;

                    --End
                    IF V_CLAWBACK_AMNT > 0
                    THEN
                        /*UPDATE cms_acct_mast
                              SET cam_loginfee_clawback_amnt =
                                                                        cam_loginfee_clawback_amnt + v_clawback_amnt
                            WHERE cam_acct_no = v_card_acct_no AND cam_inst_code = p_inst_code;
                          IF SQL%ROWCOUNT <> 1 THEN

                                V_RESP_CDE := '21';
                                V_ERR_MSG  := 'Error While Updating ClawBack ' ||SUBSTR(SQLERRM, 1, 200);
                                RAISE EXP_REJECT_RECORD;

                          END IF; */


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
                                         AND ccd_acct_no = v_card_acct_no  and CCD_FEE_CODE=V_FEE_CODE
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

                        --Added by Deepa on July 02 2012 to maintain clawback amount details in separate table
                        --Sn Clawback Details
                        BEGIN
                            SELECT COUNT (*)
                              INTO V_CLAWBACK_COUNT
                              FROM CMS_ACCTCLAWBACK_DTL
                             WHERE      CAD_INST_CODE = P_INST_CODE
                                     AND CAD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                                     AND CAD_TXN_CODE = P_TXN_CODE
                                     AND CAD_PAN_CODE = V_HASH_PAN
                                     AND CAD_ACCT_NO = V_CARD_ACCT_NO;

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
                                          V_CARD_ACCT_NO,
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
                                         AND CAD_ACCT_NO = V_CARD_ACCT_NO
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
                    --En Clawback Details

                    END IF;
                ELSE
                    V_RESP_CDE := '15';                    --Ineligible Transaction
                    V_ERR_MSG := 'Insufficient Balance '; -- modified by Ravi N for Mantis ID 0011282
                    RAISE EXP_REJECT_RECORD;
                END IF;

                V_UPD_AMT := 0; -- Added by sagar on 27-Aug2012 to log available balance as Zero when balance is < 0
                V_UPD_LEDGER_BAL := 0; -- Added by sagar on 27-Aug2012 to log available balance as Zero when balance is < 0
                V_TOTAL_AMT := V_TRAN_AMT + V_FEE_AMT; -- Added by sagar on 27-Aug2012 to log total as Zero when balance is < 0
            END IF;
        END IF;

        --Added by Deepa on June 19 2012 For the Clawback of IVR Login Fee

        --Modified by Ramkumar.MK on 03 Jan 2013, both delivery channel and transaction code condition check
        /* IF (P_DELIVERY_CHANNEL = '08') OR (P_DELIVERY_CHANNEL = '11') THEN
          --En check balance
          IF (TO_NUMBER(P_TXN_CODE) = 21) OR (TO_NUMBER(P_TXN_CODE) = 23) OR
              (TO_NUMBER(P_TXN_CODE) = 33) OR (TO_NUMBER(P_TXN_CODE) = 25) THEN
             V_DR_CR_FLAG := 'NA';
             V_TXN_TYPE   := '0';
          END IF;
         END IF;*/



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
                                                     V_CARD_ACCT_NO,
                                                     '',
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

        --Sn find narration
        BEGIN
            /*SELECT CTM_TRAN_DESC
              INTO V_TRANS_DESC
              FROM CMS_TRANSACTION_MAST
             WHERE CTM_TRAN_CODE = P_TXN_CODE AND
                    CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
                    CTM_INST_CODE = P_INST_CODE;*/
            --Commented by Deepa on May 08 as the transaction mast query executed before

            IF (V_TRANSFER_FLAG = 'Y')
            THEN
                IF TRIM (V_TRANS_DESC) IS NOT NULL
                THEN
                    V_NARRATION := V_TRANS_DESC || '/';
                END IF;

                IF TRIM (V_AUTH_ID) IS NOT NULL
                THEN
                    V_NARRATION := V_NARRATION || V_AUTH_ID || '/';
                END IF;

                IF TRIM (P_TO_ACCT_NO) IS NOT NULL
                THEN
                    V_NARRATION := V_NARRATION || P_TO_ACCT_NO || '/';
                END IF;

                IF TRIM (P_TRAN_DATE) IS NOT NULL
                THEN
                    V_NARRATION := V_NARRATION || P_TRAN_DATE;
                END IF;
            ELSE
                IF TRIM (V_TRANS_DESC) IS NOT NULL
                THEN
                    V_NARRATION := V_TRANS_DESC || '/';
                END IF;

                IF TRIM (P_MERCHANT_NAME) IS NOT NULL
                THEN
                    V_NARRATION := V_NARRATION || P_MERCHANT_NAME || '/';
                END IF;

                IF TRIM (P_MERCHANT_CITY) IS NOT NULL
                THEN
                    V_NARRATION := V_NARRATION || P_MERCHANT_CITY || '/';
                END IF;

                IF TRIM (P_TRAN_DATE) IS NOT NULL
                THEN
                    V_NARRATION := V_NARRATION || P_TRAN_DATE || '/';
                END IF;

                IF TRIM (V_AUTH_ID) IS NOT NULL
                THEN
                    V_NARRATION := V_NARRATION || V_AUTH_ID;
                END IF;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_TRANS_DESC := 'Transaction type ' || P_TXN_CODE;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                V_ERR_MSG :=
                    'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --  v_timestamp := systimestamp;   -- commented on 29-08-2013 for FSS-1144              -- Added on 20-Apr-2013 for defect 10871

        --Sn create a entry in statement log
        IF V_DR_CR_FLAG <> 'NA'
        THEN
            BEGIN
                IF V_TRANSFER_FLAG = 'Y'
                THEN
                    --Added by Deepa to add the to_account_no for C2C transactions

                    V_TOACCT_NO := P_TO_ACCT_NO;

                    --St Added by Ramesh.A on 31/08/2012
                    IF P_DELIVERY_CHANNEL IN ('10', '07')
                        AND P_TXN_CODE IN ('20', '11')
                    THEN
                        V_TOACCT_NO := '';
                    END IF;
                --End Added by Ramesh.A on 31/08/2012


                END IF;

                --Sn Added by Pankaj S. for LYFEHOST-64
                IF (P_DELIVERY_CHANNEL = '10' AND P_TXN_CODE = '18')
                    AND V_TRAN_AMT = 0
                THEN
                    NULL;
                ELSIF V_TRAN_AMT <> 0 THEN  -- modified for mantis id:13000 on july-08-2014
                    --En Added by Pankaj S. for LYFEHOST-64
                    INSERT INTO CMS_STATEMENTS_LOG (CSL_PAN_NO,
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
                                                              CSL_INS_DATE, -- Added by Ramesh.A on 25/02/12
                                                              CSL_INS_USER, -- Added by Ramesh.A on 25/02/12
                                                              CSL_ACCT_NO, --Added by Deepa to log the account number
                                                              CSL_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state and To_account no for C2C
                                                              CSL_MERCHANT_CITY,
                                                              CSL_MERCHANT_STATE,
                                                              CSL_TO_ACCTNO,
                                                              CSL_PANNO_LAST4DIGIT, --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
                                                              csl_acct_type, -- Added on 20-Apr-2013 for defect 10871
                                                              csl_time_stamp, -- Added on 20-Apr-2013 for defect 10871
                                                              csl_prod_code,csl_card_type -- Added on 20-Apr-2013 for defect 10871
                                                                                )
                          VALUES (
                                        V_HASH_PAN,
                                        ROUND (v_ledger_bal, 2), -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 1087132 --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                        ROUND (V_TRAN_AMT, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                        V_DR_CR_FLAG,
                                        V_TRAN_DATE,
                                        ROUND (
                                            DECODE (V_DR_CR_FLAG,
                                                      'DR', v_ledger_bal - V_TRAN_AMT, -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
                                                      'CR', v_ledger_bal + V_TRAN_AMT, -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
                                                      'NA', v_ledger_bal),
                                            2), -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871 --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                        V_NARRATION,
                                        V_ENCR_PAN,
                                        P_RRN,
                                        V_AUTH_ID,
                                        P_TRAN_DATE,
                                        P_TRAN_TIME,
                                        'N',
                                        P_DELIVERY_CHANNEL,
                                        P_INST_CODE,
                                        P_TXN_CODE,
                                        SYSDATE,          -- Added by Ramesh.A on 25/02/12
                                        1,                  -- Added by Ramesh.A on 25/02/12
                                        V_CARD_ACCT_NO, --Added by Deepa to log the account number
                                        P_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                                        P_MERCHANT_CITY,
                                        P_ATMNAME_LOC,
                                        V_TOACCT_NO,
                                        (SUBSTR (P_CARD_NO,
                                                    LENGTH (P_CARD_NO) - 3,
                                                    LENGTH (P_CARD_NO))), --Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
                                        v_cam_type_code, -- added on 20-Apr-2013 for defect 10871
                                        v_timestamp, -- Added on 20-Apr-2013 for defect 10871
                                        v_prod_code,V_PROD_CATTYPE -- Added on 20-Apr-2013 for defect 10871
                                                      );
                END IF;                            ---- Added by Pankaj S. for LYFEHOST-64
            EXCEPTION
                WHEN OTHERS
                THEN
                    V_RESP_CDE := '21';
                    V_ERR_MSG :=
                        'Problem while inserting into statement log for tran amt '
                        || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
            END;

            BEGIN
                SP_DAILY_BIN_BAL (P_CARD_NO,
                                        V_TRAN_DATE,
                                        V_TRAN_AMT,
                                        V_DR_CR_FLAG,
                                        P_INST_CODE,
                                        P_BANK_CODE,
                                        V_ERR_MSG);

                IF V_ERR_MSG <> 'OK'
                THEN
                    V_RESP_CDE := '21';
                    V_ERR_MSG :=
                        'Problem while calling SP_DAILY_BIN_BAL '
                        || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    V_RESP_CDE := '21';
                    V_ERR_MSG :=
                        'Problem while calling SP_DAILY_BIN_BAL '
                        || SUBSTR (SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
            END;
        END IF;

        --En create a entry in statement log
        --Sn find fee opening balance
        IF V_TOTAL_FEE <> 0 OR V_FREETXN_EXCEED = 'N'
        THEN -- Modified by Trivikram  on 27-July-2012 for logging complementory transaction
            BEGIN
                SELECT DECODE (V_DR_CR_FLAG,    'DR', v_ledger_bal - V_TRAN_AMT, -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
                                                                                                  'CR', v_ledger_bal + V_TRAN_AMT, -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
                                                                                                                                             'NA', v_ledger_bal) -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 20-Apr-2013 for defect 10871
                  INTO V_FEE_OPENING_BAL
                  FROM DUAL;
            EXCEPTION
                WHEN OTHERS
                THEN
                    V_RESP_CDE := '21';
                    --V_ERR_MSG :=
                        --'Error while selecting data from card Master for card number '
                        --|| P_CARD_NO;  commented for FSS-2320
                         V_ERR_MSG := 'Error while selecting data from card Master for card number ';

                    RAISE EXP_REJECT_RECORD;
            END;

            --En find fee opening balance
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
                                                              CSL_PAN_NO_ENCR,
                                                              CSL_RRN,
                                                              CSL_AUTH_ID,
                                                              CSL_BUSINESS_DATE,
                                                              CSL_BUSINESS_TIME,
                                                              TXN_FEE_FLAG,
                                                              CSL_DELIVERY_CHANNEL,
                                                              CSL_INST_CODE,
                                                              CSL_TXN_CODE,
                                                              CSL_INS_DATE, -- Added by Ramesh.A on 25/02/12
                                                              CSL_INS_USER, -- Added by Ramesh.A on 25/02/12
                                                              CSL_ACCT_NO, --Added by Deepa to log the account number
                                                              CSL_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                                                              CSL_MERCHANT_CITY,
                                                              CSL_MERCHANT_STATE,
                                                              CSL_PANNO_LAST4DIGIT, --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                                                              csl_acct_type, -- Added on 20-Apr-2013 for defect 10871
                                                              csl_time_stamp, -- Added on 20-Apr-2013 for defect 10871
                                                              csl_prod_code,csl_card_type -- Added on 20-Apr-2013 for defect 10871
                                                                                )
                          VALUES (
                                        V_HASH_PAN,
                                        ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                        --V_TOTAL_FEE,
                                        ROUND (V_FEE_AMT, 2), --Modified by Deepa on June 19 2012 for IVR ClawBack--Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                        'DR',
                                        V_TRAN_DATE,
                                        ROUND (V_FEE_OPENING_BAL - V_FEE_AMT, 2), --Modified by Deepa on June 19 2012 for IVR ClawBack--Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                        -- V_FEE_OPENING_BAL - V_TOTAL_FEE,
                                        --'Complimentary ' || V_DURATION ||' '|| V_NARRATION, -- Modified by Trivikram  on 27-July-2012 -- Commented for MVCSD-4471
                                        v_fee_desc,                  -- Added for MVCSD-4471
                                        V_ENCR_PAN,
                                        P_RRN,
                                        V_AUTH_ID,
                                        P_TRAN_DATE,
                                        P_TRAN_TIME,
                                        'Y',
                                        P_DELIVERY_CHANNEL,
                                        P_INST_CODE,
                                        P_TXN_CODE,
                                        SYSDATE,          -- Added by Ramesh.A on 25/02/12
                                        1,                  -- Added by Ramesh.A on 25/02/12
                                        V_CARD_ACCT_NO, --Added by Deepa to log the account number
                                        P_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                                        P_MERCHANT_CITY,
                                        P_ATMNAME_LOC,
                                        (SUBSTR (P_CARD_NO,
                                                    LENGTH (P_CARD_NO) - 3,
                                                    LENGTH (P_CARD_NO))), --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                                        v_cam_type_code, -- added on 20-Apr-2013 for defect 10871
                                        v_timestamp, -- Added on 20-Apr-2013 for defect 10871
                                        v_prod_code,V_PROD_CATTYPE -- Added on 20-Apr-2013 for defect 10871
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
                    IF V_FEEAMNT_TYPE = 'A' AND V_LOGIN_TXN != 'Y'
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
                                                                  CSL_MERCHANT_NAME,
                                                                  CSL_MERCHANT_CITY,
                                                                  CSL_MERCHANT_STATE,
                                                                  CSL_PANNO_LAST4DIGIT,
                                                                  csl_acct_type, -- Added on 20-Apr-2013 for defect 10871
                                                                  csl_time_stamp, -- Added on 20-Apr-2013 for defect 10871
                                                                  csl_prod_code,csl_card_type -- Added on 20-Apr-2013 for defect 10871
                                                                                    )
                              VALUES (
                                            V_HASH_PAN,
                                            ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-APR-2014    for 3decimal place issue
                                            ROUND (V_FLAT_FEES, 2), --Added by Deepa on Aug-22-2012 to log the Fixed Fee with waiver amount,--Modified by Sankar S on 08-APR-2014    for 3decimal place issue
                                            'DR',
                                            V_TRAN_DATE,
                                            ROUND (V_FEE_OPENING_BAL - V_FLAT_FEES, 2), --Added by Deepa on Aug-22-2012 to log the Fixed Fee with waiver amount,--Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                            --'Fixed Fee debited for ' || V_NARRATION, -- Commented for MVCSD-4471
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
                                            SYSDATE,
                                            P_MERCHANT_NAME,
                                            P_MERCHANT_CITY,
                                            P_ATMNAME_LOC,
                                            (SUBSTR (P_CARD_NO,
                                                        LENGTH (P_CARD_NO) - 3,
                                                        LENGTH (P_CARD_NO))),
                                            v_cam_type_code, -- added on 20-Apr-2013 for defect 10871
                                            v_timestamp, -- Added on 20-Apr-2013 for defect 10871
                                            v_prod_code,V_PROD_CATTYPE -- Added on 20-Apr-2013 for defect 10871
                                                          );

                        --En Entry for Fixed Fee
                        V_FEE_OPENING_BAL := V_FEE_OPENING_BAL - V_FLAT_FEES; --Added by Deepa on Aug-22-2012 to log the Fixed Fee with waiver amount;

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
                                                                  CSL_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                                                                  CSL_MERCHANT_CITY,
                                                                  CSL_MERCHANT_STATE,
                                                                  CSL_PANNO_LAST4DIGIT, --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                                                                  csl_acct_type, -- Added on 20-Apr-2013 for defect 10871
                                                                  csl_time_stamp, -- Added on 20-Apr-2013 for defect 10871
                                                                  csl_prod_code,csl_card_type -- Added on 20-Apr-2013 for defect 10871
                                                                                    )
                              VALUES (
                                            V_HASH_PAN,
                                            ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-APR-2014    for 3decimal place issue
                                            ROUND (V_PER_FEES, 2), --Modified by Sankar S on 08-APR-2014  for 3decimal place issue
                                            'DR',
                                            V_TRAN_DATE,
                                            ROUND (V_FEE_OPENING_BAL - V_PER_FEES, 2), --Modified by Sankar S on 08-APR-2014  for 3decimal place issue
                                            --'Percetage Fee debited for ' || V_NARRATION, -- Commented for MVCSD-4471
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
                                            V_CARD_ACCT_NO, --Added by Deepa to log the account number ,INS_DATE and INS_USER
                                            1,
                                            SYSDATE,
                                            P_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                                            P_MERCHANT_CITY,
                                            P_ATMNAME_LOC,
                                            (SUBSTR (P_CARD_NO,
                                                        LENGTH (P_CARD_NO) - 3,
                                                        LENGTH (P_CARD_NO))),
                                            v_cam_type_code, -- added on 20-Apr-2013 for defect 10871
                                            v_timestamp, -- Added on 20-Apr-2013 for defect 10871
                                            v_prod_code,V_PROD_CATTYPE -- Added on 20-Apr-2013 for defect 10871
                                                          );
                    --En Entry for Percentage Fee

                    ELSE
                        --Sn create entries for FEES attached
                        --  If V_FEE_AMT > 0  -- added by sagar on 27Aug2012 to insert only when fee amount is > 0
                        -- then
                        --Commented for MVHOSt-346 as we should insert even if the fee amount is zero for the claw back recovery of fee amount

                        INSERT INTO CMS_STATEMENTS_LOG (CSL_PAN_NO,
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
                                                                  CSL_INS_DATE, -- Added by Ramesh.A on 25/02/12
                                                                  CSL_INS_USER, -- Added by Ramesh.A on 25/02/12
                                                                  CSL_ACCT_NO, --Added by Deepa to log the account number
                                                                  CSL_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                                                                  CSL_MERCHANT_CITY,
                                                                  CSL_MERCHANT_STATE,
                                                                  CSL_PANNO_LAST4DIGIT, --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                                                                  csl_acct_type, -- Added on 20-Apr-2013 for defect 10871
                                                                  csl_time_stamp, -- Added on 20-Apr-2013 for defect 10871
                                                                  csl_prod_code,csl_card_type -- Added on 20-Apr-2013 for defect 10871
                                                                                    )
                              VALUES (
                                            V_HASH_PAN,
                                            ROUND (V_FEE_OPENING_BAL, 2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                            --V_TOTAL_FEE,
                                            ROUND (V_FEE_AMT, 2), --Modified by Deepa on June 19 2012 for IVR ClawBack--Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                            'DR',
                                            V_TRAN_DATE,
                                            ROUND (V_FEE_OPENING_BAL - V_FEE_AMT, 2), --Modified by Deepa on June 19 2012 for IVR ClawBack--Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                                            -- V_FEE_OPENING_BAL - V_TOTAL_FEE,
                                            --'Fee debited for ' || V_NARRATION, -- Commented for MVCSD-4471
                                            v_fee_desc,              -- Added for MVCSD-4471
                                            V_ENCR_PAN,
                                            P_RRN,
                                            V_AUTH_ID,
                                            P_TRAN_DATE,
                                            P_TRAN_TIME,
                                            'Y',
                                            P_DELIVERY_CHANNEL,
                                            P_INST_CODE,
                                            P_TXN_CODE,
                                            SYSDATE,      -- Added by Ramesh.A on 25/02/12
                                            1,              -- Added by Ramesh.A on 25/02/12
                                            V_CARD_ACCT_NO, --Added by Deepa to log the account number
                                            P_MERCHANT_NAME, --Added by Deepa on 03-May-2012 to log Merchant name,city and state
                                            P_MERCHANT_CITY,
                                            P_ATMNAME_LOC,
                                            (SUBSTR (P_CARD_NO,
                                                        LENGTH (P_CARD_NO) - 3,
                                                        LENGTH (P_CARD_NO))), --Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                                            v_cam_type_code, -- added on 20-Apr-2013 for defect 10871
                                            v_timestamp, -- Added on 20-Apr-2013 for defect 10871
                                            v_prod_code,V_PROD_CATTYPE -- Added on 20-Apr-2013 for defect 10871
                                                          );

                        -- End if;

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
                                                                     CCD_FEEATTACHTYPE --Added by Deepa on Oct-22-2012 to log the FeeAttach type for Clawback
                                                                                            )
                                      VALUES (V_HASH_PAN,
                                                 V_CARD_ACCT_NO,
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
                                                 V_FEEATTACH_TYPE); --Added by Deepa on Oct-22-2012 to log the FeeAttach type for Clawback
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

        --En create entries for FEES attached
        --Sn create a entry for successful
        
        IF v_audit_flag = 'T'		--- Modified for VMS-4379- Remove Account Statement Txn log
        THEN
        BEGIN
            INSERT INTO CMS_TRANSACTION_LOG_DTL (CTD_DELIVERY_CHANNEL,
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
                                                             CTD_INST_CODE,
                                                             CTD_HASHKEY_ID) --Added  on 29-08-2013 for Fss-1144
                  VALUES (P_DELIVERY_CHANNEL,
                             P_TXN_CODE,
                             V_TXN_TYPE,
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
                             V_ENCR_PAN,
                             P_MSG,
                             V_ACCT_NUMBER,
                             P_INST_CODE,
                             V_HASHKEY_ID);         --Added  on 29-08-2013 for Fss-1144
        EXCEPTION
            WHEN OTHERS
            THEN
                V_ERR_MSG :=
                    'Problem while selecting data from response master '
                    || SUBSTR (SQLERRM, 1, 300);
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
        END;
        
        END IF;

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
        /*
         IF SQL%ROWCOUNT = 0 THEN
            V_ERR_MSG  := 'Problem while updating data in avail trans ' ||
                          SUBSTR(SQLERRM, 1, 300);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
         END IF;
         */
        EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
                RAISE;
            WHEN NO_DATA_FOUND
            THEN
                NULL;
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
        IF V_OUTPUT_TYPE = 'B'
        THEN
            --Balance Inquiry
            P_RESP_MSG := TO_CHAR (V_UPD_AMT);
        END IF;

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
            SELECT CMS_ISO_RESPCDE
              INTO P_RESP_CODE
              FROM CMS_RESPONSE_MAST
             WHERE      CMS_INST_CODE = P_INST_CODE
                     AND CMS_DELIVERY_CHANNEL = decode(TO_NUMBER (P_DELIVERY_CHANNEL),17,10,P_DELIVERY_CHANNEL)
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

        ---

        -------------------------------------------------------------------------------------------------------
        --SN: Added on 10-Oct-2012 to log error from SP_CREATE_GL_ENTRIES_CMSAUTH into TRANSACTIONLOG table
        -------------------------------------------------------------------------------------------------------

        --- Sn create GL ENTRIES
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

            --SN - Commented for fwr-48

       /*     BEGIN
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
                                                        V_CARD_ACCT_NO,
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
                WHEN EXP_REJECT_RECORD
                THEN
                    RAISE;
                WHEN OTHERS
                THEN
                    V_GL_UPD_FLAG := 'N';
                    P_RESP_CODE := V_RESP_CDE;
                    V_ERR_MSG := V_GL_ERR_MSG;
                    RAISE EXP_REJECT_RECORD;
            END;  */

            --EN - Commented for fwr-48

        END IF;
    -------------------------------------------------------------------------------------------------------
    --EN: Added on 10-Oct-2012 to log error from SP_CREATE_GL_ENTRIES_CMSAUTH into TRANSACTIONLOG table
    -------------------------------------------------------------------------------------------------------

    EXCEPTION
        --<< MAIN EXCEPTION >>
        WHEN EXP_REJECT_RECORD
        THEN
            ROLLBACK TO V_AUTH_SAVEPOINT;

            BEGIN
                SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO, CAM_TYPE_CODE -- Added on 17-Apr-2013 for defect 10871
                  INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_ACCT_NUMBER, V_CAM_TYPE_CODE -- Added on 17-Apr-2013 for defect 10871
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

            --Sn select response code and insert record into txn log dtl
            P_RESP_CODE := V_RESP_CDE;

            BEGIN
                SELECT CMS_ISO_RESPCDE
                  INTO P_RESP_CODE
                  FROM CMS_RESPONSE_MAST
                 WHERE      CMS_INST_CODE = P_INST_CODE
                         AND CMS_DELIVERY_CHANNEL =  decode(P_DELIVERY_CHANNEL,'17','10',P_DELIVERY_CHANNEL)
                         AND CMS_RESPONSE_ID = V_RESP_CDE;

                P_RESP_MSG := V_ERR_MSG;
            EXCEPTION
                WHEN OTHERS
                THEN
                    P_RESP_MSG :=
                            'Problem while selecting data from response master '
                        || V_RESP_CDE
                        || SUBSTR (SQLERRM, 1, 300);
                    P_RESP_CODE := '89';          ---ISO MESSAGE FOR DATABASE ERROR
                    ROLLBACK;
            END;
            
            IF v_audit_flag = 'T'		--- Modified for VMS-4379- Remove Account Statement Txn log
            THEN

            BEGIN
                INSERT INTO CMS_TRANSACTION_LOG_DTL (CTD_DELIVERY_CHANNEL,
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
                                                                 CTD_INST_CODE,
                                                                 CTD_HASHKEY_ID --Added  on 29-08-2013 for Fss-1144
                                                                                    )
                      VALUES (P_DELIVERY_CHANNEL,
                                 P_TXN_CODE,
                                 V_TXN_TYPE,
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
                                 V_ENCR_PAN,
                                 P_MSG,
                                 V_ACCT_NUMBER,
                                 P_INST_CODE,
                                 V_HASHKEY_ID);     --Added  on 29-08-2013 for Fss-1144

                P_RESP_MSG := V_ERR_MSG;
            EXCEPTION
                WHEN OTHERS
                THEN
                    P_RESP_CODE := '99';
                    P_RESP_MSG :=
                        'Problem while inserting data into transaction log  dtl'
                        || SUBSTR (SQLERRM, 1, 300);
                    ROLLBACK;
                    RETURN;
            END;
            
            END IF;


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
                    SELECT CTM_CREDIT_DEBIT_FLAG,nvl(ctm_txn_log_flag,'T')
                      INTO V_DR_CR_FLAG,v_audit_flag
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
        -----------------------------------------------
        --EN: Added on 20-Apr-2013 for defect 10871
        -----------------------------------------------

        WHEN OTHERS
        THEN
            ROLLBACK TO V_AUTH_SAVEPOINT;

            BEGIN
                SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_TYPE_CODE -- Added on 17-Apr-2013 for defect 10871
                  INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CAM_TYPE_CODE -- Added on 17-Apr-2013 for defect 10871
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

            --Sn select response code and insert record into txn log dtl

            BEGIN
                SELECT CMS_ISO_RESPCDE
                  INTO P_RESP_CODE
                  FROM CMS_RESPONSE_MAST
                 WHERE      CMS_INST_CODE = P_INST_CODE
                         AND CMS_DELIVERY_CHANNEL =  decode(P_DELIVERY_CHANNEL,'17','10',P_DELIVERY_CHANNEL)
                         AND CMS_RESPONSE_ID = V_RESP_CDE;

                P_RESP_MSG := V_ERR_MSG;
            EXCEPTION
                WHEN OTHERS
                THEN
                    P_RESP_MSG :=
                            'Problem while selecting data from response master '
                        || V_RESP_CDE
                        || SUBSTR (SQLERRM, 1, 300);
                    P_RESP_CODE := '89';
                    ROLLBACK;
            END;
            
            
            IF v_audit_flag = 'T'		--- Modified for VMS-4379- Remove Account Statement Txn log
            THEN

            BEGIN
                INSERT INTO CMS_TRANSACTION_LOG_DTL (CTD_DELIVERY_CHANNEL,
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
                                                                 CTD_INST_CODE,
                                                                 CTD_HASHKEY_ID) --Added  on 29-08-2013 for Fss-1144
                      VALUES (P_DELIVERY_CHANNEL,
                                 P_TXN_CODE,
                                 V_TXN_TYPE,
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
                                 V_ENCR_PAN,
                                 P_MSG,
                                 V_ACCT_NUMBER,
                                 P_INST_CODE,
                                 V_HASHKEY_ID);     --Added  on 29-08-2013 for Fss-1144
            EXCEPTION
                WHEN OTHERS
                THEN
                    P_RESP_MSG :=
                        'Problem while inserting data into transaction log  dtl'
                        || SUBSTR (SQLERRM, 1, 300);
                    P_RESP_CODE := '99';
                    ROLLBACK;
                    RETURN;
            END;
            
            END IF;

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
                    SELECT CTM_CREDIT_DEBIT_FLAG,nvl(ctm_txn_log_flag,'T')
                      INTO V_DR_CR_FLAG,v_audit_flag
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
    -----------------------------------------------
    --EN: Added on 20-Apr-2013 for defect 10871
    -----------------------------------------------

    END;

    -------------------------------------------------------------------------------------------------------
    --SN:Commented on 10-Oct-2012 to log error from SP_CREATE_GL_ENTRIES_CMSAUTH into TRANSACTIONLOG table
    -------------------------------------------------------------------------------------------------------

    /*
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
              P_RESP_CODE     := V_RESP_CDE;
              V_ERR_MSG      := V_GL_ERR_MSG;
              RAISE EXP_REJECT_RECORD;
            END IF;
          EXCEPTION WHEN EXP_REJECT_RECORD
          THEN
                RAISE;
            WHEN OTHERS THEN
              V_GL_UPD_FLAG := 'N';
              P_RESP_CODE     := V_RESP_CDE;
              V_ERR_MSG      := V_GL_ERR_MSG;
              RAISE EXP_REJECT_RECORD;
          END;
        END IF;
     */
    -------------------------------------------------------------------------------------------------------
    --EN:Commented on 10-Oct-2012 to log error from SP_CREATE_GL_ENTRIES_CMSAUTH into TRANSACTIONLOG table
    -------------------------------------------------------------------------------------------------------


    --En create GL ENTRIES//Added srinvasu -trancde 25 is apil preauthactivation transaction
    --IF (P_TXN_CODE = '25' OR P_TXN_CODE = '21') AND P_DELIVERY_CHANNEL = '08'
    IF P_TXN_CODE = '25'  AND P_DELIVERY_CHANNEL = '08' --Txn Code 21 removed for MANTIS ID-12422
    THEN
        V_UPD_AMT := 0;
        V_UPD_LEDGER_BAL := 0;
    END IF;

	--- Modified for VMS-4379- Remove Account Statement Txn log
    IF v_audit_flag = 'T' 
    THEN
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
                                             ADD_INS_DATE, -- Added by Ramesh.A on 25/02/12
                                             ADD_INS_USER, -- Added by Ramesh.A on 25/02/12
                                             CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
                                             FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
                                             CSR_ACHACTIONTAKEN, -- added by sagar on 27Aug2012 for Fee related changes
                                             error_msg,  -- Added by sagar on 04-Sep-2012
                                             FEEATTACHTYPE, -- Added by Trivikram on 05-Sep-2012
                                             MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                                             MERCHANT_CITY, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                                             MERCHANT_STATE, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                                             acct_type,             --Added for defect 10871
                                             time_stamp,             --Added for defect 10871
                                             fundingaccount ,
											 MERCHANT_ZIP  )-- added for VMS-622 (redemption_delay zip code validation)
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
                            NULL,                                             --P_topup_acctno ,
                            NULL,                                           --P_topup_accttype,
                            P_BANK_CODE,
                            TRIM (
                                TO_CHAR (NVL (V_TOTAL_AMT, 0),
                                            '99999999999999990.99')), --NVL Added for defect 10871
                            NULL,
                            NULL,
                            P_MCC_CODE,
                            P_CURR_CODE,
                            NULL,                                               -- P_add_charge,
                            V_PROD_CODE,
                            V_PROD_CATTYPE,
                            P_TIP_AMT,
                            NULL,
                            P_ATMNAME_LOC,
                            V_AUTH_ID,
                            V_TRANS_DESC,
                            TRIM (
                                TO_CHAR (NVL (V_TRAN_AMT, 0),
                                            '999999999999999990.99')), --NVL Added for defect 10871
                            '0.00',          --NULL replaced by 0.00 for defect 10871
                            '0.00', -- Partial amount (will be given for partial txn) --NULL replaced by 0.00 for defect 10871
                            P_MCCCODE_GROUPID,
                            P_CURRCODE_GROUPID,
                            P_TRANSCODE_GROUPID,
                            P_RULES,
                            P_PREAUTH_DATE,
                            V_GL_UPD_FLAG,
                            P_STAN,
                            P_INST_CODE,
                            V_FEE_CODE,
                            NVL (V_FEE_AMT, 0),                             --Added for 13160
                            NVL (V_SERVICETAX_AMOUNT, 0),              --Added for 13160
                            NVL (V_CESS_AMOUNT, 0),                      --Added for 13160
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
                            ROUND (
                                DECODE (P_RESP_CODE, '00', V_UPD_AMT, V_ACCT_BALANCE),
                                2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                            ROUND (
                                DECODE (P_RESP_CODE,
                                          '00', V_UPD_LEDGER_BAL,
                                          V_LEDGER_BAL),
                                2), --Modified by Sankar S on 08-APR-2014 for 3decimal place issue
                            V_RESP_CDE,
                            SYSDATE,                      -- Added by Ramesh.A on 25/02/12
                            1,                              -- Added by Ramesh.A on 25/02/12
                            V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
                            V_FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
                            p_fee_flag, -- added by sagar on 27Aug2012 for Fee related changes
                            V_ERR_MSG,                     -- Added by sagar on 04-Sep-2012
                            V_FEEATTACH_TYPE,     -- Added by Trivikram on 05-Sep-2012
                            P_MERCHANT_NAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                            P_MERCHANT_CITY, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                            P_ATMNAME_LOC, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
                            v_cam_type_code,                        --Added for defect 10871
                            v_timestamp,P_funding_account, -- Modified on 29-08-2013 for FSS-1144 --Added for defect 10871
                                 P_MERCHANT_ZIP         );-- added for VMS-622 (redemption_delay zip code validation)

        P_CAPTURE_DATE := V_BUSINESS_DATE;

  IF  P_RULES ='B' THEN
             P_AUTH_ID := V_TOTAL_FEE;
     else
            P_AUTH_ID := V_AUTH_ID;
  END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            P_RESP_CODE := '99';
            P_RESP_MSG :=
                'Problem while inserting data into transaction log  dtl'
                || SUBSTR (SQLERRM, 1, 300);
    END;
    ELSIF v_audit_flag = 'A'
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
                    feecode,
                    tranfee_amt,
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
                    fee_plan,
                    error_msg,
                    feeattachtype,
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
                    p_term_id,
                    v_business_date,
                    p_txn_code,
                    v_txn_type,
                    p_txn_mode,
                    decode(p_resp_code, '00', 'C', 'F'),
                    p_resp_code,
                    p_tran_date,
                    substr(p_tran_time, 1, 10),
                    v_hash_pan,
                    p_bank_code,
                    TRIM(to_char(nvl(v_total_amt, 0), '99999999999999990.99')),
                    p_curr_code,
                    v_prod_code,
                    v_prod_cattype,
                    p_atmname_loc,
                    v_auth_id,
                    v_trans_desc,
                    TRIM(to_char(nvl(v_tran_amt, 0), '999999999999999990.99')),
                    p_stan,
                    p_inst_code,
                    v_fee_code,
                    nvl(v_fee_amt, 0),
                    v_dr_cr_flag,
                    v_encr_pan,
                    v_proxunumber,
                    p_rvsl_code,
                    v_acct_number,
                    round(decode(p_resp_code, '00', v_upd_amt, v_acct_balance),2),
                    round(decode(p_resp_code, '00', v_upd_ledger_bal,v_ledger_bal),2),
                    v_resp_cde,
                    sysdate,
                    1,
                    v_applpan_cardstat,
                    v_fee_plan,
                    v_err_msg,
                    v_feeattach_type,
                    p_merchant_name,
                    p_merchant_city,
                    p_merchant_state,
                    v_cam_type_code,
                    v_timestamp,
                    p_merchant_zip,
                    p_merchant_address,
                    p_merchant_id);
         
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
               AND vdt_card_type = v_prod_cattype
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
    
    P_CAPTURE_DATE := V_BUSINESS_DATE;

  IF  P_RULES ='B' THEN
             P_AUTH_ID := V_TOTAL_FEE;
     else
            P_AUTH_ID := V_AUTH_ID;
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
EXCEPTION
    WHEN EXP_REJECT_RECORD                             -- ADDED BY SAGAR ON 08-SEP-2012
    THEN
        P_RESP_CODE := V_RESP_CDE;
        P_RESP_MSG := V_GL_ERR_MSG;
    WHEN OTHERS
    THEN
        ROLLBACK;
        P_RESP_CODE := '99';
        P_RESP_MSG :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END;
/
show error