set define off;
CREATE OR REPLACE PROCEDURE VMSCMS.SP_CHW_UPDATE_PIN(P_INSTCODE         IN NUMBER,
                                     P_CARDNUM          IN VARCHAR2,
                                     P_CUSTID           IN VARCHAR2,
                                     P_RRN              IN VARCHAR2,
                                     P_TRANDATE         IN VARCHAR2,
                                     P_TRANTIME         IN VARCHAR2,
                                     P_TXN_CODE         IN VARCHAR2,
                                     P_DELIVERY_CHANNEL IN VARCHAR2,
                                     P_IPADDRESS        IN VARCHAR2,
                                     P_RESP_CODE        OUT VARCHAR2,
                                     P_ERRMSG           OUT VARCHAR2,
                                     P_PIN_OFF          OUT VARCHAR2) AS

  /*************************************************

      * Modified By      :  T.Narayanan
      * Modified Date    :  11-Oct-2012
      * Modified Reason  : Modified for dup entry issue
      * Reviewer         : Saravanakumar
      * Reviewed Date    :  11-Oct-2012
      * Release Number     :  CMS3.5.1_RI0019_B0012

      * Modified By      :  RAVI N
      * Modified Date    :  02-12-2013
      * Modified Reason  :  Mantis ID 0012994
      * Modified Reason  :  Invalid Customer ID combination is commented
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  05/DEC/2013
      * Release Number   :  RI0024.7_B0001

      * Modified Date    : 16-Dec-2013
      * Modified By      : Sagar More
      * Modified for     : Defect ID 13160
      * Modified reason  : To log below details in transactinlog if applicable
                           Acct_type,timestamp,dr_cr_flag,product code,cardtype,error_msg
      * Reviewer         : Dhiraj
      * Reviewed Date    : 16-Dec-2013
      * Release Number   : RI0024.7_B0002

    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1

    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-17-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
  *************************************************/
  V_CAP_CARD_STAT   CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_CAP_CAFGEN_FLAG CMS_APPL_PAN.CAP_CAFGEN_FLAG%TYPE;
  V_FIRSTTIME_TOPUP CMS_APPL_PAN.CAP_FIRSTTIME_TOPUP%TYPE;
  V_ERRMSG          VARCHAR2(300);
  V_CURRCODE        VARCHAR2(3);
  V_APPL_CODE       CMS_APPL_MAST.CAM_APPL_CODE%TYPE;
  V_RESPCODE        VARCHAR2(5);
  V_RESPMSG         VARCHAR2(500);
  V_AUTHMSG         VARCHAR2(500);
  V_CAPTURE_DATE    DATE;
  V_MBRNUMB         CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
  V_TXN_TYPE        CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
  V_INIL_AUTHID     TRANSACTIONLOG.AUTH_ID%TYPE;
  EXP_MAIN_REJECT_RECORD EXCEPTION;
  EXP_AUTH_REJECT_RECORD EXCEPTION;
  V_HASH_PAN           CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN           CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_RRN_COUNT          NUMBER;
  V_DELCHANNEL_CODE    VARCHAR2(2);
  V_BASE_CURR          CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
  V_TRAN_DATE          DATE;
  V_TRAN_AMT           NUMBER;
  V_BUSINESS_DATE      DATE;
  V_BUSINESS_TIME      VARCHAR2(5);
  V_CUTOFF_TIME        VARCHAR2(5);
  V_CUST_CODE          CMS_CUST_MAST.CCM_CUST_CODE%TYPE;
  V_TRAN_COUNT         NUMBER;
  V_CAP_PROD_CATG      VARCHAR2(100);
--V_MMPOS_USAGEAMNT    CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
--V_MMPOS_USAGELIMIT   CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_LIMIT%TYPE;
  V_BUSINESS_DATE_TRAN DATE;
  V_ACCT_BALANCE       NUMBER;
  V_LEDGER_BAL         NUMBER;
  V_PROD_CODE          CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE       CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_EXPRY_DATE         DATE;
  V_ATMONLINE_LIMIT    CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  V_POSONLINE_LIMIT    CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  V_PROXUNUMBER        CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER        CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_COUNT              NUMBER;
  V_CUST_PAN_CNT       NUMBER;

  V_DR_CR_FLAG  VARCHAR2(2);
  V_OUTPUT_TYPE VARCHAR2(2);
  V_TRAN_TYPE   VARCHAR2(2);
  V_TRANS_DESC  CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812

  --Sn Added for 13160
  v_acct_type   cms_acct_mast.cam_type_code%type;
  v_timestamp   timestamp(3);
  --En Added for 13160
v_Retperiod  date;  --Added for VMS-5733/FSP-991
v_Retdate  date; --Added for VMS-5733/FSP-991
BEGIN
  P_ERRMSG := 'OK';

  V_RESPCODE := '1';

  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(P_CARDNUM);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_CARDNUM);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '12';
     V_ERRMSG   := 'Error while converting pan ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --Sn find debit and credit flag

  BEGIN
    SELECT CTM_CREDIT_DEBIT_FLAG,
         CTM_OUTPUT_TYPE,
         TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
         CTM_TRAN_TYPE,
         CTM_TRAN_DESC
     INTO V_DR_CR_FLAG,
         V_OUTPUT_TYPE,
         V_TXN_TYPE,
         V_TRAN_TYPE,
         V_TRANS_DESC
     FROM CMS_TRANSACTION_MAST
    WHERE CTM_TRAN_CODE = P_TXN_CODE AND
         CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
         CTM_INST_CODE = P_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '12'; --Ineligible Transaction
     V_ERRMSG   := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
                ' and delivery channel ' || P_DELIVERY_CHANNEL;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21'; --Ineligible Transaction
     V_RESPCODE := 'Error while selecting transaction details';
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En find debit and credit flag

  BEGIN
    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8), 'yyyymmdd');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '45'; -- Server Declined -220509
     V_ERRMSG   := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --En Transaction Date Check

  --Sn Transaction Time Check
  BEGIN

    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8) || ' ' ||
                      SUBSTR(TRIM(P_TRANTIME), 1, 10),
                      'yyyymmdd hh24:mi:ss');

  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '32'; -- Server Declined -220509
     V_ERRMSG   := 'Problem while converting transaction Time ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --En Transaction Time Check

  V_BUSINESS_TIME := TO_CHAR(V_TRAN_DATE, 'HH24:MI');

  IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
    V_BUSINESS_DATE := TRUNC(V_TRAN_DATE) + 1;
  ELSE
    V_BUSINESS_DATE := TRUNC(V_TRAN_DATE);
  END IF;


  --Sn find card detail
  BEGIN
    SELECT CAP_PROD_CODE,
         CAP_CARD_TYPE,
         TO_CHAR(CAP_EXPRY_DATE, 'DD-MON-YY'),
         CAP_CARD_STAT,
         CAP_ATM_ONLINE_LIMIT,
         CAP_POS_ONLINE_LIMIT,
         CAP_PROD_CATG,
         CAP_CAFGEN_FLAG,
         CAP_APPL_CODE,
         CAP_FIRSTTIME_TOPUP,
         CAP_MBR_NUMB,
         CAP_CUST_CODE,
         CAP_PROXY_NUMBER,
         CAP_ACCT_NO,
         CAP_PIN_OFF
     INTO V_PROD_CODE,
         V_PROD_CATTYPE,
         V_EXPRY_DATE,
         V_CAP_CARD_STAT,
         V_ATMONLINE_LIMIT,
         V_ATMONLINE_LIMIT,
         V_CAP_PROD_CATG,
         V_CAP_CAFGEN_FLAG,
         V_APPL_CODE,
         V_FIRSTTIME_TOPUP,
         V_MBRNUMB,
         V_CUST_CODE,
         V_PROXUNUMBER,
         V_ACCT_NUMBER,
         P_PIN_OFF
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '16'; --Ineligible Transaction
     V_ERRMSG   := 'Card number not found ' || P_TXN_CODE;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '12';
     V_ERRMSG   := 'Problem while selecting card detail' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En find card detail







  BEGIN

    SELECT CDM_CHANNEL_CODE
     INTO V_DELCHANNEL_CODE
     FROM CMS_DELCHANNEL_MAST
    WHERE CDM_CHANNEL_DESC = 'IVR' AND CDM_INST_CODE = P_INSTCODE;
    --IF the DeliveryChannel is MMPOS then the base currency will be the txn curr

    IF V_DELCHANNEL_CODE = P_DELIVERY_CHANNEL THEN

     BEGIN

            SELECT TRIM(cbp_param_value)
	     INTO v_base_curr
	     FROM cms_bin_param
             WHERE cbp_param_name = 'Currency' AND cbp_inst_code= p_instcode
             AND cbp_profile_code =(select  cpc_profile_code
	     from cms_prod_cattype where cpc_prod_code = v_prod_code
	     and cpc_card_type = V_PROD_CATTYPE and cpc_inst_code = p_instcode);

	  IF V_BASE_CURR IS NULL THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Base currency cannot be null ';
        RAISE EXP_MAIN_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Base currency is not defined for the institution ';
        RAISE EXP_MAIN_REJECT_RECORD;
       WHEN OTHERS THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Error while selecting bese currecy  ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
     END;

     V_CURRCODE := V_BASE_CURR;

    ELSE
     V_CURRCODE := '840';
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting the Delivery Channel of IVR  ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;

  END;
--Start Commented on 02 DEC 2013 for regarding Mantis:0012994
/*
  --Modified by sivapragasam on May 21 2012 to verify card number and customer ID combination

  BEGIN
    SELECT COUNT(*)
     INTO V_CUST_PAN_CNT
     FROM CMS_APPL_PAN
    WHERE CAP_PAN_CODE = V_HASH_PAN AND
         CAP_CUST_CODE =
         (SELECT CCM_CUST_CODE
            FROM CMS_CUST_MAST
           WHERE CCM_CUST_ID = P_CUSTID AND CAP_CARD_STAT <> 9);
    --and CAP_STARTERCARD_FLAG='N'

    IF V_CUST_PAN_CNT = 0 THEN

     V_RESPCODE := '21';
     V_ERRMSG   := 'Invalid Combination of Card Number ' || V_HASH_PAN ||
                ' and Customer Id ' || P_CUSTID;
     RAISE EXP_MAIN_REJECT_RECORD;

    END IF;

  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
     P_ERRMSG := 'Error while verifying card number and customer ID combination' ||
               P_CUSTID;
     RAISE EXP_MAIN_REJECT_RECORD;

  END;


  --En to verify card number and customer ID combination is correct or not
*/
--End
  --Sn Duplicate RRN Check.IF duplicate RRN log the txn and return

  BEGIN
  --Added for VMS-5733/FSP-991
  select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');
       
  IF (v_Retdate>v_Retperiod)
    THEN
    SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM TRANSACTIONLOG
    WHERE INSTCODE = P_INSTCODE AND RRN = P_RRN AND
         BUSINESS_DATE = P_TRANDATE AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; --Added by ramkumar.Mk on 25 march 2012
     ELSE       --Added for VMS-5733/FSP-991
      SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST
    WHERE INSTCODE = P_INSTCODE AND RRN = P_RRN AND
         BUSINESS_DATE = P_TRANDATE AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
     END IF;        

    IF V_RRN_COUNT > 0 THEN

     V_RESPCODE := '22';
     V_ERRMSG   := 'Duplicate RRN ' || ' on ' || P_TRANDATE;
     RAISE EXP_MAIN_REJECT_RECORD;

    END IF;

  END;

  --En Duplicate RRN Check

  -- Expiry Check

  --card status
  -- Commented by Trivikram on 22-05-2012, we done card status checks inside sp_status_check_gpr, and
  -- if we check here it will not allow transaction w.r.to GPR Card Status configuration.
  /*BEGIN
    IF V_CAP_CARD_STAT IN (2, 3) THEN

     V_RESPCODE := '41';
     V_ERRMSG   := ' Lost Card ';
     RAISE EXP_MAIN_REJECT_RECORD;

    ELSIF V_CAP_CARD_STAT = 4 THEN

     V_RESPCODE := '14';
     V_ERRMSG   := ' Restricted Card ';
     RAISE EXP_MAIN_REJECT_RECORD;

    ELSIF V_CAP_CARD_STAT = 9 THEN

     V_RESPCODE := '46';
     V_ERRMSG   := ' Closed Card ';
     RAISE EXP_MAIN_REJECT_RECORD;

    END IF;
  END; */
  --card status
  -- Commented by Trivikram on 22-05-2012, we done expiry date checks inside sp_status_check_gpr, and
  -- if we check here it will not allow transaction w.r.to GPR Card Status configuration.
  /*
  BEGIN


    IF TO_DATE(P_TRANDATE, 'YYYYMMDD') >
      LAST_DAY(TO_CHAR(V_EXPRY_DATE, 'DD-MON-YY')) THEN

     V_RESPCODE := '13';
     V_ERRMSG   := 'EXPIRED CARD';
     RAISE EXP_MAIN_REJECT_RECORD;

    END IF;

  EXCEPTION

    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;

    WHEN OTHERS THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'ERROR IN EXPIRY DATE CHECK : Tran Date - ' ||
                P_TRANDATE || ', Expiry Date - ' || V_EXPRY_DATE || ',' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;

  END;
  */

  -- End Expiry Check
 -- IF V_CAP_PROD_CATG = 'P' THEN

    --Sn call to authorize txn
    BEGIN
     SP_AUTHORIZE_TXN_CMS_AUTH(P_INSTCODE,
                          '0200',
                          P_RRN,
                          P_DELIVERY_CHANNEL,
                          '0',
                          P_TXN_CODE,
                          0,
                          P_TRANDATE,
                          P_TRANTIME,
                          P_CARDNUM,
                          NULL,
                          0,
                          NULL,
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
                          '0', -- P_stan
                          '000', --Ins User
                          '00', --INS Date
                          0,
                          V_INIL_AUTHID,
                          V_RESPCODE,
                          V_RESPMSG,
                          V_CAPTURE_DATE);

     IF V_RESPCODE <> '00' AND V_RESPMSG <> 'OK' THEN
       V_ERRMSG := V_RESPMSG;
       RAISE EXP_AUTH_REJECT_RECORD;
     END IF;

    EXCEPTION
     WHEN EXP_AUTH_REJECT_RECORD THEN
       RAISE;

     WHEN OTHERS THEN
       V_RESPCODE := '21';
       V_ERRMSG   := 'Error from Card authorization' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --En call to authorize txn
 -- END IF;

  V_ERRMSG := 'OK';
  IF V_RESPCODE <> '00' THEN
    BEGIN
     P_ERRMSG    := V_ERRMSG;
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
       P_RESP_CODE := '89';
       RAISE EXP_MAIN_REJECT_RECORD;
       ---ISO MESSAGE FOR DATABASE ERROR Server Declined

    END;
  ELSE
    P_RESP_CODE := V_RESPCODE;
  END IF;

  --En select response code and insert record into txn log dtl

  --IF errmsg is OK then balance amount will be returned

  IF P_ERRMSG = 'OK' THEN

    --Sn of Getting  the Acct Balannce
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
       INTO V_ACCT_BALANCE, V_LEDGER_BAL
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO = V_ACCT_NUMBER
        AND CAM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESPCODE := '14'; --Ineligible Transaction
       V_ERRMSG   := 'Invalid Card ';
       RAISE EXP_MAIN_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESPCODE := '12';
       V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                  V_HASH_PAN;
       RAISE EXP_MAIN_REJECT_RECORD;
    END;

    --En of Getting  the Acct Balannce
    IF P_ERRMSG = 'OK' THEN
     P_ERRMSG := ' ';
    END IF;
  END IF;
  BEGIN
  
   IF (v_Retdate>v_Retperiod)
    THEN
    UPDATE TRANSACTIONLOG
      SET IPADDRESS = P_IPADDRESS
    WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRANDATE AND
         TXN_CODE = P_TXN_CODE AND BUSINESS_TIME = P_TRANTIME AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
     ELSE
         UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST
      SET IPADDRESS = P_IPADDRESS
    WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRANDATE AND
         TXN_CODE = P_TXN_CODE AND BUSINESS_TIME = P_TRANTIME AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
     END IF;        
    IF SQL%ROWCOUNT = 0 THEN
     P_RESP_CODE := '69';
     P_ERRMSG    := 'transaction log  dtl update error for rrn:' || P_RRN;
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '69';
     P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                 SUBSTR(SQLERRM, 1, 300);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
EXCEPTION
  --<< MAIN EXCEPTION >>
  WHEN EXP_AUTH_REJECT_RECORD THEN

    P_ERRMSG    := V_ERRMSG;
    P_RESP_CODE := V_RESPCODE;

  --P_ERRMSG := V_AUTHMSG;

  WHEN EXP_MAIN_REJECT_RECORD THEN
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,cam_type_code
       INTO V_ACCT_BALANCE, V_LEDGER_BAL,v_acct_type
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO = (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
             WHERE CAP_PAN_CODE = V_HASH_PAN AND
             CAP_INST_CODE = P_INSTCODE) AND
             CAM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE := 0;
       V_LEDGER_BAL   := 0;
    END;

    --Sn select response code and insert record into txn log dtl
    BEGIN
     P_ERRMSG    := V_ERRMSG;
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
       P_RESP_CODE := '89';
       ---ISO MESSAGE FOR DATABASE ERROR Server Declined

    END;

  --Sn Added for 13160

   if v_dr_cr_flag is null
   then

       BEGIN
          SELECT ctm_credit_debit_flag
            INTO v_dr_cr_flag
            FROM cms_transaction_mast
           WHERE ctm_tran_code = P_TXN_CODE
             AND ctm_delivery_channel = P_DELIVERY_CHANNEL
             AND ctm_inst_code = P_INSTCODE;
       EXCEPTION
          WHEN OTHERS
          THEN

          null;

       END;
   end if;

   if v_prod_code is null
   then

       BEGIN
          SELECT cap_prod_code, cap_card_type,
                 cap_card_stat,
                 cap_acct_no
            INTO V_PROD_CODE, V_PROD_CATTYPE,
                 V_CAP_CARD_STAT,
                 V_ACCT_NUMBER
            FROM cms_appl_pan
           WHERE cap_inst_code = P_INSTCODE AND cap_pan_code = v_hash_pan;
       EXCEPTION
          WHEN  OTHERS
          THEN
          null;

       END;
   end if;

   v_timestamp := systimestamp;

   --En Added for 13160

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
        IPADDRESS,
        CARDSTATUS, --Added CARDSTATUS insert in transactionlog by srinivasu.k
        TRANS_DESC,
        --SN Added for 13160
        acct_type,
        time_stamp,
        cr_dr_flag,
        error_msg
        --EN Added for 13160
        )
     VALUES
       ('0200',
        P_RRN,
        P_DELIVERY_CHANNEL,
        0,
        V_BUSINESS_DATE,
        P_TXN_CODE,
        V_TXN_TYPE,
        0,
        DECODE(P_RESP_CODE, '00', 'C', 'F'),
        P_RESP_CODE,
        P_TRANDATE,
        SUBSTR(P_TRANTIME, 1, 10),
        V_HASH_PAN,
        NULL,
        NULL,
        NULL,
        P_INSTCODE,
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '99999999999999990.99')), -- NVL Added for 13160
        V_CURRCODE,
        NULL,
        V_PROD_CODE,--SUBSTR(P_CARDNUM, 1, 4),  -- modified for 13160
        V_PROD_CATTYPE,--NULL,                  -- modified for 13160
        0,
        V_INIL_AUTHID,
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '99999999999999990.99')), -- NVL Added for 13160
        '0.00',--NULL,                                            -- modified for 13160
        '0.00',--NULL,                                            -- modified for 13160
        P_INSTCODE,
        V_ENCR_PAN,
        V_ENCR_PAN,
        '',
        0,
        V_ACCT_NUMBER,--'',     -- Modified for 13160
        nvl(V_ACCT_BALANCE,0),  -- NVL Added for 13160
        nvl(V_LEDGER_BAL,0),    -- NVL Added for 13160
        V_RESPCODE,
        P_IPADDRESS,
        V_CAP_CARD_STAT, --Added CARDSTATUS insert in transactionlog by srinivasu.k
        V_TRANS_DESC,
        --SN Added for 13160
        v_acct_type,
        v_timestamp,
        v_dr_cr_flag,
        v_errmsg
        --EN Added for 13160
        );

    EXCEPTION
     WHEN OTHERS THEN

       P_RESP_CODE := '89';
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
        CTD_CUST_ACCT_NUMBER)
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        '0200',
        0,
        P_TRANDATE,
        P_TRANTIME,
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
        P_RRN,
        P_INSTCODE,
        V_ENCR_PAN,
        '');

     P_ERRMSG := V_ERRMSG;
    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '22'; -- Server Declined
       ROLLBACK;
       RETURN;
    END;
    P_RESP_CODE := P_RESP_CODE;
    P_ERRMSG    := V_ERRMSG;
  WHEN OTHERS THEN
    P_ERRMSG := ' Error from main ' || SUBSTR(SQLERRM, 1, 200);

END;
/
show error