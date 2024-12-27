create or replace PROCEDURE   VMSCMS.SP_CARD_LOAD_DEFUND_AMOUNT (
    P_INST_CODE 			IN      NUMBER,
    P_MSG               	IN      VARCHAR2,
    P_RRN                   IN		VARCHAR2,
    P_DELIVERY_CHANNEL      IN		VARCHAR2,
    P_TERM_ID               IN		VARCHAR2,
    P_TXN_CODE              IN		VARCHAR2,
    P_TXN_MODE              IN		VARCHAR2,
    P_TRAN_DATE             IN		VARCHAR2,
    P_TRAN_TIME             IN		VARCHAR2,
    P_CARD_NO               IN		VARCHAR2,
    P_TXN_AMT               IN		NUMBER,
    P_MERCHANT_NAME         IN		VARCHAR2,
    P_MERCHANT_CITY         IN		VARCHAR2,
	P_MERCHANT_ZIP			IN		VARCHAR2,
    P_CURR_CODE             IN		VARCHAR2,
    P_MBR_NUMB              IN      VARCHAR2,
	P_STAN             		IN 		VARCHAR2,
	P_REMARK				IN		VARCHAR2,
	P_DR_CR_FLAG			IN		VARCHAR2,
	P_RVSL_CODE				IN		VARCHAR2,
    P_ANI                   IN      VARCHAR2,
    P_DNI                   IN      VARCHAR2,
    P_RESP_CODE             OUT 	VARCHAR2,
    P_RESP_MSG              OUT 	VARCHAR2
    )
IS
	V_RESP_CDE             	VARCHAR2 (3);
	V_TIMESTAMP             TIMESTAMP;
	V_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
	V_ENCR_PAN              CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
	EXP_REJECT_RECORD       EXCEPTION;
	V_HASHKEY_ID            CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE;
	V_TRANS_DESC            CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
	V_AUTH_ID               TRANSACTIONLOG.AUTH_ID%TYPE;
	V_TRAN_DATE             DATE;
	V_PROD_CODE 			CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
	V_PROD_CATTYPE 			CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
	V_APPLPAN_CARDSTAT		CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
	V_PROXUNUMBER			CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
	V_ACCT_NUMBER			CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
	V_ACCT_BALANCE 			CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
	V_LEDGER_BAL 			CMS_ACCT_MAST.CAM_LEDGER_BAL%TYPE;
	V_CAM_TYPE_CODE			CMS_ACCT_MAST.CAM_TYPE_CODE%TYPE; 
	V_UPD_AMT               CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
	V_UPD_LEDGER_BAL        CMS_ACCT_MAST.CAM_LEDGER_BAL%TYPE;
	V_NARRATION             CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
    V_RRN                   TRANSACTIONLOG.RRN%TYPE;
    V_TXN_TYPE              TRANSACTIONLOG.TXN_TYPE%TYPE;

BEGIN
    V_RESP_CDE  := '1';
    P_RESP_MSG  := 'OK';
    V_TIMESTAMP := SYSTIMESTAMP;
    V_TXN_TYPE  := '1';

	BEGIN
        BEGIN
			V_RRN := 'DF_'||SUBSTR(P_RRN,-LEAST(LENGTH(P_RRN),17));
		EXCEPTION
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                P_RESP_MSG :=
                    'Error defining RRN ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;
        --SN CREATE HASH PAN
        BEGIN
            V_HASH_PAN := GETHASH (P_CARD_NO);
        EXCEPTION
            WHEN OTHERS
            THEN
                P_RESP_MSG :=
                    'ERROR WHILE CONVERTING PAN ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --EN CREATE HASH PAN

        --SN CREATE ENCR PAN
        BEGIN
            V_ENCR_PAN := FN_EMAPS_MAIN (P_CARD_NO);
        EXCEPTION
            WHEN OTHERS
            THEN
                P_RESP_MSG :=
                    'ERROR WHILE CONVERTING PAN ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --EN CREATE ENCR PAN

        BEGIN
            V_HASHKEY_ID :=
                GETHASH (
                        P_DELIVERY_CHANNEL
                    || P_TXN_CODE
                    || P_CARD_NO
                    || P_RRN
                    || TO_CHAR (V_TIMESTAMP, 'YYYYMMDDHH24MISSFF5'));
        EXCEPTION
            WHEN OTHERS
            THEN
                P_RESP_MSG :=
                    'ERROR WHILE CONVERTING MASTER DATA '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

		BEGIN
            SELECT CTM_TRAN_DESC
              INTO V_TRANS_DESC
              FROM CMS_TRANSACTION_MAST
             WHERE      CTM_TRAN_CODE = P_TXN_CODE
                     AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                     AND CTM_INST_CODE = P_INST_CODE;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '21';                       --Ineligible Transaction
                P_RESP_MSG :=
                        'Transflag  not defined for txn code '
                    || P_TXN_CODE
                    || ' and delivery channel '
                    || P_DELIVERY_CHANNEL;
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';                       --Ineligible Transaction
                P_RESP_MSG :=
                    'Error while selecting transflag ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

		--SN GENERATE AUTH ID
        BEGIN
            SELECT LPAD (SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;
        EXCEPTION
            WHEN OTHERS
            THEN
                P_RESP_MSG :=
                    'ERROR WHILE GENERATING AUTHID ' || SUBSTR (SQLERRM, 1, 300);
                V_RESP_CDE := '21';                             -- SERVER DECLINED
                RAISE EXP_REJECT_RECORD;
        END;

        --EN GENERATE AUTH ID
        
        --SN GET DATE
        BEGIN
            V_TRAN_DATE :=
                TO_DATE (
                        SUBSTR (TRIM (P_TRAN_DATE), 1, 8)
                    || ' '
                    || SUBSTR (TRIM (P_TRAN_TIME), 1, 10),
                    'YYYYMMDD HH24:MI:SS');
        EXCEPTION
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                P_RESP_MSG :=
                    'PROBLEM WHILE CONVERTING TRANSACTION DATE '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;
        --EN GET DATE

		BEGIN
            SELECT CAP_PROD_CODE, CAP_CARD_TYPE, CAP_CARD_STAT,CAP_PROXY_NUMBER, CAP_ACCT_NO
              INTO V_PROD_CODE, V_PROD_CATTYPE, V_APPLPAN_CARDSTAT,V_PROXUNUMBER, V_ACCT_NUMBER
              FROM CMS_APPL_PAN
             WHERE CAP_MBR_NUMB = P_MBR_NUMB AND CAP_PAN_CODE = V_HASH_PAN;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '16';                       --INELIGIBLE TRANSACTION
                P_RESP_MSG := 'CARD NUMBER NOT FOUND ' || V_HASH_PAN;
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '12';
                P_RESP_MSG :=
                    'PROBLEM WHILE SELECTING CARD DETAIL'
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

		--Get the card no
        BEGIN
            SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_TYPE_CODE
              INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CAM_TYPE_CODE
              FROM CMS_ACCT_MAST
             WHERE CAM_ACCT_NO = V_ACCT_NUMBER  
                AND CAM_INST_CODE = P_INST_CODE
            FOR UPDATE; 
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_RESP_CDE := '14';                       --INELIGIBLE TRANSACTION
                P_RESP_MSG := 'INVALID CARD ';
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                V_RESP_CDE := '12';

                P_RESP_MSG :='ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ';

                RAISE EXP_REJECT_RECORD;
        END;

		--Sn find total transaction amount
        
        IF P_DR_CR_FLAG = 'CR'
        THEN
            V_UPD_AMT := V_ACCT_BALANCE + P_TXN_AMT;
            V_UPD_LEDGER_BAL := V_LEDGER_BAL + P_TXN_AMT;
        ELSE
            V_RESP_CDE := '12';                          --Ineligible Transaction
            P_RESP_MSG := 'Invalid transflag txn code ' || P_TXN_CODE;
            RAISE EXP_REJECT_RECORD;
        END IF;


		BEGIN
             UPDATE CMS_ACCT_MAST
             SET CAM_ACCT_BAL  = V_UPD_AMT,
                 CAM_LEDGER_BAL =  V_UPD_LEDGER_BAL,
                 CAM_TOPUPTRANS_COUNT = CAM_TOPUPTRANS_COUNT + 1,
                 CAM_DEFUND_FLAG    = 'F'
                 WHERE CAM_INST_CODE = P_INST_CODE AND CAM_ACCT_NO = V_ACCT_NUMBER;
                
                --F - Funded/Loaded The defunded amount
                
            IF SQL%ROWCOUNT = 0 THEN
             P_RESP_CODE := '21';
             P_RESP_MSG  := 'Problem while updating in account master for transaction tran type';
             RAISE EXP_REJECT_RECORD;
            END IF;
            EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
                RAISE;
             WHEN OTHERS THEN
               P_RESP_CODE := '21';
               P_RESP_MSG  := 'Error while updating CMS_ACCT_MAST ' ||
                            SUBSTR(SQLERRM, 1, 250);
               RAISE EXP_REJECT_RECORD;
             END;
        
		BEGIN

                IF TRIM (V_TRANS_DESC) IS NOT NULL
                THEN
                    V_NARRATION := V_TRANS_DESC || ' AND LOAD/';
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

        EXCEPTION
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                P_RESP_MSG :=
                    'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

		BEGIN

		INSERT INTO CMS_STATEMENTS_LOG (
						CSL_PAN_NO,
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
						CSL_INS_DATE, 
						CSL_INS_USER, 
						CSL_ACCT_NO, 
						CSL_MERCHANT_NAME, 
						CSL_MERCHANT_CITY,
						CSL_PANNO_LAST4DIGIT, 
						CSL_ACCT_TYPE, 
						CSL_TIME_STAMP, 
						CSL_PROD_CODE,
						CSL_CARD_TYPE
					) 
			VALUES (
						V_HASH_PAN,
						ROUND(V_LEDGER_BAL, 2), 
						ROUND(P_TXN_AMT, 2), 
						P_DR_CR_FLAG,
						V_TRAN_DATE,
						V_UPD_LEDGER_BAL,
						V_NARRATION,
						V_ENCR_PAN,
						V_RRN,
						V_AUTH_ID,
						P_TRAN_DATE,
						P_TRAN_TIME,
						'N',
						P_DELIVERY_CHANNEL,
						P_INST_CODE,
						P_TXN_CODE,
						SYSDATE,          
						1,                  
						V_ACCT_NUMBER, 
						P_MERCHANT_NAME, 
						P_MERCHANT_CITY,
						(SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))), 
						V_CAM_TYPE_CODE, 
						V_TIMESTAMP, 
						V_PROD_CODE,
						V_PROD_CATTYPE 

					);

		EXCEPTION
            WHEN OTHERS
            THEN
                V_RESP_CDE := '21';
                P_RESP_MSG :=
                    'Error in Inserting into Statements log ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;
        
        
                  P_RESP_CODE := V_RESP_CDE;

            BEGIN
                SELECT CMS_ISO_RESPCDE
                  INTO P_RESP_CODE
                  FROM CMS_RESPONSE_MAST
                 WHERE      CMS_INST_CODE = P_INST_CODE
                         AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
                         AND CMS_RESPONSE_ID = V_RESP_CDE;

            EXCEPTION
                WHEN OTHERS
                THEN
                    P_RESP_MSG :=
                            'PROBLEM WHILE SELECTING DATA FROM RESPONSE MASTER '
                        || V_RESP_CDE
                        || SUBSTR (SQLERRM, 1, 300);
                    P_RESP_CODE := '89';          ---ISO MESSAGE FOR DATABASE ERROR
                    ---Return;
            END;
            
            V_TRANS_DESC := REPLACE(UPPER(V_TRANS_DESC),'ACTIVATION','LOAD');

				--Sn create a entry in txn log
    BEGIN
        INSERT INTO TRANSACTIONLOG (
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
						TOTAL_AMOUNT,
						CURRENCYCODE,
						PRODUCTID,
						CATEGORYID,
						AUTH_ID,
						TRANS_DESC,
						AMOUNT,
						SYSTEM_TRACE_AUDIT_NO,
						INSTCODE,
						CR_DR_FLAG,
						CUSTOMER_CARD_NO_ENCR,
						PROXY_NUMBER,
						REVERSAL_CODE,
						CUSTOMER_ACCT_NO,
						ACCT_BALANCE,
						LEDGER_BALANCE,
						RESPONSE_ID,
						ADD_INS_DATE,
						ADD_INS_USER,
						CARDSTATUS,
						MERCHANT_NAME,
						MERCHANT_CITY,
						ACCT_TYPE,
						TIME_STAMP,
						MERCHANT_ZIP,
						REMARK,
						ERROR_MSG
					) VALUES (
						P_MSG,
						V_RRN,
						P_DELIVERY_CHANNEL,
						P_TERM_ID,
						V_TRAN_DATE,
						P_TXN_CODE,
						V_TXN_TYPE,
						P_TXN_MODE,
						'C',
						P_RESP_CODE,
						P_TRAN_DATE,
						SUBSTR(P_TRAN_TIME, 1, 10),
						V_HASH_PAN,
						TRIM(TO_CHAR(NVL(P_TXN_AMT, 0), '99999999999999990.99')),
						P_CURR_CODE,
						V_PROD_CODE,
						V_PROD_CATTYPE,
						V_AUTH_ID,
						V_TRANS_DESC,
						TRIM(TO_CHAR(NVL(P_TXN_AMT, 0), '99999999999999990.99')),
						P_STAN,
						P_INST_CODE,
						P_DR_CR_FLAG,
						V_ENCR_PAN,
						V_PROXUNUMBER,
						P_RVSL_CODE,
						V_ACCT_NUMBER,
						ROUND(V_UPD_AMT, 2),
						ROUND(V_UPD_LEDGER_BAL, 2),
						V_RESP_CDE,
						SYSDATE,
						1,
						V_APPLPAN_CARDSTAT,
						P_MERCHANT_NAME,
						P_MERCHANT_CITY,
						V_CAM_TYPE_CODE,
						V_TIMESTAMP,
						P_MERCHANT_ZIP,
						P_REMARK,
						P_RESP_MSG
					);
		EXCEPTION			
		WHEN OTHERS THEN
            P_RESP_CODE := '12';
            P_RESP_MSG := 'DF-Exception while inserting to transaction log '||SQLCODE||'---'||SQLERRM;            
		END;

		BEGIN

		INSERT INTO CMS_TRANSACTION_LOG_DTL (
						CTD_DELIVERY_CHANNEL,
						CTD_TXN_CODE,
						CTD_TXN_TYPE,
						CTD_TXN_MODE,
						CTD_BUSINESS_DATE,
						CTD_BUSINESS_TIME,
						CTD_CUSTOMER_CARD_NO,
						CTD_TXN_AMOUNT,
						CTD_TXN_CURR,
						CTD_PROCESS_FLAG,
						CTD_PROCESS_MSG,
						CTD_RRN,
						CTD_SYSTEM_TRACE_AUDIT_NO,
						CTD_CUSTOMER_CARD_NO_ENCR,
						CTD_MSG_TYPE,
						CTD_CUST_ACCT_NUMBER,
						CTD_INST_CODE,
						CTD_HASHKEY_ID
					) 
			VALUES (
						P_DELIVERY_CHANNEL,
						P_TXN_CODE,
						V_TXN_TYPE,
						P_TXN_MODE,
						P_TRAN_DATE,
						P_TRAN_TIME,
						V_HASH_PAN,
						P_TXN_AMT,
						P_CURR_CODE,
						'Y',
						'Successful',
						V_RRN,
						P_STAN,
						V_ENCR_PAN,
						P_MSG,
						V_ACCT_NUMBER,
						P_INST_CODE,
						V_HASHKEY_ID

					);
		EXCEPTION			
        WHEN OTHERS THEN
            P_RESP_CODE := '12';
            P_RESP_MSG := 'DF-Exception while inserting to transaction log detail '||SQLCODE||'---'||SQLERRM;           
		END; 


		EXCEPTION
        --<< MAIN EXCEPTION >>
        WHEN EXP_REJECT_RECORD THEN
            P_RESP_CODE := NVL(P_RESP_CODE,V_RESP_CDE);
			ROLLBACK;

		WHEN OTHERS THEN
			ROLLBACK;

			V_RESP_CDE := '21';
			P_RESP_MSG := 'DF-Error in Main Exception '|| SUBSTR (SQLERRM, 1, 200);
		END;

END;
/
show error;