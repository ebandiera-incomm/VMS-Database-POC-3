create or replace PROCEDURE                             VMSCMS.SP_STR_TO_GPR_CARDGEN_R307(
    p_instcode           IN  NUMBER,
    P_CARDNUM            IN  VARCHAR2,
    P_RRN                IN  VARCHAR2,
    P_DELIVERY_CHANNEL   IN  VARCHAR2,
    p_txn_code           IN  VARCHAR2,
    p_trandate           IN  VARCHAR2,
    p_trantime           IN  VARCHAR2,
    P_RESP_CODE          OUT VARCHAR2,
    P_PAN_NUMBER         OUT VARCHAR2,
    P_PROD_CATG          OUT VARCHAR2,
    P_ERRMSG             OUT VARCHAR2
    )
AS
  /*************************************************

    * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 25-JUN-2020
    * Purpose          : VMS_RSI0030.7
    * Reviewer         : SaravanaKumar.A
    * Release Number   : VMSGPRHOST_R30.7
	*************************************************/
  v_cap_card_stat          cms_appl_pan.cap_card_stat%TYPE;

  v_errmsg                 transactionlog.error_msg%TYPE;
  v_currcode               transactionlog.currencycode%TYPE;
  v_appl_code              cms_appl_mast.cam_appl_code%TYPE;
  v_respcode               transactionlog.response_id%TYPE;
  v_respmsg                transactionlog.error_msg%TYPE;
  V_CAPTURE_DATE           transactionlog.date_time%type;
  v_txn_type               cms_func_mast.cfm_txn_type%TYPE;
  v_inil_authid            transactionlog.auth_id%TYPE;
  v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
  v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
  v_tran_date              transactionlog.date_time%type;
  v_tran_amt               cms_acct_mast.cam_acct_bal%type;
  v_business_date          transactionlog.date_time%type;
  V_CUST_CODE              CMS_CUST_MAST.CCM_CUST_CODE%type;

  v_acct_balance           cms_acct_mast.cam_acct_bal%TYPE;
  v_prod_code              cms_prod_mast.cpm_prod_code%TYPE;
  V_PROD_CATTYPE           CMS_PROD_CATTYPE.CPC_CARD_TYPE%type;
  V_LEDGER_BALANCE         cms_acct_mast.cam_ledger_bal%type;
  v_dr_cr_flag             cms_transaction_mast.ctm_credit_debit_flag%type;



  v_acct_number            cms_appl_pan.cap_acct_no%TYPE;



  V_TRANS_DESC             CMS_TRANSACTION_MAST.CTM_TRAN_DESC%type;
  v_acct_type              cms_acct_mast.cam_type_code%type;
  v_timestamp              TIMESTAMP(3);
  V_HASHKEY_ID             CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%type;
  V_USERBIN                PLS_INTEGER DEFAULT 1;
  V_GPR_CARDCNT            PLS_INTEGER;
  v_err_msg                transactionlog.error_msg%TYPE;
  V_GPR_CARD_NO            VARCHAR2 (50);
  V_APPLPROCES_MSG         transactionlog.error_msg%TYPE;
  V_RESP_CODE              transactionlog.response_id%TYPE;
  V_GPRHASHPAN             cms_appl_pan.cap_pan_code%TYPE; --Added for JH-3043
  v_upgrade_eligible_flag  cms_prod_cattype.CPC_UPGRADE_ELIGIBLE_FLAG%TYPE;

v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
  EXP_MAIN_REJECT_RECORD   EXCEPTION;
  EXP_AUTH_REJECT_RECORD   exception;

BEGIN
  p_errmsg           := 'OK';
  v_errmsg           := 'OK';
  V_RESPCODE         := '1';
  v_timestamp        := SYSTIMESTAMP;

  --SN CREATE HASH PAN
  BEGIN
    v_hash_pan :=  gethash (p_cardnum);
  EXCEPTION
  WHEN OTHERS THEN
    v_respcode := '12';
    v_errmsg   := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_main_reject_record;
  END;
  --EN CREATE HASH PAN
  --Start Generate HashKEY
  BEGIN
    V_HASHKEY_ID :=  GETHASH (P_DELIVERY_CHANNEL||p_txn_code||p_cardnum||P_RRN||TO_CHAR(v_timestamp,'YYYYMMDDHH24MISSFF5'));
  EXCEPTION
  WHEN OTHERS THEN
    v_respcode := '21';
    v_errmsg   :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_main_reject_record;
  END;
  --End Generate HashKEY
  --SN create encr pan
  BEGIN
    v_encr_pan := fn_emaps_main (p_cardnum);
  EXCEPTION
  WHEN OTHERS THEN
    v_respcode := '12';
    v_errmsg   := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_main_reject_record;
  END;
  --Sn find debit and credit flag
  BEGIN
    SELECT ctm_credit_debit_flag,
      TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
      ctm_tran_desc
    INTO v_dr_cr_flag,
      v_txn_type,
      v_trans_desc
    FROM cms_transaction_mast
    WHERE ctm_tran_code      = p_txn_code
    AND ctm_delivery_channel = p_delivery_channel
    AND ctm_inst_code        = p_instcode;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_respcode := '12';
    v_errmsg   := 'Transflag  not defined for txn code ' || p_txn_code || ' and delivery channel ' || p_delivery_channel;
    RAISE exp_main_reject_record;
  WHEN OTHERS THEN
    v_respcode := '21';
    v_errmsg := 'Error while selecting transaction details';
    RAISE exp_main_reject_record;
  end;

   --Sn Transaction Time Check
  BEGIN
    v_tran_date := TO_DATE ( SUBSTR (TRIM (p_trandate), 1, 8) || ' ' || SUBSTR (TRIM (p_trantime), 1, 10), 'yyyymmdd hh24:mi:ss' );
  EXCEPTION
  WHEN OTHERS THEN
    v_respcode := '32';
    v_errmsg   := 'Problem while converting transaction Time ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_main_reject_record;
  END;
  --En Transaction Time Check
  v_currcode := '124';

  --Sn find card detail
  BEGIN
    SELECT CAP_PROD_CODE,
      CAP_CARD_TYPE,
      CAP_CARD_STAT,
      CAP_APPL_CODE,
      CAP_CUST_CODE,
      cap_acct_no
    INTO V_PROD_CODE,
      V_PROD_CATTYPE,
      V_CAP_CARD_STAT,
      V_APPL_CODE,
      V_CUST_CODE,
      v_acct_number
    FROM cms_appl_pan
    WHERE cap_inst_code = p_instcode
    AND cap_pan_code    = v_hash_pan;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    V_RESPCODE := '16';
    v_errmsg   := 'Card number not found';
    RAISE exp_main_reject_record;
  WHEN OTHERS THEN
    v_respcode := '12';
    v_errmsg   := 'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_main_reject_record;
  END;



  BEGIN

        SELECT NVL(CPC_UPGRADE_ELIGIBLE_FLAG,'N')
        INTO v_upgrade_eligible_flag
        FROM CMS_PROD_CATTYPE
        WHERE CPC_PROD_CODE = v_prod_code
        AND CPC_CARD_TYPE   = V_PROD_CATTYPE
        AND CPC_INST_CODE   = p_instcode;

    EXCEPTION
    WHEN OTHERS  THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting product detls ' || v_prod_code;
         RAISE exp_main_reject_record;

    END;


       BEGIN
       if v_UPGRADE_ELIGIBLE_FLAG<>'Y' then
          v_respcode := '270';
          V_ERRMSG := 'Upgrade flag disabled in Product Category Configuration';
          RAISE exp_main_reject_record;
       END IF;
       EXCEPTION
       WHEN exp_main_reject_record
        then
          RAISE;
       WHEN OTHERS  THEN
         V_RESPCODE := '21';
         v_errmsg := 'Error while selecting details from product : ' || v_prod_code ||' and Product Category :'||V_PROD_CATTYPE;
         RAISE exp_main_reject_record;
    end;


     --Sn call to authorize txn
    BEGIN
       sp_authorize_txn_cms_auth (p_instcode,
                                  '0200',
                                  p_rrn,
                                  p_delivery_channel,
                                  '0',
                                  p_txn_code,
                                  0,
                                  p_trandate,
                                  p_trantime,
                                  p_cardnum,
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
                                  '0',
                                  '000',
                                  '00',
                                  0,
                                  V_INIL_AUTHID,
                                  v_resp_code,
                                  v_respmsg,
                                  v_capture_date,
                                  'N' );

      IF V_RESP_CODE <> '00' AND V_RESPMSG <> 'OK' THEN
        V_ERRMSG     := V_RESPMSG;
        RAISE exp_auth_reject_record;
      END IF;
    EXCEPTION
      WHEN exp_auth_reject_record
         then
            RAISE;
    WHEN exp_main_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_respcode := '21';
      v_errmsg   := 'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_main_reject_record;
    END;
    --En call to authorize txn

  IF v_resp_code = '00' THEN
    BEGIN

        BEGIN
          SELECT COUNT(1)
          INTO V_GPR_CARDCNT
          FROM CMS_APPL_PAN
          WHERE cap_acct_no       = v_acct_number
          AND CAP_STARTERCARD_FLAG='N'
		  AND CAP_APPL_CODE=v_appl_code
          AND CAP_CARD_STAT <> '9'
          AND CAP_INST_CODE       = P_INSTCODE;
        EXCEPTION
        WHEN OTHERS THEN
          v_respcode := '21';
          V_ERRMSG   := 'Error while selecting GPR Card details for Account No ' || v_acct_number;
          RAISE EXP_MAIN_REJECT_RECORD;
        END;
        IF (V_GPR_CARDCNT=0) THEN
          BEGIN
            UPDATE CMS_APPL_MAST
            SET CAM_APPL_STAT   = 'A' , CAM_STARTER_CARD= 'N'
            WHERE CAM_APPL_CODE = v_appl_code
            AND CAM_INST_CODE   = P_INSTCODE;
            IF SQL%ROWCOUNT     = 0 THEN
              v_respcode       := '21';
              V_ERRMSG         := 'Error while updating cms_appl_mast for appl_stat';
              RAISE EXP_MAIN_REJECT_RECORD;
            END IF;
          EXCEPTION
          WHEN EXP_MAIN_REJECT_RECORD THEN
            RAISE;
          WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg   := 'Error while updating CMS_APPL_MAST-' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
          END;

          BEGIN
            UPDATE CMS_ACCT_MAST
            SET cam_hold_count  = cam_hold_count + 1,
              cam_lupd_user     = v_userbin
            WHERE cam_inst_code = p_instcode
            AND cam_acct_no     = v_acct_number;
            IF SQL%ROWCOUNT     = 0 THEN
              V_RESPCODE       := '21';
              v_errmsg         := 'Error while update acct ' ;
              RAISE EXP_MAIN_REJECT_RECORD;
            END IF;
          EXCEPTION
          WHEN EXP_MAIN_REJECT_RECORD THEN
          RAISE;
          WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg   := 'Error while update acct ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
          END;
          BEGIN
            sp_gen_pan_starter_to_gpr (p_instcode, v_appl_code, v_userbin, v_gpr_card_no, V_APPLPROCES_MSG, v_err_msg );
            IF v_err_msg <> 'OK' THEN
              v_respcode := '21';
              RAISE EXP_MAIN_REJECT_RECORD;
            END IF;
            IF v_applproces_msg <> 'OK' THEN
              v_respcode        := '21';
              v_errmsg          := v_applproces_msg;
              RAISE EXP_MAIN_REJECT_RECORD;
            END IF;
          EXCEPTION
          WHEN EXP_MAIN_REJECT_RECORD THEN
            RAISE;
          WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg   := 'Error while updating CMS_APPL_MAST-' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
          END;
          BEGIN
            SELECT fn_dmaps_main (pan.cap_pan_code_encr),
                   pan.cap_pan_code,
                   pan.cap_prod_catg
            INTO p_pan_number,
              V_GPRHASHPAN,
              P_PROD_CATG
            FROM cms_appl_pan pan,
              cms_cust_mast cust
            WHERE pan.cap_appl_code  = v_appl_code
            AND pan.cap_cust_code    = cust.ccm_cust_code
            AND pan.cap_inst_code    = cust.ccm_inst_code
            AND pan.cap_inst_code    = p_instcode
            AND cap_startercard_flag = 'N'
			AND CAP_CARD_STAT <> '9';
          EXCEPTION
          WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg   := 'Error while selecting (gpr card)details from appl_pan :' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
          END;



          BEGIN
            update  cms_appl_pan set cap_repl_flag=6
            where cap_pan_code=V_GPRHASHPAN and cap_inst_code=p_instcode;

              IF SQL%ROWCOUNT     = 0 THEN
                V_RESPCODE       := '21';
                v_errmsg         := 'Error while update REPL FLAG ' ;
                RAISE EXP_MAIN_REJECT_RECORD;
              END IF;
            EXCEPTION
            WHEN EXP_MAIN_REJECT_RECORD THEN
            RAISE;
            WHEN OTHERS THEN
              v_respcode := '21';
              v_errmsg   := 'Error while update REPL FLAG ' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_MAIN_REJECT_RECORD;
          END;




        --AVQ Added for FSS-1961(Melissa)
        BEGIN
                SP_LOGAVQSTATUS(
                p_instcode,
                P_DELIVERY_CHANNEL,
                p_pan_number,
                V_PROD_CODE,
                V_CUST_CODE,
                v_respcode,
                v_errmsg,
                V_PROD_CATTYPE
                );
            IF v_errmsg <> 'OK' THEN
               v_errmsg  := 'Exception while calling LOGAVQSTATUS-- ' || v_errmsg;
               v_respcode := '21';
              RAISE EXP_MAIN_REJECT_RECORD;
             END IF;
        EXCEPTION WHEN EXP_MAIN_REJECT_RECORD
        THEN  RAISE;
        WHEN OTHERS THEN
           v_errmsg  := 'Exception in LOGAVQSTATUS-- '  || SUBSTR (SQLERRM, 1, 200);
           v_respcode := '21';
           RAISE EXP_MAIN_REJECT_RECORD;
        END;
        --End  Added for FSS-1961(Melissa)
        ELSE
          V_RESPCODE := '21';
          V_ERRMSG   := 'GPR Card Already Generated';
          RAISE EXP_MAIN_REJECT_RECORD;
        END IF;

    EXCEPTION
    WHEN exp_main_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_respcode := '21';
      v_errmsg   := 'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_main_reject_record;
    END;
    --En call to authorize txn
  END IF;


  BEGIN
    -- Assign the response code to the out parameter
    SELECT cms_iso_respcde
    INTO p_resp_code
    FROM cms_response_mast
    WHERE cms_inst_code      = p_instcode
    AND cms_delivery_channel = p_delivery_channel
    AND cms_response_id      = v_respcode;

     EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                    'No data available in response master  for' || v_respcode;
            v_resp_code := '89';
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while selecting data from response master '
               || v_respcode
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_code := '89';
            RAISE exp_main_reject_record;
    ---ISO MESSAGE FOR DATABASE ERROR Server Declined
  END;
  p_errmsg := v_errmsg;
  --En select response code and insert record into txn log dtl

    BEGIN
	--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE VMSCMS.CMS_TRANSACTION_LOG_DTL
      SET CTD_PROCESS_MSG      = V_ERRMSG
      WHERE CTD_RRN            = P_RRN
      AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
      AND CTD_TXN_CODE         = P_TXN_CODE
      AND CTD_BUSINESS_DATE    = p_trandate
      AND CTD_BUSINESS_TIME    = p_trantime
      AND CTD_MSG_TYPE         = '0200'
      AND CTD_CUSTOMER_CARD_NO = V_HASH_PAN
      AND CTD_INST_CODE        =p_instcode;
ELSE
	  UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST
      SET CTD_PROCESS_MSG      = V_ERRMSG
      WHERE CTD_RRN            = P_RRN
      AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
      AND CTD_TXN_CODE         = P_TXN_CODE
      AND CTD_BUSINESS_DATE    = p_trandate
      AND CTD_BUSINESS_TIME    = p_trantime
      AND CTD_MSG_TYPE         = '0200'
      AND CTD_CUSTOMER_CARD_NO = V_HASH_PAN
      AND CTD_INST_CODE        =p_instcode;

END IF;	  
      IF SQL%ROWCOUNT         <> 1 THEN
        V_RESP_CODE           := '21';
        V_ERRMSG              := 'Error while updating transactionlog_detl ';
        RAISE exp_main_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_main_reject_record THEN
      RAISE exp_main_reject_record;
    WHEN OTHERS THEN
      V_RESP_CODE := '21';
      V_ERRMSG    := 'Error while updating transactionlog ' || SUBSTR(SQLERRM, 1, 200);
      RAISE exp_main_reject_record;
    END;


    BEGIN
       INSERT INTO CMS_CARD_EXCPFEE
                                 (CCE_INST_CODE,
                                  CCE_PAN_CODE,
                                  CCE_INS_DATE,
                                  CCE_INS_USER,
                                  CCE_LUPD_USER,
                                  CCE_LUPD_DATE,
                                  CCE_FEE_PLAN,
                                  CCE_FLOW_SOURCE,
                                  CCE_VALID_FROM,
                                  CCE_VALID_TO,
                                  CCE_PAN_CODE_ENCR,
                                  CCE_MBR_NUMB,
                                  CCE_ST_CALC_FLAG,
                                  CCE_CESS_CALC_FLAG,
                                  CCE_DRGL_CATG)
                                 (SELECT
                                  CCE_INST_CODE,
                                  V_GPRHASHPAN,
                                  SYSDATE,
                                  1,
                                  1,
                                  SYSDATE,
                                  CCE_FEE_PLAN,
                                  CCE_FLOW_SOURCE,
                                  CCE_VALID_FROM,
                                  CCE_VALID_TO,
                                  fn_emaps_main(p_pan_number),
                                  CCE_MBR_NUMB,
                                  CCE_ST_CALC_FLAG,
                                  CCE_CESS_CALC_FLAG,
                                  CCE_DRGL_CATG
                                 FROM CMS_CARD_EXCPFEE
                                 WHERE CCE_INST_CODE = p_instcode
                                 AND CCE_PAN_CODE = v_hash_pan
                                 AND ((cce_valid_to IS NOT NULL AND (TRUNC(sysdate) BETWEEN cce_valid_from AND cce_valid_to))
                                  OR (cce_valid_to IS NULL AND TRUNC(sysdate) >= cce_valid_from)));
    EXCEPTION
    WHEN OTHERS THEN
      V_RESP_CODE := '21';
      V_ERRMSG    := 'Error while inserting into cms_card_excpfee ' || SUBSTR(SQLERRM, 1, 200);
      RAISE exp_main_reject_record;
    END;

 EXCEPTION
  --<< MAIN EXCEPTION >>

when  EXP_AUTH_REJECT_RECORD then

  P_ERRMSG := V_ERRMSG;
  p_resp_code:=V_RESP_CODE;

WHEN exp_main_reject_record THEN
  ROLLBACK;
  p_errmsg := v_errmsg;
  ---Sn Updation of Usage limit and amount
  BEGIN
    SELECT cam_acct_bal,
      cam_ledger_bal,
      cam_type_code
    INTO v_acct_balance,
      v_ledger_balance,
      v_acct_type
    FROM CMS_ACCT_MAST
    WHERE cam_acct_no =v_acct_number
    AND cam_inst_code = p_instcode;
  EXCEPTION
  WHEN OTHERS THEN
    v_acct_balance   := 0;
    v_ledger_balance := 0;
  END;
  --Sn select response code and insert record into txn log dtl
  BEGIN
    -- Assign the response code to the out parameter
    SELECT cms_iso_respcde
    INTO p_resp_code
    FROM cms_response_mast
    WHERE cms_inst_code      = p_instcode
    AND cms_delivery_channel = p_delivery_channel
    AND cms_response_id      = v_respcode;
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg    := 'Problem while selecting data from response master ' || v_respcode || SUBSTR (SQLERRM, 1, 300);
    p_resp_code := '89';
    ---ISO MESSAGE FOR DATABASE ERROR Server Declined
  END;
  IF v_dr_cr_flag IS NULL THEN
    BEGIN
      SELECT ctm_credit_debit_flag
      INTO v_dr_cr_flag
      FROM cms_transaction_mast
      WHERE ctm_tran_code      = p_txn_code
      AND ctm_delivery_channel = p_delivery_channel
      AND ctm_inst_code        = p_instcode;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
  END IF;
  IF v_prod_code IS NULL THEN
    BEGIN
      SELECT cap_prod_code,
        cap_card_type,
        cap_card_stat,
        cap_acct_no
      INTO v_prod_code,
        v_prod_cattype,
        v_cap_card_stat,
        v_acct_number
      FROM cms_appl_pan
      WHERE cap_inst_code = p_instcode
      AND cap_pan_code    = v_hash_pan;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
  END IF;
  BEGIN
    INSERT
    INTO transactionlog
      (
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
        topup_card_no,
        topup_acct_no,
        topup_acct_type,
        bank_code,
        total_amount,
        currencycode,
        addcharge,
        productid,
        categoryid,
        atm_name_location,
        auth_id,
        amount,
        preauthamount,
        partialamount,
        instcode,
        customer_card_no_encr,
        topup_card_no_encr,
        proxy_number,
        reversal_code,
        customer_acct_no,
        ACCT_BALANCE,
        LEDGER_BALANCE,
        ERROR_MSG,
        RESPONSE_ID,
        CARDSTATUS,
        TRANS_DESC,
        acct_type,
        cr_dr_flag,
        time_stamp
      )
      VALUES
      (
        '0200',
        p_rrn,
        p_delivery_channel,
        0,
        v_business_date,
        p_txn_code,
        v_txn_type,
        0,
        DECODE (p_resp_code, '00', 'C', 'F'),
        p_resp_code,
        p_trandate,
        SUBSTR (p_trantime, 1, 10),
        v_hash_pan,
        NULL,
        NULL,
        NULL,
        p_instcode,
        TRIM (TO_CHAR (NVL(v_tran_amt,0), '99999999999999990.99')),
        v_currcode,
        NULL,
        v_prod_code,
        v_prod_cattype,
        0,
        v_inil_authid,
        TRIM (TO_CHAR (NVL(v_tran_amt,0), '99999999999999990.99')),
        NULL,
        NULL,
        p_instcode,
        v_encr_pan,
        v_encr_pan,
        '',
        0,
        V_ACCT_NUMBER,
        NVL(V_ACCT_BALANCE,0),
        NVL(V_LEDGER_BALANCE,0),
        V_ERRMSG,
        V_RESPCODE,
        V_CAP_CARD_STAT,
        V_TRANS_DESC,
        v_acct_type,
        v_dr_cr_flag,
        v_timestamp
      );
  EXCEPTION
  WHEN OTHERS THEN
    p_resp_code := '89';
    p_errmsg    := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 300);
  END;
  BEGIN
    INSERT
    INTO cms_transaction_log_dtl
      (
        ctd_delivery_channel,
        ctd_txn_code,
        ctd_msg_type,
        ctd_txn_mode,
        ctd_business_date,
        ctd_business_time,
        ctd_customer_card_no,
        ctd_txn_amount,
        ctd_txn_curr,
        ctd_actual_amount,
        ctd_fee_amount,
        ctd_waiver_amount,
        ctd_servicetax_amount,
        ctd_cess_amount,
        ctd_bill_amount,
        ctd_bill_curr,
        ctd_process_flag,
        ctd_process_msg,
        ctd_rrn,
        ctd_inst_code,
        ctd_customer_card_no_encr,
        ctd_cust_acct_number,
        ctd_hashkey_id
      )
      VALUES
      (
        p_delivery_channel,
        p_txn_code,
        '0200',
        0,
        p_trandate,
        p_trantime,
        v_hash_pan,
        0,
        v_currcode,
        0,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        'E',
        v_errmsg,
        p_rrn,
        p_instcode,
        v_encr_pan,
        '',
        V_HASHKEY_ID
      );
    p_errmsg := v_errmsg ;
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg    := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 300);
    p_resp_code := '89'; -- Server Declined
  END;
WHEN OTHERS THEN
  P_ERRMSG := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;
/
SHOW ERROR;