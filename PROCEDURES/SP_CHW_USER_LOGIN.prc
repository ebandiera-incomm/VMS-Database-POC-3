set define off;
CREATE OR REPLACE PROCEDURE VMSCMS.SP_CHW_USER_LOGIN ( 
                          P_INST_CODE                  IN  NUMBER ,
                          P_PAN_CODE                   IN  VARCHAR2,
                          P_DELIVERY_CHANNEL           IN  VARCHAR2,
                          P_TXN_CODE                   IN  VARCHAR2,
                          P_RRN                        IN  VARCHAR2,
                          P_USERNAME                   IN  VARCHAR2,
                          P_PASSWORD                   IN  VARCHAR2,
                          P_TXN_MODE                   IN  VARCHAR2,
                          P_TRAN_DATE                  IN  VARCHAR2,
                          P_TRAN_TIME                  IN  VARCHAR2,
                          P_IPADDRESS                  IN  VARCHAR2,
                          P_CURR_CODE                  IN  VARCHAR2,
                          P_RVSL_CODE                  IN  VARCHAR2,
                          P_BANK_CODE                  IN  VARCHAR2,
                          P_MSG                        IN  VARCHAR2,
                          P_APPL_ID                    IN  VARCHAR2 ,
                          P_RESP_CODE                  OUT VARCHAR2 ,
                          P_RESMSG                     OUT VARCHAR2 ,
                          P_STATUS                     OUT VARCHAR2,
                          P_CUSTOMERID                 OUT NUMBER,
                          P_CARD_STATUS                OUT VARCHAR2,
                          P_EXP_DATE                   OUT VARCHAR2,
                          P_LAST_USED                  OUT VARCHAR2,
                          P_ACTIVE_DATE                OUT VARCHAR2,
                          P_CARD4DIGT                  OUT VARCHAR2,
                          P_FIRSTNAME                  OUT VARCHAR2,
                          P_LASTNAME                   OUT VARCHAR2,
                          P_SPENDING_ACCT_NO           OUT VARCHAR2,
                          P_SAVINGSS_ACCT_NO           OUT VARCHAR2,
                          P_SAVING_ACCT_INFO           OUT NUMBER,
                          P_ADDRESS_VERIFIED_FLAG      OUT VARCHAR2,
                          P_EXPIRY_DAYS                OUT VARCHAR2,
                          P_SHIPPED_DATE               OUT VARCHAR2,
                          P_logonmessage               OUT VARCHAR2,
                          P_SPENDINGAVAILBAL           OUT VARCHAR2,
                          P_SAVAVAILBAL                OUT VARCHAR2,
                          P_TANDC_VERSION              OUT VARCHAR2,
                          P_TANDC_FLAG                 OUT VARCHAR2,
                          P_SAVREOPEN_DATE             OUT VARCHAR2,
                          P_SAVINGACCT_STATUS          OUT VARCHAR2,
                          P_SAVINGSACCT_CREATION_DATE  out VARCHAR2,
                          p_AVAILED_TXN                OUT NUMBER,
                          p_AVAILABLE_TXN              OUT NUMBER,
                          p_cvvplus_token              OUT VARCHAR2,
                          p_cvvplus_eligibility        OUT VARCHAR2,
                          p_cvvplus_regflag            OUT VARCHAR2,
                          p_cvvplus_activeflag         OUT VARCHAR2,
                          p_cvvplus_accountid          OUT VARCHAR2,
                          p_cvvplus_regid              OUT VARCHAR2,
                          p_business_name              OUT VARCHAR2
                          )
AS
/*****************************************************************************************
     * Created Date     : 07-Sep-2012
     * Created By       : Ramesh.A
     * PURPOSE          : User Login Authentication and Getting Customer details using Username
     * Modified By      :  Saravanakumar
     * Modified Date    :  11-Feb-2013
     * Modified Reason  :  For CR - 40 in release 23.1.1
     * Modified By     :  Sachin P.
     * Modified Date    :  27-Feb-2013
     * Modified Reason  :  Remove SQLERRM for proper error message
     * Reviewer         :  Dhiraj

     * Modified By      :  Saravanakumar
     * Modified Date    :  04-Mar-2013
     * Modified Reason  :  Included release 23 changes
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  04-Mar-2013
     * Build Number     :  CMS3.5.1_RI0023.2_B0020

     * modified by      :  RAVI N
     * modified Date    :  09-AUG-13
     * modified reason  :  logging P_USERNAME in cms_transaction_log_dtl
     * modified reason  :  FSS-1144
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  29-AUG-13
     * Build Number     :  RI0024.4_B0006

     * Modified By      : Sai Prasad
     * Modified Date    : 11-Sep-2013
     * Modified For     : Mantis ID: 0012278 (JIRA FSS-1144)
     * Modified Reason  : IP Address is not logged in transactionlog table.
     * Reviewer         : Dhiraj
     * Reviewed Date    : 11-Sep-2013
     * Build Number     : RI0024.4_B0010

     * Modified By      : Sagar More
     * Modified Date    : 26-Sep-2013
     * Modified For     : LYFEHOST-63
     * Modified Reason  : To fetch saving acct parameter based on product code
     * Reviewer         : Dhiraj
     * Reviewed Date    : 28-Sep-2013
     * Build Number     : RI0024.5_B0001

     * Modified By      : Sagar More
     * Modified Date    : 16-OCT-2013
     * Modified For     : review observation changes for LYFEHOST-63
     * Reviewer         : Dhiraj
     * Reviewed Date    : 16-OCT-2013
     * Build Number     : RI0024.6_B0001

     * Modified Date    : 08-JAN-2014
     * Modified By      : MageshKumar S
     * Modified for     : Defect ID MVCHW-489
     * Modified reason  : Customer Not Allowed to Login to CHW.
     * Reviewer         : Dhiraj
     * Reviewed Date    : 08-JAN-2014
     * Release Number   : RI0027_B0003

    * Modified Date    : 10-Dec-2013
    * Modified By      : Sagar More
    * Modified for     : Defect ID 13160
    * Modified reason  : To log below details in transactinlog if applicable
                         Acct_type ,productcode,categoryid,dr_cr_dlag
    * Reviewer         : Dhiraj
    * Reviewed Date    : 10-Dec-2013
    * Release Number   : RI0027_B0004

     * Modified By      : DINESH B.
     * Modified Date    : 18-Feb-2014
     * Modified Reason  : MVCSD-4121 and FWR-043 : Fetching address verified flag, expiry days and shipped date for the customer.
     * Reviewer         : Dhiraj
     * Reviewed Date    : 10-Mar-2014
     * Build Number     : RI0027.2_B0002

     * Modified By      : Ramesh A
     * Modified Date    : 13-JAN-2015
     * Modified Reason  : Defect id 15991

     * Modified By      : Ramesh A
     * Modified Date    : 29-JAN-2015
     * Modified Reason  : Defect id :16010
     * Build Number     : RI0027.4.3.1_B0002

     * Modified By      : Pankaj S.
     * Modified Date    : 24-Feb-2015
     * Modified For     : 2.4.2.4.4 PERF Changes integration
     * Reviewer         : Sarvanankumar
     * Build Number     : RI0027.4.3.3_B0001
     * Modified By      : Siva Kumar M
     * Modified Date    : 06-Mar-2015
     * Modified for     : DFCTNM-35
     * Reviewer         : Sarvanankumar
     * Reviewed Date    : 06-Mar-2015
     * Build Number     : VMSGPRHOSTCSD_3.0_B0001

     * Modified By      : Siva Kumar M
     * Modified Date    : 09-Mar-2015
     * Modified for     : review changes
     * Reviewer         : Pankaj S
     * Reviewed Date    : 09-Mar-2015
     * Build Number     : VMSGPRHOSTCSD_3.0_B0001

     * Modified By      : Siva Kumar M
     * Modified Date    : 24-Mar-2015
     * Modified for     : DFCTNM-35
     * Reviewer         : Pankaj S
     * Reviewed Date    : 24-Mar-2015
     * Build Number     : VMSGPRHOSTCSD_3.0_B0001

     * Modified By      : Siva Kumar M
     * Modified Date    : 31-Mar-2015
     * Modified for     : DFCTNM-35(Aditional changes)
     * Reviewer         : Pankaj S
     * Reviewed Date    : 31-Mar-2015
     * Build Number     : VMSGPRHOSTCSD_3.0_B0003

     * Modified by      : Pankaj S.
     * Modified for     : Transactionlog Functional Removal
     * Modified Date    : 14-May-2015
     * Reviewer         :  Saravanankumar
     * Build Number     : VMSGPRHOAT_3.0.3_B0001
     * Modified by      : Siva Kumar M
     * Modified for     : FSS-2279(Savings account changes)
     * Modified Date    : 31-Aug-2015
     * Reviewer         :  Saravanankumar
     * Build Number     : VMSGPRHOAT_3.1.1_B0007

     * Modified by      : Siva Kumar M
     * Modified for     : Mantis id:0016187
     * Modified Date    : 07-Sept-2015
     * Reviewer         :  Saravanankumar
     * Build Number     : VMSGPRHOAT_3.1.1_B0009

     * Modified by      : MageshKumar S
     * Modified Date    : 23-Oct-2015
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_3.1.2

     * Modified by      : Siva Kumar
     * Modified Date    : 27-Oct-2015
     * Modified for     : FSS-3721
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_3.1.1.1

     * Modified by      : Ramesh A
     * Modified Date    : 27-Nov-2015
     * Modified for     : Savings Account changes(added response tags)
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_3.2.1

   * Modified by          : Sivakaminathan
   * Modified Date        : 10-JAN-16
   * Modified For         : Mantis id 0016232
   * Reviewer             : Saravans kumar
   * Build Number         : VMSGPRHOSTCSD3.3


   * Modified by          : Siva Kumar M
   * Modified Date        : 13-June-16
   * Modified For         : Savings Account changes(avilable count reset)
   * Reviewer             : Saravans kumar
   * Build Number         : VMSGPRHOSTCSD_4.2

   * Modified by      : Pankaj S.
   * Modified for     : CVV+ changes
   * Modified Date    : 18-April-2017
   * Reviewer         :  Saravanankumar
   * Build Number     : VMSGPRHOST_17.04

   * Modified by      : Sai Prasad
   * Modified for     : FSS-5130
   * Modified Date    : 18-May-2017
   * Reviewer         : Saravanan Kumar
   * Build Number     : VMSGPRHOST_17.05


	 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07

     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01

     * Modified By      : VINI PUSHKARAN
     * Modified Date    : 01-MAR-2019
     * Purpose          : VMS-809(Decline Request for Web-account Username if Username is Already Taken)
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R13_B0002
     
    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-17-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
********************************************************************************************/

V_RRN_COUNT             NUMBER;
V_ERRMSG                TRANSACTIONLOG.ERROR_MSG%TYPE;
V_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_ENCR_PAN_FROM         CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
V_CUST_CODE             CMS_PAN_ACCT.CPA_CUST_CODE%TYPE;
V_TXN_TYPE              TRANSACTIONLOG.TXN_TYPE%TYPE;
V_CARD_EXPRY            VARCHAR2(20);
V_STAN                  CMS_TRANSACTION_LOG_DTL.CTD_SYSTEM_TRACE_AUDIT_NO%TYPE;
V_CAPTURE_DATE          TRANSACTIONLOG.DATE_TIME%TYPE;
V_TERM_ID               TRANSACTIONLOG.TERMINAL_ID%TYPE;
V_MCC_CODE              TRANSACTIONLOG.MCCODE%TYPE;
V_TXN_AMT               CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
V_AUTH_ID               TRANSACTIONLOG.AUTH_ID%TYPE;
V_CUST_ID               CMS_CUST_MAST.CCM_CUST_ID%TYPE;
V_STARTERCARD_FLAG      CMS_APPL_PAN.CAP_STARTERCARD_FLAG%TYPE;
V_CARD_STAT             CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
V_MBR_NUMB              CMS_APPL_PAN.CAP_MBR_NUMB%TYPE  DEFAULT '000';
V_DR_CR_FLAG            CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
V_OUTPUT_TYPE           CMS_TRANSACTION_MAST.CTM_OUTPUT_TYPE%TYPE;
V_TRAN_TYPE             CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
V_CARDSTATUS            CMS_CARD_STAT.CCS_STAT_DESC%TYPE;
V_ACCT_TYPE             CMS_ACCT_TYPE.CAT_TYPE_CODE%TYPE;
V_SWITCH_ACCT_TYPE      CMS_ACCT_TYPE.CAT_SWITCH_TYPE%TYPE DEFAULT '22';
V_TRANS_DESC            CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
V_LAST_UPDATEDATE       CMS_ACCT_MAST.CAM_LUPD_DATE%TYPE;
V_ACCT_STATUS           CMS_ACCT_MAST.CAM_STAT_CODE%TYPE;
V_SWITCH_ACCT_STATS     CMS_ACCT_STAT.CAS_SWITCH_STATCODE%TYPE DEFAULT '2';
V_STATUS_CODE           CMS_ACCT_MAST.CAM_STAT_CODE%TYPE;
V_REOPEN_PERIOD         CMS_DFG_PARAM.CDP_PARAM_VALUE%TYPE;
V_HASHKEY_ID            CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE;
V_TIME_STAMP            TRANSACTIONLOG.TIME_STAMP%TYPE;
V_CAP_PROD_CODE         CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
V_DATE_CHK              DATE;
V_CARD_TYPE             CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
V_ACCT_BAL              CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
V_LEDGER_BAL            CMS_ACCT_MAST.CAM_LEDGER_BAL%TYPE;
V_RENEWAL_DATE          CMS_CARDRENEWAL_HIST.CCH_RENEWAL_DATE%TYPE;
V_EXPIRY_DATE           cms_appl_pan.cap_expry_date%type;
V_GPR_FLAG              NUMBER;
V_WRNG_COUNT            CMS_CUST_MAST.CCM_WRONG_LOGINCNT%TYPE;
V_WRONG_PWDCUNT         CMS_PROD_CATTYPE.CPC_WRONG_LOGONCOUNT%TYPE;
V_UNLOCK_WAITTIME       CMS_PROD_CATTYPE.CPC_ACCTUNLOCK_DURATION%TYPE;
V_ACCTLOCK_FLAG         CMS_CUST_MAST.CCM_ACCTLOCK_FLAG%TYPE;
V_TIME_DIFF             NUMBER;
v_gpresign_optinflag    cms_optin_status.COS_GPRESIGN_OPTINFLAG%TYPE;
V_MIN_TRAN_AMT          CMS_DFG_PARAM.CDP_PARAM_VALUE%TYPE;
V_CPP_TANDC_VERSION     CMS_PROD_CATTYPE.CPC_TANDC_VERSION%TYPE;
V_CCM_TANDC_VERSION     CMS_CUST_MAST.CCM_TANDC_VERSION%TYPE;
V_CAM_LUPD_DATE         CMS_ACCT_MAST.cam_lupd_date%TYPE;
--Added on 27/11/15
V_DFG_CNT               NUMBER(10);
V_MAX_SVG_TRNS_LIMT     NUMBER(10);
V_HASH_PASSWORD         CMS_CUST_MAST.CCM_PASSWORD_HASH%TYPE;
V_ENCRYPT_ENABLE        CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
V_ENCR_USERNAME         CMS_CUST_MAST.CCM_USER_NAME%TYPE;
EXP_AUTH_REJECT_RECORD  EXCEPTION;
EXP_REJECT_RECORD       EXCEPTION;
v_Retperiod  date;  --Added for VMS-5733/FSP-991
v_Retdate  date; --Added for VMS-5733/FSP-991


   CURSOR c (p_prod_code cms_prod_mast.cpm_prod_code%type,p_card_type cms_appl_pan.cap_card_type%type)
   IS
      SELECT cdp_param_key, cdp_param_value
        FROM cms_dfg_param
       WHERE cdp_inst_code = p_inst_code
       AND   cdp_prod_code = p_prod_code
       and  cdp_card_type = p_card_type
       and   cdp_param_key in ('InitialTransferAmount','MaxNoTrans','Saving account reopen period');

--En Getting DFG Parameters

BEGIN
   V_TXN_TYPE := '1';
   V_TIME_STAMP :=SYSTIMESTAMP;
       --Sn Get the HashPan
       BEGIN
          V_HASH_PAN := GETHASH(P_PAN_CODE);
        EXCEPTION
          WHEN OTHERS THEN
         P_RESP_CODE     := '12';
         V_ERRMSG := 'Error while converting into hash pan ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;
      --En Get the HashPan

      --Sn Create encr pan
        BEGIN
          V_ENCR_PAN_FROM := FN_EMAPS_MAIN(P_PAN_CODE);
          EXCEPTION
          WHEN OTHERS THEN
            P_RESP_CODE     := '12';
            V_ERRMSG := 'Error while converting into encrypt pan ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
        END;

     --Start Generate HashKEY value for regarding FSS-1144
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_PAN_CODE||P_RRN||to_char(V_TIME_STAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        P_RESP_CODE := '21';
        V_ERRMSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
       END;

    --End Generate HashKEY value for regarding FSS-1144



      Begin

       select to_Date(substr(P_TRAN_DATE,1,8),'yyyymmdd')
       into v_date_chk
       from dual;

      exception when others
      then
        P_RESP_CODE := '21';
        V_ERRMSG := 'Invalid transaction date '||P_TRAN_DATE;
        RAISE EXP_REJECT_RECORD;
      End;

     --EN: Added as per review observation for LYFEHOST-63

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
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE
          and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
     else   --Added for VMS-5733/FSP-991
          SELECT COUNT(1)
          INTO V_RRN_COUNT
          FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE AND INSTCODE=P_INST_CODE
          and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; 
      end if;    
           IF V_RRN_COUNT    > 0 THEN
            P_RESP_CODE     := '22';
            V_ERRMSG      := 'Duplicate RRN on ' || P_TRAN_DATE;
            RAISE EXP_REJECT_RECORD;
          END IF;
         EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
            RAISE;
            WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Problem while selecting TRANSACTIONLOG ' ||
                SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
       --En Duplicate RRN Check


  --Sn find debit and credit flag
    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,CTM_TRAN_DESC
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,V_TRANS_DESC
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       P_RESP_CODE := '12'; --Ineligible Transaction
       V_ERRMSG  := 'Transflag  not defined for txn code ' ||
                  P_TXN_CODE || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       P_RESP_CODE := '21'; --Ineligible Transaction
       V_ERRMSG  := 'Error while selecting transaction details '||substr(sqlerrm,1,100);
       RAISE EXP_REJECT_RECORD;
    END;



          BEGIN
     SELECT TO_CHAR(CAP.CAP_ACTIVE_DATE, 'MM/DD/YYYY HH24MISS'),
                 TO_CHAR(CAP.CAP_EXPRY_DATE, 'MM/YY'),
                 CAP.CAP_CARD_STAT,CAP_ACCT_NO,
                 CAP_PROD_CODE, CAP_EXPRY_DATE ,cap_cust_code,
                 cap_card_type, DECODE(NVL(cap_cvvplus_reg_flag,'N'),'N','No','Yes'),  DECODE (NVL(cap_cvvplus_active_flag,'N'),'N','No','Yes')
             INTO P_ACTIVE_DATE, P_EXP_DATE, P_CARD_STATUS , P_SPENDING_ACCT_NO,
                  v_cap_prod_code , V_EXPIRY_DATE ,V_CUST_CODE ,
                  v_card_type, p_cvvplus_regflag,  p_cvvplus_activeflag
             FROM CMS_APPL_PAN CAP
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
                 CAP_MBR_NUMB = V_MBR_NUMB AND
                 CAP_INST_CODE = P_INST_CODE;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'No data found while selecting customer master details for card number ';
         RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
               P_RESP_CODE := '12';
               V_ERRMSG  := 'Error while selecting data from customer master details for card number ' ||SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

    END;

   --Sn Added for CVV plus changes
    BEGIN
       SELECT DECODE(NVL (cpc_cvvplus_eligibility, 'N'),'N','No','Yes'),CPC_WRONG_LOGONCOUNT-1,
                CPC_ACCTUNLOCK_DURATION,
                CPC_TANDC_VERSION,upper(CPC_ENCRYPT_ENABLE)
         INTO p_cvvplus_eligibility,V_WRONG_PWDCUNT,
                V_UNLOCK_WAITTIME,
                V_CPP_TANDC_VERSION,V_ENCRYPT_ENABLE
         FROM cms_prod_cattype
        WHERE     cpc_inst_code = p_inst_code
              AND cpc_prod_code = v_cap_prod_code
              AND cpc_card_type = v_card_type;
    EXCEPTION
       WHEN OTHERS
       THEN
          p_resp_code := '12';
          v_errmsg :=
             'Error while selecting cvvplus_eligibility from cms_prod_cattype : '
             || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;

    IF p_cvvplus_eligibility='Yes' AND p_cvvplus_regflag='Yes' THEN
        BEGIN
           SELECT vci_cvvplus_token,
                  vci_cvvplus_accountid,
                  vci_cvvplus_registration_id
             INTO p_cvvplus_token, p_cvvplus_accountid, p_cvvplus_regid
             FROM vms_cvvplus_info
            WHERE VCI_CVVPLUS_ACCT_NO = p_spending_acct_no;
        EXCEPTION
           WHEN OTHERS
           THEN
              p_resp_code := '12';
              v_errmsg :=
                 'Error while selecting cvvplus_info : ' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;

    END IF;

--       --Sn Get the HashPassword
       BEGIN
          V_HASH_PASSWORD := GETHASH(trim(P_PASSWORD));
        EXCEPTION
          WHEN OTHERS THEN
         P_RESP_CODE     := '12';
         V_ERRMSG := 'Error while converting password ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;
--      --En Get the HashPassword


         begin

            select nvl(CCM_WRONG_LOGINCNT,'0'),
                   nvl(CCM_ACCTLOCK_FLAG,'N'),
                 ROUND((sysdate- nvl(ccm_last_logindate,sysdate))*24*60),
                 NVL(decode(v_encrypt_enable,'Y',fn_dmaps_main(CCM.ccm_first_name),CCM.ccm_first_name), ' '),
                 NVL(decode(v_encrypt_enable,'Y',fn_dmaps_main(CCM.ccm_last_name),CCM.ccm_last_name), ' '),
                 CCM_TANDC_VERSION,
                NVL(CCM_BUSINESS_NAME,' ')
                 INTO v_wrng_count,
                  v_acctlock_flag,
                  v_time_diff, P_FIRSTNAME, P_LASTNAME,
                  V_CCM_TANDC_VERSION, P_BUSINESS_NAME
                  FROM CMS_CUST_MAST CCM
                  WHERE ccm_cust_code=V_CUST_CODE
                  AND ccm_inst_code=P_INST_CODE;

           EXCEPTION
           WHEN OTHERS THEN

               P_RESP_CODE     := '12';
               V_ERRMSG := 'Error while getting customer details ' || SUBSTR(SQLERRM, 1, 200);

         RAISE EXP_REJECT_RECORD;

         end;


        IF  V_CCM_TANDC_VERSION = V_CPP_TANDC_VERSION THEN

        P_TANDC_FLAG :='0';

        ELSE

        P_TANDC_FLAG := '1';

        END IF;
       P_TANDC_VERSION :=V_CPP_TANDC_VERSION;

          if  (v_acctlock_flag ='L' and  v_time_diff < V_UNLOCK_WAITTIME) and (V_WRONG_PWDCUNT is not null and  V_UNLOCK_WAITTIME is not  null)   then

              P_RESP_CODE := '224';
              V_ERRMSG  := 'User id is locked.Please try after'||V_UNLOCK_WAITTIME||' minutes';
               P_logonmessage  := (V_WRONG_PWDCUNT+1);
              RAISE EXP_REJECT_RECORD;

          end if;

             --St User Authentication
               BEGIN





                   IF  v_encrypt_enable = 'Y' THEN
                       v_encr_username:= fn_emaps_main(upper(trim(p_username)));
                     ELSE
                       v_encr_username:= upper(trim(p_username));
                  END IF;

				  SELECT
				  --CCM_CUST_CODE ,                 -- Modified for Decline Request for Web-account Username if Username is Already Taken(VMS-809)
					CCM_CUST_ID ,
					CCM_ADDRVERIFY_FLAG
				  INTO
				  --V_CUST_CODE ,                   -- Modified for Decline Request for Web-account Username if Username is Already Taken(VMS-809)
					V_CUST_ID ,
					P_ADDRESS_VERIFIED_FLAG
				  FROM CMS_CUST_MAST
				  WHERE CCM_INST_CODE=P_INST_CODE
				  AND CCM_CUST_CODE  = V_CUST_CODE -- Modified for Decline Request for Web-account Username if Username is Already Taken(VMS-809)
	              AND UPPER(CCM_USER_NAME)=v_encr_username AND CCM_PASSWORD_HASH=V_HASH_PASSWORD
	              AND CCM_INST_CODE=P_INST_CODE
	              AND CCM_APPL_ID =P_APPL_ID ;

               EXCEPTION WHEN NO_DATA_FOUND
               THEN

                if V_WRONG_PWDCUNT is not null and  V_UNLOCK_WAITTIME is not  null then

                  if  v_wrng_count < V_WRONG_PWDCUNT  and v_time_diff < V_UNLOCK_WAITTIME  then

                       BEGIN

                            SP_UPDATE_USERID ( P_INST_CODE, V_CUST_CODE,v_acctlock_flag,'U', V_ERRMSG );

                            IF   V_ERRMSG='OK' THEN
                                P_RESP_CODE := '114';
                                  V_ERRMSG  := 'Invalid Username or Password ';
                                 p_logonmessage  := (V_WRONG_PWDCUNT - v_wrng_count);
                                RAISE EXP_REJECT_RECORD;
                          end if;
                                 P_RESP_CODE := '21';
                                 RAISE EXP_REJECT_RECORD;

                          --end if;


                         EXCEPTION

                          WHEN EXP_REJECT_RECORD THEN

                          RAISE;

                          WHEN OTHERS THEN

                           P_RESP_CODE := '21';
                           V_ERRMSG  := 'Error from while updating user wrong count,acct flag ' ||
                           SUBSTR(SQLERRM, 1, 200);
                           RAISE EXP_REJECT_RECORD;


                         END;


                elsif v_wrng_count = V_WRONG_PWDCUNT  and  v_time_diff < V_UNLOCK_WAITTIME  then


                 BEGIN


                   SP_UPDATE_USERID ( P_INST_CODE, V_CUST_CODE,'L','U' ,V_ERRMSG );

                  IF   V_ERRMSG='OK' THEN
                       P_RESP_CODE := '224';
                        V_ERRMSG  := 'User id is locked.Please try after'||V_UNLOCK_WAITTIME||' minutes';
                         P_logonmessage  := (V_WRONG_PWDCUNT+1);
                       RAISE EXP_REJECT_RECORD;
                  end if;
                       P_RESP_CODE := '21';
                       RAISE EXP_REJECT_RECORD;

                  --end if;


                 EXCEPTION

                  WHEN EXP_REJECT_RECORD THEN

                  RAISE;

                  WHEN OTHERS THEN

                   P_RESP_CODE := '21';
                   V_ERRMSG  := 'Error from while updating user wrong count,acct flag ' ||
                        SUBSTR(SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
                   END;
                else -- customer has given invlaid user crendenital even after the waitting time ....

                      BEGIN

                          SP_UPDATE_USERID ( P_INST_CODE, V_CUST_CODE,'N','R', V_ERRMSG );

                         IF V_ERRMSG='OK' THEN
                          P_RESP_CODE := '114';
                             V_ERRMSG  := 'Invalid Username or Password ';
                             P_logonmessage  :=  V_WRONG_PWDCUNT;
                           RAISE EXP_REJECT_RECORD;
                         end if;

                           P_RESP_CODE := '21';
                           RAISE EXP_REJECT_RECORD;
                       --end if;

                        EXCEPTION

                      WHEN EXP_REJECT_RECORD THEN

                      RAISE;

                      WHEN OTHERS THEN

                       P_RESP_CODE := '21';
                       V_ERRMSG  := 'Error from while updating user wrong count,acct flag ' ||
                            SUBSTR(SQLERRM, 1, 200);
                      RAISE EXP_REJECT_RECORD;


                      END;
                 end if;
                else

                  P_RESP_CODE := '114';
                  V_ERRMSG  := 'Invalid Username or Password ';
                  RAISE EXP_REJECT_RECORD;


                 end if;


               WHEN EXP_REJECT_RECORD THEN
                 RAISE EXP_REJECT_RECORD;
               WHEN OTHERS THEN
                   P_RESP_CODE := '21';
                   V_ERRMSG  := 'Error from while Authenticate user ' ||
                        SUBSTR(SQLERRM, 1, 200);
                 RAISE EXP_REJECT_RECORD;

               END;



       IF V_WRONG_PWDCUNT is not null and  V_UNLOCK_WAITTIME is not  null THEN

          begin


          update cms_cust_mast set CCM_WRONG_LOGINCNT=0,CCM_LAST_LOGINDATE='',CCM_ACCTLOCK_FLAG='N'
              where ccm_cust_code=V_CUST_CODE and ccm_inst_code=P_INST_CODE;

               P_logonmessage := (V_WRONG_PWDCUNT+1);

            IF SQL%ROWCOUNT = 0 THEN

               P_RESP_CODE := '21';
               V_ERRMSG  := 'Error while updating cust master ' ||SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;

           end if;

           EXCEPTION
            when exp_reject_record then
            raise;
             WHEN OTHERS THEN
               P_RESP_CODE := '21';
                   V_ERRMSG  := 'Error from while Authenticate user ' ||
                        SUBSTR(SQLERRM, 1, 200);
                 RAISE EXP_REJECT_RECORD;

          end;

      END IF;

      --Sn call to authorize procedure
       BEGIN
        SP_AUTHORIZE_TXN_CMS_AUTH(P_INST_CODE,
                P_MSG,
                P_RRN,
                P_DELIVERY_CHANNEL,
                V_TERM_ID,
                P_TXN_CODE,
                P_TXN_MODE,
                P_TRAN_DATE,
                P_TRAN_TIME,
                P_PAN_CODE,
                P_BANK_CODE,
                V_TXN_AMT,
                NULL,
                NULL,
                V_MCC_CODE,
                P_CURR_CODE,
                NULL,
                NULL,
                NULL,
                P_SPENDING_ACCT_NO,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                V_CARD_EXPRY,
                V_STAN,
                V_MBR_NUMB,
                P_RVSL_CODE,
                V_TXN_AMT,
                V_AUTH_ID,
                P_RESP_CODE,
                V_ERRMSG,
                V_CAPTURE_DATE);
        IF P_RESP_CODE <> '00' AND V_ERRMSG <> 'OK' THEN
        RAISE EXP_AUTH_REJECT_RECORD;
        END IF;
      EXCEPTION
        WHEN EXP_AUTH_REJECT_RECORD THEN
          RAISE;
        WHEN OTHERS THEN
       P_RESP_CODE := '21';
       V_ERRMSG  := 'Error from Card authorization' ||
            SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
      END;


    IF P_ADDRESS_VERIFIED_FLAG ='1' THEN
        P_EXPIRY_DAYS  := TRUNC(V_EXPIRY_DATE - SYSDATE);
      END IF;
    IF P_ADDRESS_VERIFIED_FLAG ='0' THEN
    BEGIN
      SELECT cch_renewal_date
      INTO V_RENEWAL_DATE
      FROM cms_cardrenewal_hist
      WHERE CCH_INST_CODE= P_INST_CODE
      AND cch_pan_code   =V_HASH_PAN;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    NULL;
    WHEN OTHERS THEN
      P_RESP_CODE := '89';
      V_ERRMSG    := 'Error while selecting data from renewal history for card number'|| SUBSTR (SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
    END IF;


    IF P_ADDRESS_VERIFIED_FLAG ='0' AND V_RENEWAL_DATE IS NOT NULL THEN
    BEGIN
      SELECT ccs_shipped_date
      INTO P_SHIPPED_DATE
      FROM cms_cardissuance_status
      WHERE ccs_pan_code = V_HASH_PAN
      AND ccs_inst_code  = P_INST_CODE;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
             P_RESP_CODE := '21';
             V_ERRMSG    := 'No data found while selecting SHIPPED DATE';
              RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
            P_RESP_CODE := '21';
            V_ERRMSG  := 'while selecting SHIPPED DATE'|| SUBSTR (SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
      END;
    END IF;


    BEGIN
      SELECT COUNT(1),count(distinct cap_prod_code)
      INTO V_STARTERCARD_FLAG,V_GPR_FLAG
      FROM CMS_APPL_PAN
      WHERE CAP_CUST_CODE=V_CUST_CODE AND UPPER(CAP_STARTERCARD_FLAG) = 'N'
      AND CAP_INST_CODE=P_INST_CODE AND CAP_CARD_STAT not in('3','9');

     --St Added by ramesh.a for checking flag
      IF V_STARTERCARD_FLAG = '1' THEN

          SELECT CAP_CARD_STAT INTO V_CARD_STAT
          FROM CMS_APPL_PAN
          WHERE CAP_CUST_CODE=V_CUST_CODE AND UPPER(CAP_STARTERCARD_FLAG) = 'N'
          AND CAP_INST_CODE=P_INST_CODE AND CAP_CARD_STAT not in('3','9');


      END IF;
      --En Added by ramesh.a for checking flag

     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'No data found while selecting STARTERCARD STATUS ';
         RAISE EXP_REJECT_RECORD;
         WHEN TOO_MANY_ROWS THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'TOO MANY ROWS found while selecting STARTERCARD STATUS ';
         RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
         P_RESP_CODE := '21';
         V_ERRMSG  := 'Error from while selecting STARTERCARD STATUS ' ||
              SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;

    END;


    BEGIN

    SELECT nvl(cos_gpresign_optinflag,'0')
    INTO  v_gpresign_optinflag
    FROM cms_optin_status
    WHERE  cos_cust_id=V_CUST_ID;

    EXCEPTION

      WHEN  NO_DATA_FOUND THEN
      v_gpresign_optinflag :='0';

      WHEN  OTHERS THEN

          P_RESP_CODE := '21';
          V_ERRMSG  := 'Error from while selecting GPR T and C' ||
                  SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;

     END;




      P_RESP_CODE := 1;
      V_ERRMSG := 'Successful';
      P_CUSTOMERID := V_CUST_ID;

     IF V_STARTERCARD_FLAG = '0' THEN     --GPR Card not present  -- Modified by ramesh.a for checking 0 instead of 'Y'

       P_STATUS := '2';

     ELSIF V_STARTERCARD_FLAG = '1' THEN  --GPR Card present  -- Modified by ramesh.a for checking 1 instead of 'N'

        IF V_CARD_STAT = '0' THEN --GPR Card not activated
          P_STATUS := '1';

        ELSIF v_gpresign_optinflag = '0' THEN

         P_STATUS := '3';   -- Active GPR Card and GPR T& C not accpted.
        ELSE
         P_STATUS := '0';

        END IF;

     ELSE

      IF V_GPR_FLAG > 1 THEN

          SELECT count(CAP_CARD_STAT) INTO V_CARD_STAT
          FROM CMS_APPL_PAN
          WHERE CAP_CUST_CODE=V_CUST_CODE AND UPPER(CAP_STARTERCARD_FLAG) = 'N'
          AND CAP_INST_CODE=P_INST_CODE AND CAP_CARD_STAT ='0';

           IF V_CARD_STAT <> '0' THEN
              P_STATUS := '1';   --GPR Card present and not Activated
            ELSIF v_gpresign_optinflag = '0' THEN

           P_STATUS := '3';   -- Active GPR Card and GPR T& C not accpted.
           ELSE
              P_STATUS := '0';  --GPR card Present and activated.
           END IF;

      else

         P_RESP_CODE := '160';
         V_ERRMSG  := 'Customer have more than one GPR card';
         RAISE EXP_REJECT_RECORD;

      END IF;



     END IF;

      P_LAST_USED := TO_CHAR(sysdate,'MM/DD/YYYY');

            P_CARD4DIGT := (SUBSTR(P_PAN_CODE, LENGTH(P_PAN_CODE) - 3, LENGTH(P_PAN_CODE)));
      IF P_CARD_STATUS = '0' THEN

         IF P_ACTIVE_DATE IS NULL --V_COUNT = 0
         THEN

                 P_RESMSG := 'INACTIVE';

               ELSE

          P_RESMSG := 'BLOCKED';

         END IF;
      ELSE

        BEGIN

               SELECT CCS_STAT_DESC
               INTO V_CARDSTATUS
               FROM CMS_CARD_STAT
               WHERE CCS_STAT_CODE = P_CARD_STATUS AND
                   CCS_INST_CODE = P_INST_CODE;

        exception WHEN OTHERS THEN
            P_RESP_CODE := '12';
            V_ERRMSG  := 'Error while selecting card status '||SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
        END;

             P_RESMSG := V_CARDSTATUS;
      END IF;


         BEGIN
             SELECT  CAM_ACCT_BAL
                INTO P_SPENDINGAVAILBAL
                FROM CMS_ACCT_MAST
               WHERE CAM_INST_CODE = P_INST_CODE
                 AND CAM_ACCT_NO = p_spending_acct_no;


         EXCEPTION
         WHEN NO_DATA_FOUND THEN
                        P_RESP_CODE := '21';
                        V_ERRMSG    := 'Error while selecting account balance';
                        RAISE EXP_REJECT_RECORD;
                    WHEN OTHERS THEN
                        P_RESP_CODE := '21';
                        V_ERRMSG    := 'Error while selecting  acct bal ' ||  SUBSTR(SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;

         END;
               BEGIN
                  SELECT CAT_TYPE_CODE
                    INTO V_ACCT_TYPE
                    FROM CMS_ACCT_TYPE
                   WHERE CAT_INST_CODE = P_INST_CODE
                     AND CAT_SWITCH_TYPE = V_SWITCH_ACCT_TYPE;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     P_RESP_CODE := '21';
                     V_ERRMSG := 'Acct type not defined in master(Savings)';
                     RAISE  EXP_REJECT_RECORD;
                  WHEN OTHERS
                  THEN
                     P_RESP_CODE := '12';
                     V_ERRMSG :=
                           'Error while selecting accttype(Savings) '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE  EXP_REJECT_RECORD;
               END;

                BEGIN
                  SELECT CAM_ACCT_NO,
                         CAM_STAT_CODE,
                         CAM_LUPD_DATE ,
                         to_char(CAM_ACCT_BAl,'99999999999999990.99') ,
                         CAM_LUPD_DATE ,
                         to_char(CAM_CREATION_DATE,'MMDDYYYY'),
                         case when sysdate >CAM_SAVTOSPD_TFER_DATE then 0  else NVL(CAM_SAVTOSPD_TFER_COUNT,0) end
                    INTO P_SAVINGSS_ACCT_NO,
                         V_STATUS_CODE,
                         V_LAST_UPDATEDATE ,
                         P_SAVAVAILBAL,
                         V_CAM_LUPD_DATE,
                         P_SAVINGSACCT_CREATION_DATE,
                         P_AVAILED_TXN
                    FROM CMS_ACCT_MAST
                   WHERE CAM_ACCT_ID IN (
                            SELECT CCA_ACCT_ID
                              FROM CMS_CUST_ACCT
                             WHERE CCA_CUST_CODE = V_CUST_CODE
                               AND CCA_INST_CODE = P_INST_CODE)
                     AND CAM_TYPE_CODE = V_ACCT_TYPE
                     AND CAM_INST_CODE = P_INST_CODE;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                 THEN

                   P_AVAILED_TXN :=0;
                 WHEN OTHERS
                 THEN
                     P_RESP_CODE := '12';
                     V_ERRMSG :=
                          'Error while selecting savings acc number '
                       || SUBSTR (SQLERRM, 1, 200);
                       RAISE  EXP_REJECT_RECORD;
               END;


   v_dfg_cnt:=0;
   BEGIN
      FOR i IN c (v_cap_prod_code,v_card_type)
      LOOP
         BEGIN
           IF i.cdp_param_key = 'InitialTransferAmount' THEN
               v_dfg_cnt:=v_dfg_cnt+1;
               V_MIN_TRAN_AMT := i.cdp_param_value;
            ELSIF i.cdp_param_key = 'MaxNoTrans' THEN
               v_dfg_cnt:=v_dfg_cnt+1;
               v_max_svg_trns_limt := i.cdp_param_value;
            ELSIF i.cdp_param_key = 'Saving account reopen period' THEN
                V_REOPEN_PERIOD := i.cdp_param_value;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '21';
               v_errmsg :='Error while selecting Saving account parameters ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END LOOP;

       IF v_dfg_cnt=0 THEN

        V_MIN_TRAN_AMT :=0;
        v_max_svg_trns_limt :=0;
        V_REOPEN_PERIOD :=0;
       END IF;
       P_AVAILABLE_TXN :=v_max_svg_trns_limt - P_AVAILED_TXN;
   EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :='Error while opening cursor C ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

        IF P_SAVINGSS_ACCT_NO IS NULL THEN
            P_SAVING_ACCT_INFO:='0';--Saving Account does not exists

              -- customer is eligible  for savings account or  not
                    IF   v_gpresign_optinflag = '0' OR  TO_NUMBER(P_SPENDINGAVAILBAL) < TO_NUMBER(V_MIN_TRAN_AMT) OR TO_NUMBER(V_MIN_TRAN_AMT) =0  THEN

                     P_SAVINGACCT_STATUS := 'NE';
                    ELSE
                      -- customer is eligible for savings account ....
                    P_SAVINGACCT_STATUS :='E';

                    END IF;

        ELSE
            P_SAVING_ACCT_INFO:='1';--Savings Account exists and open

            BEGIN
                 BEGIN
                    SELECT CAS_STAT_CODE
                    INTO V_ACCT_STATUS
                    FROM CMS_ACCT_STAT
                    WHERE CAS_INST_CODE = P_INST_CODE AND
                    CAS_SWITCH_STATCODE = V_SWITCH_ACCT_STATS;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        P_RESP_CODE := '21';
                        V_ERRMSG    := 'Acct stat not defined for  master';
                        RAISE EXP_REJECT_RECORD;
                    WHEN OTHERS THEN
                        P_RESP_CODE := '21';
                        V_ERRMSG    := 'Error while selecting V_ACCT_STATS ' ||  SUBSTR(SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
                END;

                IF V_ACCT_STATUS = V_STATUS_CODE THEN
                    P_SAVING_ACCT_INFO:='2';
                    P_SAVINGACCT_STATUS :='D';--2;--Savings Account closed and incase of closed its not exceeded the number of days for reopening (Not eligible for re-opening)

                  P_SAVREOPEN_DATE:=TO_CHAR(V_CAM_LUPD_DATE+V_REOPEN_PERIOD,'MM/DD/YYYY'); --Added on 27/11/15

                    IF SYSDATE - V_LAST_UPDATEDATE > V_REOPEN_PERIOD THEN
                        P_SAVING_ACCT_INFO:=3;--Savings Account closed and it can be reopened as its exceeded number of days for reopening  (Eligible for re-opening)
                    END IF;


                ELSE
                 P_SAVINGACCT_STATUS:='A';

                END IF;
            EXCEPTION
                WHEN EXP_REJECT_RECORD THEN
                    RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                    P_RESP_CODE := '21';
                    V_ERRMSG   := 'Error while selecting V_LAST_UPDATEDATE  ' ||  SUBSTR(SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
            END;
        END IF;


 P_SPENDINGAVAILBAL := TO_CHAR (P_SPENDINGAVAILBAL, '99999999999999990.99');


        BEGIN
          SELECT CMS_ISO_RESPCDE
          INTO P_RESP_CODE
          FROM CMS_RESPONSE_MAST
          WHERE CMS_INST_CODE      = P_INST_CODE
          AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
          AND CMS_RESPONSE_ID      = P_RESP_CODE;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
             P_RESP_CODE := '21';
             V_ERRMSG := 'Responce code not found '||P_RESP_CODE;
             RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          P_RESP_CODE := '69';
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          RAISE EXP_REJECT_RECORD;

        END;
      --En Get responce code fomr master

       --Sn update topup card number details in translog
        BEGIN

 --Added for VMS-5733/FSP-991
 IF (v_Retdate>v_Retperiod)
    THEN
          UPDATE TRANSACTIONLOG
          SET  RESPONSE_ID=P_RESP_CODE,
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG = V_ERRMSG,
               IPADDRESS=P_IPADDRESS
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;
        ELSE
          UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST  --Added for VMS-5733/FSP-991
          SET  RESPONSE_ID=P_RESP_CODE,
               ADD_LUPD_DATE=SYSDATE, ADD_LUPD_USER=1,
               ERROR_MSG = V_ERRMSG,
               IPADDRESS=P_IPADDRESS
          WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
           BUSINESS_TIME = P_TRAN_TIME AND  MSGTYPE = P_MSG AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE=P_INST_CODE;
      END IF;
          IF SQL%ROWCOUNT <> 1 THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog ' ||
                'no valid records ';
           RAISE EXP_REJECT_RECORD;
          END IF;

         EXCEPTION
         WHEN EXP_REJECT_RECORD THEN
               RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog ' ||
                SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
        END;
     --En update topup card number details in translog


       BEGIN
--Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';

--Added for VMS-5733/FSP-991
IF (v_Retdate>v_Retperiod)
    THEN            
              UPDATE CMS_TRANSACTION_LOG_DTL
             SET CTD_USER_NAME= v_encr_username
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
      ELSE--Added for VMS-5733/FSP-991
         UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST
             SET CTD_USER_NAME= v_encr_username
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
         END IF;             
              

             IF SQL%ROWCOUNT = 0 THEN
                V_ERRMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
                P_RESP_CODE := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;
             EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
                P_RESP_CODE := '21';
                V_ERRMSG  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
            END;


--Sn Handle EXP_REJECT_RECORD execption
EXCEPTION
WHEN EXP_AUTH_REJECT_RECORD THEN  --Added by Ramesh.A on 10/09/2012

            BEGIN
            
            --Added for VMS-5733/FSP-991
IF (v_Retdate>v_Retperiod)
    THEN  
              UPDATE CMS_TRANSACTION_LOG_DTL
              -- SET CTD_USER_NAME= P_USERNAME
             SET CTD_USER_NAME= v_encr_username
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
         ELSE   --Added for VMS-5733/FSP-991
                   UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST
              -- SET CTD_USER_NAME= P_USERNAME
             SET CTD_USER_NAME= v_encr_username
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
            END IF;  
                   

                 IF SQL%ROWCOUNT = 0 THEN
                    V_ERRMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL '||V_ERRMSG;
                    P_RESP_CODE := '21';
                 END IF;

            EXCEPTION


            WHEN OTHERS THEN
                P_RESP_CODE := '21';
                V_ERRMSG  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200)||' '||V_ERRMSG;
            END;


P_RESMSG := V_ERRMSG;
WHEN EXP_REJECT_RECORD THEN
 ROLLBACK;-- TO V_AUTH_SAVEPOINT;

   --Sn Get responce code fomr master
     BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = P_RESP_CODE;

        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          P_RESP_CODE := '69';
     END;
  --En Get responce code fomr master

    --SN : Added for 13160

    if V_DR_CR_FLAG is null
    then

        BEGIN
         SELECT CTM_CREDIT_DEBIT_FLAG
           INTO V_DR_CR_FLAG
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = P_TXN_CODE
          AND   CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
          AND   CTM_INST_CODE = P_INST_CODE;

        EXCEPTION WHEN OTHERS
        THEN
            null;
        END;
    end if;

    if v_cap_prod_code is null
    then

        BEGIN

         SELECT CAP_CARD_STAT,
                CAP_PROD_CODE,
                cap_card_type,
                cap_acct_no
         INTO   P_CARD_STATUS,
                v_cap_prod_code,
                v_card_type,
                p_spending_acct_no
         FROM CMS_APPL_PAN
         WHERE CAP_PAN_CODE = V_HASH_PAN
         AND   CAP_MBR_NUMB = V_MBR_NUMB
         AND   CAP_INST_CODE = P_INST_CODE;

        EXCEPTION WHEN OTHERS
        THEN
            null;
        END;

        BEGIN
              SELECT CAM_TYPE_CODE,CAM_ACCT_BAL,CAM_LEDGER_BAL
                INTO V_ACCT_TYPE,V_ACCT_BAL,V_LEDGER_BAL
                FROM CMS_ACCT_MAST
               WHERE CAM_INST_CODE = P_INST_CODE
                 AND CAM_ACCT_NO = p_spending_acct_no;
        EXCEPTION WHEN OTHERS
           then
                null;

        END;


    end if;


    --EN : Added for 13160

  --Sn Inserting data in transactionlog
    BEGIN

        INSERT INTO TRANSACTIONLOG(MSGTYPE,
                     RRN,
                     DELIVERY_CHANNEL,
                     DATE_TIME,
                     TXN_CODE,
                     TXN_TYPE,
                     TXN_MODE,
                     TXN_STATUS,
                     RESPONSE_CODE,
                     BUSINESS_DATE,
                     BUSINESS_TIME,
                     CUSTOMER_CARD_NO,
                     INSTCODE,
                     CUSTOMER_CARD_NO_ENCR,
                     CUSTOMER_ACCT_NO,
                     ERROR_MSG,
                     IPADDRESS,
                     ADD_INS_DATE,
                     ADD_INS_USER,
                     CARDSTATUS,
                     TRANS_DESC,
                     RESPONSE_id,
                     TIME_STAMP,
                     acct_type,
                     productid,
                     Categoryid,
                     CR_DR_FLAG,
                     ACCT_BALANCE,
                     LEDGER_BALANCE
                     )
              VALUES(P_MSG,
                     P_RRN,
                     P_DELIVERY_CHANNEL,
                     SYSDATE,
                     P_TXN_CODE,
                     V_TXN_TYPE,
                     P_TXN_MODE,
                     'F',
                     P_RESP_CODE,
                     P_TRAN_DATE,
                     P_TRAN_TIME,
                     V_HASH_PAN,
                     P_INST_CODE,
                     V_ENCR_PAN_FROM,
                      P_SPENDING_ACCT_NO,
                      V_ERRMSG,
                     P_IPADDRESS,
                     SYSDATE,
                     1,
                     P_CARD_STATUS,
                     V_TRANS_DESC,
                     P_RESP_CODE,
                     V_TIME_STAMP,
                     V_ACCT_TYPE,
                     v_cap_prod_code,
                     v_card_type,
                     v_dr_cr_flag,
                     V_ACCT_BAL,
                     V_LEDGER_BAL
                     );
    EXCEPTION
    WHEN OTHERS THEN
        P_RESP_CODE := '12';
        V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||substr(SQLERRM,1,100)||' '||V_ERRMSG;
      END;
  --En Inserting data in transactionlog

  --Sn Inserting data in transactionlog dtl
     BEGIN

          INSERT INTO CMS_TRANSACTION_LOG_DTL
            (
              CTD_DELIVERY_CHANNEL,
              CTD_TXN_CODE,
              CTD_TXN_TYPE,
              CTD_TXN_MODE,
              CTD_BUSINESS_DATE,
              CTD_BUSINESS_TIME,
              CTD_CUSTOMER_CARD_NO,
              CTD_FEE_AMOUNT,
              CTD_WAIVER_AMOUNT,
              CTD_SERVICETAX_AMOUNT,
              CTD_CESS_AMOUNT,
              CTD_PROCESS_FLAG,
              CTD_PROCESS_MSG,
              CTD_RRN,
              CTD_INST_CODE,
              CTD_INS_DATE,
              CTD_INS_USER,
              CTD_CUSTOMER_CARD_NO_ENCR,
              CTD_MSG_TYPE,
              REQUEST_XML,
              CTD_CUST_ACCT_NUMBER,
              CTD_ADDR_VERIFY_RESPONSE,
              CTD_USER_NAME,
              CTD_HASHKEY_ID
            )
            VALUES
            (
              P_DELIVERY_CHANNEL,
              P_TXN_CODE,
              V_TXN_TYPE,
              P_TXN_MODE,
              P_TRAN_DATE,
              P_TRAN_TIME,
              V_HASH_PAN,
              NULL,
              NULL,
              NULL,
              NULL,
              'E',
              V_ERRMSG,
              P_RRN,
              P_INST_CODE,
              SYSDATE,
              1,
              V_ENCR_PAN_FROM,
              '000',
              '',
              P_SPENDING_ACCT_NO,
              '',
              v_encr_username,
              V_HASHKEY_ID
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 300
          )
          ;
          P_RESP_CODE := '69';
          RETURN;
        END;
    --En Inserting data in transactionlog dtl
--En Handle EXP_REJECT_RECORD execption

--Sn Handle OTHERS Execption
 WHEN OTHERS THEN
      P_RESP_CODE := '21';
      V_ERRMSG := 'Main Exception '||SQLCODE||'---'||SQLERRM;
      ROLLBACK;-- TO V_AUTH_SAVEPOINT;

    --Sn Get responce code fomr master
     BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = P_INST_CODE
        AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = P_RESP_CODE;

        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG  := 'Problem while selecting data from response master ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
          P_RESP_CODE := '69';
     END;
   --En Get responce code fomr master

    --SN : Added for 13160

    if V_DR_CR_FLAG is null
    then

        BEGIN
         SELECT CTM_CREDIT_DEBIT_FLAG
           INTO V_DR_CR_FLAG
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = P_TXN_CODE
          AND   CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
          AND   CTM_INST_CODE = P_INST_CODE;

        EXCEPTION WHEN OTHERS
        THEN
            null;
        END;
    end if;

    if v_cap_prod_code is null
    then

        BEGIN

         SELECT CAP_CARD_STAT,
                CAP_PROD_CODE,
                cap_card_type,
                cap_acct_no
         INTO   P_CARD_STATUS,
                v_cap_prod_code,
                v_card_type,
                p_spending_acct_no
         FROM CMS_APPL_PAN
         WHERE CAP_PAN_CODE = V_HASH_PAN
         AND   CAP_MBR_NUMB = V_MBR_NUMB
         AND   CAP_INST_CODE = P_INST_CODE;

        EXCEPTION WHEN OTHERS
        THEN
            null;
        END;


        BEGIN
              SELECT CAM_TYPE_CODE,CAM_ACCT_BAL,CAM_LEDGER_BAL
                INTO V_ACCT_TYPE,V_ACCT_BAL,V_LEDGER_BAL
                FROM CMS_ACCT_MAST
               WHERE CAM_INST_CODE = P_INST_CODE
                 AND CAM_ACCT_NO = p_spending_acct_no;
        EXCEPTION WHEN OTHERS
           then
                null;

        END;


    end if;

    --EN : Added for 13160

   --Sn Inserting data in transactionlog
      BEGIN
          INSERT INTO TRANSACTIONLOG(MSGTYPE,
                       RRN,
                       DELIVERY_CHANNEL,
                       DATE_TIME,
                       TXN_CODE,
                       TXN_TYPE,
                       TXN_MODE,
                       TXN_STATUS,
                       RESPONSE_CODE,
                       BUSINESS_DATE,
                       BUSINESS_TIME,
                       CUSTOMER_CARD_NO,
                       INSTCODE,
                       CUSTOMER_CARD_NO_ENCR,
                       CUSTOMER_ACCT_NO,
                       ERROR_MSG,
                       IPADDRESS,
                       ADD_INS_DATE,
                       ADD_INS_USER,
                       CARDSTATUS,
                       TRANS_DESC,
                       RESPONSE_id,
                       TIME_STAMP,
                       acct_type,
                       productid,
                       Categoryid,
                       CR_DR_FLAG,
                       ACCT_BALANCE,
                       LEDGER_BALANCE
                       )
                VALUES(P_MSG,
                       P_RRN,
                       P_DELIVERY_CHANNEL,
                       SYSDATE,
                       P_TXN_CODE,
                       V_TXN_TYPE,
                       P_TXN_MODE,
                       'F',
                       P_RESP_CODE,
                       P_TRAN_DATE,
                       P_TRAN_TIME,
                       V_HASH_PAN,
                       P_INST_CODE,
                       V_ENCR_PAN_FROM,
                       P_SPENDING_ACCT_NO,
                       V_ERRMSG,
                       P_IPADDRESS,
                       SYSDATE,
                       1,
                       P_CARD_STATUS,
                       V_TRANS_DESC,
                       P_RESP_CODE,
                       V_TIME_STAMP,
                       V_ACCT_TYPE,
                       v_cap_prod_code,
                       v_card_type,
                       v_dr_cr_flag,
                       V_ACCT_BAL,
                       V_LEDGER_BAL
                       );
         EXCEPTION
          WHEN OTHERS THEN
            P_RESP_CODE := '12';
            V_ERRMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||substr(SQLERRM,1,100);
         END;
     --En Inserting data in transactionlog

     --Sn Inserting data in transactionlog dtl
       BEGIN
          INSERT  INTO CMS_TRANSACTION_LOG_DTL
            (
              CTD_DELIVERY_CHANNEL,
              CTD_TXN_CODE,
              CTD_TXN_TYPE,
              CTD_TXN_MODE,
              CTD_BUSINESS_DATE,
              CTD_BUSINESS_TIME,
              CTD_CUSTOMER_CARD_NO,
              CTD_FEE_AMOUNT,
              CTD_WAIVER_AMOUNT,
              CTD_SERVICETAX_AMOUNT,
              CTD_CESS_AMOUNT,
              CTD_PROCESS_FLAG,
              CTD_PROCESS_MSG,
              CTD_RRN,
              CTD_INST_CODE,
              CTD_INS_DATE,
              CTD_INS_USER,
              CTD_CUSTOMER_CARD_NO_ENCR,
              CTD_MSG_TYPE,
              REQUEST_XML,
              CTD_CUST_ACCT_NUMBER,
              CTD_ADDR_VERIFY_RESPONSE,
              CTD_USER_NAME,
              CTD_HASHKEY_ID
            )
            VALUES
            (
              P_DELIVERY_CHANNEL,
              P_TXN_CODE,
              V_TXN_TYPE,
              P_TXN_MODE,
              P_TRAN_DATE,
              P_TRAN_TIME,
              V_HASH_PAN,
              NULL,
              NULL,
              NULL,
              NULL,
             'E',
              V_ERRMSG,
              P_RRN,
              P_INST_CODE,
              SYSDATE,
              1,
              V_ENCR_PAN_FROM,
              '000',
              '',
              P_SPENDING_ACCT_NO,
              '',
              v_encr_username,
              V_HASHKEY_ID
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
          (
            SQLERRM, 1, 300
          )
          ;
          P_RESP_CODE := '69';
          RETURN;
      END;
    --En Inserting data in transactionlog dtl
 --En Handle OTHERS Execption

END;
/
show error