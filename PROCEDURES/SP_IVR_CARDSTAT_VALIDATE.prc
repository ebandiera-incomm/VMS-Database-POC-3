SET DEFINE OFF;
create or replace PROCEDURE    VMSCMS.SP_IVR_CARDSTAT_VALIDATE(P_INSTCODE         IN NUMBER,
                                          P_CARDNUM          IN VARCHAR2,
                                          P_RRN              IN VARCHAR2,
                                          P_TRANDATE         IN VARCHAR2,
                                          P_TRANTIME         IN VARCHAR2,
                                          P_TXN_CODE         IN VARCHAR2,
                                          P_DELIVERY_CHANNEL IN VARCHAR2,
                                          P_ANI              IN VARCHAR2,
                                          P_DNI              IN VARCHAR2,
                                          P_MSG_TYPE         IN VARCHAR2,--Added for defect 9786
                                          P_TXN_MODE         IN VARCHAR2,--Added for defect 9786
                                          P_RESP_CODE        OUT VARCHAR2,
                                          P_CARD_STATUS      OUT VARCHAR2,
                                          P_CARD_STATUS_MESG OUT VARCHAR2,
                                          P_ACCT_BAL         OUT VARCHAR2,
                                          P_ERRMSG           OUT VARCHAR2,
                                          P_REPLFLAG         OUT VARCHAR2,--Added for FSS-813
                                          P_ORIGCARDNO           OUT VARCHAR2 --Added for FSS-813
                                          ) AS

  /*************************************************
      * Created Date     :  17-Dec-2012
      * Created By       :  Saravanakumar
      * PURPOSE          :  For return card status
      * Modified reason  : Modified for defect 9777 and 9786
      * Modified by      : Saravanakumar
      * Modified date    : 04-Jan-2013
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  04-Jan-2013
     * Release Number    :  CMS3.5.1_RI0023_B0008
     
      * Modified By      : B.Dhinakaran
      * Modified Date    : 27-Mar-2013
      * Modified For     : FSS-813
      * Modified Reason  : Added two  out parameter(FSS-813)
      * Reviewer         : Dhiarj 
      * Reviewed Date    : 27-Mar-2013
      * Build Number     : RI0024_B0011
      
      * Modified By      : Pankaj S.
      * Modified Date    : 10-May-2013
      * Modified For     : MVHOST-346
      * Modified Reason  : Call the fee calculation procedure SP_AUTHORIZE_TXN_CMS_AUTH 
                            and comment the card status check 
      * Reviewer         : Dhiraj 
      * Reviewed Date    : 
      * Build Number     : RI0024.1_B0021
      
      * Modified By      : Sai Prasad
      * Modified Date    : 11-Sep-2013
      * Modified For     : Mantis ID: 0012275 (JIRA FSS-1144)
      * Modified Reason  : ANI & DNI is not logged in transactionlog table.
      * Reviewer         : Dhiraj 
      * Reviewed Date    : 11-Sep-2013
      * Build Number     : RI0024.4_B0010
      
      * Modified Date    : 16-Dec-2013
      * Modified By      : Sagar More
      * Modified for     : Defect ID 13160
      * Modified reason  : To log below details in transactinlog if applicable
                           Acct_type,timestamp,dr_cr_flag,product code,cardtype,error_msg
      * Reviewer         : Dhiraj
      * Reviewed Date    : 16-Dec-2013
      * Release Number   : RI0024.7_B0001        
      
       * Modified by      : Pankaj S.
       * Modified for     : Transactionlog Functional Removal
       * Modified Date    : 14-May-2015
       * Reviewer         :  Saravanankumar
       * Build Number     : VMSGPRHOAT_3.0.3_B0001

       * Modified by      : Siva kumar M.
       * Modified for     : B2B changes
       * Modified Date    : 17-Aug-2017
       * Reviewer         :  Saravanankumar
       * Build Number     : VMSGPRHOAT_17.08
	   
    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
 
       * Modified By      : venkat Singamaneni
    * Modified Date    : 4-25-2022
    * Purpose          : Archival changes.
    * Reviewer         : Jyothi G
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991
      
  *************************************************/

    V_CURRCODE            CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
    V_RESPCODE            VARCHAR2(5);
    V_TXN_TYPE            CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
    EXP_MAIN_REJECT_RECORD EXCEPTION;
    V_HASH_PAN            CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
    V_ENCR_PAN            CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
    V_RRN_COUNT           NUMBER;
    V_TRAN_DATE           DATE;
    V_ACCT_BALANCE        CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
    V_LEDGER_BAL          CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
    V_ACCT_NUMBER         CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
    V_STATUS_COUNT        NUMBER;
    V_TXNCODE             TRANSACTIONLOG.TXN_CODE%TYPE;
    V_CARDSTATUS_DESC     CMS_CARD_STAT.CCS_STAT_DESC%TYPE;
    V_TRANS_DESC          CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
    V_EXPRY_DATE          DATE;--Added for defect 9786
    V_PROD_CODE           CMS_APPL_PAN.CAP_PROD_CODE%TYPE;--Added for defect 9786
    V_PROD_CATTYPE        CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;--Added for defect 9786
    --Sn Added by Pankaj S. for MVHOST-346
    v_authid               transactionlog.auth_id%TYPE;
    v_business_date        DATE;
    exp_auth_reject_record EXCEPTION;
    --En Added by Pankaj S. for MVHOST-346
    
    --SN : Added for 13160
    v_cr_dr_flag  cms_transaction_mast.ctm_credit_debit_flag%type;
    v_acct_type   cms_acct_mast.cam_type_code%type;   
    v_timestamp   timestamp(3);
    --EN : Added for 13160  
    v_cardactive_dt     cms_appl_pan.cap_active_date%TYPE;    
v_Retperiod  date;  --Added for VMS-5735/FSP-991
v_Retdate  date; --Added for VMS-5735/FSP-991
       

BEGIN
    P_ERRMSG   := 'OK';
    V_RESPCODE := '1';

    --SN CREATE HASH PAN
    BEGIN
        V_HASH_PAN := GETHASH(P_CARDNUM);
    EXCEPTION
    WHEN OTHERS THEN
        V_RESPCODE := '12';
        P_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --EN CREATE HASH PAN

    --SN create encr pan
    BEGIN
        V_ENCR_PAN := FN_EMAPS_MAIN(P_CARDNUM);
    EXCEPTION
    WHEN OTHERS THEN
        V_RESPCODE := '12';
        P_ERRMSG   := 'Error while converting pan ' ||SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --EN create encr pan

    --Sn find debit and credit flag
    BEGIN
        SELECT  TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
                ctm_tran_desc,
                ctm_credit_debit_flag           --Added for 13160
        INTO    V_TXN_TYPE,
                V_TRANS_DESC,
                v_cr_dr_flag                    --Added for 13160 
        FROM CMS_TRANSACTION_MAST
        WHERE CTM_TRAN_CODE = P_TXN_CODE AND
        CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
        CTM_INST_CODE = P_INSTCODE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            V_RESPCODE := '12'; 
            P_ERRMSG   := 'Transflag  not defined for txn code ' || P_TXN_CODE || ' and delivery channel ' || P_DELIVERY_CHANNEL;
            RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
            V_RESPCODE := '12'; 
            P_ERRMSG := 'Error while selecting CMS_TRANSACTION_MAST' ||SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --En find debit and credit flag

    --Sn Transaction Date Check
    BEGIN
        V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8), 'yyyymmdd');
    EXCEPTION
        WHEN OTHERS THEN
            V_RESPCODE := '12'; 
            P_ERRMSG   := 'Problem while converting transaction date ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --En Transaction Date Check

    --Sn Transaction Time Check
    BEGIN
        V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8) || ' ' || SUBSTR(TRIM(P_TRANTIME), 1, 10),'yyyymmdd hh24:mi:ss');
    EXCEPTION
        WHEN OTHERS THEN
            V_RESPCODE := '12'; 
            P_ERRMSG   := 'Problem while converting transaction Time ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --En Transaction Time Check



    --Sn Duplicate RRN Check.IF duplicate RRN log the txn and return
    BEGIN
--Added for VMS-5735/FSP-991
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
        DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; 
ELSE
       SELECT COUNT(1)
        INTO V_RRN_COUNT
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
        WHERE INSTCODE = P_INSTCODE AND RRN = P_RRN AND
        BUSINESS_DATE = P_TRANDATE AND
        DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; 
END IF;

        IF V_RRN_COUNT > 0 THEN
            V_RESPCODE := '22';
            P_ERRMSG   := 'Duplicate RRN ' || ' on ' || P_TRANDATE;
            RAISE EXP_MAIN_REJECT_RECORD;
        END IF;
    EXCEPTION
        WHEN EXP_MAIN_REJECT_RECORD THEN
            RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
            V_RESPCODE := '12';
            P_ERRMSG := 'Error while selecting rrn count  ' ||  SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --En Duplicate RRN Check

    --Sn find card detail
    BEGIN
        SELECT  CAP_ACCT_NO,
                CAP_CARD_STAT,
                CAP_EXPRY_DATE,--Added for defect 9786
                CAP_PROD_CODE,--Added for defect 9786
                CAP_CARD_TYPE,--Added for defect 9786
                cap_active_date
        INTO    V_ACCT_NUMBER,
                P_CARD_STATUS,
                V_EXPRY_DATE,--Added for defect 9786
                V_PROD_CODE,--Added for defect 9786
                V_PROD_CATTYPE,--Added for defect 9786
                v_cardactive_dt
        FROM CMS_APPL_PAN
        WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            V_RESPCODE := '16'; 
            P_ERRMSG   := 'Card number not found ' || V_HASH_PAN;
            RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
            V_RESPCODE := '12';
            P_ERRMSG   := 'Problem while selecting CMS_APPL_PAN' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
    END;
    
   
   
       BEGIN
--        SELECT CIP_PARAM_VALUE
--        INTO V_CURRCODE
--        FROM CMS_INST_PARAM
--        WHERE CIP_INST_CODE = P_INSTCODE AND CIP_PARAM_KEY = 'CURRENCY';


             SELECT TRIM (cbp_param_value) 
			 INTO V_CURRCODE
			 FROM cms_bin_param 
             WHERE cbp_param_name = 'Currency' AND cbp_inst_code= p_instcode
             AND cbp_profile_code = (select  cpc_profile_code from 
             cms_prod_cattype where cpc_prod_code = v_prod_code and
	      cpc_card_type = v_prod_cattype and cpc_inst_code=p_instcode);
			 
			
        IF V_CURRCODE IS NULL THEN
            V_RESPCODE := '12';
            P_ERRMSG   := 'Base currency cannot be null ';
            RAISE EXP_MAIN_REJECT_RECORD;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            V_RESPCODE := '12';
            P_ERRMSG   := 'Base currency is not defined for the BIN PROFILE ';
            RAISE EXP_MAIN_REJECT_RECORD;
        WHEN EXP_MAIN_REJECT_RECORD THEN
            RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
            V_RESPCODE := '12';
            P_ERRMSG   := 'Error while selecting base currency for bin  ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
    END; 
    ---Changes START for FSS-813
    BEGIN
            SELECT FN_DMAPS_MAIN(CHR_PAN_CODE_ENCR)
            INTO P_ORIGCARDNO    
            FROM CMS_HTLST_REISU
            WHERE CHR_INST_CODE = P_INSTCODE
            AND CHR_NEW_PAN = V_HASH_PAN
            AND CHR_REISU_CAUSE = 'R'
            AND CHR_PAN_CODE_ENCR IS NOT NULL;
            
            P_REPLFLAG :='1';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          P_REPLFLAG :='0';
        WHEN OTHERS THEN
            V_RESPCODE := '12';
            P_ERRMSG   := 'Problem while selecting Original Card no' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --Changes END  FSS-813

   --Sn commented by Pankaj S. on 10_May_2013 for MVHOST-346 
   /*--Sn Added for defect 9786
    BEGIN
        SP_STATUS_CHECK_GPR(P_INSTCODE,
                            P_CARDNUM,
                            P_DELIVERY_CHANNEL,
                            V_EXPRY_DATE,
                            P_CARD_STATUS,
                            P_TXN_CODE,
                            P_TXN_MODE,
                            V_PROD_CODE,
                            V_PROD_CATTYPE,
                            P_MSG_TYPE,
                            P_TRANDATE,
                            P_TRANTIME,
                            NULL,
                            NULL,   
                            NULL,
                            V_RESPCODE,
                            P_ERRMSG);

        IF V_RESPCODE NOT IN ('0','1') AND P_ERRMSG <> 'OK' THEN
            RAISE EXP_MAIN_REJECT_RECORD;
        END IF;

    EXCEPTION
        WHEN EXP_MAIN_REJECT_RECORD THEN
            RAISE EXP_MAIN_REJECT_RECORD;
        WHEN OTHERS THEN
            V_RESPCODE := '12';
            P_ERRMSG   := 'Error while calling SP_STATUS_CHECK_GPR  ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
    END;
    --En Added for defect 9786*/
    --En Commented by Pankaj S. on 10_May_2013 for MVHOST-346
    
    --Sn Authorize procedure call added by Pankaj S. on 10_May_2013 for MVHOST-346 
     BEGIN
         
         sp_authorize_txn_cms_auth (p_instcode,
                                    '0200',
                                    p_rrn,
                                    p_delivery_channel,
                                    0,
                                    p_txn_code,
                                    p_txn_mode,
                                    p_trandate,
                                    p_trantime,
                                    p_cardnum,
                                    NULL,
                                    NULL,--p_amount,
                                    NULL,--p_merchant_name,
                                    NULL,--p_merchant_city,
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
                                    NULL,--p_stan, 
                                    '000',
                                    '0',   
                                    NULL, --v_tran_amt,
                                    v_authid,
                                    v_respcode,
                                    p_errmsg,
                                    v_business_date
                                   );

         IF v_respcode <> '00' AND p_errmsg <> 'OK'
         THEN
          p_errmsg := 'Error from auth process' || p_errmsg;
            RAISE exp_auth_reject_record;
         ELSE
            v_respcode:=1;
         END IF;
      EXCEPTION
         WHEN exp_auth_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_respcode := '12';
            p_errmsg :='Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
      --En Authorize procedure call added by Pankaj S. on 10_May_2013 for MVHOST-346

    IF P_CARD_STATUS = '0' THEN
        --Sn Modified for Transactionlog Functional Removal
        /*BEGIN
            SELECT COUNT(*)
            INTO V_STATUS_COUNT
            FROM TRANSACTIONLOG
            WHERE RESPONSE_CODE = '00' AND
            ((TXN_CODE = '69' AND DELIVERY_CHANNEL = '04') OR
            (TXN_CODE = '05' AND DELIVERY_CHANNEL IN ('10', '07')) OR 
            (TXN_CODE = '26' AND DELIVERY_CHANNEL  ='05')) AND      --Added for FSS 813
            CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE = P_INSTCODE;
        EXCEPTION
            WHEN OTHERS THEN
                V_RESPCODE := '12';
                P_ERRMSG   := 'Problem while selecting TRANSACTIONLOG 1' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_MAIN_REJECT_RECORD;
        END;*/

        IF v_cardactive_dt IS NULL --V_STATUS_COUNT = 0 
        THEN
        --En Modified for Transactionlog Functional Removal
            P_CARD_STATUS_MESG := 'INACTIVE';
        ELSE
            BEGIN
                SELECT TXN_CODE     INTO V_TXNCODE FROM 
                (SELECT TXN_CODE  FROM VMSCMS.TRANSACTIONLOG_VW --Added for VMS-5735/FSP-991
                WHERE RESPONSE_CODE = '00' AND
                ((TXN_CODE = '69' AND DELIVERY_CHANNEL = '04') OR
                (TXN_CODE = '05' AND
                DELIVERY_CHANNEL IN ('10', '07')) OR 
               (TXN_CODE = '26' AND DELIVERY_CHANNEL  ='05')) AND   --Added for FSS 813
                CUSTOMER_CARD_NO = V_HASH_PAN AND
                INSTCODE = P_INSTCODE
                ORDER BY TO_DATE(SUBSTR(TRIM(BUSINESS_DATE), 1, 8) || ' ' ||
                SUBSTR(TRIM(BUSINESS_TIME), 1, 10),
                'yyyymmdd hh24:mi:ss') DESC)
                WHERE ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    V_RESPCODE := '16'; 
                    P_ERRMSG   := 'Card number not found ' || V_HASH_PAN;
                    RAISE EXP_MAIN_REJECT_RECORD;
                WHEN OTHERS THEN
                    V_RESPCODE := '12';
                    P_ERRMSG   := 'Problem while selecting TRANSACTIONLOG 21 ' || SUBSTR(SQLERRM, 1, 200);
                    RAISE EXP_MAIN_REJECT_RECORD;
            END;

            IF V_TXNCODE = '69' THEN
                P_CARD_STATUS_MESG := 'INACTIVE';
            ELSIF V_TXNCODE = '05' OR V_TXNCODE = '26' THEN
                P_CARD_STATUS_MESG := 'BLOCKED';
            END IF;
        END IF;
    ELSE
        BEGIN
            SELECT CCS_STAT_DESC
            INTO V_CARDSTATUS_DESC
            FROM CMS_CARD_STAT
            WHERE CCS_STAT_CODE = P_CARD_STATUS AND CCS_INST_CODE = P_INSTCODE;
            P_CARD_STATUS_MESG := V_CARDSTATUS_DESC;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                V_RESPCODE := '16'; 
                P_ERRMSG   := 'Card number not found ' || V_HASH_PAN;
                RAISE EXP_MAIN_REJECT_RECORD;
            WHEN OTHERS THEN
                V_RESPCODE := '12';
                P_ERRMSG   := 'Problem while selecting CMS_CARD_STAT' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_MAIN_REJECT_RECORD;
        END;
    END IF;

    --En find card detail

    BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO P_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = P_INSTCODE AND
        CMS_DELIVERY_CHANNEL = decode(P_DELIVERY_CHANNEL,'17','10',P_DELIVERY_CHANNEL) AND
        CMS_RESPONSE_ID = V_RESPCODE;
    EXCEPTION
        WHEN OTHERS THEN
            P_ERRMSG    := 'Problem while selecting data from response master ' ||
            V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '89';
            RAISE EXP_MAIN_REJECT_RECORD;
    END;

    BEGIN
        SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
        INTO V_ACCT_BALANCE, V_LEDGER_BAL
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO = V_ACCT_NUMBER 
	AND CAM_INST_CODE = P_INSTCODE;
    EXCEPTION
        WHEN OTHERS THEN
            V_ACCT_BALANCE := 0;
            V_LEDGER_BAL   := 0;
    END;

    P_ACCT_BAL:=TRIM(TO_CHAR (V_ACCT_BALANCE,'999999999999999990.99'));
    
    --sn Added for mantis id 0012275(FSS-1144)
     BEGIN


IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE transactionlog
         SET 
             ANI=P_ANI, 
             DNI=P_DNI 
       WHERE rrn = p_rrn
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND business_date = p_trandate
         AND business_time = P_TRANTIME
         AND msgtype = P_MSG_TYPE
         AND customer_card_no = v_hash_pan
         AND instcode = P_INSTCODE;
ELSE 
   
      UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
         SET 
             ANI=P_ANI, 
             DNI=P_DNI 
       WHERE rrn = p_rrn
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND business_date = p_trandate
         AND business_time = P_TRANTIME
         AND msgtype = P_MSG_TYPE
         AND customer_card_no = v_hash_pan
         AND instcode = P_INSTCODE;
END IF;


      
      IF SQL%ROWCOUNT = 0
      THEN
         p_resp_code := '21';
         P_ERRMSG := 'transactionlog is not updated '||P_MSG_TYPE;
         RAISE EXP_MAIN_REJECT_RECORD;
      END IF;
      
   EXCEPTION
      WHEN EXP_MAIN_REJECT_RECORD
      THEN
         RAISE EXP_MAIN_REJECT_RECORD;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         P_ERRMSG :=
            'Error while updating transactionlog '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_MAIN_REJECT_RECORD;
   END;
       --en Added for mantis id 0012275(FSS-1144)
   --Sn Commented by Pankaj S. on 10_May_2013 for MVHOST-346
    /*BEGIN
        INSERT INTO TRANSACTIONLOG
                    (MSGTYPE,
                    RRN,
                    DELIVERY_CHANNEL,
                    TERMINAL_ID,
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
                    ANI,
                    DNI,
                    CARDSTATUS, 
                    TRANS_DESC  )
        VALUES
                    ('0200',
                    P_RRN,
                    P_DELIVERY_CHANNEL,
                    0,
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
                    NULL,
                    V_CURRCODE,
                    NULL,
                    SUBSTR(P_CARDNUM, 1, 4),
                    NULL,
                    0,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    P_INSTCODE,
                    V_ENCR_PAN,
                    V_ENCR_PAN,
                    '',
                    0,
                    V_ACCT_NUMBER,  
                    V_ACCT_BALANCE,
                    V_LEDGER_BAL,
                    V_RESPCODE,
                    P_ANI,
                    P_DNI,
                    P_CARD_STATUS, 
                    V_TRANS_DESC 
                    );
    EXCEPTION
        WHEN OTHERS THEN
            P_RESP_CODE := '89';
            P_ERRMSG    := 'Error while inserting TRANSACTIONLOG' || SUBSTR(SQLERRM, 1, 200);
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
                        CTD_CUST_ACCT_NUMBER,
                        CTD_TXN_TYPE)
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
                        'Y',--Modified for defect 9777
                        'Successful',--Modified for defect 9777
                        P_RRN,
                        P_INSTCODE,
                        V_ENCR_PAN,
                        '',
                        V_TXN_TYPE);

    EXCEPTION
        WHEN OTHERS THEN
        P_ERRMSG    := 'Error while inserting CMS_TRANSACTION_LOG_DTL' || SUBSTR(SQLERRM, 1, 300);
        P_RESP_CODE := '89'; 
    END;*/
    --En Commented by Pankaj S. on 10_May_2013 for MVHOST-346

EXCEPTION
   --Sn Added by Pankaj S. on 10_May_2013 for MVHOST-346
    WHEN exp_auth_reject_record
   THEN
      p_resp_code := v_respcode;
      
      BEGIN
            SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
            INTO V_ACCT_BALANCE, V_LEDGER_BAL
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO = (SELECT CAP_ACCT_NO
	                FROM CMS_APPL_PAN
			WHERE CAP_PAN_CODE = V_HASH_PAN AND
			      CAP_INST_CODE = P_INSTCODE) 
			  AND CAM_INST_CODE = P_INSTCODE;
        EXCEPTION
            WHEN OTHERS THEN
                V_ACCT_BALANCE := 0;
                V_LEDGER_BAL   := 0;
        END;

        P_ACCT_BAL:=TRIM(TO_CHAR (V_ACCT_BALANCE,'999999999999999990.99'));
    --En Added by Pankaj S. on 10_May_2013 for MVHOST-346
    WHEN EXP_MAIN_REJECT_RECORD THEN
       ROLLBACK; --Added by Pankaj S. on 10_May_2013 for MVHOST-346
      
        BEGIN
            SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,CAM_TYPE_CODE
            INTO V_ACCT_BALANCE, V_LEDGER_BAL,v_acct_type
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO = (SELECT CAP_ACCT_NO
	                FROM CMS_APPL_PAN
			WHERE CAP_PAN_CODE = V_HASH_PAN AND
			      CAP_INST_CODE = P_INSTCODE) 
			  AND CAM_INST_CODE = P_INSTCODE;
        EXCEPTION
            WHEN OTHERS THEN
                V_ACCT_BALANCE := 0;
                V_LEDGER_BAL   := 0;
        END;

        P_ACCT_BAL:=TRIM(TO_CHAR (V_ACCT_BALANCE,'999999999999999990.99'));

        --Sn select response code and insert record into txn log dtl
        BEGIN
            SELECT CMS_ISO_RESPCDE
            INTO P_RESP_CODE
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE = P_INSTCODE AND
            CMS_DELIVERY_CHANNEL = decode(P_DELIVERY_CHANNEL,'17','10',P_DELIVERY_CHANNEL) AND
            CMS_RESPONSE_ID = V_RESPCODE;
            EXCEPTION
                WHEN OTHERS THEN
                    P_ERRMSG    := 'Error while selecting CMS_RESPONSE_MAST ' ||  V_RESPCODE || SUBSTR(SQLERRM, 1, 200);
                    P_RESP_CODE := '89';
        END;

     --SN Added for 13160
     
     
     v_timestamp := systimestamp; 
        
      if v_cr_dr_flag is null
      then
      
        --Sn find debit and credit flag
        BEGIN
            SELECT  ctm_credit_debit_flag
            INTO    v_cr_dr_flag 
            FROM CMS_TRANSACTION_MAST
            WHERE CTM_TRAN_CODE = P_TXN_CODE 
            AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL 
            AND CTM_INST_CODE = P_INSTCODE;
        EXCEPTION
            WHEN OTHERS THEN
            
            null;

        END;
        --En find debit and credit flag
        
     end if;
     
     if V_PROD_CODE is null
     then    
        
        BEGIN
        
            SELECT  CAP_ACCT_NO,
                    CAP_CARD_STAT,
                    CAP_EXPRY_DATE,
                    CAP_PROD_CODE,
                    CAP_CARD_TYPE
            INTO    V_ACCT_NUMBER,
                    P_CARD_STATUS,
                    V_EXPRY_DATE,
                    V_PROD_CODE,
                    V_PROD_CATTYPE
            FROM CMS_APPL_PAN
            WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN;
        EXCEPTION
            WHEN OTHERS THEN
            
            null;
    
        END;

     end if;
     
     --EN Added for 13160

        BEGIN
            INSERT INTO TRANSACTIONLOG
                        (MSGTYPE,
                        RRN,
                        DELIVERY_CHANNEL,
                        TERMINAL_ID,
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
                        ANI,
                        DNI,
                        CARDSTATUS, 
                        TRANS_DESC,
                        --SN Added for 13160
                        acct_type,
                        Time_stamp,
                        cr_dr_flag,
                        error_msg
                        --EN Added for 13160
                        )
            VALUES
                        ('0200',
                        P_RRN,
                        P_DELIVERY_CHANNEL,
                        0,
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
                        NULL,
                        V_CURRCODE,
                        NULL,
                        V_PROD_CODE,--SUBSTR(P_CARDNUM, 1, 4),  --Modified for 13160
                        V_PROD_CATTYPE,--NULL,                  --Modified for 13160    
                        0,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        P_INSTCODE,
                        V_ENCR_PAN,
                        V_ENCR_PAN,
                        '',
                        0,
                        V_ACCT_NUMBER,  
                        nvl(V_ACCT_BALANCE,0),
                        nvl(V_LEDGER_BAL,0),
                        V_RESPCODE,
                        P_ANI,
                        P_DNI,
                        P_CARD_STATUS, 
                        V_TRANS_DESC,
                        --SN Added for 13160
                        V_ACCT_TYPE,
                        V_TIMESTAMP,
                        V_CR_DR_FLAG,
                        P_ERRMSG
                        --EN Added for 13160 
                        );
        EXCEPTION
            WHEN OTHERS THEN
                P_RESP_CODE := '89';
                P_ERRMSG    := 'Error while inserting TRANSACTIONLOG' || SUBSTR(SQLERRM, 1, 200);
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
                            CTD_CUST_ACCT_NUMBER,
                            CTD_TXN_TYPE)
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
                            P_ERRMSG,
                            P_RRN,
                            P_INSTCODE,
                            V_ENCR_PAN,
                            '',
                            V_TXN_TYPE);

        EXCEPTION
            WHEN OTHERS THEN
            P_ERRMSG    := 'Error while inserting CMS_TRANSACTION_LOG_DTL' || SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '89'; 
        END;

    WHEN OTHERS THEN
       ROLLBACK; --Added by Pankaj S. on 10_May_2013 for MVHOST-346
        BEGIN
            SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,CAM_TYPE_CODE
            INTO V_ACCT_BALANCE, V_LEDGER_BAL,v_acct_type
            FROM CMS_ACCT_MAST
            WHERE CAM_ACCT_NO =
            (SELECT CAP_ACCT_NO
            FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
            CAP_INST_CODE = P_INSTCODE) AND
            CAM_INST_CODE = P_INSTCODE;
        EXCEPTION
            WHEN OTHERS THEN
                V_ACCT_BALANCE := 0;
                V_LEDGER_BAL   := 0;
        END;

        P_ACCT_BAL:=TRIM(TO_CHAR (V_ACCT_BALANCE,'999999999999999990.99'));

        --Sn select response code and insert record into txn log dtl
        BEGIN
            SELECT CMS_ISO_RESPCDE
            INTO P_RESP_CODE
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE = P_INSTCODE AND
            CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESPCODE;
            EXCEPTION
                WHEN OTHERS THEN
                    P_ERRMSG    := 'Error while selecting CMS_RESPONSE_MAST ' ||  V_RESPCODE || SUBSTR(SQLERRM, 1, 200);
                    P_RESP_CODE := '89';
        END;

    --SN Added for 13160
     
     v_timestamp := systimestamp; 
        
      if v_cr_dr_flag is null
      then
      
        --Sn find debit and credit flag
        BEGIN
            SELECT  ctm_credit_debit_flag
            INTO    v_cr_dr_flag 
            FROM CMS_TRANSACTION_MAST
            WHERE CTM_TRAN_CODE = P_TXN_CODE 
            AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL 
            AND CTM_INST_CODE = P_INSTCODE;
        EXCEPTION
            WHEN OTHERS THEN
            
            null;

        END;
        --En find debit and credit flag
        
     end if;
     
     if V_PROD_CODE is null
     then    
        
        BEGIN
        
            SELECT  CAP_ACCT_NO,
                    CAP_CARD_STAT,
                    CAP_EXPRY_DATE,
                    CAP_PROD_CODE,
                    CAP_CARD_TYPE
            INTO    V_ACCT_NUMBER,
                    P_CARD_STATUS,
                    V_EXPRY_DATE,
                    V_PROD_CODE,
                    V_PROD_CATTYPE
            FROM CMS_APPL_PAN
            WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN;
        EXCEPTION
            WHEN OTHERS THEN
            
            null;
    
        END;

     end if;
     
     --EN Added for 13160


        BEGIN
            INSERT INTO TRANSACTIONLOG
                        (MSGTYPE,
                        RRN,
                        DELIVERY_CHANNEL,
                        TERMINAL_ID,
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
                        ANI,
                        DNI,
                        CARDSTATUS, 
                        TRANS_DESC,
                        --SN Added for 13160
                        acct_type,
                        Time_stamp,
                        cr_dr_flag,
                        error_msg
                        --EN Added for 13160                        
                        )
            VALUES
                        ('0200',
                        P_RRN,
                        P_DELIVERY_CHANNEL,
                        0,
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
                        NULL,
                        V_CURRCODE,
                        NULL,
                        v_prod_code,--SUBSTR(P_CARDNUM, 1, 4),  -- Modified for 13160
                        V_PROD_CATTYPE,--NULL,                  -- Modified for 13160
                        0,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        P_INSTCODE,
                        V_ENCR_PAN,
                        V_ENCR_PAN,
                        '',
                        0,
                        V_ACCT_NUMBER,  
                        V_ACCT_BALANCE,
                        V_LEDGER_BAL,
                        V_RESPCODE,
                        P_ANI,
                        P_DNI,
                        P_CARD_STATUS, 
                        V_TRANS_DESC,
                        --SN Added for 13160
                        V_ACCT_TYPE,
                        V_TIMESTAMP,
                        V_CR_DR_FLAG,
                        P_ERRMSG
                        --EN Added for 13160                         
                        );
        EXCEPTION
            WHEN OTHERS THEN
                P_RESP_CODE := '89';
                P_ERRMSG    := 'Error while inserting TRANSACTIONLOG' || SUBSTR(SQLERRM, 1, 200);
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
                            CTD_CUST_ACCT_NUMBER,
                            CTD_TXN_TYPE)
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
                            P_ERRMSG,
                            P_RRN,
                            P_INSTCODE,
                            V_ENCR_PAN,
                            '',
                            V_TXN_TYPE);

        EXCEPTION
            WHEN OTHERS THEN
            P_ERRMSG    := 'Error while inserting CMS_TRANSACTION_LOG_DTL' || SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '89'; 
        END;
END;
/
SHOW ERROR;