CREATE OR REPLACE PROCEDURE VMSCMS.SP_UPDATE_CONTACT_INFO_CSR
  (
    PRM_INSTCODE         IN NUMBER,
    PRM_RRN              IN VARCHAR2,
    PRM_TERMINALID       IN VARCHAR2,
    PRM_STAN             IN VARCHAR2,
    PRM_TRANDATE         IN VARCHAR2,
    PRM_TRANTIME         IN VARCHAR2,
    PRM_ACCTNO           IN VARCHAR2,
    PRM_CURRCODE         IN VARCHAR2,
    PRM_MSG_TYPE         IN VARCHAR2,
    PRM_TXN_CODE         IN VARCHAR2,
    PRM_TXN_MODE         IN VARCHAR2,
    PRM_DELIVERY_CHANNEL IN VARCHAR2,
    PRM_MBR_NUMB         IN VARCHAR2,
    PRM_RVSL_CODE        IN VARCHAR2,
    PRM_ADD_LINE_ONE     IN VARCHAR2,
    PRM_ADD_LINE_TWO     IN VARCHAR2,
    PRM_CITY             IN VARCHAR2,
    PRM_ZIP              IN VARCHAR2,
    PRM_PHONENUM         IN VARCHAR2,
    PRM_OTHERPHONE       IN VARCHAR2,
    PRM_STATE            IN VARCHAR2,
    PRM_COUNTRY_CODE     IN VARCHAR2,
    PRM_EMAIL            IN VARCHAR2,
    PRM_PHY_ADD_LINE_ONE IN VARCHAR2,
    PRM_PHY_ADD_LINE_TWO IN VARCHAR2,
    PRM_PHY_CITY         IN VARCHAR2,
    PRM_PHY_ZIP          IN VARCHAR2,
    PRM_PHY_PHONENUM     IN VARCHAR2,
    PRM_PHY_OTHERPHONE   IN VARCHAR2,
    PRM_PHY_STATE        IN VARCHAR2,
    PRM_PHY_COUNTRY_CODE IN VARCHAR2,
    PRM_RESP_CODE OUT VARCHAR2,
    PRM_ERRMSG OUT VARCHAR2 )
AS
  V_CAP_PROD_CATG CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
  V_CAP_CARD_STAT CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_CAP_CAFGEN_FLAG CMS_APPL_PAN.CAP_CAFGEN_FLAG%TYPE;
  V_FIRSTTIME_TOPUP CMS_APPL_PAN.CAP_FIRSTTIME_TOPUP%TYPE;
  V_ERRMSG   VARCHAR2(300);
  V_CURRCODE VARCHAR2(3);
  V_APPL_CODE CMS_APPL_MAST.CAM_APPL_CODE%TYPE;
  V_RESPCODE VARCHAR2(5);
  V_RESPMSG  VARCHAR2(500);
  V_AUTHMSG  VARCHAR2(500);
  V_CAPTURE_DATE DATE;
  V_MBRNUMB CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
  V_TXN_CODE CMS_FUNC_MAST.CFM_TXN_CODE%TYPE;
  V_TXN_MODE CMS_FUNC_MAST.CFM_TXN_MODE%TYPE;
  V_DEL_CHANNEL CMS_FUNC_MAST.CFM_DELIVERY_CHANNEL%TYPE;
  V_TXN_TYPE CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
  V_INIL_AUTHID TRANSACTIONLOG.AUTH_ID%TYPE;
  EXP_MAIN_REJECT_RECORD EXCEPTION;
  EXP_AUTH_REJECT_RECORD EXCEPTION;
  V_HASH_PAN CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_RRN_COUNT       NUMBER;
  V_DELCHANNEL_CODE VARCHAR2(2);
  V_BASE_CURR CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_TRAN_DATE DATE;
  V_ACCT_BALANCE   NUMBER;
  V_LEDGER_BALANCE NUMBER;
  V_BUSINESS_DATE  VARCHAR2(8);
  V_BUSINESS_TIME  VARCHAR2(12);
  V_CUTOFF_TIME    VARCHAR2(5);
  V_CUST_CODE CMS_CUST_MAST.CCM_CUST_CODE%TYPE;
  V_AGE_CHECK DATE;
  EXP_REJECT_RECORD EXCEPTION;
  V_MMPOS_USAGEAMNT CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
  V_MMPOS_USAGELIMIT CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_LIMIT%TYPE;
  V_BUSINESS_DATE_TRAN DATE;
  V_PROXUNUMBER CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
BEGIN
  --<<MAIN BEGIN >>
  PRM_ERRMSG := 'OK';
  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(PRM_ACCTNO);
    DBMS_OUTPUT.PUT_LINE('AFTER INSERT IN TRANSACTIONLOG' || V_HASH_PAN);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --EN CREATE HASH PAN
  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(PRM_ACCTNO);
  EXCEPTION
  WHEN OTHERS THEN
    V_RESPCODE := '12';
    V_ERRMSG   := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --EN create encr pan
  --Sn Transaction Date Check
  BEGIN
    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(PRM_TRANDATE), 1, 8), 'yyyymmdd');
  EXCEPTION
  WHEN OTHERS THEN
    V_RESPCODE := '45'; -- Server Declined -220509
    V_ERRMSG   := 'Problem while converting transaction date ' || SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --En Transaction Date Check
  --Sn Transaction Time Check
  BEGIN
    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(PRM_TRANDATE), 1, 8) || ' ' || SUBSTR(TRIM(PRM_TRANTIME), 1, 10), 'yyyymmdd hh24:mi:ss');
  EXCEPTION
  WHEN OTHERS THEN
    V_RESPCODE := '32'; -- Server Declined -220509
    V_ERRMSG   := 'Problem while converting transaction Time ' || SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --En Transaction Time Check
  BEGIN
    SELECT CDM_CHANNEL_CODE
    INTO V_DELCHANNEL_CODE
    FROM CMS_DELCHANNEL_MAST
    WHERE CDM_CHANNEL_DESC = 'MMPOS'
    AND CDM_INST_CODE      = PRM_INSTCODE;
    IF V_DELCHANNEL_CODE   = PRM_DELIVERY_CHANNEL THEN
      BEGIN
        SELECT CIP_PARAM_VALUE
        INTO V_BASE_CURR
        FROM CMS_INST_PARAM
        WHERE CIP_INST_CODE   = PRM_INSTCODE
        AND CIP_PARAM_KEY     = 'CURRENCY';
        IF TRIM(V_BASE_CURR) IS NULL THEN
          V_RESPCODE         := '21';
          V_ERRMSG           := 'Base currency cannot be null ';
          RAISE EXP_MAIN_REJECT_RECORD;
        END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Base currency is not defined for the institution ';
        RAISE EXP_MAIN_REJECT_RECORD;
      WHEN OTHERS THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Error while selecting bese currecy  ' || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
      END;
      V_CURRCODE := V_BASE_CURR;
    ELSE
      V_CURRCODE := PRM_CURRCODE;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERRMSG := 'Error while selecting the Delivery Channel of MMPOS  ' || SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --Sn Duplicate RRN Check.IF duplicate RRN log the txn and return
  BEGIN
    SELECT TO_CHAR(SYSDATE, 'yyyymmdd') INTO V_BUSINESS_DATE FROM DUAL;
    SELECT COUNT(1)
    INTO V_RRN_COUNT
    FROM TRANSACTIONLOG
    WHERE INSTCODE    = PRM_INSTCODE
    AND RRN           = PRM_RRN
    AND BUSINESS_DATE = V_BUSINESS_DATE;
    IF V_RRN_COUNT    > 0 THEN
      V_RESPCODE     := '22';
      V_ERRMSG       := 'Duplicate RRN from the Treminal  on ' || PRM_TRANDATE;
      RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;
  --En Duplicate RRN Check
  BEGIN
    SELECT CAP_CARD_STAT,
      CAP_PROD_CATG,
      CAP_CAFGEN_FLAG,
      CAP_APPL_CODE,
      CAP_FIRSTTIME_TOPUP,
      CAP_MBR_NUMB,
      CAP_CUST_CODE,
      CAP_PROXY_NUMBER,
      CAP_ACCT_NO
    INTO V_CAP_CARD_STAT,
      V_CAP_PROD_CATG,
      V_CAP_CAFGEN_FLAG,
      V_APPL_CODE,
      V_FIRSTTIME_TOPUP,
      V_MBRNUMB,
      V_CUST_CODE,
      V_PROXUNUMBER,
      V_ACCT_NUMBER
    FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = PRM_INSTCODE
    AND CAP_PAN_CODE    = V_HASH_PAN; -- prm_acctno;
  EXCEPTION
  WHEN EXP_MAIN_REJECT_RECORD THEN
    RAISE;
  WHEN NO_DATA_FOUND THEN
    V_ERRMSG := 'Invalid Card number ' || PRM_ACCTNO;
    RAISE EXP_MAIN_REJECT_RECORD;
  WHEN OTHERS THEN
    V_ERRMSG := 'Error while selecting card number ' || PRM_ACCTNO;
    RAISE EXP_MAIN_REJECT_RECORD;
  END;
  BEGIN
    IF V_CAP_CARD_STAT = '4' THEN
      V_RESPCODE      := '14'; --added
      V_ERRMSG        := 'Card Restricted';
      RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;
  BEGIN
    IF V_CAP_CARD_STAT = '2' THEN
      V_RESPCODE      := '41'; --added
      V_ERRMSG        := 'Lost Card';
      RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;
  BEGIN
    IF V_CAP_CARD_STAT = '9' THEN
      V_RESPCODE      := '46'; --added
      V_ERRMSG        := 'Closed Card';
      RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;
  BEGIN
    IF V_CAP_CARD_STAT = '0' THEN
      V_RESPCODE      := '10'; --added
      V_ERRMSG        := 'Inactive Card';
      RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  END;
  BEGIN
    --IF PRM_DELIVERY_CHANNEL = '10' AND PRM_TXN_CODE = '09' THEN  //Commented by Lince on 27 Sep 2011
    UPDATE CMS_ADDR_MAST
    SET CAM_ADD_ONE       = PRM_ADD_LINE_ONE,
      CAM_ADD_TWO         = PRM_ADD_LINE_TWO,
      CAM_CITY_NAME       = PRM_CITY,
      CAM_PIN_CODE        = PRM_ZIP,
      CAM_PHONE_ONE       = PRM_PHONENUM,
      CAM_MOBL_ONE        = PRM_OTHERPHONE,
      CAM_STATE_CODE      = PRM_STATE,
      CAM_CNTRY_CODE      = PRM_COUNTRY_CODE,
      CAM_PHY_ADD_ONE     = PRM_PHY_ADD_LINE_ONE,
      CAM_PHY_ADD_TWO     = PRM_PHY_ADD_LINE_TWO,
      CAM_PHY_CITY_CODE   = PRM_PHY_CITY,
      CAM_PHY_ZIP_CODE    = PRM_PHY_ZIP,
      CAM_PHY_PHONE_NUM   = PRM_PHY_PHONENUM,
      CAM_PHY_OTHER_PHONE = PRM_PHY_OTHERPHONE,
      CAM_PHY_STATE_CODE  = PRM_PHY_STATE,
      CAM_PHY_CNTRY_CODE  = PRM_PHY_COUNTRY_CODE,
      CAM_EMAIL           = PRM_EMAIL
    WHERE CAM_INST_CODE   = PRM_INSTCODE
    AND CAM_CUST_CODE     = V_CUST_CODE;
    --END IF;                                                  //Commented by Lince on 27 Sep 2011
  EXCEPTION
  WHEN OTHERS THEN
    V_RESPCODE := '21';
    V_ERRMSG   := 'ERROR IN  UPDATE CONTACT INFORMATION ' || SUBSTR(SQLERRM, 1, 300);
    RAISE EXP_MAIN_REJECT_RECORD;
  END;
  SELECT TO_CHAR(SYSDATE, 'hh24miss') INTO V_BUSINESS_TIME FROM DUAL;
  SELECT TO_CHAR(SYSDATE, 'yyyymmdd') INTO V_BUSINESS_DATE FROM DUAL;
  BEGIN
    SP_AUTHORIZE_TXN_CMS_AUTH(PRM_INSTCODE, PRM_MSG_TYPE, PRM_RRN, PRM_DELIVERY_CHANNEL, PRM_TERMINALID, PRM_TXN_CODE, PRM_TXN_MODE, V_BUSINESS_DATE, V_BUSINESS_TIME, PRM_ACCTNO, NULL, 0, NULL, NULL, NULL, V_CURRCODE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, PRM_STAN, -- prm_stan
    PRM_MBR_NUMB,                                                                                                                                                                                                                                                                                                 --Ins User
    PRM_RVSL_CODE,                                                                                                                                                                                                                                                                                                --INS Date
    NULL, V_INIL_AUTHID, V_RESPCODE, V_RESPMSG, V_CAPTURE_DATE);
    IF V_RESPCODE <> '00' AND V_RESPMSG <> 'OK' THEN
      V_ERRMSG    := V_RESPMSG;
      --v_errmsg := 'Error from auth process' || v_respmsg;
      RAISE EXP_AUTH_REJECT_RECORD;
    END IF;
    IF V_RESPCODE <> '00' THEN
      BEGIN
        PRM_ERRMSG    := ' ';
        PRM_RESP_CODE := V_RESPCODE;
        -- Assign the response code to the out parameter
        SELECT CMS_ISO_RESPCDE
        INTO PRM_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = PRM_INSTCODE
        AND CMS_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = V_RESPCODE;
      EXCEPTION
      WHEN OTHERS THEN
        PRM_ERRMSG    := 'Problem while selecting data from response master ' || V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
        PRM_RESP_CODE := '89';
        ---ISO MESSAGE FOR DATABASE ERROR Server Declined
        ROLLBACK;
      END;
    ELSE
      PRM_RESP_CODE := V_RESPCODE;
    END IF;
    --En select response code and insert record into txn log dtl
    ---Sn Updation of Usage limit and amount
    BEGIN
      SELECT CTC_MMPOSUSAGE_AMT,
        CTC_MMPOSUSAGE_LIMIT,
        CTC_BUSINESS_DATE
      INTO V_MMPOS_USAGEAMNT,
        V_MMPOS_USAGELIMIT,
        V_BUSINESS_DATE_TRAN
      FROM CMS_TRANSLIMIT_CHECK
      WHERE CTC_INST_CODE = PRM_INSTCODE
      AND CTC_PAN_CODE    = V_HASH_PAN --prm_card_no
      AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' || SUBSTR(SQLERRM, 1, 300);
      V_RESPCODE := '21';
      RAISE EXP_MAIN_REJECT_RECORD;
    END;
    BEGIN
      --Sn Usage limit and amount updation for MMPOS
      IF PRM_DELIVERY_CHANNEL = '04' THEN
        IF V_TRAN_DATE        > V_BUSINESS_DATE_TRAN THEN
          V_MMPOS_USAGELIMIT := 1;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET CTC_MMPOSUSAGE_AMT = 0,
            CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT,
            CTC_ATMUSAGE_AMT     = 0,
            CTC_ATMUSAGE_LIMIT   = 0,
            CTC_BUSINESS_DATE    = TO_DATE(PRM_TRANDATE
            || '23:59:59', 'yymmdd'
            || 'hh24:mi:ss'),
            CTC_PREAUTHUSAGE_LIMIT = 0,
            CTC_POSUSAGE_AMT       = 0,
            CTC_POSUSAGE_LIMIT     = 0
          WHERE CTC_INST_CODE      = PRM_INSTCODE
          AND CTC_PAN_CODE         = V_HASH_PAN -- prm_card_no
          AND CTC_MBR_NUMB         = PRM_MBR_NUMB;
        ELSE
          V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET --ctc_mmposusage_amt = v_mmpos_usageamnt,
            CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
          WHERE CTC_INST_CODE    = PRM_INSTCODE
          AND CTC_PAN_CODE       = V_HASH_PAN --prm_card_no
          AND CTC_MBR_NUMB       = PRM_MBR_NUMB;
        END IF;
      END IF;
      --En Usage limit and amount updation for MMPOS
    END;
    ---En Updation of Usage limit and amount
    --IF errmsg is OK then balance amount will be returned
    IF PRM_ERRMSG = 'OK' THEN
      --Sn of Getting  the Acct Balannce
      BEGIN
        SELECT CAM_ACCT_BAL,
          CAM_LEDGER_BAL
        INTO V_ACCT_BALANCE,
          V_LEDGER_BALANCE
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =
          (SELECT CAP_ACCT_NO
          FROM CMS_APPL_PAN
          WHERE CAP_PAN_CODE = V_HASH_PAN --prm_card_no
          AND CAP_MBR_NUMB   = PRM_MBR_NUMB
          AND CAP_INST_CODE  = PRM_INSTCODE
          )
        AND CAM_INST_CODE = PRM_INSTCODE FOR UPDATE NOWAIT;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_RESPCODE := '14'; --Ineligible Transaction
        V_ERRMSG   := 'Invalid Card ';
        RAISE EXP_MAIN_REJECT_RECORD;
      WHEN OTHERS THEN
        V_RESPCODE := '12';
        V_ERRMSG   := 'Error while selecting data from card Master for card number ' || V_HASH_PAN;
        RAISE EXP_MAIN_REJECT_RECORD;
      END;
      --En of Getting  the Acct Balannce
      PRM_ERRMSG := ' ';
    END IF;
  EXCEPTION
    --<< MAIN EXCEPTION >>
  WHEN EXP_AUTH_REJECT_RECORD THEN
    ROLLBACK;
    ---Sn Updation of Usage limit and amount
    BEGIN
      SELECT CTC_MMPOSUSAGE_AMT,
        CTC_MMPOSUSAGE_LIMIT,
        CTC_BUSINESS_DATE
      INTO V_MMPOS_USAGEAMNT,
        V_MMPOS_USAGELIMIT,
        V_BUSINESS_DATE_TRAN
      FROM CMS_TRANSLIMIT_CHECK
      WHERE CTC_INST_CODE = PRM_INSTCODE
      AND CTC_PAN_CODE    = V_HASH_PAN --prm_card_no
      AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' || SUBSTR(SQLERRM, 1, 300);
      V_RESPCODE := '21';
      RAISE EXP_MAIN_REJECT_RECORD;
    END;
    BEGIN
      --Sn Usage limit and amount updation for MMPOS
      IF PRM_DELIVERY_CHANNEL = '04' THEN
        IF V_TRAN_DATE        > V_BUSINESS_DATE_TRAN THEN
          V_MMPOS_USAGELIMIT := 1;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET CTC_MMPOSUSAGE_AMT = 0,
            CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT,
            CTC_ATMUSAGE_AMT     = 0,
            CTC_ATMUSAGE_LIMIT   = 0,
            CTC_BUSINESS_DATE    = TO_DATE(PRM_TRANDATE
            || '23:59:59', 'yymmdd'
            || 'hh24:mi:ss'),
            CTC_PREAUTHUSAGE_LIMIT = 0,
            CTC_POSUSAGE_AMT       = 0,
            CTC_POSUSAGE_LIMIT     = 0
          WHERE CTC_INST_CODE      = PRM_INSTCODE
          AND CTC_PAN_CODE         = V_HASH_PAN -- prm_card_no
          AND CTC_MBR_NUMB         = PRM_MBR_NUMB;
        ELSE
          V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;
          UPDATE CMS_TRANSLIMIT_CHECK
          SET --ctc_mmposusage_amt = v_mmpos_usageamnt,
            CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
          WHERE CTC_INST_CODE    = PRM_INSTCODE
          AND CTC_PAN_CODE       = V_HASH_PAN --prm_card_no
          AND CTC_MBR_NUMB       = PRM_MBR_NUMB;
        END IF;
      END IF;
      --En Usage limit and amount updation for MMPOS
    END;
    ---En Updation of Usage limit and amount
    PRM_ERRMSG    := V_ERRMSG;
    PRM_RESP_CODE := V_RESPCODE;
    --Sn select response code and insert record into txn log dtl
    --Sn create a entry in txn log
    BEGIN
      INSERT
      INTO TRANSACTIONLOG
        (
          MSGTYPE,
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
          TRANFEE_AMT,
          PROXY_NUMBER,
          REVERSAL_CODE,
          CUSTOMER_ACCT_NO,
          ACCT_BALANCE,
          LEDGER_BALANCE
        )
        VALUES
        (
          PRM_MSG_TYPE,
          PRM_RRN,
          PRM_DELIVERY_CHANNEL,
          PRM_TERMINALID,
          V_BUSINESS_DATE,
          PRM_TXN_CODE,
          '',
          PRM_TXN_MODE,
          DECODE(PRM_RESP_CODE, '00', 'C', 'F'),
          PRM_RESP_CODE,
          PRM_TRANDATE,
          SUBSTR(PRM_TRANTIME, 1, 10),
          V_HASH_PAN,
          NULL,
          NULL,
          NULL,
          PRM_INSTCODE,
          TRIM(TO_CHAR(0, '99999999999999999.99')),
          V_CURRCODE,
          NULL,
          '',
          '',
          PRM_TERMINALID,
          V_INIL_AUTHID,
          TRIM(TO_CHAR(0, '99999999999999999.99')),
          NULL,
          NULL,
          PRM_INSTCODE,
          V_ENCR_PAN,
          V_ENCR_PAN,
          0,
          V_PROXUNUMBER,
          PRM_RVSL_CODE,
          V_ACCT_NUMBER,
          V_ACCT_BALANCE,
          V_LEDGER_BALANCE
        );
    EXCEPTION
    WHEN OTHERS THEN
      PRM_RESP_CODE := '89';
      PRM_ERRMSG    := 'Problem while inserting data into transaction log  dtl' || SUBSTR
      (
        SQLERRM, 1, 300
      )
      ;
    END;
    --En create a entry in txn log
    BEGIN
      INSERT
      INTO CMS_TRANSACTION_LOG_DTL
        (
          CTD_DELIVERY_CHANNEL,
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
          CTD_CUST_ACCT_NUMBER
        )
        VALUES
        (
          PRM_DELIVERY_CHANNEL,
          PRM_TXN_CODE,
          PRM_MSG_TYPE,
          PRM_TXN_MODE,
          PRM_TRANDATE,
          PRM_TRANTIME,
          --prm_card_no
          V_HASH_PAN,
          0,
          V_CURRCODE,
          0,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          'E',
          V_ERRMSG,
          PRM_RRN,
          PRM_INSTCODE,
          V_ENCR_PAN,
          V_ACCT_NUMBER
        );
      
      PRM_ERRMSG := V_ERRMSG;
      RETURN;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
      (
        SQLERRM, 1, 300
      )
      ;
      PRM_RESP_CODE := '22'; -- Server Declined
      ROLLBACK;
      RETURN;
    END;
    PRM_ERRMSG := V_AUTHMSG;
    -- prm_errmsg := 'OK';
  WHEN EXP_MAIN_REJECT_RECORD THEN
    ROLLBACK;
    --Sn select response code and insert record into txn log dtl
    BEGIN
      ---Sn Updation of Usage limit and amount
      BEGIN
        SELECT CTC_MMPOSUSAGE_AMT,
          CTC_MMPOSUSAGE_LIMIT,
          CTC_BUSINESS_DATE
        INTO V_MMPOS_USAGEAMNT,
          V_MMPOS_USAGELIMIT,
          V_BUSINESS_DATE_TRAN
        FROM CMS_TRANSLIMIT_CHECK
        WHERE CTC_INST_CODE = PRM_INSTCODE
        AND CTC_PAN_CODE    = V_HASH_PAN --prm_card_no
        AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' || SUBSTR(SQLERRM, 1, 300);
        V_RESPCODE := '21';
        RAISE EXP_MAIN_REJECT_RECORD;
      END;
      BEGIN
        --Sn Usage limit and amount updation for MMPOS
        IF PRM_DELIVERY_CHANNEL = '04' THEN
          IF V_TRAN_DATE        > V_BUSINESS_DATE_TRAN THEN
            V_MMPOS_USAGELIMIT := 1;
            UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_MMPOSUSAGE_AMT = 0,
              CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT,
              CTC_ATMUSAGE_AMT     = 0,
              CTC_ATMUSAGE_LIMIT   = 0,
              CTC_BUSINESS_DATE    = TO_DATE(PRM_TRANDATE
              || '23:59:59', 'yymmdd'
              || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0
            WHERE CTC_INST_CODE      = PRM_INSTCODE
            AND CTC_PAN_CODE         = V_HASH_PAN -- prm_card_no
            AND CTC_MBR_NUMB         = PRM_MBR_NUMB;
          ELSE
            V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;
            UPDATE CMS_TRANSLIMIT_CHECK
            SET --ctc_mmposusage_amt = v_mmpos_usageamnt,
              CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
            WHERE CTC_INST_CODE    = PRM_INSTCODE
            AND CTC_PAN_CODE       = V_HASH_PAN --prm_card_no
            AND CTC_MBR_NUMB       = PRM_MBR_NUMB;
          END IF;
        END IF;
        --En Usage limit and amount updation for MMPOS
      END;
      ---En Updation of Usage limit and amount
      PRM_ERRMSG    := V_ERRMSG;
      PRM_RESP_CODE := V_RESPCODE;
      -- Assign the response code to the out parameter
      SELECT CMS_ISO_RESPCDE
      INTO PRM_RESP_CODE
      FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE      = PRM_INSTCODE
      AND CMS_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL
      AND CMS_RESPONSE_ID      = V_RESPCODE;
    EXCEPTION
    WHEN OTHERS THEN
      PRM_ERRMSG    := 'Problem while selecting data from response master ' || V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
      PRM_RESP_CODE := '89';
      ---ISO MESSAGE FOR DATABASE ERROR Server Declined
      ROLLBACK;
      -- RETURN;
    END;
    --Sn create a entry in txn log
    BEGIN
      INSERT
      INTO TRANSACTIONLOG
        (
          MSGTYPE,
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
          TRANFEE_AMT,
          PROXY_NUMBER,
          REVERSAL_CODE,
          CUSTOMER_ACCT_NO,
          ACCT_BALANCE,
          LEDGER_BALANCE
        )
        VALUES
        (
          PRM_MSG_TYPE,
          PRM_RRN,
          PRM_DELIVERY_CHANNEL,
          PRM_TERMINALID,
          V_BUSINESS_DATE,
          PRM_TXN_CODE,
          V_TXN_TYPE,
          PRM_TXN_MODE,
          DECODE(PRM_RESP_CODE, '00', 'C', 'F'),
          PRM_RESP_CODE,
          PRM_TRANDATE,
          SUBSTR(PRM_TRANTIME, 1, 10),
          V_HASH_PAN,
          NULL,
          NULL,
          NULL,
          PRM_INSTCODE,
          TRIM(TO_CHAR(0, '99999999999999999.99')),
          V_CURRCODE,
          NULL,
          '',
          '',
          PRM_TERMINALID,
          V_INIL_AUTHID,
          TRIM(TO_CHAR(0, '99999999999999999.99')),
          NULL,
          NULL,
          PRM_INSTCODE,
          V_ENCR_PAN,
          V_ENCR_PAN,
          0,
          V_PROXUNUMBER,
          PRM_RVSL_CODE,
          V_ACCT_NUMBER,
          V_ACCT_BALANCE,
          V_LEDGER_BALANCE
        );
    EXCEPTION
    WHEN OTHERS THEN
      PRM_RESP_CODE := '89';
      PRM_ERRMSG    := 'Problem while inserting data into transaction log  dtl' || SUBSTR
      (
        SQLERRM, 1, 300
      )
      ;
    END;
    --En create a entry in txn log
    BEGIN
      INSERT
      INTO CMS_TRANSACTION_LOG_DTL
        (
          CTD_DELIVERY_CHANNEL,
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
          CTD_CUST_ACCT_NUMBER
        )
        VALUES
        (
          PRM_DELIVERY_CHANNEL,
          PRM_TXN_CODE,
          PRM_MSG_TYPE,
          PRM_TXN_MODE,
          PRM_TRANDATE,
          PRM_TRANTIME,
          --prm_card_no
          V_HASH_PAN,
          0,
          V_CURRCODE,
          0,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          'E',
          V_ERRMSG,
          PRM_RRN,
          PRM_INSTCODE,
          V_ENCR_PAN,
          V_ACCT_NUMBER
        );
      
      PRM_ERRMSG := V_ERRMSG;
      RETURN;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERRMSG := 'Problem while inserting data into transaction log  dtl' || SUBSTR
      (
        SQLERRM, 1, 300
      )
      ;
      PRM_RESP_CODE := '22'; -- Server Declined
      ROLLBACK;
      RETURN;
    END;
    PRM_ERRMSG := V_ERRMSG;
  WHEN OTHERS THEN
    -- insert transactionlog and cms_transactio_log_dtl for exception cases
    BEGIN
      ROLLBACK;
      ---Sn Updation of Usage limit and amount
      BEGIN
        SELECT CTC_MMPOSUSAGE_AMT,
          CTC_MMPOSUSAGE_LIMIT,
          CTC_BUSINESS_DATE
        INTO V_MMPOS_USAGEAMNT,
          V_MMPOS_USAGELIMIT,
          V_BUSINESS_DATE_TRAN
        FROM CMS_TRANSLIMIT_CHECK
        WHERE CTC_INST_CODE = PRM_INSTCODE
        AND CTC_PAN_CODE    = V_HASH_PAN --prm_card_no
        AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' || SUBSTR(SQLERRM, 1, 300);
        V_RESPCODE := '21';
        RAISE EXP_MAIN_REJECT_RECORD;
      END;
      BEGIN
        --Sn Usage limit and amount updation for MMPOS
        IF PRM_DELIVERY_CHANNEL = '04' THEN
          IF V_TRAN_DATE        > V_BUSINESS_DATE_TRAN THEN
            V_MMPOS_USAGELIMIT := 1;
            UPDATE CMS_TRANSLIMIT_CHECK
            SET CTC_MMPOSUSAGE_AMT = 0,
              CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT,
              CTC_ATMUSAGE_AMT     = 0,
              CTC_ATMUSAGE_LIMIT   = 0,
              CTC_BUSINESS_DATE    = TO_DATE(PRM_TRANDATE
              || '23:59:59', 'yymmdd'
              || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0
            WHERE CTC_INST_CODE      = PRM_INSTCODE
            AND CTC_PAN_CODE         = V_HASH_PAN -- prm_card_no
            AND CTC_MBR_NUMB         = PRM_MBR_NUMB;
          ELSE
            V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;
            UPDATE CMS_TRANSLIMIT_CHECK
            SET --ctc_mmposusage_amt = v_mmpos_usageamnt,
              CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
            WHERE CTC_INST_CODE    = PRM_INSTCODE
            AND CTC_PAN_CODE       = V_HASH_PAN --prm_card_no
            AND CTC_MBR_NUMB       = PRM_MBR_NUMB;
          END IF;
        END IF;
        --En Usage limit and amount updation for MMPOS
      END;
      ---En Updation of Usage limit and amount
      --Sn select response code and insert record into txn log dtl
      BEGIN
        PRM_ERRMSG    := V_ERRMSG;
        PRM_RESP_CODE := V_RESPCODE;
        -- Assign the response code to the out parameter
        SELECT CMS_ISO_RESPCDE
        INTO PRM_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE      = PRM_INSTCODE
        AND CMS_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL
        AND CMS_RESPONSE_ID      = V_RESPCODE;
      EXCEPTION
      WHEN OTHERS THEN
        PRM_ERRMSG    := 'Problem while selecting data from response master ' || V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
        PRM_RESP_CODE := '89';
        ---ISO MESSAGE FOR DATABASE ERROR Server Declined
        --ROLLBACK;
        -- RETURN;
      END;
      INSERT
      INTO CMS_TRANSACTION_LOG_DTL
        (
          CTD_DELIVERY_CHANNEL,
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
          CTD_CUST_ACCT_NUMBER
        )
        VALUES
        (
          PRM_DELIVERY_CHANNEL,
          PRM_TXN_CODE,
          PRM_MSG_TYPE,
          PRM_TXN_MODE,
          PRM_TRANDATE,
          PRM_TRANTIME,
          --prm_card_no
          V_HASH_PAN,
          0,
          V_CURRCODE,
          0,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          'E',
          V_ERRMSG,
          PRM_RRN,
          PRM_INSTCODE,
          V_ENCR_PAN,
          V_ACCT_NUMBER
        );
      
      PRM_ERRMSG := ' Error from main ' || SUBSTR
      (
        SQLERRM, 1, 200
      )
      ;
    END;
  END;
EXCEPTION
WHEN OTHERS THEN
  -- insert transactionlog and cms_transactio_log_dtl for exception cases
  ROLLBACK;
  ---Sn Updation of Usage limit and amount
  BEGIN
    SELECT CTC_MMPOSUSAGE_AMT,
      CTC_MMPOSUSAGE_LIMIT,
      CTC_BUSINESS_DATE
    INTO V_MMPOS_USAGEAMNT,
      V_MMPOS_USAGELIMIT,
      V_BUSINESS_DATE_TRAN
    FROM CMS_TRANSLIMIT_CHECK
    WHERE CTC_INST_CODE = PRM_INSTCODE
    AND CTC_PAN_CODE    = V_HASH_PAN --prm_card_no
    AND CTC_MBR_NUMB    = PRM_MBR_NUMB;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' || SUBSTR(SQLERRM, 1, 300);
    V_RESPCODE := '21';
    RAISE EXP_MAIN_REJECT_RECORD;
  END;
  BEGIN
    --Sn Usage limit and amount updation for MMPOS
    IF PRM_DELIVERY_CHANNEL = '04' THEN
      IF V_TRAN_DATE        > V_BUSINESS_DATE_TRAN THEN
        V_MMPOS_USAGELIMIT := 1;
        UPDATE CMS_TRANSLIMIT_CHECK
        SET CTC_MMPOSUSAGE_AMT = 0,
          CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT,
          CTC_ATMUSAGE_AMT     = 0,
          CTC_ATMUSAGE_LIMIT   = 0,
          CTC_BUSINESS_DATE    = TO_DATE(PRM_TRANDATE
          || '23:59:59', 'yymmdd'
          || 'hh24:mi:ss'),
          CTC_PREAUTHUSAGE_LIMIT = 0,
          CTC_POSUSAGE_AMT       = 0,
          CTC_POSUSAGE_LIMIT     = 0
        WHERE CTC_INST_CODE      = PRM_INSTCODE
        AND CTC_PAN_CODE         = V_HASH_PAN -- prm_card_no
        AND CTC_MBR_NUMB         = PRM_MBR_NUMB;
      ELSE
        V_MMPOS_USAGELIMIT := V_MMPOS_USAGELIMIT + 1;
        UPDATE CMS_TRANSLIMIT_CHECK
        SET --ctc_mmposusage_amt = v_mmpos_usageamnt,
          CTC_MMPOSUSAGE_LIMIT = V_MMPOS_USAGELIMIT
        WHERE CTC_INST_CODE    = PRM_INSTCODE
        AND CTC_PAN_CODE       = V_HASH_PAN --prm_card_no
        AND CTC_MBR_NUMB       = PRM_MBR_NUMB;
      END IF;
    END IF;
    --En Usage limit and amount updation for MMPOS
  END;
  ---En Updation of Usage limit and amount
  --Sn select response code and insert record into txn log dtl
  BEGIN
    PRM_ERRMSG    := V_ERRMSG;
    PRM_RESP_CODE := V_RESPCODE;
    -- Assign the response code to the out parameter
    SELECT CMS_ISO_RESPCDE
    INTO PRM_RESP_CODE
    FROM CMS_RESPONSE_MAST
    WHERE CMS_INST_CODE      = PRM_INSTCODE
    AND CMS_DELIVERY_CHANNEL = PRM_DELIVERY_CHANNEL
    AND CMS_RESPONSE_ID      = V_RESPCODE;
  EXCEPTION
  WHEN OTHERS THEN
    PRM_ERRMSG    := 'Problem while selecting data from response master ' || V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
    PRM_RESP_CODE := '89';
    ---ISO MESSAGE FOR DATABASE ERROR Server Declined
    --ROLLBACK;
    -- RETURN;
  END;
  INSERT
  INTO CMS_TRANSACTION_LOG_DTL
    (
      CTD_DELIVERY_CHANNEL,
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
      CTD_CUST_ACCT_NUMBER
    )
    VALUES
    (
      PRM_DELIVERY_CHANNEL,
      PRM_TXN_CODE,
      PRM_MSG_TYPE,
      PRM_TXN_MODE,
      PRM_TRANDATE,
      PRM_TRANTIME,
      --prm_card_no
      V_HASH_PAN,
      0,
      V_CURRCODE,
      0,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      'E',
      V_ERRMSG,
      PRM_RRN,
      PRM_INSTCODE,
      V_ENCR_PAN,
      V_ACCT_NUMBER
    );
END;
/


