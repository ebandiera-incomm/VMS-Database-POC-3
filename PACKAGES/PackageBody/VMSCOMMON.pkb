create or replace PACKAGE BODY               VMSCMS.VMSCOMMON
IS
PROCEDURE TRFR_ALERTS(
    p_instcode_in IN NUMBER,
    p_fromcard_in IN VARCHAR2,
    p_tocard_in   IN VARCHAR2,
    p_resp_code_out OUT VARCHAR2,
    p_errmsg_out OUT VARCHAR2 )
IS
  /****************************************************************************
  ******************
  * Created by                  : MageshKumar S.
  * Created Date                : 29-DECEMBER-15
  * Created For                 : FSS-3506
  * Created reason              : ALERTS TRANSFER
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD3.3_B0002
  *****************************************************************************
  *********************/
  l_cellphone_carr cms_smsandemail_alert.CSA_CELLPHONECARRIER%TYPE;
  l_loadcredit_flag cms_smsandemail_alert.CSA_LOADORCREDIT_FLAG%TYPE;
  l_lowbal_flag cms_smsandemail_alert.CSA_LOWBAL_FLAG%TYPE;
  l_lowbal_amnt cms_smsandemail_alert.CSA_LOWBAL_AMT%TYPE;
  l_negbal_flag cms_smsandemail_alert.CSA_NEGBAL_FLAG%TYPE;
  l_highauth_flag cms_smsandemail_alert.CSA_HIGHAUTHAMT_FLAG%TYPE;
  l_highauth_amnt cms_smsandemail_alert.CSA_HIGHAUTHAMT%TYPE;
  l_dalybal_flag cms_smsandemail_alert.CSA_DAILYBAL_FLAG%TYPE;
  l_begin_time cms_smsandemail_alert.CSA_BEGIN_TIME%TYPE;
  l_end_time cms_smsandemail_alert.CSA_END_TIME%TYPE;
  l_insuff_flag cms_smsandemail_alert.CSA_INSUFF_FLAG%TYPE;
  l_incorrpin_flag cms_smsandemail_alert.CSA_INCORRPIN_FLAG%TYPE;
  l_c2c_flag cms_smsandemail_alert.CSA_C2C_FLAG%TYPE;
  l_fast50_flag cms_smsandemail_alert.CSA_FAST50_FLAG%TYPE;
  l_fedtax_flag cms_smsandemail_alert.CSA_FEDTAX_REFUND_FLAG%TYPE;
  l_depe_flag cms_smsandemail_alert.CSA_DEPPENDING_FLAG%TYPE;
  l_deacc_flag cms_smsandemail_alert.CSA_DEPACCEPTED_FLAG%TYPE;
  l_derej_flag cms_smsandemail_alert.CSA_DEPREJECTED_FLAG%TYPE;
  EXP_REJECT_RECORD EXCEPTION;
BEGIN
  p_errmsg_out    := 'OK';
  p_resp_code_out := '00';
  BEGIN
    SELECT
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
      CSA_C2C_FLAG,
      CSA_FAST50_FLAG,
      CSA_FEDTAX_REFUND_FLAG,
      CSA_DEPPENDING_FLAG,
      CSA_DEPACCEPTED_FLAG,
      CSA_DEPREJECTED_FLAG
    INTO
      l_cellphone_carr,
      l_loadcredit_flag,
      l_lowbal_flag,
      l_lowbal_amnt,
      l_negbal_flag,
      l_highauth_flag,
      l_highauth_amnt,
      l_dalybal_flag,
      l_begin_time,
      l_end_time,
      l_insuff_flag,
      l_incorrpin_flag,
      l_c2c_flag,
      l_fast50_flag,
      l_fedtax_flag,
      l_depe_flag,
      l_deacc_flag,
      l_derej_flag
    FROM
      CMS_SMSANDEMAIL_ALERT
    WHERE
      CSA_PAN_CODE   =p_fromcard_in
    AND CSA_INST_CODE=p_instcode_in;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    p_resp_code_out := '21';
    p_errmsg_out    := 'Configured Alerts not found for starter card'||
    p_fromcard_in;
    RAISE EXP_REJECT_RECORD;
  WHEN OTHERS THEN
    p_resp_code_out := '21';
    p_errmsg_out    :=
    'Error while selecting alert details from cms_smsandemail_alert table' ||
    SUBSTR(SQLERRM, 1, 300);
    RAISE EXP_REJECT_RECORD;
  END;
  BEGIN
    UPDATE
      CMS_SMSANDEMAIL_ALERT
    SET
      CSA_CELLPHONECARRIER   = l_cellphone_carr,
      CSA_LOADORCREDIT_FLAG  = l_loadcredit_flag,
      CSA_LOWBAL_FLAG        = l_lowbal_flag,
      CSA_LOWBAL_AMT         = l_lowbal_amnt,
      CSA_NEGBAL_FLAG        = l_negbal_flag,
      CSA_HIGHAUTHAMT_FLAG   = l_highauth_flag,
      CSA_HIGHAUTHAMT        = l_highauth_amnt,
      CSA_DAILYBAL_FLAG      = l_dalybal_flag,
      CSA_BEGIN_TIME         = l_begin_time,
      CSA_END_TIME           = l_end_time,
      CSA_INSUFF_FLAG        = l_insuff_flag,
      CSA_INCORRPIN_FLAG     = l_incorrpin_flag,
      CSA_C2C_FLAG           = l_c2c_flag,
      CSA_FAST50_FLAG        = l_fast50_flag,
      CSA_FEDTAX_REFUND_FLAG = l_fedtax_flag,
      CSA_DEPPENDING_FLAG    = l_depe_flag,
      CSA_DEPACCEPTED_FLAG   = l_deacc_flag,
      CSA_DEPREJECTED_FLAG   = l_derej_flag,
      CSA_LUPD_USER          =1,
      CSA_LUPD_DATE          =SYSDATE
    WHERE
      CSA_INST_CODE    =p_instcode_in
    AND CSA_PAN_CODE   =p_tocard_in;
    IF SQL%ROWCOUNT    =0 THEN
      p_resp_code_out := '21';
      p_errmsg_out    := 'No records updated in CMS_SMSANDEMAIL_ALERT table';
      RAISE EXP_REJECT_RECORD;
    END IF;
  EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
    RAISE;
  WHEN OTHERS THEN
    p_resp_code_out := '21';
    p_errmsg_out    := 'Error while updating CMS_SMSANDEMAIL_ALERT table ' ||
    SUBSTR (SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;
  END;
EXCEPTION
WHEN EXP_REJECT_RECORD THEN
  ROLLBACK;
WHEN OTHERS THEN
  ROLLBACK;
  p_resp_code_out := '21';
  p_errmsg_out    :=
  'Exception while updating configured alerts in CMS_SMSANDEMAIL_ALERT' ||
  p_errmsg_out || SUBSTR(SQLERRM, 1, 200);
END TRFR_ALERTS;

PROCEDURE TXN_MAPPING(
    P_INSTCODE_IN     IN NUMBER,
    P_FROMDEL_CHNL_IN IN VARCHAR2,
    P_TODEL_CHNL_IN   IN VARCHAR2,
    P_FROMTXN_CODE_IN IN VARCHAR2,
    P_TO_TRAN_DESC_IN IN VARCHAR2,
    P_USERCODE_IN     IN NUMBER,
    P_RESP_CODE_OUT OUT VARCHAR2,
    P_TO_TRAN_CODE_OUT OUT VARCHAR2,
    P_ERRMSG_OUT OUT VARCHAR2 )
IS
  /****************************************************************************
  **
  * Created by                  : T.Narayanaswamy.
  * Created Date                : 03-November-16
  * Created For                 : FSS-4129
  * Created reason              : Copy Transaction Functionality from Existing
  API
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOST4.11_B0001

  * Modified by                 : DHINAKARAN B
  * Modified Date               : 26-NOV-2019
  * Modified For                : VMS-1415
  * Reviewer                    :  Saravana Kumar A
  * Build Number                :  VMSGPRHOST_R23_B1
  *****************************************************************************
  ****/

  L_TO_TXN_CODE CMS_TRANSACTION_MAST.CTM_TRAN_CODE%TYPE;
  EXP_REJECT_RECORD EXCEPTION;

BEGIN
  p_errmsg_out       := 'OK';
  P_RESP_CODE_OUT    := '00';
  P_TO_TRAN_CODE_OUT :='NA';

  BEGIN
    SELECT
      DECODE(LENGTH(MIN(N)),1,'0'
      ||MIN(N),2,MIN(N),'NA')
    INTO
      l_to_txn_code
    FROM
      (
        SELECT
          ROWNUM N
        FROM
          DUAL
          CONNECT BY LEVEL <= 100
      )
    WHERE
      N >= 0
    AND N NOT IN
      (
        SELECT
          to_number(CTM_TRAN_CODE)
        FROM
          CMS_TRANSACTION_MAST
        WHERE
          CTM_DELIVERY_CHANNEL=P_TODEL_CHNL_IN
        AND CTM_INST_CODE     =P_INSTCODE_IN
      );

    P_TO_TRAN_CODE_OUT :=L_TO_TXN_CODE;

    IF P_TO_TRAN_CODE_OUT    = 'NA' THEN
      P_RESP_CODE_OUT  := '21';
      P_ERRMSG_OUT     := 'To Delivery Channel Transaction Code Reached Maximum Limit, so Transaction Mapping Not Done. Try with another Delivery Channel';
      RAISE EXP_REJECT_RECORD;
    END IF;

  EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
    RAISE;
  WHEN OTHERS THEN
    p_resp_code_out := '21';
    p_errmsg_out    := 'Error while selecting To Transaction Code' || SUBSTR(SQLERRM, 1, 300);
    RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    INSERT
    INTO
      CMS_TRANSACTION_MAST
      (
        CTM_INST_CODE,
        CTM_TRAN_CODE,
        CTM_TRAN_DESC,
        CTM_CREDIT_DEBIT_FLAG,
        CTM_DELIVERY_CHANNEL,
        CTM_OUTPUT_TYPE,
        CTM_TRAN_TYPE,
        CTM_SUPPORT_TYPE,
        CTM_LUPD_DATE,
        CTM_LUPD_USER,
        CTM_INS_DATE,
        CTM_INS_USER,
        CTM_SUPPORT_CATG,
        CTM_PREAUTH_FLAG,
        CTM_AMNT_TRANSFER_FLAG,
        CTM_LOGIN_TXN,
        CTM_PRFL_FLAG,
        CTM_FEE_FLAG,
        CTM_TXN_IND,
        CTM_ADJUSTMENT_FLAG,
        CTM_INITIAL_PREAUTH_IND,
        CTM_DEPLOYMENT_FLAG,
        CTM_LOADTRANS_FLAG,
        CTM_PREAUTH_TYPE,
        CTM_SUCCESS_ALERTS,
        CTM_RVSL_SUCCESS_ALERTS,
        CTM_FAILURE_ALERTS,
        CTM_PRFLUPD_FLAG,
        CTM_DISPLAY_TXNDESC,
        CTM_KYCDISPLAY_FLAG,
        CTM_TXN_MAP_CODE,
        CTM_TXN_MAP_FLAG
      )
      (
        (
          SELECT
            CTM_INST_CODE,
            L_TO_TXN_CODE,
            UPPER(P_TO_TRAN_DESC_IN),
            CTM_CREDIT_DEBIT_FLAG,
            P_TODEL_CHNL_IN,
            CTM_OUTPUT_TYPE,
            CTM_TRAN_TYPE,
            CTM_SUPPORT_TYPE,
            SYSDATE,
            P_USERCODE_IN,
            SYSDATE,
            P_USERCODE_IN,
            CTM_SUPPORT_CATG,
            CTM_PREAUTH_FLAG,
            CTM_AMNT_TRANSFER_FLAG,
            CTM_LOGIN_TXN,
            CTM_PRFL_FLAG,
            CTM_FEE_FLAG,
            CTM_TXN_IND,
            CTM_ADJUSTMENT_FLAG,
            CTM_INITIAL_PREAUTH_IND,
            CTM_DEPLOYMENT_FLAG,
            CTM_LOADTRANS_FLAG,
            CTM_PREAUTH_TYPE,
            CTM_SUCCESS_ALERTS,
            CTM_RVSL_SUCCESS_ALERTS,
            CTM_FAILURE_ALERTS,
            CTM_PRFLUPD_FLAG,
            UPPER(P_TO_TRAN_DESC_IN),
            CTM_KYCDISPLAY_FLAG,
            P_FROMDEL_CHNL_IN||':'||P_FROMTXN_CODE_IN,
            CTM_TXN_MAP_FLAG
          FROM
            cms_transaction_mast
          WHERE
            CTM_TRAN_CODE         =P_FROMTXN_CODE_IN
          AND CTM_DELIVERY_CHANNEL=P_FROMDEL_CHNL_IN
          AND CTM_INST_CODE       =P_INSTCODE_IN
        )
      );
  EXCEPTION
  WHEN OTHERS THEN
    P_RESP_CODE_OUT := '21';
    p_errmsg_out    := 'Error while inserting into CMS_TRANSACTION_MAST table '
    || SUBSTR (SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    INSERT
    INTO
      CMS_TXN_PROPERTIES
      (
        CTP_TXN_CODE,
        CTP_INST_CODE,
        CTP_MSGBODY_PROP,
        CTP_HEADER_PROP,
        CTP_REVERSAL_CODE,
        CTP_MSG_TYPE,
        CTP_DELIVERY_CHANNEL,
        CTP_VALIDATION_PROP,
        CTP_HEADERPROP_VALIDATION,
        CTP_NONMANDATORY_MSGBODY_PROP,
        CTP_NONMANDATORY_VALIDATION
      )
      (
        SELECT
          l_to_txn_code,
          CTP_INST_CODE,
          CTP_MSGBODY_PROP,
          CTP_HEADER_PROP,
          CTP_REVERSAL_CODE,
          CTP_MSG_TYPE,
          P_TODEL_CHNL_IN,
          CTP_VALIDATION_PROP,
          CTP_HEADERPROP_VALIDATION,
          CTP_NONMANDATORY_MSGBODY_PROP,
          CTP_NONMANDATORY_VALIDATION
        FROM
          CMS_TXN_PROPERTIES
        WHERE
          CTP_DELIVERY_CHANNEL=P_FROMDEL_CHNL_IN
        AND CTP_TXN_CODE      =P_FROMTXN_CODE_IN
        AND CTP_INST_CODE     =P_INSTCODE_IN
      );
  EXCEPTION
  WHEN OTHERS THEN
    P_RESP_CODE_OUT := '21';
    p_errmsg_out    := 'Error while inserting into CMS_TXN_PROPERTIES table '
    || SUBSTR (SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    INSERT
    INTO
      CMS_VERIFICATION_CLASSES
      (
        CVC_INST_CODE,
        CVC_VERIFY_CNAME,
        CVC_DAO_CNAME,
        CVC_DELIVERY_CHANEL,
        CVC_TXN_CODE,
        CVC_MSG_TYPE,
        CVC_REVERSAL_CODE,
        CVC_INS_USER,
        CVC_INS_DATE,
        CVC_LUPD_USER,
        CVC_LUPD_DATE
      )
      (
        SELECT
          CVC_INST_CODE,
          CVC_VERIFY_CNAME,
          CVC_DAO_CNAME,
          P_TODEL_CHNL_IN,
          l_to_txn_code,
          CVC_MSG_TYPE,
          CVC_REVERSAL_CODE,
          P_USERCODE_IN,
          SYSDATE,
          P_USERCODE_IN,
          SYSDATE
        FROM
          CMS_VERIFICATION_CLASSES
        WHERE
          CVC_DELIVERY_CHANEL=P_FROMDEL_CHNL_IN
        AND CVC_TXN_CODE     =P_FROMTXN_CODE_IN
        AND CVC_INST_CODE    =P_INSTCODE_IN
      );
  EXCEPTION
  WHEN OTHERS THEN
    P_RESP_CODE_OUT := '21';
    p_errmsg_out    :=
    'Error while inserting into CMS_VERIFICATION_CLASSES table ' || SUBSTR (
    SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
  INSERT
  INTO
    CMS_PRM_MSGQUEUE_SPEC
    (
      CPM_TXN_FIELDNAME,
      CPM_TRANSACTION_CODE,
      CPM_PRM_TYPE,
      CPM_PAD_POS,
      CPM_PADDING_VALUE,
      CPM_LUPD_DATE,
      CPM_INS_DATE,
      CPM_INST_CODE,
      CPM_FIELD_STARTPOSTION,
      CPM_FIELD_NAME,
      CPM_FIELD_LENGTH,
      CPM_FIELD_DEFAULT,
      CPM_DELIVERY_CHANNEL
    )
    (
      SELECT
        CPM_TXN_FIELDNAME,
        l_to_txn_code,
        CPM_PRM_TYPE,
        CPM_PAD_POS,
        CPM_PADDING_VALUE,
        SYSDATE,
        SYSDATE,
        P_INSTCODE_IN,
        CPM_FIELD_STARTPOSTION,
        CPM_FIELD_NAME,
        CPM_FIELD_LENGTH,
        CPM_FIELD_DEFAULT,
        P_TODEL_CHNL_IN
      FROM
        CMS_PRM_MSGQUEUE_SPEC
      WHERE
        CPM_DELIVERY_CHANNEL   =P_FROMDEL_CHNL_IN
      AND CPM_TRANSACTION_CODE =P_FROMTXN_CODE_IN
      AND CPM_INST_CODE        = P_INSTCODE_IN
    );
EXCEPTION
WHEN OTHERS THEN
  P_RESP_CODE_OUT := '21';
  p_errmsg_out    := 'Error while inserting into CMS_PRM_MSGQUEUE_SPEC table '
  || SUBSTR ( SQLERRM, 1, 200);
  RAISE EXP_REJECT_RECORD;
END;

EXCEPTION
WHEN EXP_REJECT_RECORD THEN
  ROLLBACK;
WHEN OTHERS THEN
  ROLLBACK;
  P_RESP_CODE_OUT := '21';
  p_errmsg_out    := 'Exception while doing Transaction Mapping' ||p_errmsg_out
  || SUBSTR(SQLERRM, 1, 200);
END TXN_MAPPING;

   -- Function and procedure implementations
   function CHECK_OVERLAPS (P_EXISTING_SERIAL_IN    varchar2,
                            p_new_serial_in         VARCHAR2)
      RETURN VARCHAR2
   as
      L_START_SERIAL   varchar2 (10);
      l_end_serial    VARCHAR2 (10);
      l_resp_msg     VARCHAR2 (100) := 'OK';
   BEGIN
      L_START_SERIAL := SUBSTR (p_new_serial_in, 1, 6);
      l_end_serial := SUBSTR (p_new_serial_in, 8);

      for L_IDX
         IN (SELECT SUBSTR (period, 1, 6) start_serial, SUBSTR (period, 8) end_serial
               FROM (    SELECT REGEXP_SUBSTR (P_EXISTING_SERIAL_IN, '[^|]+', 1, LEVEL) period
                           FROM DUAL
                     CONNECT BY REGEXP_SUBSTR (P_EXISTING_SERIAL_IN, '[^|]+', 1, LEVEL) IS NOT NULL))
      LOOP
         IF ( (L_START_SERIAL >= l_idx.start_serial
               AND L_START_SERIAL <= l_idx.end_serial)
             OR (l_end_serial >= l_idx.start_serial
                 AND l_end_serial <= l_idx.end_serial)
             OR (L_START_SERIAL <= l_idx.start_serial
                 AND l_end_serial >= l_idx.end_serial))
         THEN
            l_resp_msg := 'THERE IS OVERLAP';
            EXIT;
         END IF;
      END LOOP;


      return L_RESP_MSG;
   END check_overlaps;

 --Sn  Transaction Details
PROCEDURE get_transaction_details(p_inst_code_in          IN   NUMBER,
                                  p_delivery_channel_in   IN   VARCHAR2,
                                  p_tran_code_in          IN   VARCHAR2,
                                  p_cr_dr_flag_out        OUT  VARCHAR2,
                                  p_tran_type_out         OUT  VARCHAR2,
                                  p_tran_desc_out         OUT  VARCHAR2,
                                  p_prfl_flag_out         OUT  VARCHAR2,
                                  p_preauth_flag_out      OUT  VARCHAR2,
                                  p_login_txn_out         OUT  VARCHAR2,
                                  p_preauth_type_out      OUT  VARCHAR2,
                                  p_dup_rrn_check_out     OUT  VARCHAR2,
                                  p_resp_code_out         OUT  VARCHAR2,
                                  p_errmsg_out            OUT  VARCHAR2)
 IS

 BEGIN
  p_errmsg_out    := 'OK';
  p_resp_code_out := '00';

  --Sn find debit and credit flag
  BEGIN
    SELECT CTM_CREDIT_DEBIT_FLAG,
           TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
           CTM_TRAN_DESC,
           CTM_PRFL_FLAG,
           CTM_PREAUTH_FLAG,
           CTM_LOGIN_TXN,
           CTM_PREAUTH_TYPE,
           NVL(CTM_RRN_CHECK,'Y')
    INTO   p_cr_dr_flag_out,
           p_tran_type_out,
           p_tran_desc_out,
           p_prfl_flag_out,
           p_preauth_flag_out,
           p_login_txn_out,
           p_preauth_type_out,
           p_dup_rrn_check_out
    FROM   CMS_TRANSACTION_MAST
    WHERE  CTM_INST_CODE = p_inst_code_in
    AND    CTM_DELIVERY_CHANNEL = p_delivery_channel_in
    AND    CTM_TRAN_CODE = p_tran_code_in;
  EXCEPTION
       WHEN NO_DATA_FOUND   THEN
                p_resp_code_out := '21';
                p_errmsg_out :=  'Transflag  not defined for txn code ' || p_tran_code_in || ' and delivery channel ' || p_delivery_channel_in;
        WHEN OTHERS THEN
            p_resp_code_out := '21';
            p_errmsg_out := 'Error while selecting CMS_TRANSACTION_MAST' ||SUBSTR(SQLERRM, 1, 200);
   END;
    --En find debit and credit flag
END get_transaction_details;
-- EN Transaction Details

-- Sn validating Date Time RRN
PROCEDURE validate_date_rrn( P_INST_CODE_IN        IN  NUMBER,
                             P_RRN_IN              IN  VARCHAR2,
                             P_TRANDATE_IN         IN  VARCHAR2,
                             P_TRANTIME_IN         IN  VARCHAR2,
                             P_DELIVERY_CHANNEL_IN IN  VARCHAR2,
                             P_ERRMSG_OUT          OUT VARCHAR2,
                             P_RESP_CODE_OUT       OUT VARCHAR2)
IS
L_TRAN_DATE           DATE;
L_RRN_COUNT           NUMBER;

BEGIN
    P_ERRMSG_OUT    := 'OK';
    P_RESP_CODE_OUT := '00';

 --Sn Transaction Date Check
    BEGIN
        L_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE_IN), 1, 8), 'yyyymmdd');
    EXCEPTION
        WHEN OTHERS THEN
            P_RESP_CODE_OUT := '21';
            P_ERRMSG_OUT   := 'Problem while converting transaction date ' ||P_TRANDATE_IN|| SUBSTR(SQLERRM, 1, 200);
            return;
    END;
    --En Transaction Date Check

    --Sn Transaction Time Check
    BEGIN
        L_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE_IN), 1, 8) || ' ' || SUBSTR(TRIM(P_TRANTIME_IN), 1, 10),'yyyymmdd hh24:mi:ss');
    EXCEPTION
        WHEN OTHERS THEN
            P_RESP_CODE_OUT := '21';
            P_ERRMSG_OUT   := 'Problem while converting transaction Time ' || SUBSTR(SQLERRM, 1, 200);
            return;
    END;
    --En Transaction Time Check

      --Sn Duplicate RRN Check.IF duplicate RRN log the txn and return
    BEGIN
        SELECT COUNT(1)
        INTO L_RRN_COUNT
        FROM TRANSACTIONLOG
        WHERE INSTCODE = P_INST_CODE_IN AND RRN = P_RRN_IN AND
        BUSINESS_DATE = P_TRANDATE_IN AND
        DELIVERY_CHANNEL = P_DELIVERY_CHANNEL_IN;

        IF L_RRN_COUNT > 0 THEN
            P_RESP_CODE_OUT := '22';
            P_ERRMSG_OUT   := 'Duplicate RRN ';
            return;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            P_RESP_CODE_OUT := '21';
            P_ERRMSG_OUT := 'Error while selecting rrn count  ' ||  SUBSTR(SQLERRM, 1, 200);
            return;
    END;
    --En Duplicate RRN Check

END validate_date_rrn;
-- En validating Date Time RRN

PROCEDURE   authorize_nonfinancial_txn (
   p_inst_code_in           IN       NUMBER,
   p_msg_type_in            IN       VARCHAR2,
   p_rrn_in                 IN       VARCHAR2,
   p_delivery_channel_in    IN       cms_delchannel_mast.cdm_channel_code%TYPE,
   p_txn_code_in            IN       cms_transaction_mast.ctm_tran_code%TYPE,
   p_txn_mode_in            IN       VARCHAR2,
   p_tran_date_in           IN       VARCHAR2,
   p_tran_time_in           IN       VARCHAR2,
   p_rvsl_code_in           IN       VARCHAR2,
   p_tran_type_in           IN       cms_transaction_mast.ctm_tran_type%TYPE,
   p_pan_code_in            IN       VARCHAR2,
   p_hash_pan_in            IN       cms_appl_pan.cap_pan_code%TYPE,
   p_encr_pan_in            IN       cms_appl_pan.cap_pan_code_encr%TYPE,
   p_acct_no_in             IN       cms_acct_mast.cam_acct_no%TYPE,
   p_card_stat_in           IN       cms_appl_pan.cap_card_stat%TYPE,
   p_expry_date_in          IN       cms_appl_pan.cap_expry_date%TYPE,
   p_prod_code_in           IN       cms_appl_pan.cap_prfl_code%TYPE,
   p_card_type_in           IN       cms_appl_pan.cap_card_type%TYPE,
   p_prfl_flag_in           IN       cms_transaction_mast.ctm_prfl_flag%TYPE,
   p_prfl_code_in           IN       cms_appl_pan.cap_prfl_code%TYPE,
   p_txn_type_in            IN       VARCHAR2,
   p_curr_code_in           IN       VARCHAR2,
   p_preauth_flag_in        IN       cms_transaction_mast.ctm_preauth_flag%TYPE,
   p_trans_desc_in          IN       cms_transaction_mast.ctm_tran_desc%TYPE,
   p_dr_cr_flag_in          IN       cms_transaction_mast.ctm_credit_debit_flag%TYPE,
   p_login_txn_in           IN       cms_transaction_mast.ctm_login_txn%TYPE,
   p_resp_code_out          OUT      VARCHAR2,
   p_res_msg_out            OUT      VARCHAR2,
   p_comb_hash_out          OUT      pkg_limits_check.type_hash,
   p_auth_id_out            OUT      transactionlog.auth_id%TYPE,
   p_fee_code_out           OUT      transactionlog.feecode%TYPE,
   p_fee_plan_out           OUT      transactionlog.fee_plan%TYPE,
   p_feeattach_type_out     OUT      transactionlog.feeattachtype%TYPE,
   p_tranfee_amt_out        OUT      transactionlog.tranfee_amt%TYPE,
   p_total_amt_out          OUT      transactionlog.total_amount%TYPE,
   p_preauth_type_out       OUT      cms_transaction_mast.ctm_preauth_type%TYPE
)
AS
   l_tran_date         DATE;
   l_tran_amt          NUMBER (9, 3):=0;
   l_status_chk        NUMBER;
   l_precheck_flag     NUMBER;
   l_acct_balance      cms_acct_mast.cam_acct_bal%TYPE;
   l_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
   l_acct_type         cms_acct_mast.cam_type_code%TYPE;
   l_timestamp         TIMESTAMP;
   v_compl_fee varchar2(10);
   v_compl_feetxn_excd varchar2(10);
   v_compl_feecode varchar2(10);
Begin

   --Sn GPR Card status check
   p_res_msg_out      :='OK';

   BEGIN
      sp_status_check_gpr (p_inst_code_in,
                           p_pan_code_in,
                           p_delivery_channel_in,
                           p_expry_date_in,
                           p_card_stat_in,
                           p_txn_code_in,
                           p_txn_mode_in,
                           p_prod_code_in,
                           p_card_type_in,
                           p_msg_type_in,
                           p_tran_date_in,
                           p_tran_time_in,
                           NULL,
                           NULL,
                           NULL,
                           p_resp_code_out,
                           p_res_msg_out
                          );

      IF (   (p_resp_code_out <> '1' AND p_res_msg_out <> 'OK')
          OR (p_resp_code_out <> '0' AND p_res_msg_out <> 'OK')
         )
      THEN
         return;
      ELSE
         l_status_chk := p_resp_code_out;
         p_resp_code_out := '1';
      END IF;
   EXCEPTION
      WHEN OTHERS  THEN
         p_resp_code_out := '21';
         p_res_msg_out :=  'Error from GPR Card Status Check '|| SUBSTR (SQLERRM, 1, 200);
         return;
   END;

   --En GPR Card status check
   IF l_status_chk = '1'
   THEN
      -- Expiry Check
      BEGIN
         IF TO_DATE (p_tran_date_in, 'YYYYMMDD') >  LAST_DAY (TO_CHAR (p_expry_date_in, 'DD-MON-YY'))
         THEN
            p_resp_code_out := '13';
            p_res_msg_out := 'EXPIRED CARD';
            return;
         END IF;
      EXCEPTION
         WHEN OTHERS    THEN
            p_resp_code_out := '21';
            p_res_msg_out :='ERROR IN EXPIRY DATE CHECK ' || SUBSTR (SQLERRM, 1, 200);
           return;
      END;

      --Sn select authorization processe flag
      BEGIN
         SELECT ptp_param_value
           INTO l_precheck_flag
           FROM pcms_tranauth_param
          WHERE ptp_param_name = 'PRE CHECK' AND ptp_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS   THEN
            p_resp_code_out := '21';
            p_res_msg_out :=  'Error while selecting precheck flag' || SUBSTR (SQLERRM, 1, 200);
            return;
      END;

      --Sn check for precheck
      IF l_precheck_flag = 1
      THEN
         BEGIN
            sp_precheck_txn (p_inst_code_in,
                             p_pan_code_in,
                             p_delivery_channel_in,
                             p_expry_date_in,
                             p_card_stat_in,
                             p_txn_code_in,
                             p_txn_mode_in,
                             p_tran_date_in,
                             p_tran_time_in,
                             l_tran_amt,
                             NULL,
                             NULL,
                             p_resp_code_out,
                             p_res_msg_out
                            );

            IF (p_resp_code_out <> '1' OR p_res_msg_out <> 'OK')
            THEN
               return;
            END IF;
         EXCEPTION
            WHEN OTHERS   THEN
               p_resp_code_out := '21';
               p_res_msg_out := 'Error from precheck processes '  || SUBSTR (SQLERRM, 1, 200);
               return;
         END;
      END IF;
   END IF;

   --Start  Limit check
   IF p_prfl_code_in IS NOT NULL AND p_prfl_flag_in = 'Y'
   THEN
      BEGIN
         pkg_limits_check.sp_limits_check
                                  (p_hash_pan_in,
                                   NULL,
                                   NULL,
                                   null,
                                   p_txn_code_in,
                                   case  p_tran_type_in when '0' then
                                    'N' else  'F' end,
                                   --p_tran_type_in,
                                   null,
                                   null,
                                   p_inst_code_in,
                                   NULL,
                                   p_prfl_code_in,
                                   l_tran_amt,
                                   p_delivery_channel_in,
                                   p_comb_hash_out,
                                   p_resp_code_out,
                                   p_res_msg_out
                                  );

         IF p_res_msg_out <> 'OK'
         THEN
            IF p_delivery_channel_in = '13' AND p_txn_code_in = '28'
            THEN
               p_res_msg_out := 'MATCHRULEFAILED' || p_res_msg_out;
               return;
            END IF;

            return;
         END IF;

      EXCEPTION
         WHEN OTHERS    THEN
            p_resp_code_out := '21';
            p_res_msg_out :=  'Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
            return;
      END;
   END IF;


--End  Limit check


              --SN : Get account balance details from acct master
     BEGIN
        SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
          INTO l_acct_balance, l_ledger_bal, l_acct_type
          FROM cms_acct_mast
         WHERE cam_acct_no = p_acct_no_in
               AND cam_inst_code = p_inst_code_in
        FOR UPDATE;
     EXCEPTION
        WHEN OTHERS  THEN
           p_resp_code_out := '89';
           p_res_msg_out :=   'Error while selecting account balance ' || SUBSTR (SQLERRM, 1, 200);
           return;
     END;

     --EN : Get account balance details from acct master

     BEGIN
        SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
          INTO p_auth_id_out
          FROM DUAL;
     EXCEPTION
        WHEN OTHERS  THEN
           p_resp_code_out := '21';
           p_res_msg_out :=  'Error while generating authid-' || SUBSTR (SQLERRM, 1, 300);
           return;
     END;

     l_timestamp := SYSTIMESTAMP;

     BEGIN
        sp_fee_calc (p_inst_code_in,
                     p_msg_type_in,
                     p_rrn_in,
                     p_delivery_channel_in,
                     p_txn_code_in,
                     '0',
                     p_tran_date_in,
                     p_tran_time_in,
                     '000',
                     p_rvsl_code_in,
                     p_txn_type_in,
                     p_curr_code_in,
                     l_tran_amt,
                     p_pan_code_in,
                     p_hash_pan_in,
                     p_encr_pan_in,
                     p_acct_no_in,
                     p_prod_code_in,
                     p_card_type_in,
                     p_preauth_flag_in,
                     NULL,
                     NULL,
                     NULL,
                     p_trans_desc_in,
                     p_dr_cr_flag_in,
                     l_acct_balance,
                     l_ledger_bal,
                     l_acct_type,
                     p_login_txn_in,
                     p_auth_id_out,
                     l_timestamp,
                     p_resp_code_out,
                     p_res_msg_out,
                     p_fee_code_out,
                     p_fee_plan_out,
                     p_feeattach_type_out,
                     p_tranfee_amt_out,
                     p_total_amt_out,
                     v_compl_fee,
                     v_compl_feetxn_excd,
                     v_compl_feecode,
                     p_preauth_type_out);

        IF p_res_msg_out <> 'OK'
        THEN
           return;
        END IF;
     EXCEPTION
       WHEN OTHERS    THEN
           p_resp_code_out := '21';
           p_res_msg_out :=  'Error from sp_fee_calc  ' || SUBSTR (SQLERRM, 1, 200);
           return;
     END;

     --SN :Update limits
     IF p_prfl_code_in IS NOT NULL AND p_prfl_flag_in = 'Y'
     THEN
        BEGIN
           pkg_limits_check.sp_limitcnt_reset (p_inst_code_in,
                                               p_hash_pan_in,
                                               l_tran_amt,
                                               p_comb_hash_out,
                                               p_resp_code_out,
                                               p_res_msg_out);

           IF p_res_msg_out <> 'OK'
           THEN
              p_res_msg_out := 'From Procedure sp_limitcnt_reset-' || p_res_msg_out;
              return;
           END IF;
        EXCEPTION
           WHEN OTHERS   THEN
              p_resp_code_out := '21';
              p_res_msg_out :=   'Error from Limit Reset Count Process-' || SUBSTR (SQLERRM, 1, 200);
              return;
        END;
     END IF;
EXCEPTION
   WHEN OTHERS   THEN
      ROLLBACK;
      p_resp_code_out := '69';
      p_res_msg_out := 'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END authorize_nonfinancial_txn;

PROCEDURE authorize_financial_txn (
   p_inst_code_in           IN       NUMBER,
   p_msg_type_in            IN       VARCHAR2,
   p_rrn_in                 IN       VARCHAR2,
   p_delivery_channel_in    IN       VARCHAR2,
   p_terminal_id_in         IN       VARCHAR2,
   p_txn_code_in            IN       VARCHAR2,
   p_txn_mode_in            IN       VARCHAR2,
   p_tran_date_in           IN       VARCHAR2,
   p_tran_time_in           IN       VARCHAR2,
   p_card_no_in             IN       VARCHAR2,
   p_hash_pan_in            IN       cms_appl_pan.cap_pan_code%TYPE,
   p_encr_pan_in            IN       cms_appl_pan.cap_pan_code_encr%TYPE,
   p_card_status_in         IN       cms_appl_pan.cap_card_stat%TYPE,
   p_proxy_number_in        IN       cms_appl_pan.cap_proxy_number%TYPE,
   p_acct_no_in             IN       cms_acct_mast.cam_acct_no%TYPE,
   p_expry_date_in          IN       cms_appl_pan.cap_expry_date%TYPE,
   p_prod_code_in           IN       cms_appl_pan.cap_prfl_code%TYPE,
   p_card_type_in           IN       cms_appl_pan.cap_card_type%TYPE,
   p_prfl_flag_in           IN       cms_transaction_mast.ctm_prfl_flag%TYPE,
   p_prfl_code_in           IN       cms_appl_pan.cap_prfl_code%TYPE,
   p_txn_type_in            IN       VARCHAR2,
   p_curr_code_in           IN       VARCHAR2,
   p_preauth_flag_in        IN       cms_transaction_mast.ctm_preauth_flag%TYPE,
   p_trans_desc_in          IN       cms_transaction_mast.ctm_tran_desc%TYPE,
   p_dr_cr_flag_in          IN       cms_transaction_mast.ctm_credit_debit_flag%TYPE,
   p_login_txn_in           IN       cms_transaction_mast.ctm_login_txn%TYPE,
   p_amnt_tnfr_flag_in      IN       cms_transaction_mast.ctm_amnt_transfer_flag%TYPE,
   p_bank_code_in           IN       VARCHAR2,
   p_txn_amt_in             IN       NUMBER,
   p_merchant_name_in       IN       VARCHAR2,
   p_merchant_city_in       IN       VARCHAR2,
   p_mcc_code_in            IN       VARCHAR2,
   p_tip_amt_in             IN       VARCHAR2,
   p_to_acct_no_in          IN       VARCHAR2,
   p_atmname_loc_in         IN       VARCHAR2,
   p_mcccode_groupid_in     IN       VARCHAR2,
   p_currcode_groupid_in    IN       VARCHAR2,
   p_transcode_groupid_in   IN       VARCHAR2,
   p_rules_in               IN       VARCHAR2,
   p_preauth_date_in        IN       DATE,
   p_consodium_code_in      IN       VARCHAR2,
   p_partner_code_in        IN       VARCHAR2,
   p_stan_in                IN       VARCHAR2,
   p_rvsl_code_in           IN       VARCHAR2,
   p_fee_flag_in            IN       VARCHAR2 ,
   p_admin_flag_in          IN       VARCHAR2 ,
   p_ip_addr_in                IN       VARCHAR2,
   p_ani_in                    IN       VARCHAR2,
   p_dni_in                    IN       VARCHAR2,
   p_device_mob_no_in          IN       VARCHAR2,
   p_device_id_in              IN       VARCHAR2,
   p_uuid_in                   IN       VARCHAR2,
   p_os_name_in                IN       VARCHAR2,
   p_os_version_in             IN       VARCHAR2,
   p_gps_coordinates_in        IN       VARCHAR2,
   p_display_resolution_in     IN       VARCHAR2,
   p_physical_memory_in        IN       VARCHAR2,
   p_app_name_in               IN       VARCHAR2,
   p_app_version_in            IN       VARCHAR2,
   p_session_id_in             IN       VARCHAR2,
   p_device_country_in         IN       VARCHAR2,
   p_device_region_in          IN       VARCHAR2,
   p_comments_in              in   varchar2,
   p_auth_id_out            OUT      VARCHAR2,
   p_resp_code_out          OUT      VARCHAR2,
   p_resp_msg_out           OUT      VARCHAR2
)
IS
   l_err_msg                VARCHAR2 (900)                            := 'OK';
   l_acct_balance           NUMBER;
   l_tran_amt               NUMBER                                       := 0;
   l_total_amt              NUMBER;
   l_tran_date              DATE;
   l_fee_amt                NUMBER;
   l_total_fee              NUMBER;
   l_upd_amt                NUMBER;
   l_narration              VARCHAR2 (300);
   l_opening_bal            NUMBER;
   l_precheck_flag          NUMBER;
   l_preauth_flag           NUMBER;
   l_tran_fee               NUMBER;
   l_error                  VARCHAR2 (500);
   l_business_date          DATE;
   l_business_time          VARCHAR2 (5);
   l_cutoff_time            VARCHAR2 (5);
   l_fee_code               cms_fee_mast.cfm_fee_code%TYPE;
   l_fee_crgl_catg          cms_prodcattype_fees.cpf_crgl_catg%TYPE;
   l_fee_crgl_code          cms_prodcattype_fees.cpf_crgl_code%TYPE;
   l_fee_crsubgl_code       cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
   l_fee_cracct_no          cms_prodcattype_fees.cpf_cracct_no%TYPE;
   l_fee_drgl_catg          cms_prodcattype_fees.cpf_drgl_catg%TYPE;
   l_fee_drgl_code          cms_prodcattype_fees.cpf_drgl_code%TYPE;
   l_fee_drsubgl_code       cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
   l_fee_dracct_no          cms_prodcattype_fees.cpf_dracct_no%TYPE;
   l_servicetax_percent     cms_inst_param.cip_param_value%TYPE;
   l_cess_percent           cms_inst_param.cip_param_value%TYPE;
   l_servicetax_amount      NUMBER;
   l_cess_amount            NUMBER;
   l_st_calc_flag           cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
   l_cess_calc_flag         cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
   l_st_cracct_no           cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
   l_st_dracct_no           cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
   l_cess_cracct_no         cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
   l_cess_dracct_no         cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
   l_waiv_percnt            cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
   l_err_waiv               VARCHAR2 (300);
   l_log_actual_fee         NUMBER;
   l_log_waiver_amt         NUMBER;
   l_actual_exprydate       DATE;
   l_mini_totrec            NUMBER (2);
   l_ministmt_errmsg        VARCHAR2 (500);
   l_ministmt_output        VARCHAR2 (900);
   l_fee_attach_type        VARCHAR2 (1);
   exp_reject_record        EXCEPTION;
   l_ledger_bal             NUMBER;
   l_card_acct_no           VARCHAR2 (20);
   l_max_card_bal           NUMBER;
   l_min_act_amt            NUMBER;
   l_curr_date              DATE;
   l_upd_ledger_bal         NUMBER;
   l_status_chk             NUMBER;
   l_toacct_no              cms_statements_log.csl_to_acctno%TYPE;
   l_internation_ind        cms_fee_mast.cfm_intl_indicator%TYPE;
   l_pos_verfication        cms_fee_mast.cfm_pin_sign%TYPE;
   l_feeamnt_type           cms_fee_mast.cfm_feeamnt_type%TYPE;
   l_per_fees               cms_fee_mast.cfm_per_fees%TYPE;
   l_flat_fees              cms_fee_mast.cfm_fee_amt%TYPE;
   l_clawback               cms_fee_mast.cfm_clawback_flag%TYPE;
   l_fee_plan               cms_fee_feeplan.cff_fee_plan%TYPE;
   l_clawback_amnt          cms_fee_mast.cfm_fee_amt%TYPE;
   l_actual_fee_amnt        NUMBER;
   l_clawback_count         NUMBER;
   l_freetxn_exceed         VARCHAR2 (1);
   l_duration               VARCHAR2 (20);
   l_feeattach_type         VARCHAR2 (2);
   l_cam_type_code          cms_acct_mast.cam_type_code%TYPE;
   l_timestamp              TIMESTAMP;
   l_fee_desc               cms_fee_mast.cfm_fee_desc%TYPE;
   l_rrn_count              NUMBER;
   l_tot_clwbck_count       cms_fee_mast.cfm_clawback_count%TYPE;
   l_chrg_dtl_cnt           NUMBER;
   l_profile_code           cms_prod_cattype.cpc_profile_code%TYPE;
   l_badcredit_flag         cms_prod_cattype.cpc_badcredit_flag%TYPE;
   l_badcredit_transgrpid   vms_group_tran_detl.vgd_group_id%TYPE;
   l_cnt                    NUMBER;
   l_card_stat              cms_appl_pan.cap_card_stat%TYPE           := '12';
   l_enable_flag            VARCHAR2 (20)                              := 'Y';
   l_initialload_amt        cms_acct_mast.cam_new_initialload_amt%TYPE;
   l_hashkey_id             cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   l_comb_hash          pkg_limits_check.type_hash;
BEGIN
   p_resp_code_out := '1';
   p_resp_msg_out := 'OK';
   l_tran_amt := NVL (p_txn_amt_in, 0);
   l_timestamp := SYSTIMESTAMP;

   BEGIN
      l_hashkey_id :=
         gethash (   p_delivery_channel_in
                  || p_txn_code_in
                  || p_card_no_in
                  || p_rrn_in
                  || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5')
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         l_err_msg :=
            'Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
        INTO p_auth_id_out
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_err_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '21';                          -- Server Declined
         RAISE exp_reject_record;
   END;

   --En generate auth id

   --Sn check txn currency
   BEGIN
      IF TRIM (p_curr_code_in) IS NULL
      THEN
         p_resp_code_out := '21';
         l_err_msg := 'Transaction currency  cannot be null ';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_err_msg :=
               'Error while selecting Transcurrency  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En check txn currency

   --Sn get date
   BEGIN
      l_tran_date :=
         TO_DATE (   SUBSTR (TRIM (p_tran_date_in), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_tran_time_in), 1, 10),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_err_msg :=
               'Problem while converting transaction date '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En get date
   --Sn find service tax
   BEGIN
      SELECT cip_param_value
        INTO l_servicetax_percent
        FROM cms_inst_param
       WHERE cip_param_key = 'SERVICETAX' AND cip_inst_code = p_inst_code_in;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code_out := '21';
         l_err_msg := 'Service Tax is  not defined in the system';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_err_msg := 'Error while selecting service tax from system ';
         RAISE exp_reject_record;
   END;

   --En find service tax

   --Sn find cess
   BEGIN
      SELECT cip_param_value
        INTO l_cess_percent
        FROM cms_inst_param
       WHERE cip_param_key = 'CESS' AND cip_inst_code = p_inst_code_in;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code_out := '21';
         l_err_msg := 'Cess is not defined in the system';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_err_msg := 'Error while selecting cess from system ';
         RAISE exp_reject_record;
   END;

   --En find cess

   ---Sn find cutoff time
   BEGIN
      SELECT cip_param_value
        INTO l_cutoff_time
        FROM cms_inst_param
       WHERE cip_param_key = 'CUTOFF' AND cip_inst_code = p_inst_code_in;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         l_cutoff_time := 0;
         p_resp_code_out := '21';
         l_err_msg := 'Cutoff time is not defined in the system';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_err_msg := 'Error while selecting cutoff  dtl  from system ';
         RAISE exp_reject_record;
   END;

   ---En find cutoff time

   --Sn select authorization processe flag
   BEGIN
      SELECT ptp_param_value
        INTO l_precheck_flag
        FROM pcms_tranauth_param
       WHERE ptp_param_name = 'PRE CHECK' AND ptp_inst_code = p_inst_code_in;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code_out := '21';                    --only for master setups
         l_err_msg := 'Master set up is not done for Authorization Process';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';                    --only for master setups
         l_err_msg :=
            'Error while selecting precheck flag' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En select authorization process    flag
   --Sn select authorization processe flag
   BEGIN
      SELECT ptp_param_value
        INTO l_preauth_flag
        FROM pcms_tranauth_param
       WHERE ptp_param_name = 'PRE AUTH' AND ptp_inst_code = p_inst_code_in;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code_out := '21';                    --only for master setups
         l_err_msg := 'Master set up is not done for Authorization Process';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';                    --only for master setups
         l_err_msg :=
             'Error while selecting preauth flag' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En select authorization process    flag
   --Sn find card detail
   BEGIN
      sp_status_check_gpr (p_inst_code_in,
                           p_card_no_in,
                           p_delivery_channel_in,
                           p_expry_date_in,
                           p_card_status_in,
                           p_txn_code_in,
                           p_txn_mode_in,
                           p_prod_code_in,
                           p_card_type_in,
                           p_msg_type_in,
                           p_tran_date_in,
                           p_tran_time_in,
                           NULL,
                           NULL,
                           p_mcc_code_in,
                           p_resp_code_out,
                           l_err_msg
                          );

      IF (   (p_resp_code_out <> '1' AND l_err_msg <> 'OK')
          OR (p_resp_code_out <> '0' AND l_err_msg <> 'OK')
         )
      THEN
         RAISE exp_reject_record;
      ELSE
         l_status_chk := p_resp_code_out;
         p_resp_code_out := '1';
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_err_msg :=
              'Error from GPR Card Status Check ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En GPR Card status check
   IF l_status_chk = '1'
   THEN
      -- Expiry Check
      IF p_delivery_channel_in <> '11'
      THEN
         BEGIN
            IF     p_delivery_channel_in = '03'
               AND p_txn_code_in IN
                       ('22', '29', '75', '13', '14', '38', '39', '83', '17')
            THEN
               p_resp_code_out := '1';
            ELSE
               IF TO_DATE (p_tran_date_in, 'YYYYMMDD') >
                            LAST_DAY (TO_CHAR (p_expry_date_in, 'DD-MON-YY'))
               THEN
                  p_resp_code_out := '13';
                  l_err_msg := 'EXPIRED CARD';
                  RAISE exp_reject_record;
               END IF;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_err_msg :=
                     'ERROR IN EXPIRY DATE CHECK : Tran Date - '
                  || p_tran_date_in
                  || ', Expiry Date - '
                  || p_expry_date_in
                  || ','
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      -- End Expiry Check

      --Sn check for precheck
      IF p_admin_flag_in <> 'Y'
      THEN
         IF l_precheck_flag = 1
         THEN
            BEGIN
               sp_precheck_txn (p_inst_code_in,
                                p_card_no_in,
                                p_delivery_channel_in,
                                p_expry_date_in,
                                p_card_status_in,
                                p_txn_code_in,
                                p_txn_mode_in,
                                p_tran_date_in,
                                p_tran_time_in,
                                l_tran_amt,
                                NULL,
                                NULL,
                                p_resp_code_out,
                                l_err_msg
                               );

               IF (p_resp_code_out <> '1' OR l_err_msg <> 'OK')
               THEN
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  p_resp_code_out := '21';
                  l_err_msg :=
                        'Error from precheck processes '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;
      END IF;
   END IF;

   --En check for Precheck
   --Sn check for Preauth
   IF l_preauth_flag = 1
   THEN
      BEGIN
         sp_preauthorize_txn (p_card_no_in,
                              p_mcc_code_in,
                              p_curr_code_in,
                              l_tran_date,
                              p_txn_code_in,
                              p_inst_code_in,
                              p_tran_date_in,
                              p_txn_amt_in,
                              p_delivery_channel_in,
                              p_resp_code_out,
                              l_err_msg
                             );

         IF (p_resp_code_out <> '1' OR l_err_msg <> 'OK')
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_err_msg :=
                   'Error from pre_auth process ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;

   --En check for preauth

   --Get the card no
   BEGIN
      SELECT     cam_acct_bal, cam_ledger_bal, cam_acct_no,
                 cam_type_code,
                 NVL (cam_new_initialload_amt, cam_initialload_amt)
            INTO l_acct_balance, l_ledger_bal, l_card_acct_no,
                 l_cam_type_code,
                 l_initialload_amt
            FROM cms_acct_mast
           WHERE cam_acct_no = p_acct_no_in AND cam_inst_code = p_inst_code_in
      FOR UPDATE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code_out := '14';                    --Ineligible Transaction
         l_err_msg := 'Invalid Card ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code_out := '12';
         l_err_msg :=
               'Error while selecting data from card Master for card number ';
         RAISE exp_reject_record;
   END;

   l_timestamp := SYSTIMESTAMP;

   BEGIN
      sp_dup_rrn_check (p_hash_pan_in,
                        p_rrn_in,
                        p_tran_date_in,
                        p_delivery_channel_in,
                        p_msg_type_in,
                        p_txn_code_in,
                        l_err_msg
                       );

      IF l_err_msg <> 'OK'
      THEN
         p_resp_code_out := '22';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         p_resp_code_out := '22';
         l_err_msg := 'Error while checking RRN' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   ---Sn dynamic fee calculation .

   IF p_prfl_code_in IS NOT NULL AND p_prfl_flag_in = 'Y'
   THEN
      BEGIN
         pkg_limits_check.sp_limits_check
                                  (p_hash_pan_in,
                                   NULL,
                                   NULL,
                                   null,
                                   p_txn_code_in,
                                    case  p_txn_type_in when '0' then
                                    'N' else  'F' end,
                                  -- p_txn_type_in,
                                   null,
                                   null,
                                   p_inst_code_in,
                                   NULL,
                                   p_prfl_code_in,
                                   l_tran_amt,
                                   p_delivery_channel_in,
                                   l_comb_hash,
                                   p_resp_code_out,
                                   l_err_msg
                                  );

         IF l_err_msg <> 'OK'
         THEN
            IF p_delivery_channel_in = '13' AND p_txn_code_in = '28'
            THEN
               l_err_msg := 'MATCHRULEFAILED' || l_err_msg;
               raise exp_reject_record;
            END IF;

           raise exp_reject_record;
         END IF;

      EXCEPTION
         when exp_reject_record then
            raise;
         WHEN OTHERS    THEN
            p_resp_code_out := '21';
            l_err_msg :=  'Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
            raise exp_reject_record;
      END;
   END IF;

   BEGIN
      sp_tran_fees_cmsauth (p_inst_code_in,
                            p_card_no_in,
                            p_delivery_channel_in,
                            p_txn_type_in,
                            p_txn_mode_in,
                            p_txn_code_in,
                            p_curr_code_in,
                            p_consodium_code_in,
                            p_partner_code_in,
                            l_tran_amt,
                            l_tran_date,
                            l_internation_ind,
                            l_pos_verfication,
                            p_resp_code_out,
                            p_msg_type_in,
                            p_rvsl_code_in,
                            p_mcc_code_in,
                            l_fee_amt,
                            l_error,
                            l_fee_code,
                            l_fee_crgl_catg,
                            l_fee_crgl_code,
                            l_fee_crsubgl_code,
                            l_fee_cracct_no,
                            l_fee_drgl_catg,
                            l_fee_drgl_code,
                            l_fee_drsubgl_code,
                            l_fee_dracct_no,
                            l_st_calc_flag,
                            l_cess_calc_flag,
                            l_st_cracct_no,
                            l_st_dracct_no,
                            l_cess_cracct_no,
                            l_cess_dracct_no,
                            l_feeamnt_type,
                            l_clawback,
                            l_fee_plan,
                            l_per_fees,
                            l_flat_fees,
                            l_freetxn_exceed,
                            l_duration,
                            l_feeattach_type,
                            l_fee_desc
                           );

      IF l_error <> 'OK'
      THEN
         p_resp_code_out := '21';
         l_err_msg := l_error;
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_err_msg :=
                   'Error from fee calc process ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   ---En dynamic fee calculation .

   --Sn calculate waiver on the fee
   BEGIN
      sp_calculate_waiver (p_inst_code_in,
                           p_card_no_in,
                           '000',
                           p_prod_code_in,
                           p_card_type_in,
                           l_fee_code,
                           l_fee_plan,
                           l_tran_date,
                           l_waiv_percnt,
                           l_err_waiv
                          );

      IF l_err_waiv <> 'OK'
      THEN
         p_resp_code_out := '21';
         l_err_msg := l_err_waiv;
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_err_msg :=
                'Error from waiver calc process ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En calculate waiver on the fee

   --Sn apply waiver on fee amount
   l_log_actual_fee := l_fee_amt;              --only used to log in log table
   l_fee_amt := ROUND (l_fee_amt - ((l_fee_amt * l_waiv_percnt) / 100), 2);
   l_log_waiver_amt := l_log_actual_fee - l_fee_amt;

   --Sn apply service tax and cess
   IF l_st_calc_flag = 1
   THEN
      l_servicetax_amount := (l_fee_amt * l_servicetax_percent) / 100;
   ELSE
      l_servicetax_amount := 0;
   END IF;

   IF l_cess_calc_flag = 1
   THEN
      l_cess_amount := (l_servicetax_amount * l_cess_percent) / 100;
   ELSE
      l_cess_amount := 0;
   END IF;

   l_total_fee := ROUND (l_fee_amt + l_servicetax_amount + l_cess_amount, 2);

   --En apply service tax and cess
   IF p_fee_flag_in = 'N'
   THEN
      l_fee_amt := 0;
      l_log_waiver_amt := 0;
      l_servicetax_amount := 0;
      l_cess_amount := 0;
      l_total_fee := 0;
      l_st_calc_flag := 0;
      l_cess_calc_flag := 0;
      l_log_actual_fee := 0;
   END IF;

   --En find fees amount attached to func code, prod code and card type
   BEGIN
      SELECT cpc_profile_code, cpc_badcredit_flag, cpc_badcredit_transgrpid
        INTO l_profile_code, l_badcredit_flag, l_badcredit_transgrpid
        FROM cms_prod_cattype
       WHERE cpc_inst_code = p_inst_code_in
         AND cpc_prod_code = p_prod_code_in
         AND cpc_card_type = p_card_type_in;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_err_msg :=
               'Profile code not defined for product code '
            || p_prod_code_in
            || 'card type '
            || p_card_type_in
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   IF p_dr_cr_flag_in = 'CR'
   THEN
      l_total_amt := l_tran_amt - l_total_fee;
      l_upd_amt := l_acct_balance + l_total_amt;
      l_upd_ledger_bal := l_ledger_bal + l_total_amt;
   ELSIF p_dr_cr_flag_in = 'DR'
   THEN
      l_total_amt := l_tran_amt + l_total_fee;
      l_upd_amt := l_acct_balance - l_total_amt;
      l_upd_ledger_bal := l_ledger_bal - l_total_amt;
   ELSE
      p_resp_code_out := '12';
      l_err_msg := 'Invalid transflag    txn code ' || p_txn_code_in;
      RAISE exp_reject_record;
   END IF;

   IF    (p_dr_cr_flag_in = 'CR' AND p_rvsl_code_in = '00')
      OR (p_dr_cr_flag_in = 'DR' AND p_rvsl_code_in <> '00')
   THEN
      BEGIN
         SELECT TO_NUMBER (cbp_param_value)
           INTO l_max_card_bal
           FROM cms_bin_param
          WHERE cbp_inst_code = p_inst_code_in
            AND cbp_param_name = 'Max Card Balance'
            AND cbp_profile_code = l_profile_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_err_msg := SQLERRM;
            RAISE exp_reject_record;
      END;

      IF l_badcredit_flag = 'Y'
      THEN
         EXECUTE IMMEDIATE    'SELECT  count(*)
              FROM vms_group_tran_detl
              WHERE vgd_group_id ='
                           || l_badcredit_transgrpid
                           || '
              AND vgd_tran_detl LIKE
              (''%'
                           || p_delivery_channel_in
                           || ':'
                           || p_txn_code_in
                           || '%'')'
                      INTO l_cnt;

         IF l_cnt = 1
         THEN
            l_enable_flag := 'N';

            IF    ((l_upd_amt) > l_initialload_amt)
               OR ((l_upd_ledger_bal) > l_initialload_amt)
            THEN
               UPDATE cms_appl_pan
                  SET cap_card_stat = '18'
                WHERE cap_inst_code = p_inst_code_in
                  AND cap_pan_code = p_hash_pan_in;

               BEGIN
                  sp_log_cardstat_chnge (p_inst_code_in,
                                         p_hash_pan_in,
                                         p_encr_pan_in,
                                         p_auth_id_out,
                                         '10',
                                         p_rrn_in,
                                         p_tran_date_in,
                                         p_tran_time_in,
                                         p_resp_code_out,
                                         l_err_msg
                                        );

                  IF p_resp_code_out <> '00' AND l_err_msg <> 'OK'
                  THEN
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     p_resp_code_out := '21';
                     l_err_msg :=
                           'Error while logging system initiated card status change '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            END IF;
         END IF;
      END IF;

      IF l_enable_flag = 'Y'
      THEN
         IF    ((l_upd_amt) > l_max_card_bal)
            OR ((l_upd_ledger_bal) > l_max_card_bal)
         THEN
            p_resp_code_out := '30';
            l_err_msg := 'EXCEEDING MAXIMUM CARD BALANCE';
            RAISE exp_reject_record;
         END IF;
      END IF;
   END IF;

   --Sn check balance
   IF (p_dr_cr_flag_in NOT IN ('NA', 'CR') OR (l_total_fee <> 0))
   THEN
      IF l_upd_amt < 0
      THEN
         IF p_login_txn_in = 'Y' AND l_clawback = 'Y'
         THEN
            l_actual_fee_amnt := l_total_fee;

            IF (l_acct_balance > 0)
            THEN
               l_clawback_amnt := l_total_fee - l_acct_balance;
               l_fee_amt := l_acct_balance;
            ELSE
               l_clawback_amnt := l_total_fee;
               l_fee_amt := 0;
            END IF;

            --End
            IF l_clawback_amnt > 0
            THEN
               BEGIN
                  SELECT cfm_clawback_count
                    INTO l_tot_clwbck_count
                    FROM cms_fee_mast
                   WHERE cfm_fee_code = l_fee_code;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     p_resp_code_out := '12';
                     l_err_msg :=
                           'Clawback count not configured '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               BEGIN
                  SELECT COUNT (*)
                    INTO l_chrg_dtl_cnt
                    FROM cms_charge_dtl
                   WHERE ccd_inst_code = p_inst_code_in
                     AND ccd_delivery_channel = p_delivery_channel_in
                     AND ccd_txn_code = p_txn_code_in
                     AND ccd_acct_no = l_card_acct_no
                     AND ccd_fee_code = l_fee_code
                     AND ccd_clawback = 'Y';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_resp_code_out := '21';
                     l_err_msg :=
                           'Error occured while fetching count from cms_charge_dtl'
                        || SUBSTR (SQLERRM, 1, 100);
                     RAISE exp_reject_record;
               END;

               BEGIN
                  SELECT COUNT (*)
                    INTO l_clawback_count
                    FROM cms_acctclawback_dtl
                   WHERE cad_inst_code = p_inst_code_in
                     AND cad_delivery_channel = p_delivery_channel_in
                     AND cad_txn_code = p_txn_code_in
                     AND cad_pan_code = p_hash_pan_in
                     AND cad_acct_no = l_card_acct_no;

                  IF l_clawback_count = 0
                  THEN
                     INSERT INTO cms_acctclawback_dtl
                                 (cad_inst_code, cad_acct_no,
                                  cad_pan_code, cad_pan_code_encr,
                                  cad_clawback_amnt, cad_recovery_flag,
                                  cad_ins_date, cad_lupd_date,
                                  cad_delivery_channel, cad_txn_code,
                                  cad_ins_user, cad_lupd_user
                                 )
                          VALUES (p_inst_code_in, l_card_acct_no,
                                  p_hash_pan_in, p_encr_pan_in,
                                  ROUND (l_clawback_amnt, 2), 'N',
                                  SYSDATE, SYSDATE,
                                  p_delivery_channel_in, p_txn_code_in,
                                  '1', '1'
                                 );
                  ELSIF l_chrg_dtl_cnt < l_tot_clwbck_count
                  THEN
                     UPDATE cms_acctclawback_dtl
                        SET cad_clawback_amnt =
                                ROUND (cad_clawback_amnt + l_clawback_amnt, 2),
                            cad_recovery_flag = 'N',
                            cad_lupd_date = SYSDATE
                      WHERE cad_inst_code = p_inst_code_in
                        AND cad_acct_no = l_card_acct_no
                        AND cad_pan_code = p_hash_pan_in
                        AND cad_delivery_channel = p_delivery_channel_in
                        AND cad_txn_code = p_txn_code_in;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_resp_code_out := '21';
                     l_err_msg :=
                           'Error while inserting Account ClawBack details'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            END IF;
         ELSE
            p_resp_code_out := '15';
            l_err_msg := 'Insufficient Balance ';
            RAISE exp_reject_record;
         END IF;

         l_upd_amt := 0;
         l_upd_ledger_bal := 0;
         l_total_amt := l_tran_amt + l_fee_amt;
      END IF;
   END IF;

   BEGIN
      sp_upd_transaction_accnt_auth (p_inst_code_in,
                                     l_tran_date,
                                     p_prod_code_in,
                                     p_card_type_in,
                                     l_tran_amt,
                                     NULL,
                                     p_txn_code_in,
                                     p_dr_cr_flag_in,
                                     p_rrn_in,
                                     p_terminal_id_in,
                                     p_delivery_channel_in,
                                     p_txn_mode_in,
                                     p_card_no_in,
                                     l_fee_code,
                                     l_fee_amt,
                                     l_fee_cracct_no,
                                     l_fee_dracct_no,
                                     l_st_calc_flag,
                                     l_cess_calc_flag,
                                     l_servicetax_amount,
                                     l_st_cracct_no,
                                     l_st_dracct_no,
                                     l_cess_amount,
                                     l_cess_cracct_no,
                                     l_cess_dracct_no,
                                     l_card_acct_no,
                                     '',
                                     p_msg_type_in,
                                     p_resp_code_out,
                                     l_err_msg
                                    );

      IF (p_resp_code_out <> '1' OR l_err_msg <> 'OK')
      THEN
         p_resp_code_out := '21';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_err_msg :=
                'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --Sn find narration
   BEGIN
      IF (p_amnt_tnfr_flag_in = 'Y')
      THEN
         IF TRIM (p_trans_desc_in) IS NOT NULL
         THEN
            l_narration := p_trans_desc_in || '/';
         END IF;

         IF TRIM (p_auth_id_out) IS NOT NULL
         THEN
            l_narration := l_narration || p_auth_id_out || '/';
         END IF;

         IF TRIM (p_to_acct_no_in) IS NOT NULL
         THEN
            l_narration := l_narration || p_to_acct_no_in || '/';
         END IF;

         IF TRIM (p_tran_date_in) IS NOT NULL
         THEN
            l_narration := l_narration || p_tran_date_in;
         END IF;
      ELSE
         IF TRIM (p_trans_desc_in) IS NOT NULL
         THEN
            l_narration := p_trans_desc_in || '/';
         END IF;

         IF TRIM (p_merchant_name_in) IS NOT NULL
         THEN
            l_narration := l_narration || p_merchant_name_in || '/';
         END IF;

         IF TRIM (p_merchant_city_in) IS NOT NULL
         THEN
            l_narration := l_narration || p_merchant_city_in || '/';
         END IF;

         IF TRIM (p_tran_date_in) IS NOT NULL
         THEN
            l_narration := l_narration || p_tran_date_in || '/';
         END IF;

         IF TRIM (p_auth_id_out) IS NOT NULL
         THEN
            l_narration := l_narration || p_auth_id_out;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_err_msg :=
                'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --Sn create a entry in statement log
   BEGIN
      IF p_amnt_tnfr_flag_in = 'Y'
      THEN
         l_toacct_no := p_to_acct_no_in;

         IF     p_delivery_channel_in IN ('10', '07')
            AND p_txn_code_in IN ('20', '11')
         THEN
            l_toacct_no := '';
         END IF;
      END IF;

      IF l_tran_amt <> 0
      THEN
         INSERT INTO cms_statements_log
                     (csl_pan_no, csl_opening_bal,
                      csl_trans_amount, csl_trans_type, csl_trans_date,
                      csl_closing_balance,
                      csl_trans_narrration, csl_pan_no_encr, csl_rrn,
                      csl_auth_id, csl_business_date, csl_business_time,
                      txn_fee_flag, csl_delivery_channel, csl_inst_code,
                      csl_txn_code, csl_ins_date, csl_ins_user, csl_acct_no,
                      csl_merchant_name, csl_merchant_city,
                      csl_merchant_state, csl_to_acctno,
                      csl_panno_last4digit,
                      csl_acct_type, csl_time_stamp, csl_prod_code,
                      csl_card_type
                     )
              VALUES (p_hash_pan_in, ROUND (l_ledger_bal, 2),
                      ROUND (l_tran_amt, 2), p_dr_cr_flag_in, l_tran_date,
                      ROUND (DECODE (p_dr_cr_flag_in,
                                     'DR', l_ledger_bal - l_tran_amt,
                                     'CR', l_ledger_bal + l_tran_amt
                                    ),
                             2
                            ),
                      l_narration, p_encr_pan_in, p_rrn_in,
                      p_auth_id_out, p_tran_date_in, p_tran_time_in,
                      'N', p_delivery_channel_in, p_inst_code_in,
                      p_txn_code_in, SYSDATE, 1, l_card_acct_no,
                      p_merchant_name_in, p_merchant_city_in,
                      p_atmname_loc_in, l_toacct_no,
                      (SUBSTR (p_card_no_in,
                               LENGTH (p_card_no_in) - 3,
                               LENGTH (p_card_no_in)
                              )
                      ),
                      l_cam_type_code, l_timestamp, p_prod_code_in,
                      p_card_type_in
                     );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '21';
         l_err_msg :=
               'Problem while inserting into statement log for tran amt '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   IF l_total_fee <> 0 OR l_freetxn_exceed = 'N'
   THEN
      BEGIN
         SELECT DECODE (p_dr_cr_flag_in,
                        'DR', l_ledger_bal - l_tran_amt,
                        'CR', l_ledger_bal + l_tran_amt
                       )
           INTO l_opening_bal
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '21';
            l_err_msg :=
               'Error while selecting data from card Master for card number ';
            RAISE exp_reject_record;
      END;

      IF l_freetxn_exceed = 'N'
      THEN
         BEGIN
            INSERT INTO cms_statements_log
                        (csl_pan_no, csl_opening_bal,
                         csl_trans_amount, csl_trans_type, csl_trans_date,
                         csl_closing_balance, csl_trans_narrration,
                         csl_pan_no_encr, csl_rrn, csl_auth_id,
                         csl_business_date, csl_business_time, txn_fee_flag,
                         csl_delivery_channel, csl_inst_code,
                         csl_txn_code, csl_ins_date, csl_ins_user,
                         csl_acct_no, csl_merchant_name,
                         csl_merchant_city, csl_merchant_state,
                         csl_panno_last4digit,
                         csl_acct_type, csl_time_stamp, csl_prod_code,
                         csl_card_type
                        )
                 VALUES (p_hash_pan_in, ROUND (l_opening_bal, 2),
                         ROUND (l_fee_amt, 2), 'DR', l_tran_date,
                         ROUND (l_opening_bal - l_fee_amt, 2), l_fee_desc,
                         -- Added for MVCSD-4471
                         p_encr_pan_in, p_rrn_in, p_auth_id_out,
                         p_tran_date_in, p_tran_time_in, 'Y',
                         p_delivery_channel_in, p_inst_code_in,
                         p_txn_code_in, SYSDATE, 1,
                         l_card_acct_no, p_merchant_name_in,
                         p_merchant_city_in, p_atmname_loc_in,
                         (SUBSTR (p_card_no_in,
                                  LENGTH (p_card_no_in) - 3,
                                  LENGTH (p_card_no_in)
                                 )
                         ),
                         l_cam_type_code, l_timestamp, p_prod_code_in,
                         p_card_type_in
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_err_msg :=
                     'Problem while inserting into statement log for tran fee '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      ELSE
         BEGIN
            IF l_feeamnt_type = 'A' AND p_login_txn_in != 'Y'
            THEN
               l_flat_fees :=
                  ROUND (l_flat_fees - ((l_flat_fees * l_waiv_percnt) / 100),
                         2
                        );
               l_per_fees :=
                  ROUND (l_per_fees - ((l_per_fees * l_waiv_percnt) / 100), 2);

               --En Entry for Fixed Fee
               INSERT INTO cms_statements_log
                           (csl_pan_no, csl_opening_bal,
                            csl_trans_amount, csl_trans_type, csl_trans_date,
                            csl_closing_balance,
                            csl_trans_narrration,
                            csl_inst_code, csl_pan_no_encr, csl_rrn,
                            csl_auth_id, csl_business_date,
                            csl_business_time, txn_fee_flag,
                            csl_delivery_channel, csl_txn_code,
                            csl_acct_no, csl_ins_user, csl_ins_date,
                            csl_merchant_name, csl_merchant_city,
                            csl_merchant_state,
                            csl_panno_last4digit,
                            csl_acct_type, csl_time_stamp, csl_prod_code,
                            csl_card_type
                           )
                    VALUES (p_hash_pan_in, ROUND (l_opening_bal, 2),
                            ROUND (l_flat_fees, 2), 'DR', l_tran_date,
                            ROUND (l_opening_bal - l_flat_fees, 2),
                            'Fixed Fee debited for ' || l_fee_desc,
                            p_inst_code_in, p_encr_pan_in, p_rrn_in,
                            p_auth_id_out, p_tran_date_in,
                            p_tran_time_in, 'Y',
                            p_delivery_channel_in, p_txn_code_in,
                            l_card_acct_no, 1, SYSDATE,
                            p_merchant_name_in, p_merchant_city_in,
                            p_atmname_loc_in,
                            (SUBSTR (p_card_no_in,
                                     LENGTH (p_card_no_in) - 3,
                                     LENGTH (p_card_no_in)
                                    )
                            ),
                            l_cam_type_code, l_timestamp, p_prod_code_in,
                            p_card_type_in
                           );

               l_opening_bal := l_opening_bal - l_flat_fees;

               --Sn Entry for Percentage Fee
               INSERT INTO cms_statements_log
                           (csl_pan_no, csl_opening_bal,
                            csl_trans_amount, csl_trans_type, csl_trans_date,
                            csl_closing_balance,
                            csl_trans_narrration,
                            csl_inst_code, csl_pan_no_encr, csl_rrn,
                            csl_auth_id, csl_business_date,
                            csl_business_time, txn_fee_flag,
                            csl_delivery_channel, csl_txn_code,
                            csl_acct_no, csl_ins_user, csl_ins_date,
                            csl_merchant_name, csl_merchant_city,
                            csl_merchant_state,
                            csl_panno_last4digit,
                            csl_acct_type, csl_time_stamp, csl_prod_code,
                            csl_card_type
                           )
                    VALUES (p_hash_pan_in, ROUND (l_opening_bal, 2),
                            ROUND (l_per_fees, 2), 'DR', l_tran_date,
                            ROUND (l_opening_bal - l_per_fees, 2),
                            'Percentage Fee debited for ' || l_fee_desc,
                            p_inst_code_in, p_encr_pan_in, p_rrn_in,
                            p_auth_id_out, p_tran_date_in,
                            p_tran_time_in, 'Y',
                            p_delivery_channel_in, p_txn_code_in,
                            l_card_acct_no, 1, SYSDATE,
                            p_merchant_name_in, p_merchant_city_in,
                            p_atmname_loc_in,
                            (SUBSTR (p_card_no_in,
                                     LENGTH (p_card_no_in) - 3,
                                     LENGTH (p_card_no_in)
                                    )
                            ),
                            l_cam_type_code, l_timestamp, p_prod_code_in,
                            p_card_type_in
                           );
            --En Entry for Percentage Fee
            ELSE
               INSERT INTO cms_statements_log
                           (csl_pan_no, csl_opening_bal,
                            csl_trans_amount, csl_trans_type,
                            csl_trans_date,
                            csl_closing_balance,
                            csl_trans_narrration, csl_pan_no_encr, csl_rrn,
                            csl_auth_id, csl_business_date,
                            csl_business_time, txn_fee_flag,
                            csl_delivery_channel, csl_inst_code,
                            csl_txn_code, csl_ins_date, csl_ins_user,
                            csl_acct_no, csl_merchant_name,
                            csl_merchant_city, csl_merchant_state,
                            csl_panno_last4digit,
                            csl_acct_type, csl_time_stamp, csl_prod_code,
                            csl_card_type
                           )
                    VALUES (p_hash_pan_in, ROUND (l_opening_bal, 2),
                            ROUND (l_fee_amt, 2), 'DR',
                            l_tran_date,
                            ROUND (l_opening_bal - l_fee_amt, 2),
                            l_fee_desc, p_encr_pan_in, p_rrn_in,
                            p_auth_id_out, p_tran_date_in,
                            p_tran_time_in, 'Y',
                            p_delivery_channel_in, p_inst_code_in,
                            p_txn_code_in, SYSDATE, 1,
                            l_card_acct_no, p_merchant_name_in,
                            p_merchant_city_in, p_atmname_loc_in,
                            (SUBSTR (p_card_no_in,
                                     LENGTH (p_card_no_in) - 3,
                                     LENGTH (p_card_no_in)
                                    )
                            ),
                            l_cam_type_code, l_timestamp, p_prod_code_in,
                            p_card_type_in
                           );

               IF     p_login_txn_in = 'Y'
                  AND l_clawback_amnt > 0
                  AND l_chrg_dtl_cnt < l_tot_clwbck_count
               THEN
                  BEGIN
                     INSERT INTO cms_charge_dtl
                                 (ccd_pan_code, ccd_acct_no,
                                  ccd_clawback_amnt,
                                  ccd_gl_acct_no, ccd_pan_code_encr,
                                  ccd_rrn, ccd_calc_date, ccd_fee_freq,
                                  ccd_file_status, ccd_clawback,
                                  ccd_inst_code, ccd_fee_code,
                                  ccd_calc_amt, ccd_fee_plan,
                                  ccd_delivery_channel, ccd_txn_code,
                                  ccd_debited_amnt, ccd_mbr_numb,
                                  ccd_process_msg,
                                  ccd_feeattachtype
                                 )
                          VALUES (p_hash_pan_in, l_card_acct_no,
                                  ROUND (l_clawback_amnt, 2),
                                  l_fee_cracct_no, p_encr_pan_in,
                                  p_rrn_in, l_tran_date, 'T',
                                  'C', l_clawback,
                                  p_inst_code_in, l_fee_code,
                                  ROUND (l_actual_fee_amnt, 2), l_fee_plan,
                                  p_delivery_channel_in, p_txn_code_in,
                                  ROUND (l_fee_amt, 2), '000',
                                  DECODE (l_err_msg, 'OK', 'SUCCESS'),
                                  l_feeattach_type
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_resp_code_out := '21';
                        l_err_msg :=
                              'Problem while inserting into CMS_CHARGE_DTL '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code_out := '21';
               l_err_msg :=
                     'Problem while inserting into statement log for tran fee '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;
   END IF;

--   IF p_output_type_in = 'B'
--   THEN
--      --Balance Inquiry
--      p_resp_msg_out := TO_CHAR (l_upd_amt);
--   END IF;
--
--   IF p_output_type_in = 'M'
--   THEN
--      --Mini statement
--      BEGIN
--         sp_gen_mini_stmt (p_inst_code_in,
--                           p_card_no_in,
--                           l_mini_totrec,
--                           l_ministmt_output,
--                           l_ministmt_errmsg
--                          );
--
--         IF l_ministmt_errmsg <> 'OK'
--         THEN
--            l_err_msg := l_ministmt_errmsg;
--            p_resp_code_out := '21';
--            RAISE exp_reject_record;
--         END IF;
--
--         p_resp_msg_out :=
--                    LPAD (TO_CHAR (l_mini_totrec), 2, '0')
--                    || l_ministmt_output;
--      EXCEPTION
--         WHEN exp_reject_record
--         THEN
--            RAISE;
--         WHEN OTHERS
--         THEN
--            l_err_msg :=
--                  'Problem while selecting data for mini statement '
--               || SUBSTR (SQLERRM, 1, 300);
--            p_resp_code_out := '21';
--            RAISE exp_reject_record;
--      END;
--   END IF;

BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code_out
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code_in
         AND cms_delivery_channel = p_delivery_channel_in
         AND cms_response_id = TO_NUMBER (p_resp_code_out);
   EXCEPTION
      WHEN OTHERS
      THEN
         l_err_msg :=
               'Problem while selecting data from response master for respose code'
            || p_resp_code_out
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '21';
         RAISE exp_reject_record;
   END;
   BEGIN
      INSERT INTO cms_transaction_log_dtl
                  (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                   ctd_txn_mode, ctd_business_date, ctd_business_time,
                   ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                   ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                   ctd_servicetax_amount, ctd_cess_amount, ctd_bill_amount,
                   ctd_bill_curr, ctd_process_flag, ctd_process_msg,
                   ctd_rrn, ctd_system_trace_audit_no,
                   ctd_customer_card_no_encr, ctd_msg_type,
                   ctd_cust_acct_number, ctd_inst_code, ctd_hashkey_id
                  )                        --Added  on 29-08-2013 for Fss-1144
           VALUES (p_delivery_channel_in, p_txn_code_in, p_txn_type_in,
                   p_txn_mode_in, p_tran_date_in, p_tran_time_in,
                   p_hash_pan_in, p_txn_amt_in, p_curr_code_in,
                   l_tran_amt, l_log_actual_fee, l_log_waiver_amt,
                   l_servicetax_amount, l_cess_amount, l_total_amt,
                   NULL, 'Y', 'Successful',
                   p_rrn_in, p_stan_in,
                   p_encr_pan_in, p_msg_type_in,
                   p_acct_no_in, p_inst_code_in, l_hashkey_id
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         l_err_msg :=
               'Problem while selecting data from response master '
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '21';
         RAISE exp_reject_record;
   END;

   BEGIN
      INSERT INTO transactionlog
                  (msgtype, rrn, delivery_channel,
                   terminal_id, date_time, txn_code,
                   txn_type, txn_mode,
                   txn_status,
                   response_code, business_date,
                   business_time, customer_card_no, topup_card_no,
                   topup_acct_no, topup_acct_type, bank_code,
                   total_amount,
                   rule_indicator, rulegroupid, mccode, currencycode,
                   addcharge, productid, categoryid, tips, decline_ruleid,
                   atm_name_location, auth_id, trans_desc,
                   amount,
                   preauthamount, partialamount, mccodegroupid,
                   currencycodegroupid, transcodegroupid,
                   rules, preauth_date, gl_upd_flag, system_trace_audit_no,
                   instcode, feecode, tranfee_amt,
                   servicetax_amt, cess_amt,
                   cr_dr_flag, tranfee_cr_acctno, tranfee_dr_acctno,
                   tran_st_calc_flag, tran_cess_calc_flag,
                   tran_st_cr_acctno, tran_st_dr_acctno,
                   tran_cess_cr_acctno, tran_cess_dr_acctno,
                   customer_card_no_encr, topup_card_no_encr, proxy_number,
                   reversal_code, customer_acct_no,
                   acct_balance,
                   ledger_balance,
                   response_id, add_ins_date, add_ins_user, cardstatus,
                   fee_plan, csr_achactiontaken, error_msg, feeattachtype,
                   merchant_name, merchant_city, merchant_state,
                   acct_type, time_stamp,OS_NAME,OS_VERSION,GPS_COORDINATES,
                   DISPLAY_RESOLUTION,PHYSICAL_MEMORY,APP_NAME,APP_VERSION,SESSION_ID,
                   DEVICE_COUNTRY,DEVICE_REGION,IPADDRESS,ANI,DNI,remark
                  )
           VALUES (p_msg_type_in, p_rrn_in, p_delivery_channel_in,
                   p_terminal_id_in, l_business_date, p_txn_code_in,
                   p_txn_type_in, p_txn_mode_in,
                   DECODE (p_resp_code_out, '00', 'C', 'F'),
                   p_resp_code_out, p_tran_date_in,
                   SUBSTR (p_tran_time_in, 1, 10), p_hash_pan_in, NULL,
                   NULL, NULL, p_bank_code_in,
                   TRIM (TO_CHAR (NVL (l_total_amt, 0),
                                  '99999999999999990.99')
                        ),
                   NULL, NULL, p_mcc_code_in, p_curr_code_in,
                   NULL,                                      -- P_add_charge,
                        p_prod_code_in, p_card_type_in, p_tip_amt_in, NULL,
                   p_atmname_loc_in, p_auth_id_out, p_trans_desc_in,
                   TRIM (TO_CHAR (NVL (l_tran_amt, 0),
                                  '999999999999999990.99')
                        ),
                   '0.00', '0.00', p_mcccode_groupid_in,
                   p_currcode_groupid_in, p_transcode_groupid_in,
                   p_rules_in, p_preauth_date_in, NULL, p_stan_in,
                   p_inst_code_in, l_fee_code, NVL (l_fee_amt, 0),
                   NVL (l_servicetax_amount, 0), NVL (l_cess_amount, 0),
                   p_dr_cr_flag_in, l_fee_cracct_no, l_fee_dracct_no,
                   l_st_calc_flag, l_cess_calc_flag,
                   l_st_cracct_no, l_st_dracct_no,
                   l_cess_cracct_no, l_cess_dracct_no,
                   p_encr_pan_in, NULL, p_proxy_number_in,
                   p_rvsl_code_in, p_acct_no_in,
                   ROUND (DECODE (p_resp_code_out,
                                  '00', l_upd_amt,
                                  l_acct_balance
                                 ),
                          2
                         ),
                   ROUND (DECODE (p_resp_code_out,
                                  '00', l_upd_ledger_bal,
                                  l_ledger_bal
                                 ),
                          2
                         ),
                   p_resp_code_out, SYSDATE, 1, p_card_status_in,
                   l_fee_plan, p_fee_flag_in, l_err_msg, l_feeattach_type,
                   p_merchant_name_in, p_merchant_city_in, p_atmname_loc_in,
                   l_cam_type_code, l_timestamp,p_os_name_in,p_os_version_in,
                   p_gps_coordinates_in,p_display_resolution_in,p_physical_memory_in,
                   p_app_name_in,p_app_version_in,p_session_id_in,
                   p_device_country_in,p_device_region_in,p_ip_addr_in,p_ani_in,p_dni_in,
                   p_comments_in
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         l_err_msg :=
               'Problem while selecting data from response master '
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code_out := '21';
         RAISE exp_reject_record;
   END;

   IF p_prfl_code_in IS NOT NULL AND p_prfl_flag_in = 'Y'
     THEN
        BEGIN
           pkg_limits_check.sp_limitcnt_reset (p_inst_code_in,
                                               p_hash_pan_in,
                                               l_tran_amt,
                                               l_comb_hash,
                                               p_resp_code_out,
                                               l_err_msg);

           IF l_err_msg <> 'OK'
           THEN
              l_err_msg := 'From Procedure sp_limitcnt_reset-' || l_err_msg;
              raise exp_reject_record;
           END IF;
        EXCEPTION
           when exp_reject_record then
              raise;
           WHEN OTHERS   THEN
              p_resp_code_out := '21';
              l_err_msg :=   'Error from Limit Reset Count Process-' || SUBSTR (SQLERRM, 1, 200);
              raise exp_reject_record;
        END;
     END IF;
EXCEPTION
   WHEN exp_reject_record
   THEN
      ROLLBACK;
      p_resp_msg_out := l_err_msg;
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_resp_msg_out := 'Error in main ' || SUBSTR (SQLERRM, 1, 300);
      p_resp_code_out := '21';
END authorize_financial_txn;


PROCEDURE CHECK_ORDER_STATUS(
    P_I_INST_CODE          IN NUMBER,
    p_I_delivery_channel   IN       VARCHAR2,
    p_I_tran_code          IN       VARCHAR2,
    p_I_hash_pan      IN       VARCHAR2,
    p_I_prod_code          IN       VARCHAR2,
    p_I_card_type          IN       VARCHAR2,
    P_I_CARD_STATUS     IN       VARCHAR2,
    P_I_MSGTYPE                 IN      VARCHAR2,
    P_O_STATUS_CHECK      OUT VARCHAR2,
    p_O_resp_code          OUT      VARCHAR2,
    p_O_resp_msg           OUT      VARCHAR2
         )

 IS
 /****************************************************************************
  ******************
  * Created by                  : Sivakumar M.
  * Created Date                : 03-APR-19
  * Created For                 : VMS-850&VMS-849
  * Created reason              : Orderstatus validation
  * Reviewer                    : SARAVANAKUMAR
  * Build Number                : VMSGPRHOST R14


  * Modified  by                  : Baskar Krishnan R.
  * Modified Date                : 06-May-19
  * Modified For                 : VMS-911
  * Reviewer                    : SARAVANAKUMAR
  * Build Number                : VMSGPRHOST R15
  *****************************************************************************/
   v_order_status   VMS_ORDER_DETAILS.vod_order_status%TYPE;
   v_order_statcode VMS_ORDER_STATUS_MAST.vom_status_code%TYPE;
   v_approve_count   Number(2);
    v_reject_count   Number(2);

 Begin
    p_O_resp_code  :='00';
    p_O_resp_msg  :='OK';
    P_O_STATUS_CHECK :='N';
  begin
  select orderdtl.vod_order_status
  into v_order_status
   from  VMS_LINE_ITEM_DTL lineitem,VMS_ORDER_DETAILS orderdtl where
    orderdtl.vod_order_id=lineitem.vli_order_id
    and orderdtl.VOD_PARTNER_ID=lineitem.VLI_PARTNER_ID
    and lineitem.vli_pan_code=p_I_hash_pan;
 exception
  WHEN OTHERS   THEN
                p_O_resp_code := '21';
                p_O_resp_msg :=   'Error while fetching order status pan ' || SUBSTR (SQLERRM, 1, 200);
                RETURN;
 end;

 begin

    select vom_status_code
     into v_order_statcode
     from VMS_ORDER_STATUS_MAST
     where VOM_STATUS_DESC=UPPER(v_order_status);

  exception
  WHEN OTHERS   THEN
                p_O_resp_code := '21';
                p_O_resp_msg :=   'Error while fetching order status details ' || SUBSTR (SQLERRM, 1, 200);
                RETURN;
  end;

    BEGIN
            --VMS-911
       SELECT  NVL(SUM(DECODE(gvc_approve_txn,'Y',1,0)),0),NVL(SUM(DECODE(gvc_approve_txn,'N',1,0)),0)
                 INTO v_approve_count,v_reject_count
                FROM gpr_valid_cardstat
               WHERE     gvc_tran_code = p_I_tran_code
                     AND gvc_delivery_channel =p_I_delivery_channel
                     AND gvc_prod_code = p_I_prod_code
                     AND gvc_card_type = p_I_card_type
                     AND gvc_inst_code = P_I_INST_CODE
                     and gvc_card_stat=v_order_statcode
                     AND GVC_STAT_FLAG='O'
                     AND GVC_MSG_TYPE=P_I_MSGTYPE;


            IF v_reject_count > 0  THEN
                p_O_resp_code :='10';
                p_O_resp_msg := 'Invalid order Status Not Allowed For Transaction';
                SELECT nvl(CCS_SPIL_RESP_ID,NVL(p_O_resp_code, '10')),
                     nvl(CCS_SPIL_RESP_MSG,'Transaction not allowed for card status')
                    INTO p_O_resp_code,p_O_resp_msg
                    FROM CMS_CARD_STAT WHERE CCS_STAT_CODE = P_I_CARD_STATUS;

            END IF;

            IF v_reject_count=0 AND v_approve_count=0 THEN
                P_O_STATUS_CHECK:='Y';
            END IF;

            EXCEPTION
            WHEN OTHERS   THEN
               p_O_resp_code := '21';
               p_O_resp_msg :=   'Error status count check ' || SUBSTR (SQLERRM, 1, 200);

        END;

end CHECK_ORDER_STATUS;

END VMSCOMMON;
/
SHOW ERROR;