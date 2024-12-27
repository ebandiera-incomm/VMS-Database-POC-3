set define off;
CREATE OR REPLACE PROCEDURE VMSCMS.SP_SMSANDEMAIL_ALERT (
   p_instcode            IN       NUMBER,
   p_rrn                 IN       VARCHAR2,
   p_terminalid          IN       VARCHAR2,
   p_stan                IN       VARCHAR2,
   p_trandate            IN       VARCHAR2,
   p_trantime            IN       VARCHAR2,
   p_acctno              IN       VARCHAR2,
   p_currcode            IN       VARCHAR2,
   p_msg_type            IN       VARCHAR2,
   p_txn_code            IN       VARCHAR2,
   p_txn_mode            IN       VARCHAR2,
   p_delivery_channel    IN       VARCHAR2,
   p_mbr_numb            IN       VARCHAR2,
   p_rvsl_code           IN       VARCHAR2,
   p_cellphoneno         IN       VARCHAR2,
   p_emailid1            IN       VARCHAR2,
   p_emailid2            IN       VARCHAR2,
   p_loadorcreditalert   IN       VARCHAR2,
   p_lowbalalert         IN       VARCHAR2,
   p_lowbalamount        IN       VARCHAR2,
   p_negativebalalert    IN       VARCHAR2,
   p_highauthamtalert    IN       VARCHAR2,
   p_highauthamt         IN       VARCHAR2,
   p_dailybalalert       IN       VARCHAR2,
   p_begintime           IN       VARCHAR2,
   p_endtime             IN       VARCHAR2,
   p_insufficientalert   IN       VARCHAR2,
   p_incorrectpinalert   IN       VARCHAR2,
   p_ipaddress           IN       VARCHAR2,
   p_fast50_alert        IN       VARCHAR2, --Added on 19-09-2013 by MageshKumar.S for JH-6
   p_federal_state_alert IN       VARCHAR2, --Added on 19-09-2013 by MageshKumar.S for JH-6
   P_OPTIN_LANG          IN       VARCHAR2,
   p_resp_code           OUT      VARCHAR2,
   P_Errmsg              Out      Varchar2,
   p_optin_flag_out      OUT      VARCHAR2
)
AS
   /*************************************************************************
    * modified by       : B.Besky
    * modified Date     : 06-NOV-12
    * modified reason   : Changes in Exception handling
    * Reviewer          : Saravanakumar
    * Reviewed Date     : 06-NOV-12
    * Build Number      : CMS3.5.1_RI0023_B0001

     * Modified By      : Sachin P.
     * Modified Date    : 08-Aug-2013
     * Modified for     : MOB-31
     * Modified Reason  : Enable Card to Card Transfer Feature for Mobile API
     * Reviewer         : Dhiraj
     * Reviewed Date    : 08-Aug-2013
     * Build Number     : RI0024.4_B0003

     * Modified By      : Sachin P.
     * Modified Date    : 26-Aug-2013
     * Modified for     : MOB-31(Review Observation)
     * Modified Reason  : Review Observation
     * Reviewer         : Dhiraj
     * Reviewed Date    : 30-Aug-2013
     * Build Number     : RI0024.4_B0006

     * Modified By      : MageshKumar.S
     * Modified Date    : 19-Sep-2013
     * Modified for     : JH-6(Fast50 and Federal State Tax Refund Alerts)
     * Reviewer         : Dhiraj
     * Reviewed Date    : 19-Sep-2013
     * Build Number     : RI0024.5_B0001

     * Modified By      : Pankaj S.
     * Modified Date    : 20-Nov-2013
     * Modified for     : MVHOST-671
     * Modified Reason  : Not Able to perform card to card transfer Functionality in DFC-CHW
     * Reviewer         : Dhiraj
     * Reviewed Date    : 20-Nov-2013
     * Build Number     : RI0027_B0003

     * Modified By     : Pankaj S.
     * Modified Date    : 19-Dec-2013
     * Modified Reason  : Logging issue changes(Mantis ID-13160)
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : RI0027_B0004

     * Modified By      : Raja Gopal G
     * Modified Date    : 30-Jul-2014
     * Modified Reason  : Check Deposit Pending ,Accepted And Rejected Alerts(FR 3.2)
     * Reviewer         : Spankaj
     * Build Number     : RI0027.3.1_B0002

     * Modified By     :  DHINAKARAN B
     * Modified Date    : 27-AUG-2014
     * Modified Reason  : To Revret the FWR-67 changes
     * Reviewer         : Spankaj
     * Build Number     : RI0027.3.1_B0007

     * Modified by      : MAGESHKUMAR.S
     * Modified Date    : 29-April-15
     * Modified For     : FSS-3369
     * Reviewer         : Spankaj
     * Build Number     : VMSGPRHOSTCSD_3.0.1_B0002

     * Modified by      : MAGESHKUMAR.S
     * Modified Date    : 30-April-15
     * Modified For     : FSS-3369(Logic Change)
     * Reviewer         : Spankaj
     * Build Number     : VMSGPRHOSTCSD_3.0.1_B0003

     * Modified by      : MAGESHKUMAR.S
     * Modified Date    : 04-May-15
     * Modified For     : FSS-3369(Logic Change unwanted code commented)
     * Reviewer         : Spankaj
     * Build Number     : VMSGPRHOSTCSD_3.0.1_B0003

     * Modified by      : Siva Kumar M
     * Modified Date    : 05-Aug-15
     * Modified For     : DFCCSD-100
     * Reviewer         : Spankaj
     * Build Number     : VRVMSGPRHOSTCSD_3.1_B0001

      * Modified by      : Pankaj S.
     * Modified for     : To audit SMS and Email Alerts changes
     * Modified Date  : 21-Mar-2016
     * Reviewer          : Saravanan
     * Build Number  : VMSGPRHOST_4.0

      * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1

     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01

 	* Modified By      : Vini Pushkaran
    * Modified Date    : 14-MAY-2018
    * Purpose          : VMS 207 - Added new field to VMS_AUDITTXN_DTLS.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST_R01

    * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 09-JUL-2019
    * Purpose          : VMS 960/962 - Enhance Website/middleware to
                                support cardholder data search ¿¿¿ phase 2.
    * Reviewer         : Saravana Kumar.A
    * Release Number   : VMSGPRHOST_R18
    
    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991

   ***************************************************************************/
   v_cap_prod_catg          cms_appl_pan.cap_prod_catg%TYPE;
   v_cap_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_cap_cafgen_flag        cms_appl_pan.cap_cafgen_flag%TYPE;
   v_firsttime_topup        cms_appl_pan.cap_firsttime_topup%TYPE;
   v_errmsg                 TRANSACTIONLOG.ERROR_MSG%TYPE;
   v_currcode               transactionlog.currencycode%TYPE;
   v_appl_code              cms_appl_mast.cam_appl_code%TYPE;
   v_respcode               TRANSACTIONLOG.response_id%TYPE;
   v_respmsg                TRANSACTIONLOG.ERROR_MSG%TYPE;

   v_capture_date           DATE;
   v_mbrnumb                cms_appl_pan.cap_mbr_numb%TYPE;

   v_txn_type               cms_func_mast.cfm_txn_type%TYPE;
   v_inil_authid            transactionlog.auth_id%TYPE;

   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_rrn_count              PLS_INTEGER;

   v_delchannel_code        cms_delchannel_mast.cdm_channel_code%type;

   v_base_curr              cms_bin_param.cbp_param_value%TYPE;
   v_tran_date              DATE;
   v_acct_balance           cms_acct_mast.cam_acct_bal%type;
   v_ledger_balance         cms_acct_mast.cam_ledger_bal%type;
   v_business_date          VARCHAR2 (8);

   v_dr_cr_flag              cms_transaction_mast.ctm_credit_debit_flag%type;
   v_output_type             cms_transaction_mast.ctm_output_type%type;
   v_tran_type               cms_transaction_mast.ctm_tran_type%type;


   v_cust_code              cms_cust_mast.ccm_cust_code%TYPE;



   v_proxunumber            cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
   v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   v_card_type              cms_appl_pan.cap_card_type%TYPE;

   v_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
   v_cam_type_code          cms_acct_mast.cam_type_code%type; --Added on 27.08.2013 for MOB-31(Review Observation)
   v_timestamp              timestamp;                       --Added on 27.08.2013 for MOB-31(Review Observation)

--Added for txn detail report

  v_cust_id                  cms_cust_mast.ccm_cust_id%TYPE;

  V_COUNT                   PLS_INTEGER;
  v_optout_time_stamp       varchar2(30);
  v_sms_on_cnt              PLS_INTEGER;
  v_email_on_cnt            PLS_INTEGER;
  V_CRAD_ALERT_VALUE        NUMBER(1);
  v_enabled_alertcnt        NUMBER;
  v_alert_name              CMS_SMSEMAIL_ALERT_DET.CAD_ALERT_NAME%TYPE;
  v_query                   varchar2(500);
  v_col_name                CMS_SMSEMAIL_ALERT_DET.CAD_COLUMN_NAME%TYPE;
  v_cardconfig_query        varchar2(500);
  v_alert_lang_id           VMS_ALERTS_SUPPORTLANG.VAS_ALERT_LANG_ID%TYPE;
  v_profile_code            cms_prod_cattype.cpc_profile_code%type;
  v_encrypt_enable          cms_prod_cattype.cpc_encrypt_enable%type;
  v_encr_cellphn            cms_addr_mast.cam_mobl_one%type;
  v_encr_mail               cms_addr_mast.cam_email%type;
  V_Decr_Cellphn            Cms_Addr_Mast.Cam_Mobl_One%Type;
  V_Cam_Mobl_One            Cms_Addr_Mast.Cam_Mobl_One%Type;
   v_loadcredit_flag        CMS_SMSANDEMAIL_ALERT.CSA_LOADORCREDIT_FLAG%TYPE;
   v_lowbal_flag            CMS_SMSANDEMAIL_ALERT.CSA_LOWBAL_AMT%TYPE;
   v_negativebal_flag       CMS_SMSANDEMAIL_ALERT.CSA_NEGBAL_FLAG%TYPE;
   v_highauthamt_flag       CMS_SMSANDEMAIL_ALERT.CSA_HIGHAUTHAMT_FLAG%TYPE;
   v_dailybal_flag          CMS_SMSANDEMAIL_ALERT.CSA_DAILYBAL_FLAG%TYPE;
   V_Insuffund_Flag         CMS_SMSANDEMAIL_ALERT.CSA_INSUFF_FLAG%Type;
   V_Incorrectpin_Flag      CMS_SMSANDEMAIL_ALERT.CSA_INCORRPIN_FLAG%Type;
   V_Fast50_Flag            CMS_SMSANDEMAIL_ALERT.Csa_Fast50_Flag%Type;
   v_federal_state_flag     CMS_SMSANDEMAIL_ALERT.CSA_FEDTAX_REFUND_FLAG%Type;
   V_Doptin_Flag            PLS_INTEGER;
   L_Alert_Lang_Id          Cms_Smsandemail_Alert.Csa_Alert_Lang_Id%Type;

   Type Previousalert_Collection    Is Table Of Varchar2(30);
   Previousalert                    Previousalert_Collection;

   Type CurrentAlert_Collection     Is Table Of Varchar2(30);
   CurrentAlert                     CurrentAlert_Collection;
    v_Retperiod  date; --Added for VMS-5733/FSP-991
    v_Retdate  date; --Added for VMS-5733/FSP-991

   exp_main_reject_record   EXCEPTION;
   exp_auth_reject_record   EXCEPTION;
   exp_reject_record        EXCEPTION;

  CURSOR ALERTDET IS
    select CAD_ALERT_NAME,CAD_COLUMN_NAME,CAD_PRODCC_COLUMN,cad_alert_id from CMS_SMSEMAIL_ALERT_DET;

  CURSOR ALERTDTLS (p_instcode IN VARCHAR2,P_prod_code IN VARCHAR2,p_card_type IN VARCHAR2,p_alert_lang_id IN VARCHAR2) IS
    SELECT cps_config_flag, dbms_lob.substr(CPS_ALERT_MSG,1,1) alert_flag,CPS_ALERT_ID
        FROM cms_prodcatg_smsemail_alerts
       WHERE cps_inst_code = p_instcode
         AND cps_prod_code = p_prod_code
         AND cps_card_type = p_card_type
         AND cps_alert_lang_id=p_alert_lang_id;

BEGIN
   p_errmsg := 'OK';
   p_optin_flag_out :='Y';
   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (p_acctno);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN CREATE HASH PAN

   --SN create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (p_acctno);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '12';
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN create encr pan

   --Sn find debit and credit flag
   BEGIN
      SELECT ctm_credit_debit_flag, ctm_output_type,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
             ctm_tran_type, ctm_tran_desc
        INTO v_dr_cr_flag, v_output_type,
             v_txn_type,
             v_tran_type, v_trans_desc
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delivery_channel
         AND ctm_inst_code = p_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '12';                         --Ineligible Transaction
         v_errmsg :=
               'Transflag  not defined for txn code '
            || p_txn_code
            || ' and delivery channel '
            || p_delivery_channel;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';                         --Ineligible Transaction
         v_respcode := 'Error while selecting transaction details';
         RAISE exp_main_reject_record;
   END;

   --En find debit and credit flag

   --Sn Transaction Date Check
   BEGIN
      v_tran_date := TO_DATE (SUBSTR (TRIM (p_trandate), 1, 8), 'yyyymmdd');
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '45';                       -- Server Declined -220509
         v_errmsg :=
               'Problem while converting transaction date '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En Transaction Date Check

   --Sn Transaction Time Check
   BEGIN
      v_tran_date :=
         TO_DATE (   SUBSTR (TRIM (p_trandate), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_trantime), 1, 10),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '32';                       -- Server Declined -220509
         v_errmsg :=
               'Problem while converting transaction Time '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
       --En Transaction Time Check


   BEGIN
      SELECT pan.cap_card_stat,pan.cap_prod_catg,pan.cap_cafgen_flag,
             pan.cap_appl_code,pan.cap_firsttime_topup,pan.cap_mbr_numb,
             pan.cap_cust_code,pan.cap_proxy_number,pan.cap_acct_no,pan.cap_prod_code,
             pan.cap_card_type,cust.ccm_cust_id
        INTO v_cap_card_stat, v_cap_prod_catg, v_cap_cafgen_flag,
             v_appl_code, v_firsttime_topup, v_mbrnumb,
             v_cust_code, v_proxunumber, v_acct_number, v_prod_code,
             v_card_type,v_cust_id
        FROM cms_appl_pan pan,CMS_CUST_MAST cust
       WHERE pan.cap_inst_code = p_instcode AND pan.cap_pan_code = v_hash_pan
        AND pan.cap_cust_code = cust.ccm_cust_code
              AND pan.cap_inst_code = cust.CCM_INST_CODE;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Invalid Card number ' || v_hash_pan;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg := 'Error while selecting card number ' || v_hash_pan;
         RAISE exp_main_reject_record;
   END;

   BEGIN
      SELECT upper(cpc_encrypt_enable),cpc_profile_code
        INTO v_encrypt_enable,v_profile_code
        FROM cms_prod_cattype
       WHERE cpc_inst_code = p_instcode
         AND cpc_prod_code = v_prod_code and cpc_card_type = v_card_type;

   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error from selecting the encrypt enable flag and profile code for product'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;


   BEGIN
      SELECT cdm_channel_code
        INTO v_delchannel_code
        FROM cms_delchannel_mast
       WHERE cdm_channel_desc = 'MMPOS' AND cdm_inst_code = p_instcode;

      IF v_delchannel_code = p_delivery_channel
      THEN
         BEGIN


            SELECT TRIM (cbp_param_value)
	     INTO v_base_curr
	     FROM cms_bin_param
             WHERE cbp_param_name = 'Currency' AND cbp_inst_code= p_instcode
             AND cbp_profile_code = v_profile_code;


            IF v_base_curr IS NULL
            THEN
               v_respcode := '21';
               v_errmsg := 'Base currency cannot be null ';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
           --Sn Added on 26.08.2013 for MOB-31(Review Observation)
            WHEN exp_main_reject_record THEN
             RAISE;
           --En Added on 26.08.2013 for MOB-31(Review Observation)
            WHEN NO_DATA_FOUND
            THEN
               v_respcode := '21';
               v_errmsg :=
                          'Base currency is not defined for the bin profile ';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg :=
                     'Error while selecting base currency for bin  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         v_currcode := v_base_curr;
      ELSE
         v_currcode := p_currcode;
      END IF;
     --Sn Added on 26.08.2013 for MOB-31(Review Observation)
   EXCEPTION
    WHEN exp_main_reject_record THEN
     RAISE;
     WHEN NO_DATA_FOUND  THEN
        v_respcode := '21';
        v_errmsg :=
               'No data found the Delivery Channel of MMPOS';
         RAISE exp_main_reject_record;
      --En Added on 26.08.2013 for MOB-31(Review Observation)
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting the Delivery Channel of MMPOS  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --Sn Duplicate RRN Check.IF duplicate RRN log the txn and return
   BEGIN
      SELECT TO_CHAR (SYSDATE, 'yyyymmdd')
        INTO v_business_date
        FROM DUAL;
        
               --Added for VMS-5733/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');

IF (v_Retdate>v_Retperiod)
    THEN
      SELECT COUNT (1)
        INTO v_rrn_count
        FROM transactionlog
       WHERE instcode = p_instcode
         AND rrn = p_rrn
         AND business_date = p_trandate
         AND delivery_channel = p_delivery_channel;
      ELSE
              SELECT COUNT (1)
        INTO v_rrn_count
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST  --Added for VMS-5733/FSP-991
       WHERE instcode = p_instcode
         AND rrn = p_rrn
         AND business_date = p_trandate
         AND delivery_channel = p_delivery_channel;
      END IF;   

      --Added by ramkumar.Mk on 25 march 2012
      IF v_rrn_count > 0
      THEN
         v_respcode := '22';
         v_errmsg := 'Duplicate RRN from the Terminal  on ' || p_trandate;
         RAISE exp_main_reject_record;
      END IF;
     --Sn Added on 26.08.2013 for MOB-31(Review Observation)
  EXCEPTION
    WHEN exp_main_reject_record THEN
     RAISE;
    WHEN OTHERS THEN
       v_respcode := '21';
       v_errmsg  := 'Error while checking  duplicate RRN-'|| SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
  --En Added on 26.08.2013 for MOB-31(Review Observation)
   END;



   BEGIN
    IF P_OPTIN_LANG IS NOT NULL THEN
   SELECT VAS_ALERT_LANG_ID INTO
   v_alert_lang_id
   FROM VMS_ALERTS_SUPPORTLANG
   WHERE UPPER(VAS_ALERT_LANG)=TRIM(UPPER(P_OPTIN_LANG));
   ELSE
   SELECT cps_alert_lang_id INTO v_alert_lang_id  FROM
   cms_prodcatg_smsemail_alerts
     WHERE cps_inst_code = p_instcode
         AND cps_prod_code = V_prod_code
         AND cps_card_type = V_card_type
         AND cps_defalert_lang_flag='Y'
         AND ROWNUM=1;
    END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg :='Unsupported Language ';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while selecting language id for '
            || P_OPTIN_LANG;

         RAISE exp_main_reject_record;
   END;



   BEGIN
      sp_authorize_txn_cms_auth (p_instcode,
                                 p_msg_type,
                                 p_rrn,
                                 p_delivery_channel,
                                 p_terminalid,
                                 p_txn_code,
                                 p_txn_mode,
                                 p_trandate,
                                 p_trantime,
                                 p_acctno,
                                 NULL,
                                 0,
                                 NULL,
                                 NULL,
                                 NULL,
                                 v_currcode,
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
                                 p_stan,                             -- P_stan
                                 p_mbr_numb,                        --Ins User
                                 p_rvsl_code,                       --INS Date
                                 NULL,
                                 v_inil_authid,
                                 v_respcode,
                                 v_respmsg,
                                 v_capture_date
                                );

      IF v_respcode <> '00' AND v_respmsg <> 'OK'
      THEN
         v_errmsg := v_respmsg;
         RAISE exp_auth_reject_record;
      END IF;
   END;--Added on 26.08.2013 for MOB-31(Review Observation) testing

      IF v_respcode <> '00'
      THEN
         BEGIN
            p_errmsg := ' ';
            p_resp_code := v_respcode;

            -- Assign the response code to the out parameter
            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_instcode
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = v_respcode;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Problem while selecting data from response master '
                  || v_respcode
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '89';
               ---ISO MESSAGE FOR DATABASE ERROR Server Declined
               ROLLBACK;
         END;
      ELSE
         p_resp_code := v_respcode;
      END IF;
        --En select response code and insert record into txn log dtl

   BEGIN
   for i1 in ALERTDTLS(p_instcode,v_prod_code, v_card_type,v_alert_lang_id)
   LOOP
   IF I1.alert_flag='0' THEN
    --  IF v_loadcredit_flag = '0'
    IF I1.CPS_ALERT_ID='9'
      THEN
         IF p_loadorcreditalert <> '0'
         THEN
            v_respcode := '08';
            v_errmsg :=
                  'LOAD/CREDIT ALERT NOT ENABLED FOR THIS PRODUCT CATEGORY '
               || v_prod_code
               || ' and '
               || v_card_type;
            RAISE exp_main_reject_record;
         END IF;
      END IF;

   --   IF v_lowbal_flag = '0'
    IF I1.CPS_ALERT_ID='10' and
         p_lowbalalert <> '0'
         THEN
            v_respcode := '08';
            v_errmsg :=
                  'LOW BALANCE ALERT NOT ENABLED FOR THIS PRODUCT CATEGORY '
               || v_prod_code
               || ' and '
               || v_card_type;
            RAISE exp_main_reject_record;
    END IF;


    --  IF v_negativebal_flag = '0'
     IF I1.CPS_ALERT_ID='11' and p_negativebalalert <> '0'
         THEN
            v_respcode := '08';
            v_errmsg :=
                  'NEGATIVE BALANCE ALERT NOT ENABLED FOR THIS PRODUCT CATEGORY '
               || v_prod_code
               || ' and '
               || v_card_type;
            RAISE exp_main_reject_record;

      END IF;

    --  IF v_highauthamt_flag = '0'
     IF I1.CPS_ALERT_ID='16' and p_highauthamtalert <> '0'
         THEN
            v_respcode := '08';
            v_errmsg :=
                  'HIGH AUTH AMOUNT ALERT NOT ENABLED FOR THIS PRODUCT CATEGORY '
               || v_prod_code
               || ' and '
               || v_card_type;
            RAISE exp_main_reject_record;

      END IF;

   --   IF v_dailybal_flag = '0'
    IF I1.CPS_ALERT_ID='12' and p_dailybalalert <> '0'
         THEN
            v_respcode := '08';
            v_errmsg :=
                  'DAILY BALANCE ALERT NOT ENABLED FOR THIS PRODUCT CATEGORY '
               || v_prod_code
               || ' and '
               || v_card_type;
            RAISE exp_main_reject_record;

      END IF;

    --  IF v_insuffund_flag = '0'
     IF I1.CPS_ALERT_ID='17' and p_insufficientalert <> '0'
         THEN
            v_respcode := '08';
            v_errmsg :=
                  'INSUFFICIENT FUNDS DECLINE ALERT NOT ENABLED FOR THIS PRODUCT CATEGORY '
               || v_prod_code
               || ' and '
               || v_card_type;
            RAISE exp_main_reject_record;

      END IF;

    --  IF v_incorrectpin_flag = '0'
     IF I1.CPS_ALERT_ID='13' and  p_incorrectpinalert <> '0'
         THEN
            v_respcode := '08';
            v_errmsg :=
                  'INCORRECT PIN ALERT NOT ENABLED FOR THIS PRODUCT CATEGORY '
               || v_prod_code
               || ' and '
               || v_card_type;
            RAISE exp_main_reject_record;

      END IF;
    --Sn Added on 19.09.2013 by MageshKumar.S for JH-6
  --    IF v_fast50_flag = '0'
   IF I1.CPS_ALERT_ID='21' and  p_fast50_alert <> '0'
         THEN
            v_respcode := '08';
            v_errmsg :=
                  'FAST50 ALERT NOT ENABLED FOR THIS PRODUCT CATEGORY '
               || v_prod_code
               || ' and '
               || v_card_type;
            RAISE exp_main_reject_record;

      END IF;

   --   IF v_federal_state_flag = '0'
    IF I1.CPS_ALERT_ID='22' and p_federal_state_alert <> '0'
         THEN
            v_respcode := '08';
            v_errmsg :=
                  'FEDERAL AND STATE TAX REFUND ALERT NOT ENABLED FOR THIS PRODUCT CATEGORY '
               || v_prod_code
               || ' and '
               || v_card_type;
            RAISE exp_main_reject_record;

      END IF;
  --En Added on 19.09.2013 by MageshKumar.S for JH-6
  END IF;
  END LOOP;
  EXCEPTION
  WHEN exp_main_reject_record THEN
  RAISE;
   WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
               'Invalid product code '
            || v_prod_code
            || ' and card type'
            || v_card_type;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting alerts for '
            || v_prod_code
            || ' and '
            || v_card_type;
         RAISE exp_main_reject_record;
  END;
      IF  ( p_loadorcreditalert = '1'
         OR p_lowbalalert = '1'
         OR p_negativebalalert = '1'
         OR p_highauthamtalert = '1'
         OR p_dailybalalert = '1'
         OR p_insufficientalert = '1'
         OR p_incorrectpinalert = '1'
         OR p_fast50_alert = '1' -- Added on 19.09.2013 by MageshKumar.S for JH-6
         OR p_federal_state_alert = '1' -- Added on 19.09.2013 by MageshKumar.S for JH-6
         OR p_loadorcreditalert = '3'
         OR p_lowbalalert = '3'
         OR p_negativebalalert = '3'
         OR p_highauthamtalert = '3'
         OR p_dailybalalert = '3'
         OR p_insufficientalert = '3'
         OR p_incorrectpinalert = '3'
         OR p_fast50_alert = '3' --En Added on 19.09.2013 by MageshKumar.S for JH-6
         OR p_federal_state_alert = '3') --En Added on 19.09.2013 by MageshKumar.S for JH-6
       AND  NVL (p_cellphoneno, 0) = 0
         THEN
            v_respcode := '124';
            v_errmsg :=
                   'For Enabling SMS alert Mobile Number should be Mandatory';
            --Modified for spelling mistake error - mantis id 0007988
            RAISE exp_main_reject_record;

      END IF;

      IF    (p_loadorcreditalert = '2'
         OR p_lowbalalert = '2'
         OR p_negativebalalert = '2'
         OR p_highauthamtalert = '2'
         OR p_dailybalalert = '2'
         OR p_insufficientalert = '2'
         OR p_incorrectpinalert = '2'
         OR p_fast50_alert = '2' -- Added on 19.09.2013 by MageshKumar.S for JH-6
         OR p_federal_state_alert = '2' -- Added on 19.09.2013 by MageshKumar.S for JH-6
         OR p_loadorcreditalert = '3'
         OR p_lowbalalert = '3'
         OR p_negativebalalert = '3'
         OR p_highauthamtalert = '3'
         OR p_dailybalalert = '3'
         OR p_insufficientalert = '3'
         OR p_incorrectpinalert = '3'
         OR p_fast50_alert = '3' -- Added on 19.09.2013 by MageshKumar.S for JH-6
         OR p_federal_state_alert = '3') -- Added on 19.09.2013 by MageshKumar.S for JH-6
         and NVL (p_emailid1, '0') = '0'
         THEN
            v_respcode := '125';
            v_errmsg :=
                      'For Enabling EMail alert EMail ID should be Mandatory';
            --Modified for spelling mistake error - mantis id 0007988
            RAISE exp_main_reject_record;

      END IF;


        --Sn To audit SMS and Email Alerts changes
        BEGIN
           INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user)
                VALUES (p_rrn, p_delivery_channel, p_txn_code, v_cust_code, 1);
        EXCEPTION
           WHEN OTHERS THEN
              v_respcode := '21';
              v_errmsg :='Error while inserting audit dtls- ' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_main_reject_record;
        END;
        --En To audit SMS and Email Alerts changes


      BEGIN
    Select Csa_Alert_Lang_Id,Csa_Loadorcredit_Flag,Csa_Lowbal_Flag,Csa_Negbal_Flag,Csa_Highauthamt_Flag,Csa_Dailybal_Flag,Csa_Insuff_Flag, Csa_Fedtax_Refund_Flag, Csa_Fast50_Flag,Csa_Incorrpin_Flag
    Into l_alert_lang_id,v_loadcredit_flag,v_lowbal_flag,v_negativebal_flag,v_highauthamt_flag,v_dailybal_flag,V_Insuffund_Flag, v_federal_state_flag, V_Fast50_Flag,V_Incorrectpin_Flag
    From Cms_Smsandemail_Alert Where Csa_Pan_Code=V_Hash_Pan and CSA_INST_CODE=p_instcode;
     EXCEPTION
        WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg :='Error while selecting customer alerts ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
    BEGIN
    select count(1) into v_doptin_flag from CMS_PRODCATG_SMSEMAIL_ALERTS
    WHERE nvl(dbms_lob.substr( cps_alert_msg,1,1),0) <> 0
    And Cps_Prod_Code = V_Prod_Code
    AND CPS_CARD_TYPE = v_card_type
    and cps_alert_id=33
    And Cps_Inst_Code= p_instcode
      And ( Cps_Alert_Lang_Id = l_alert_lang_id or (l_alert_lang_id is null and CPS_DEFALERT_LANG_FLAG = 'Y'));
      If(v_doptin_flag = 1)
      Then
        Previousalert := Previousalert_Collection(V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag);
        CurrentAlert := CurrentAlert_Collection(p_loadorcreditalert,p_lowbalalert,p_negativebalalert,p_highauthamtalert,p_dailybalalert,p_insufficientalert,p_federal_state_alert,p_fast50_alert, p_incorrectpinalert);
           If (1 Member Of Previousalert Or 3 Member Of Previousalert )
               Then
              p_optin_flag_out:='N';
            Else
                if(1  Member Of CurrentAlert or 3  Member Of CurrentAlert)
                Then
                  p_optin_flag_out:='Y';
                 Else
                 p_optin_flag_out:='N';
                End If;
            End If;
      Else
       p_optin_flag_out:='N';
     End If;
     EXCEPTION
        WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg :='Error while selecting product category alerts(double optin) ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
    BEGIN
         -- IF P_DELIVERY_CHANNEL = '10' AND P_TXN_CODE = '13' THEN -- if condition commented by sagar on 19-Jun2012 to allow from CSR channel also
         UPDATE cms_smsandemail_alert
            SET
                csa_loadorcredit_flag = p_loadorcreditalert,
                csa_lowbal_flag = p_lowbalalert,
                csa_lowbal_amt = p_lowbalamount,
                csa_negbal_flag = p_negativebalalert,
                csa_highauthamt_flag = p_highauthamtalert,
                csa_highauthamt = p_highauthamt,
                csa_dailybal_flag = p_dailybalalert,
                csa_begin_time = p_begintime,
                csa_end_time = p_endtime,
                csa_insuff_flag = p_insufficientalert,
                csa_incorrpin_flag = p_incorrectpinalert,
                CSA_FAST50_FLAG = NVL (p_fast50_alert, CSA_FAST50_FLAG),-- Added on 19.09.2013 by MageshKumar.S for JH-6
                CSA_FEDTAX_REFUND_FLAG = NVL(p_federal_state_alert,CSA_FEDTAX_REFUND_FLAG), -- Added on 19.09.2013 by MageshKumar.S for JH-6
                csa_lupd_date = SYSDATE,
                CSA_ALERT_LANG_ID=v_alert_lang_id
          WHERE csa_pan_code = v_hash_pan AND csa_inst_code = p_instcode;
      --Sn Added on 26.08.2013 for MOB-31(Review Observation)
         IF SQL%ROWCOUNT  = 0 THEN
           v_respcode := '21';
            v_errmsg := 'No Records Updated in SMSEMAIL';
            RAISE exp_main_reject_record;

         END IF;
      EXCEPTION
      WHEN exp_main_reject_record THEN
       RAISE;
      WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'ERROR IN SMSEMAIL ALERT UPDATE --'
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_main_reject_record;
      --En Added on 26.08.2013 for MOB-31(Review Observation)

      END;


           v_optout_time_stamp:=to_char(SYSTIMESTAMP,'DD-Mon-RR HH24:MI:SS.FF');
           v_sms_on_cnt :=0;
           v_email_on_cnt :=0;


            FOR I1 IN ALERTDET LOOP

        BEGIN
        --    v_query:= 'select count(1)  from CMS_PRODCATG_SMSEMAIL_ALERTS where '||I1.CAD_PRODCC_COLUMN ||' !=0
          v_query:= 'select count(1)  from CMS_PRODCATG_SMSEMAIL_ALERTS where dbms_lob.substr(cps_alert_msg,1,1) !=0
            and CPS_PROD_CODE =:1 AND CPS_CARD_TYPE =:2 AND CPS_INST_CODE=:3 AND cps_alert_lang_id=:4  and cps_alert_id=:5'  ;
            execute immediate v_query into v_enabled_alertcnt using V_PROD_CODE,V_CARD_TYPE,p_instcode,v_alert_lang_id,I1.cad_alert_id;

         if v_enabled_alertcnt=1 then

            BEGIN
            SELECT cad_alert_name, cad_column_name
              INTO v_alert_name, v_col_name
              FROM cms_smsemail_alert_det
             WHERE --cad_prodcc_column = I1.cad_prodcc_column;
             cad_alert_id=I1.cad_alert_id;

             v_cardconfig_query:= 'select '|| v_col_name||' from CMS_SMSANDEMAIL_ALERT WHERE CSA_PAN_CODE=:1';
             execute immediate v_cardconfig_query INTO V_CRAD_ALERT_VALUE using V_HASH_PAN;

              EXCEPTION

                WHEN NO_DATA_FOUND THEN
                    v_respcode := '21';
                    V_ERRMSG  := 'No Alert Details found for the card '||SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
                WHEN OTHERS THEN
                v_respcode := '21';
                V_ERRMSG  := 'Error while Selecting Alert Details of CArd'||SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
             END;

          --  IF V_ALERT_DET IS NOT NULL THEN

         --   V_ALERT_DET:=V_ALERT_DET||'||';

         --   END IF;


            IF V_CRAD_ALERT_VALUE=1 THEN
              v_sms_on_cnt:=v_sms_on_cnt+1;
             ELSIF V_CRAD_ALERT_VALUE=2 THEN
                v_email_on_cnt:=v_email_on_cnt+1;
             ELSIF V_CRAD_ALERT_VALUE=3 THEN
             v_sms_on_cnt:=v_sms_on_cnt+1;
             v_email_on_cnt:=v_email_on_cnt+1;
            END IF;

     END IF;

        EXCEPTION
        WHEN OTHERS THEN
         v_respcode := '21';
         V_ERRMSG  := 'Error while Selecting Producat Catg Alert Details'||SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
        END;

        END LOOP;

   BEGIN




         SELECT COUNT (*)
           INTO v_count
           FROM cms_optin_status
          WHERE cos_inst_code = p_instcode AND cos_cust_id = v_cust_id;

         IF v_count > 0
         THEN
            UPDATE cms_optin_status
               SET cos_sms_optinflag = decode(v_sms_on_cnt,0,0,1),
                   cos_sms_optintime =to_timestamp(decode(v_sms_on_cnt,'0',null,v_optout_time_stamp),'DD-Mon-RR HH24:MI:SS.FF'),
                   cos_sms_optouttime =to_timestamp(decode(v_sms_on_cnt,'0',v_optout_time_stamp,null),'DD-Mon-RR HH24:MI:SS.FF'),
                   cos_email_optinflag = decode(v_email_on_cnt,0,0,1),
                   cos_email_optintime =to_timestamp(decode(v_email_on_cnt,'0',null,v_optout_time_stamp),'DD-Mon-RR HH24:MI:SS.FF'),
                   cos_email_optouttime = to_timestamp(decode(v_email_on_cnt,'0',v_optout_time_stamp,null),'DD-Mon-RR HH24:MI:SS.FF')
             WHERE cos_inst_code = p_instcode AND cos_cust_id = v_cust_id;
         ELSE
            INSERT INTO cms_optin_status
                        (cos_inst_code,
                        cos_cust_id,
                        cos_sms_optinflag,
                         cos_sms_optintime,
                         cos_sms_optouttime,
                         cos_email_optinflag,
                         cos_email_optintime,
                         cos_email_optouttime
                        )
                 VALUES (p_instcode,
                 v_cust_id,
                 decode(v_sms_on_cnt,0,0,1),
                 to_timestamp(decode(v_sms_on_cnt,'0',null,v_optout_time_stamp),'DD-Mon-RR HH24:MI:SS.FF'),
                 to_timestamp(decode(v_sms_on_cnt,'0',v_optout_time_stamp,null),'DD-Mon-RR HH24:MI:SS.FF'),
                 decode(v_email_on_cnt,0,0,1),
                 to_timestamp(decode(v_email_on_cnt,'0',null,v_optout_time_stamp),'DD-Mon-RR HH24:MI:SS.FF'),
                 to_timestamp(decode(v_email_on_cnt,'0',v_optout_time_stamp,null),'DD-Mon-RR HH24:MI:SS.FF')
                );
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'ERROR IN INSERTING RECORDS IN CMS_OPTIN_STATUS'
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;



         -- IF P_DELIVERY_CHANNEL = '10' AND P_TXN_CODE = '13' THEN  -- if condition commented by sagar on 19-Jun2012 to allow from CSR channel also
      BEGIN

          IF  v_encrypt_enable = 'Y' THEN
             v_encr_cellphn:= fn_emaps_main(p_cellphoneno);
             v_encr_mail:= fn_emaps_main(p_emailid1);
          ELSE
             v_encr_cellphn:= p_cellphoneno;
             v_encr_mail:= p_emailid1;
          END IF;

     BEGIN
      If(v_doptin_flag = 1) AND (p_optin_flag_out = 'N' and ('1' Member Of Currentalert or '3' Member Of Currentalert))
        THEN

          Select Cam_Mobl_One
            into V_Cam_Mobl_One
            From Cms_Addr_Mast
            where cam_cust_code=v_cust_code and cam_addr_flag='P'
              and cam_inst_code=p_instcode;

                  If(V_Encrypt_Enable = 'Y') Then
                      V_Decr_Cellphn :=Fn_Dmaps_Main(V_Cam_Mobl_One);
                    Else
                      V_Decr_Cellphn := V_Cam_Mobl_One;
                  End If;

                    If(V_Decr_Cellphn <> P_Cellphoneno)
                        Then
                        p_optin_flag_out :='Y';
                    end if;

      End If;

     EXCEPTION
        WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg :='Error while selecting mobile number ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;

         UPDATE cms_addr_mast
            SET cam_mobl_one =v_encr_cellphn,-- NVL (p_cellphoneno, 0), modified for DFCCSD-100
                cam_email = NVL (v_encr_mail, ' '),
                CAM_EMAIL_ENCR = NVL (fn_emaps_main(p_emailid1), fn_emaps_main(' '))
          WHERE cam_cust_code = v_cust_code AND cam_inst_code = p_instcode;
      -- END IF;
      /* T.Narayanan changed For Separting the configuration of SMS and Email on 12th june 2012  -- end */
      --Sn Added on 26.08.2013 for MOB-31(Review Observation)
         IF SQL%ROWCOUNT  = 0 THEN
            v_respcode := '21';
            v_errmsg := 'No Records Updated in ADDRMAST';
            RAISE exp_main_reject_record;

         END IF;
      EXCEPTION
      WHEN exp_main_reject_record THEN
      RAISE;
      WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'Error while upadating Customer ADDRMAST --'
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_main_reject_record;
      --En Added on 26.08.2013 for MOB-31(Review Observation)
      END;

      --En Sivapragasam on June 15 2012


      --IF errmsg is OK then balance amount will be returned
      IF p_errmsg = 'OK'
      THEN
         --Sn of Getting  the Acct Balannce
         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal
                  INTO v_acct_balance, v_ledger_balance
                  FROM cms_acct_mast
                 WHERE cam_acct_no = v_acct_number --Commented and Modified on 26.08.2013 for MOB-31(Review Observation)
                   AND cam_inst_code = p_instcode
            FOR UPDATE NOWAIT;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_respcode := '14';                   --Ineligible Transaction
               v_errmsg := 'Invalid Card ';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_respcode := '12';
               v_errmsg :=
                     'Error while selecting data from card Master for card number '
                  || v_hash_pan;
               RAISE exp_main_reject_record;
         END;

         --En of Getting  the Acct Balannce
         p_errmsg := ' ';
      END IF;

      BEGIN
      
IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE transactionlog
            SET ipaddress = p_ipaddress
          WHERE rrn = p_rrn
            AND business_date = p_trandate
            AND txn_code = p_txn_code
            AND msgtype = p_msg_type
            AND business_time = p_trantime
            AND delivery_channel = p_delivery_channel;
      ELSE
      UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST  --Added for VMS-5733/FSP-991
            SET ipaddress = p_ipaddress
          WHERE rrn = p_rrn
            AND business_date = p_trandate
            AND txn_code = p_txn_code
            AND msgtype = p_msg_type
            AND business_time = p_trantime
            AND delivery_channel = p_delivery_channel;
      END IF;      
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '69';
            p_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
      END;
   EXCEPTION
      --<< MAIN EXCEPTION >>
      WHEN exp_auth_reject_record
      THEN


         p_errmsg := v_errmsg;
         p_resp_code := v_respcode;

         --Sn select response code and insert record into txn log dtl


         --p_errmsg := v_authmsg; Commented by Besky on 06-nov-12
      WHEN exp_main_reject_record
      THEN
         ROLLBACK;

      --Sn Added on 27.08.2013 for MOB-31(Review Observation)
       IF v_prod_code is null
       THEN

            BEGIN
               SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
                 INTO v_prod_code, v_card_type, v_cap_card_stat, v_acct_number
                 FROM cms_appl_pan
                WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

       END IF;

       IF  v_acct_balance is null
          then

             BEGIN
                SELECT cam_acct_bal, cam_ledger_bal, cam_acct_no,
                       cam_type_code
                  INTO v_acct_balance, v_ledger_balance, v_acct_number,
                       v_cam_type_code
                  FROM cms_acct_mast
                  --Sn Modified by Pankaj S. for logging changes(Mantis ID-13160)
                 WHERE cam_acct_no =v_acct_number
                   AND cam_inst_code = p_instcode;
             EXCEPTION
                WHEN OTHERS
                THEN
                   v_acct_balance := 0;
                   v_ledger_balance := 0;
             END;

       END IF;




         IF v_dr_cr_flag is null
         THEN

            BEGIN
               SELECT ctm_credit_debit_flag
                 INTO v_dr_cr_flag
                 FROM cms_transaction_mast
                WHERE ctm_inst_code = p_instcode
                  AND ctm_tran_code = p_txn_code
                  AND ctm_delivery_channel = p_delivery_channel;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

         END IF;
      --En Added on 27.08.2013 for MOB-31(Review Observation)

         --Sn select response code and insert record into txn log dtl
         BEGIN
            ---Sn Updation of Usage limit and amount

            p_errmsg := v_errmsg;
            p_resp_code := v_respcode;

            -- Assign the response code to the out parameter
            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_instcode
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = v_respcode;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Problem while selecting data from response master '
                  || v_respcode
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '89';
               ---ISO MESSAGE FOR DATABASE ERROR Server Declined
               ROLLBACK;
         -- RETURN;
         END;

         --Sn create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         terminal_id,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status, response_code,
                         business_date, business_time, customer_card_no,
                         topup_card_no, topup_acct_no, topup_acct_type,
                         bank_code,
                         total_amount,
                         currencycode, addcharge, productid, categoryid,
                         atm_name_location, auth_id,
                         amount, preauthamount,
                         partialamount, instcode, customer_card_no_encr,
                         topup_card_no_encr, proxy_number, reversal_code,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, ipaddress, cardstatus,
                         trans_desc,
                         acct_type,            --Added on 27.08.2013 for MOB-31(Review Observation)
                         time_stamp,          --Added on 27.08.2013 for MOB-31(Review Observation)
                         cr_dr_flag,--Added on 27.08.2013 for MOB-31(Review Observation)
                         error_msg --Added by Pankaj S. for logging changes(Mantis ID-13160)
                        )
                 --Added cardstatus insert in transactionlog by srinivasu.k
            VALUES      (p_msg_type, p_rrn, p_delivery_channel,
                         p_terminalid,
                         TO_DATE (v_business_date, 'YYYY/MM/DD'),
                         p_txn_code, v_txn_type, p_txn_mode,
                         DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                         p_trandate, SUBSTR (p_trantime, 1, 10), v_hash_pan,
                         NULL, NULL, NULL,
                         p_instcode,
                         TRIM (TO_CHAR (0, '999999999999999990.99')),  --Formatted by Pankaj S. for logging changes(Mantis ID-13160)
                         v_currcode, NULL,
                          --'', '',--Commented and modified on 27.08.2013 for MOB-31(Review Observation)
                         v_prod_code,
                         v_card_type,
                         p_terminalid, v_inil_authid,
                         TRIM (TO_CHAR (0, '999999999999999990.99')), '0.00','0.00', --Formatted by Pankaj S. for logging changes(Mantis ID-13160)
                         p_instcode, v_encr_pan,
                         v_encr_pan, v_proxunumber, p_rvsl_code,
                         v_acct_number, v_acct_balance, v_ledger_balance,
                         v_respcode, p_ipaddress, v_cap_card_stat,
                         v_trans_desc,
                         v_cam_type_code,--Added on 27.08.2013 for MOB-31(Review Observation)
                         nvl(v_timestamp,systimestamp),--Added on 27.08.2013 for MOB-31(Review Observation)
                         V_DR_CR_FLAG,--Added on 27.08.2013 for MOB-31(Review Observation)
                         v_errmsg  --Added by Pankaj S. for logging changes(Mantis ID-13160)
                        );
         --Added cardstatus insert in transactionlog by srinivasu.k
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '89';
               p_errmsg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
         END;

         --En create a entry in txn log
         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                         ctd_txn_mode, ctd_business_date, ctd_business_time,
                         ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                         ctd_actual_amount, ctd_fee_amount,
                         ctd_waiver_amount, ctd_servicetax_amount,
                         ctd_cess_amount, ctd_bill_amount, ctd_bill_curr,
                         ctd_process_flag, ctd_process_msg, ctd_rrn,
                         ctd_inst_code, ctd_customer_card_no_encr,
                         ctd_cust_acct_number, ctd_txn_type
                        )
                 VALUES (p_delivery_channel, p_txn_code, p_msg_type,
                         p_txn_mode, p_trandate, p_trantime,
                         v_hash_pan, 0, v_currcode,
                         0, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_errmsg, p_rrn,
                         p_instcode, v_encr_pan,
                         v_acct_number, v_txn_type
                        );

            p_errmsg := v_errmsg;
            RETURN;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code := '22';                         -- Server Declined
               ROLLBACK;
               RETURN;
         END;

         p_errmsg := v_errmsg;
       --SN Commented and modified on 26.08.2013 for MOB-31(Review Observation) testing

--EN Commented and modified on 26.08.2013 for MOB-31(Review Observation) testing
   WHEN OTHERS
   THEN

      -- insert transactionlog and cms_transactio_log_dtl for exception cases

      ROLLBACK;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,
                cam_type_code --Added on 26.08.2013 for MOB-31(Review Observation)
           INTO v_acct_balance, v_ledger_balance,
                v_cam_type_code--Added on 26.08.2013 for MOB-31(Review Observation)
           FROM cms_acct_mast
          WHERE cam_acct_no =
                   (SELECT cap_acct_no
                      FROM cms_appl_pan
                     WHERE cap_pan_code = v_hash_pan
                       AND cap_inst_code = p_instcode)
            AND cam_inst_code = p_instcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_balance := 0;
      END;

       --Sn Added on 27.08.2013 for MOB-31(Review Observation)

       IF V_PROD_CODE is null
       THEN

            BEGIN
               SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
                 INTO v_prod_code, v_card_type, v_cap_card_stat, v_acct_number
                 FROM cms_appl_pan
                WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

       END IF;


         IF V_DR_CR_FLAG is null
         THEN

            BEGIN
               SELECT ctm_credit_debit_flag
                 INTO v_dr_cr_flag
                 FROM cms_transaction_mast
                WHERE ctm_inst_code = p_instcode
                  AND ctm_tran_code = p_txn_code
                  AND ctm_delivery_channel = p_delivery_channel;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

         END IF;
      --En Added on 27.08.2013 for MOB-31(Review Observation)


      --Sn select response code and insert record into txn log dtl
      BEGIN
         p_errmsg := v_errmsg;
         p_resp_code := v_respcode;

         -- Assign the response code to the out parameter
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_respcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Problem while selecting data from response master '
               || v_respcode
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
      ---ISO MESSAGE FOR DATABASE ERROR Server Declined
      END;

      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time, txn_code,
                      txn_type, txn_mode, txn_status,
                      response_code, business_date, business_time,
                      customer_card_no, topup_card_no, topup_acct_no,
                      topup_acct_type, bank_code,
                      total_amount,
                      currencycode, addcharge, productid, categoryid,
                      atm_name_location, auth_id,
                      amount, preauthamount,
                      partialamount, instcode, customer_card_no_encr,
                      topup_card_no_encr, proxy_number, reversal_code,
                      customer_acct_no, acct_balance, ledger_balance,
                      response_id, ipaddress, cardstatus, trans_desc,
                      acct_type,           --Added on 27.08.2013 for MOB-31(Review Observation)
                      time_stamp,           --Added on 27.08.2013 for MOB-31(Review Observation)
                      cr_dr_flag,--Added on 27.08.2013 for MOB-31(Review Observation)
                      error_msg  --Added by Pankaj S. fro logging changes(Mantis ID-13160)
                     )
              --Added cardstatus insert in transactionlog by srinivasu.k
         VALUES      (p_msg_type, p_rrn, p_delivery_channel, p_terminalid,
                      TO_DATE (v_business_date, 'YYYY/MM/DD'), p_txn_code,
                      '', p_txn_mode, DECODE (p_resp_code, '00', 'C', 'F'),
                      p_resp_code, p_trandate, SUBSTR (p_trantime, 1, 10),
                      v_hash_pan, NULL, NULL,
                      NULL, p_instcode,
                      TRIM (TO_CHAR (0, '999999999999999990.99')), --Formatted by Pankaj S. for logging changes(Mantis ID-13160)
                      v_currcode, NULL,
                      --'', '',--Commented and modified on 27.08.2013 for MOB-31(Review Observation)
                      v_prod_code,
                      v_card_type,
                      p_terminalid, v_inil_authid,
                      TRIM (TO_CHAR (0, '999999999999999990.99')), '0.00','0.00', --Formatted by Pankaj S. for logging changes(Mantis ID-13160)
                      p_instcode, v_encr_pan,
                      v_encr_pan, v_proxunumber, p_rvsl_code,
                      v_acct_number, v_acct_balance, v_ledger_balance,
                      v_respcode, p_ipaddress, v_cap_card_stat, v_trans_desc,
                      v_cam_type_code,--Added on 27.08.2013 for MOB-31(Review Observation)
                      nvl(v_timestamp,systimestamp),--Added on 27.08.2013 for MOB-31(Review Observation)
                      V_DR_CR_FLAG,--Added on 27.08.2013 for MOB-31(Review Observation)
                      v_errmsg--Added by Pankaj S. fro logging changes(Mantis ID-13160)
                     );
      --Added cardstatus insert in transactionlog by srinivasu.k
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            p_errmsg :=
                  'Problem while inserting data into transaction log '
               || SUBSTR (SQLERRM, 1, 300);
      END;

   --SN Added EXCEPTIONM on 27.08.2013 for MOB-31(Review Observation)
      BEGIN

      INSERT INTO cms_transaction_log_dtl
                  (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                   ctd_txn_mode, ctd_business_date, ctd_business_time,
                   ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                   ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                   ctd_servicetax_amount, ctd_cess_amount, ctd_bill_amount,
                   ctd_bill_curr, ctd_process_flag, ctd_process_msg, ctd_rrn,
                   ctd_inst_code, ctd_customer_card_no_encr,
                   ctd_cust_acct_number, ctd_txn_type
                  )
           VALUES (p_delivery_channel, p_txn_code, p_msg_type,
                   p_txn_mode, p_trandate, p_trantime,
                   v_hash_pan, 0, v_currcode,
                   0, NULL, NULL,
                   NULL, NULL, NULL,
                   NULL, 'E', v_errmsg, p_rrn,
                   p_instcode, v_encr_pan,
                   v_acct_number, v_txn_type
                  );
        EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            p_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);

      END;
     --EN Added EXCEPTIONM on 27.08.2013 for MOB-31(Review Observation)

END;
/
show error