create or replace PROCEDURE        VMSCMS.SP_ENQUEUE_MSG (
											P_INSTCODE        IN                NUMBER,
											P_HASH_PAN        IN                VARCHAR2,
											P_HOLD_AMOUNT     IN                NUMBER,
											P_RRN             IN                VARCHAR2,
											P_DELV_CHNL       IN                VARCHAR2,
											P_TXN_CODE        IN                VARCHAR2,
											P_ACCT_BAL        IN                NUMBER,
											P_LEDGER_BAL      IN                NUMBER,
											P_INS_DATE        IN                DATE,
											P_MBR_NUMB        IN                VARCHAR2,
											P_MERCHANT_NAME   IN                VARCHAR2,
											P_ERRMSG          OUT               VARCHAR2
										)
   AS
   
/******************************************************************************************************************************
   * MODIFIED BY          : RAJ DEVKOTA
   * MODIFIED DATE        : 03-MAY-2021
   * MODIFIED FOR         : VMS-4020 - Activation Push Notification, Add customerId and cardStatus in payload
   * MODIFIED BY          : PUVANESH.N
   * MODIFIED DATE        : 22-APR-2021
   * MODIFIED FOR         : VMS-3944 - VMS HOST UI throws SQL Exception upon selecting HOST 
							as delivery channel in Transaction Configuration for OTP/Event Notification screen
*******************************************************************************************************************************/	

		V_PAY_LOAD             VARCHAR2(4000);
		V_PROD_CODE            CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
		V_CARD_TYPE            CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
		V_PROXY_NUMBER         CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
		V_PRODUCT_NAME         CMS_PROD_CATTYPE.CPC_CARDTYPE_DESC%TYPE;
		V_LAST_FOUR_PAN        VARCHAR2(10);
		V_EVENT_MSG_TYPE       VMS_TRANS_CONFIGURATION.VTC_EVENT_MSG_TYPE%TYPE;
		V_PARTNER_ID           VARCHAR2(100) := 'INST-FIN-PUSHNOTIFY';
		V_EVENT_NOTIFICATION   CMS_PROD_CATTYPE.CPC_EVENT_NOTIFICATION%TYPE;
		V_PARTNER_NAME         CMS_PROD_CATTYPE.CPC_PARTNER_NAME%TYPE;
		V_QUEUE_NAME           VMS_EVENT_PROCESSING.VEP_QUEUE_NAME%TYPE;
		V_TRAN_DESC            CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
		V_TRAN_TYPE            CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
		V_CARD_STATUS          cms_card_stat.ccs_stat_desc%TYPE;
        V_CUSTOMER_ID          cms_cust_mast.ccm_cust_id%TYPE;


		EXP_REJECT_RECORD 	   EXCEPTION;

   BEGIN
      P_ERRMSG := 'OK';

    BEGIN
        SELECT
            CAP_PROD_CODE,
            CAP_CARD_TYPE,
            CAP_PROXY_NUMBER,
            SUBSTR(CAP_MASK_PAN, - 4),
            ccs_stat_desc,
            ccm_cust_id 
        INTO
            V_PROD_CODE,
            V_CARD_TYPE,
            V_PROXY_NUMBER,
            V_LAST_FOUR_PAN,
            V_CARD_STATUS,
            V_CUSTOMER_ID
        FROM
            CMS_APPL_PAN, cms_cust_mast, cms_card_stat
        WHERE
            CAP_PAN_CODE = P_HASH_PAN
            AND CAP_MBR_NUMB = P_MBR_NUMB            
            AND cap_cust_code = ccm_cust_code 
            AND cap_inst_code = ccm_inst_code
            AND ccs_stat_code = cap_card_stat;

    EXCEPTION
        WHEN OTHERS THEN
            P_ERRMSG := 'ERROR IN SELECTING CARD DETAILS'
                        || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
        SELECT
            CPC_CARDTYPE_DESC,
            NVL(CPC_EVENT_NOTIFICATION, 'N'),
            CPC_PARTNER_NAME
        INTO
            V_PRODUCT_NAME,
            V_EVENT_NOTIFICATION,
            V_PARTNER_NAME
        FROM
            CMS_PROD_CATTYPE
        WHERE
            CPC_PROD_CODE = V_PROD_CODE
            AND CPC_CARD_TYPE = V_CARD_TYPE
            AND CPC_INST_CODE = P_INSTCODE;

    EXCEPTION
        WHEN OTHERS THEN
            P_ERRMSG := 'ERROR IN GETTING PRODUCT DETAILS'
                        || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;

    IF V_EVENT_NOTIFICATION = 'N' THEN
        RETURN;
    END IF;

    BEGIN
        SELECT
            CTM_TRAN_DESC,
            CTM_TRAN_TYPE
        INTO
            V_TRAN_DESC,
            V_TRAN_TYPE
        FROM
            CMS_TRANSACTION_MAST
        WHERE
            CTM_DELIVERY_CHANNEL = P_DELV_CHNL
            AND CTM_TRAN_CODE = P_TXN_CODE
            AND CTM_INST_CODE = P_INSTCODE;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_ERRMSG := 'TRANSACTION DETAILS NOT FOUND';
            RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
            P_ERRMSG := 'WHILE GETTING TRANSACTION DESCRIPTION'
                        || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
        SELECT
            VTC_EVENT_MSG_TYPE
        INTO V_EVENT_MSG_TYPE
        FROM
            VMS_TRANS_CONFIGURATION
        WHERE
            VTC_INST_CODE = P_INSTCODE
            AND VTC_TRAN_CODE = P_TXN_CODE
            AND VTC_DELIVERY_CHANNEL = P_DELV_CHNL
            AND VTC_PROD_CODE = V_PROD_CODE
            AND VTC_CARD_TYPE = V_CARD_TYPE
            AND VTC_TRANS_CONF_CODE = 'E';

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        RETURN;
        WHEN OTHERS THEN
        P_ERRMSG := 'ERROR WHILE SELECTING FROM TRANS CONFIGURATION '
                        || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
        SELECT
            CIP_PARAM_VALUE
        INTO V_QUEUE_NAME
        FROM
            CMS_INST_PARAM
        WHERE
            CIP_INST_CODE = 1
            AND CIP_PARAM_KEY = 'EVENT_PROCESS_QueueName';

    EXCEPTION
        WHEN OTHERS THEN
            P_ERRMSG := 'ERROR WHILE SELECTING FROM TRANS CONFIGURATION '
                        || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;



      BEGIN 

		SELECT
            JSON_OBJECT ( KEY 'proxyNumber' VALUE V_PROXY_NUMBER, 
													  KEY 'lastFourPAN' VALUE V_LAST_FOUR_PAN,
                                                      KEY 'productName' VALUE V_PRODUCT_NAME, 
                                                      KEY 'transactionReferenceNumber' VALUE P_RRN,
                                                      KEY 'ledgerBalance' VALUE TRIM(TO_CHAR(P_LEDGER_BAL, '99999999999999999.99')),
                                                      KEY 'availableBalance' VALUE TRIM(TO_CHAR(P_ACCT_BAL, '99999999999999999.99')), 
                                                      KEY 'transactionAmount' VALUE TRIM(TO_CHAR(P_HOLD_AMOUNT, '99999999999999999.99')), 
                                                      KEY 'transactionDescription' VALUE V_TRAN_DESC, 
                                                      KEY 'transactionType' VALUE DECODE(V_TRAN_TYPE, 'DR', 'DEBIT', 'CREDIT'), 
                                                      KEY 'transactionDateTime' VALUE TO_CHAR(P_INS_DATE, 'YYYY-MM-DD HH24:MI:SS'), 
                                                      KEY 'transactionPostedDate' VALUE TO_CHAR(P_INS_DATE, 'YYYY-MM-DD HH24:MI:SS'), 
                                                      KEY 'merchantname' VALUE P_MERCHANT_NAME,                                                      
                                                      KEY 'customerId' VALUE V_Customer_Id,
                                                      KEY 'cardStatus' VALUE V_Card_Status)
        INTO V_PAY_LOAD
        FROM
            DUAL;

        EXCEPTION
        WHEN OTHERS THEN
            P_ERRMSG :='ERROR WHILE FORMING PAYLOAD' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;


	VMS_PUSH_QUEUE_NOTIFICATION@CEP_OAQ(V_QUEUE_NAME,P_RRN,V_PAY_LOAD,V_EVENT_MSG_TYPE,V_PARTNER_NAME,P_ERRMSG);

    IF P_ERRMSG <> 'OK' THEN
        RAISE EXP_REJECT_RECORD;
    END IF;


   EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
         P_ERRMSG :='PROBLEM WHILE ENQUEUE MSG INTO QUEUE-'|| P_ERRMSG;         
      WHEN OTHERS THEN
         P_ERRMSG :='PROBLEM WHILE ENQUEUE MSG INTO QUEUE-'|| SUBSTR (SQLERRM, 1, 300);         

END SP_ENQUEUE_MSG;
/
SHOW ERROR