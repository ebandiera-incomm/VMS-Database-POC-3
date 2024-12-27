CREATE OR REPLACE PROCEDURE VMSCMS.SP_IVR_CALLLOGID(
                                P_INST_CODE        IN NUMBER ,
                                P_PAN_CODE         IN NUMBER,
                                P_CALL_LOGID      IN  VARCHAR2,
                                P_DELIVERY_CHANNEL IN  VARCHAR2,
                                P_TXN_CODE         IN  VARCHAR2,
                                P_RRN              IN  VARCHAR2,
                                P_TXN_MODE         IN   VARCHAR2,
                                P_TRAN_DATE        IN  VARCHAR2,
                                P_TRAN_TIME        IN   VARCHAR2,
                                P_ANI              IN VARCHAR2,
                                P_DNI              IN VARCHAR2,
                                P_CURR_CODE        IN   VARCHAR2,  
                                P_RVSL_CODE        IN VARCHAR2,     
                                P_MSG              IN VARCHAR2,    
                                P_RESP_CODE        OUT  VARCHAR2 ,
                                P_RESMSG           OUT VARCHAR2)
AS
/*************************************************
     * Created Date     :  27-Aug-2012
     * Created By       :  sriram
     * PURPOSE          :  CallLog Id Verification
     * Reviewer         :  B.Besky Anand.
     * Reviewed Date    :  31-Aug-2012
     * Release Number     :CMS3.5.1_RI0015_B0015

     * Modified Date    : 16-Dec-2013
     * Modified By      : Sagar More
     * Modified for     : Defect ID 13160
     * Modified reason  : To log below details in transactinlog if applicable
                          Acct_type,timestamp,dr_cr_flag,product code,cardtype,
                          account numver
     * Reviewer         : Dhiraj
     * Reviewed Date    : 16-Dec-2013
     * Release Number   : RI0024.7_B0001 

     * Modified Date    : 14-Nov-2016
     * Modified By      : T.Narayanaswamy
     * Modified for     : FSS-4921 - IVR callLogId Validation
     * Modified reason  : Call Log ID validation should be for Customer not per Card Number
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 14-Nov-2016
     * Release Number   : 4.11_B0001  
	 
	 * Modified Date    : 30-Nov-2020
     * Modified By      : Puvanesh.N/Ubaidur.H
     * Modified for     : VMS-3349 - IVR callLogId Validation
     * Modified reason  : IVR Call Log ID transaction - Blocking Session while fetching the account balance.
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 30-Nov-2020
     * Release Number   : R39 Build 2

    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-25-2022
    * Purpose          : Archival changes.
    * Reviewer         : Jyothi G
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991

*************************************************/
V_CARDSTAT         VARCHAR2(5);
V_RRN_COUNT        NUMBER;
V_HASH_PAN          CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_ENCR_PAN_FROM     CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
V_TXN_TYPE          CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
V_CARD_EXPRY           VARCHAR2(20);
V_STAN                 VARCHAR2(20);
V_CAPTURE_DATE         DATE;
V_TERM_ID              VARCHAR2(20);
V_MCC_CODE             VARCHAR2(20);
V_TXN_AMT               NUMBER;
V_ACCT_NUMBER           CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
V_AUTH_ID              TRANSACTIONLOG.AUTH_ID%TYPE;
V_TRANS_DESC   CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; 
EXP_REJECT_RECORD EXCEPTION;
V_CALL_STATUS   CMS_CALLLOG_MAST.CCM_CALL_STATUS%TYPE;
--SN Added for 13160    
v_acct_type cms_acct_mast.cam_type_code%type;  
v_timestamp TIMESTAMP(3);                      
v_prod_code cms_appl_pan.cap_prod_code%type;
v_card_type cms_appl_pan.cap_card_type%type;
v_cr_dr_flag CMS_TRANSACTION_MAST.ctm_credit_debit_flag%type;
--EN Added for 13160    

v_acct_bal  cms_acct_mast.cam_acct_bal%type;
v_ledger_bal cms_acct_mast.cam_ledger_bal%type;
V_STATUS_CHK              NUMBER;
l_precheck_flag           PLS_INTEGER;
V_EXPRY_DATE      cms_appl_pan.cap_expry_date%type;   
V_APPLPAN_CARDSTAT cms_appl_pan.CAP_CARD_STAT%type;   
V_ATMONLINE_LIMIT    CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;                     
V_POSONLINE_LIMIT    CMS_APPL_PAN.CAP_POS_ONLINE_LIMIT%TYPE;
V_PROXY_NUMBER 	 CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
v_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
V_RESP_ID 			CMS_RESPONSE_MAST.CMS_RESPONSE_ID%TYPE;
v_Retperiod  date;  --Added for VMS-5735/FSP-991
v_Retdate  date; --Added for VMS-5735/FSP-991

BEGIN 

BEGIN
    P_RESMSG :='OK';
    P_RESP_CODE:='00';
-- Get the HashPan
        BEGIN
           V_HASH_PAN := GETHASH(P_PAN_CODE);
       EXCEPTION
         WHEN OTHERS THEN
          P_RESP_CODE     := '12';
         P_RESMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
       END;

   --SN create encr pan
     BEGIN
          V_ENCR_PAN_FROM := FN_EMAPS_MAIN(P_PAN_CODE);
        EXCEPTION
         WHEN OTHERS THEN
        P_RESP_CODE     := '12';
        P_RESMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
      END;

   --SN Added for 13160 

    BEGIN

            SELECT LPAD (SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;
        EXCEPTION
            WHEN OTHERS
            THEN
                P_RESMSG :=
                    'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
                P_RESP_CODE := '21';                
                RAISE EXP_REJECT_RECORD;
        END;

		v_timestamp := systimestamp;

		BEGIN
         v_hashkey_id :=
            gethash (   P_DELIVERY_CHANNEL
                     || P_TXN_CODE
                     || P_PAN_CODE
                     || P_RRN
                     || TO_CHAR (NVL (v_timestamp, SYSTIMESTAMP),
                                 'YYYYMMDDHH24MISSFF5'
                                )
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            P_RESP_CODE := '21';
            P_RESMSG :=
                  'Error while generating hashkey_id- '
               || SUBSTR (SQLERRM, 1, 200);
			 RAISE EXP_REJECT_RECORD;  
		END;


      BEGIN

        SELECT
            CAP_ACCT_NO,
            cap_card_stat,
            cap_prod_code,
            cap_card_type,
			CAP_EXPRY_DATE, 
			CAP_CARD_STAT,
            CAP_ATM_ONLINE_LIMIT,
            CAP_POS_ONLINE_LIMIT,
			CAP_PROXY_NUMBER

        INTO
            V_ACCT_NUMBER,
            v_cardstat,
            v_prod_code,
            v_card_type,
			V_EXPRY_DATE,
			V_APPLPAN_CARDSTAT,
            V_ATMONLINE_LIMIT,
            V_POSONLINE_LIMIT,
			V_PROXY_NUMBER
        FROM CMS_APPL_PAN
        WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
         P_RESP_CODE := '21';
         P_RESMSG   := 'Invalid Card number ' || V_HASH_PAN;
          RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
         P_RESP_CODE  := '21';
         P_RESMSG   := 'Error while selecting card number ' || V_HASH_PAN;
         RAISE EXP_REJECT_RECORD;
      END;

    --EN Added for 13160

    --Sn find debit and credit flag

    BEGIN
     SELECT TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
            CTM_TRAN_DESC,
            CTM_CREDIT_DEBIT_FLAG                                 --Added for 13160
       INTO V_TXN_TYPE,V_TRANS_DESC,
            v_cr_dr_flag                                           --Added for 13160
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       P_RESP_CODE := '12'; 
       P_RESMSG  := 'Transflag  not defined for txn code ' ||
                  P_TXN_CODE || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
    WHEN EXP_REJECT_RECORD THEN
        RAISE;
     WHEN OTHERS THEN
       P_RESP_CODE := '21';
       P_RESMSG  := 'Error while selecting transaction details';
       RAISE EXP_REJECT_RECORD;
    END;

 --Sn Duplicate RRN Check
        BEGIN
--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
          SELECT COUNT(1)
          INTO V_RRN_COUNT
          FROM TRANSACTIONLOG
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE 
              and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
ELSE
          SELECT COUNT(1)
          INTO V_RRN_COUNT
          FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE RRN         = P_RRN
          AND BUSINESS_DATE = P_TRAN_DATE 
              and DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; 
END IF;

          IF V_RRN_COUNT    > 0 THEN
            P_RESP_CODE     := '22';
            P_RESMSG      := 'Duplicate RRN on ' || P_TRAN_DATE;

            RAISE EXP_REJECT_RECORD;
          END IF;
        END;
        -- Changed for FSS-4921 - IVR callLogId Validation beg
            BEGIN
            SELECT CCM_CALL_STATUS INTO V_CALL_STATUS  FROM CMS_CALLLOG_MAST 
            WHERE  CCM_INST_CODE=P_INST_CODE 
            AND CCM_CALL_ID =P_CALL_LOGID
            AND CCM_ACCT_NO= V_ACCT_NUMBER;            
        -- Changed for FSS-4921 - IVR callLogId Validation end

            IF V_CALL_STATUS <> 'O' THEN
                 P_RESP_CODE := '139';   
                 P_RESMSG := 'Call Status is invalid ';
                 RAISE EXP_REJECT_RECORD;
            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 P_RESP_CODE := '138';   
                 P_RESMSG := 'Invalid Call Log ID ';
                 RAISE EXP_REJECT_RECORD;
    WHEN EXP_REJECT_RECORD THEN
        RAISE;
            WHEN OTHERS THEN
                 P_RESP_CODE := '12';   
                 P_RESMSG := 'Error while selecting CMS_CALLLOG_MAST 11'|| V_CALL_STATUS || '---'|| SUBSTR(SQLERRM, 1, 300);
                 RAISE EXP_REJECT_RECORD;
        END;
       --En Duplicate RRN Check

		-- Modified for VMS-3349 Start
        --Sn GPR Card status check
        BEGIN
            SP_STATUS_CHECK_GPR (P_INST_CODE,
                                        P_PAN_CODE,
                                        P_DELIVERY_CHANNEL,
                                        V_EXPRY_DATE,   
                                        V_APPLPAN_CARDSTAT,     
                                        P_TXN_CODE,
                                        P_TXN_MODE,
                                        v_prod_code,
                                        v_card_type,
                                        P_MSG,
                                        P_TRAN_DATE,
                                        P_TRAN_TIME,
                                        NULL,
                                        NULL,  
                                        V_MCC_CODE,
                                        P_RESP_CODE,
                                        P_RESMSG);
          
            IF ( (P_RESP_CODE <> '1' AND P_RESMSG <> 'OK')
                 OR (P_RESP_CODE <> '0' AND P_RESMSG <> 'OK'))
            THEN
                RAISE EXP_REJECT_RECORD;
            ELSE
                V_STATUS_CHK := P_RESP_CODE;
                P_RESP_CODE := '1';
            END IF;
        EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
                RAISE;
            WHEN OTHERS
            THEN
                P_RESP_CODE := '21';
                P_RESMSG :=
                    'Error from GPR Card Status Check '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --En GPR Card status check
        IF V_STATUS_CHK = '1'
        THEN
            -- Expiry Check

                BEGIN

                        IF TO_DATE (P_TRAN_DATE, 'YYYYMMDD') >
                                LAST_DAY (V_EXPRY_DATE)
                        THEN
                            P_RESP_CODE := '13';
                            P_RESMSG := 'EXPIRED CARD';
                            RAISE EXP_REJECT_RECORD;
                        END IF;

                EXCEPTION
                    WHEN EXP_REJECT_RECORD
                    THEN
                        RAISE;
                    WHEN OTHERS
                    THEN
                        P_RESP_CODE := '21';
                        P_RESMSG :=
                                'ERROR IN EXPIRY DATE CHECK : Tran Date - '
                            || P_TRAN_DATE
                            || ', Expiry Date - '
                            || V_EXPRY_DATE
                            || ','
                            || SUBSTR (SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
                END; 
            -- End Expiry Check

			BEGIN
				SELECT ptp_param_value
					INTO l_precheck_flag
				FROM pcms_tranauth_param
				WHERE ptp_param_name = 'PRE CHECK' AND ptp_inst_code = P_INST_CODE;

			EXCEPTION
				WHEN OTHERS   THEN
					P_RESP_CODE := '21';
					P_RESMSG :=  'Error while selecting precheck flag' || SUBSTR (SQLERRM, 1, 200);
				RAISE exp_reject_record;
			END; 
            --Sn check for precheck

            IF l_precheck_flag = 1
                THEN
                    BEGIN

                        SP_PRECHECK_TXN (P_INST_CODE,
                                              P_PAN_CODE,
                                              P_DELIVERY_CHANNEL,
                                              V_EXPRY_DATE,
                                              V_APPLPAN_CARDSTAT,
                                              P_TXN_CODE,
                                              P_TXN_MODE,
                                              P_TRAN_DATE,
                                              P_TRAN_TIME,
                                              V_TXN_AMT,        
                                              V_ATMONLINE_LIMIT, 
                                              V_POSONLINE_LIMIT,  
                                              P_RESP_CODE,
                                              P_RESMSG);
                    IF (P_RESP_CODE <> '1' OR P_RESMSG <> 'OK')
                    THEN
                        RAISE EXP_REJECT_RECORD;
                    END IF;
                EXCEPTION
                    WHEN EXP_REJECT_RECORD
                    THEN
                        RAISE;
                    WHEN OTHERS
                    THEN
                        P_RESP_CODE := '21';
                        P_RESMSG :=
                            'Error from precheck processes '
                            || SUBSTR (SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
                END;
                END IF;
    END IF;

--- End for account log changes

  P_RESMSG :='';


EXCEPTION  -- <<Main Exception>>--
WHEN EXP_REJECT_RECORD
THEN
    ROLLBACK;    
WHEN OTHERS THEN
   ROLLBACK;
  P_RESP_CODE := '21';
  P_RESMSG := 'Main Exception '||SQLCODE||'---'||SQLERRM;

END;

     BEGIN

			V_RESP_ID := P_RESP_CODE;

            SELECT CMS_ISO_RESPCDE
            INTO P_RESP_CODE
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE      = P_INST_CODE
            AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
            AND CMS_RESPONSE_ID      = P_RESP_CODE;

                EXCEPTION
                WHEN OTHERS THEN
                  P_RESMSG  := 'Problem while selecting data from response master1 ' || P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
                  P_RESP_CODE := '69';
      END;
  --Sn Inserting data in transactionlog

   --SN Added for 13160      

      BEGIN

            SELECT CAM_TYPE_CODE,cam_acct_bal,cam_ledger_bal
            INTO   V_ACCT_TYPE,v_acct_bal,v_ledger_bal
            FROM   CMS_ACCT_MAST
            WHERE  CAM_INST_CODE = P_INST_CODE
            AND    CAM_ACCT_NO = V_ACCT_NUMBER; 

      EXCEPTION
        WHEN OTHERS THEN

            v_acct_bal := 0;
            v_ledger_bal := 0;

      END;     

   --EN Added for 13160


    BEGIN

        INSERT INTO TRANSACTIONLOG(MSGTYPE,
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
					 TOTAL_AMOUNT,
					 MCCODE,   
                     CURRENCYCODE,  
                     INSTCODE,
					 AUTH_ID,
					 AMOUNT,
					 PREAUTHAMOUNT,  
                     PARTIALAMOUNT,  
					 SYSTEM_TRACE_AUDIT_NO,
                     CUSTOMER_CARD_NO_ENCR,
					 PROXY_NUMBER,  
                     REVERSAL_CODE, 
					 ADD_INS_USER,			
                     CUSTOMER_ACCT_NO,
                     ERROR_MSG,
                     IPADDRESS,
                     ANI,
                     DNI,
                     CARDSTATUS,
                     TRANS_DESC, 
                     response_id,
                     acct_type,
                     productid,
                     Categoryid,
                     Time_stamp,
                     CR_DR_FLAG,
                     acct_balance,
                     ledger_balance
                     )
              VALUES(P_MSG,
                     P_RRN,
                     P_DELIVERY_CHANNEL,
					 V_TERM_ID,
                     SYSDATE,
                     P_TXN_CODE,
                     V_TXN_TYPE,
                     P_TXN_MODE,
                     DECODE (P_RESP_CODE, '00', 'C', 'F'),
                     P_RESP_CODE,
                     P_TRAN_DATE,
                     P_TRAN_TIME,
                     V_HASH_PAN,
					TRIM (
                                TO_CHAR (NVL (V_TXN_AMT, 0),
                                            '99999999999999990.99')),
					V_MCC_CODE,
					P_CURR_CODE,																	
                    P_INST_CODE,
					V_AUTH_ID,	
					TRIM (
                                TO_CHAR (NVL (V_TXN_AMT, 0),
                                            '99999999999999990.99')),
					'0.00',
					'0.00',
					V_STAN,
                    V_ENCR_PAN_FROM,
					V_PROXY_NUMBER,
					P_RVSL_CODE,
					'1',					
                    V_ACCT_NUMBER, 
                    nvl(P_RESMSG,'OK'),
                    null,
                    --P_IPADDRESS,
                    P_ANI,
                     P_DNI,
                     V_CARDSTAT, 
                     V_TRANS_DESC,                      
                     V_RESP_ID, 
                     V_ACCT_TYPE,
                     v_prod_code,
                     v_card_type,
                     v_timestamp,
                     v_cr_dr_flag,
                     v_acct_bal,
                     v_ledger_bal
                    );
           EXCEPTION
          WHEN OTHERS THEN
            P_RESP_CODE := '12';
            P_RESMSG := 'Exception while inserting to transaction log '||SQLCODE||'---'||SQLERRM;
         ---   RAISE EXP_REJECT_RECORD;
     END;

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
			  CTD_TXN_AMOUNT, 
			  CTD_TXN_CURR,   
			  CTD_ACTUAL_AMOUNT,  
              CTD_FEE_AMOUNT,
              CTD_WAIVER_AMOUNT,
              CTD_SERVICETAX_AMOUNT,
              CTD_CESS_AMOUNT,
              CTD_PROCESS_FLAG,
              CTD_PROCESS_MSG,
              CTD_RRN,
              CTD_INST_CODE,
              CTD_INS_DATE,
              CTD_CUSTOMER_CARD_NO_ENCR,
              CTD_MSG_TYPE,
              REQUEST_XML,
              CTD_CUST_ACCT_NUMBER,
              CTD_ADDR_VERIFY_RESPONSE,
			  CTD_HASHKEY_ID,
			  CTD_SYSTEM_TRACE_AUDIT_NO
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
			  V_TXN_AMT,
			  P_CURR_CODE,
              NVL (V_TXN_AMT, 0),
              NULL,
              NULL,
              NULL,
              NULL,
              DECODE (P_RESP_CODE, '00', 'Y', 'E'),
              DECODE (nvl(P_RESMSG,'OK'), 'OK', 'Successful', P_RESMSG), 
              P_RRN,
              P_INST_CODE,
              SYSDATE,
              V_ENCR_PAN_FROM,
              P_MSG,
              '',
              V_ACCT_NUMBER,
              '',
			  v_hashkey_id,
			  V_STAN
            );
        EXCEPTION
        WHEN OTHERS THEN
          P_RESMSG := 'Problem while inserting data into transaction log  dtl2' || SUBSTR
          (
            SQLERRM, 1, 300
          )
          ;
          P_RESP_CODE := '69';
        END;
		
		-- Modified for VMS-3349 End

END;

/
SHOW ERROR;
