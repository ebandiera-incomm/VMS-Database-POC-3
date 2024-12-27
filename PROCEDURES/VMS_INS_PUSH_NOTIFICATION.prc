create or replace PROCEDURE        VMSCMS.VMS_INS_PUSH_NOTIFICATION (
    p_instcode        IN                NUMBER,
    p_hash_pan        IN                VARCHAR2,
    p_hold_amount     IN                NUMBER,
    p_rrn             IN                VARCHAR2,
    p_delv_chnl       IN                VARCHAR2,
    p_txn_code        IN                VARCHAR2,
    p_acct_bal        IN                NUMBER,
    p_ledger_bal      IN                NUMBER,
    p_ins_date        IN                DATE,
    p_mbr_numb        IN                VARCHAR2,
    p_merchant_name   IN                VARCHAR2,
	p_event_status    IN                VARCHAR2,
    p_errmsg          OUT               VARCHAR2
) AS

/******************************************************************************************************************************
   * MODIFIED BY          : PUVANESH.N
   * MODIFIED DATE        : 22-APR-2021
   * MODIFIED FOR         : VMS-3944 - VMS HOST UI throws SQL Exception upon selecting HOST 
							as delivery channel in Transaction Configuration for OTP/Event Notification screen
*******************************************************************************************************************************/	

    V_PAY_LOAD             VARCHAR2(4000);
    V_PROD_CODE            CMS_APPL_PAN.CAP_PROD_CODE%type;
    V_CARD_TYPE            CMS_APPL_PAN.CAP_CARD_TYPE%type;
    V_PROXY_NUMBER         CMS_APPL_PAN.CAP_PROXY_NUMBER%type;
    V_PRODUCT_NAME         CMS_PROD_CATTYPE.CPC_CARDTYPE_DESC%type;
    V_LAST_FOUR_PAN        VARCHAR2(10);
    V_EVENT_MSG_TYPE       VMS_TRANS_CONFIGURATION.VTC_EVENT_MSG_TYPE%type;
    V_PARTNER_ID           VARCHAR2(100) := 'INST-FIN-PUSHNOTIFY';
    V_EVENT_NOTIFICATION   CMS_PROD_CATTYPE.CPC_EVENT_NOTIFICATION%type;
    V_PARTNER_NAME         CMS_PROD_CATTYPE.CPC_PARTNER_NAME%type;
    V_QUEUE_NAME           VMS_EVENT_PROCESSING.VEP_QUEUE_NAME%type;
    V_TRAN_DESC            CMS_TRANSACTION_MAST.CTM_TRAN_DESC%type;
    V_TRAN_TYPE            CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%type;
    V_CARD_STATUS          cms_card_stat.ccs_stat_desc%TYPE;
    V_CUSTOMER_ID          cms_cust_mast.ccm_cust_id%TYPE;


    EXP_REJECT_RECORD      exception;
BEGIN
    p_errmsg := 'OK';

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
            p_errmsg := 'ERROR IN SELECTING CARD DETAILS'
                        || substr(sqlerrm, 1, 200);
            RAISE exp_reject_record;
    END;

    BEGIN
        SELECT
            cpc_cardtype_desc,
            nvl(cpc_event_notification, 'N'),
            cpc_partner_name
        INTO
            v_product_name,
            v_event_notification,
            v_partner_name
        FROM
            cms_prod_cattype
        WHERE
            cpc_prod_code = v_prod_code
            AND cpc_card_type = v_card_type
            AND cpc_inst_code = p_instcode;

    EXCEPTION
        WHEN OTHERS THEN
            p_errmsg := 'ERROR IN GETTING PRODUCT DETAILS'
                        || substr(sqlerrm, 1, 200);
            RAISE exp_reject_record;
    END;

    IF v_event_notification = 'N' THEN
        return;
    END IF;
    BEGIN
        SELECT
            ctm_tran_desc,
            ctm_tran_type
        INTO
            v_tran_desc,
            v_tran_type
        FROM
            cms_transaction_mast
        WHERE
            ctm_delivery_channel = p_delv_chnl
            AND ctm_tran_code = p_txn_code
            AND ctm_inst_code = p_instcode;

    EXCEPTION
        WHEN no_data_found THEN
            p_errmsg := 'Transaction Details Not Found';
            RAISE exp_reject_record;
        WHEN OTHERS THEN
            p_errmsg := 'While getting Transaction Description'
                        || substr(sqlerrm, 1, 200);
            RAISE exp_reject_record;
    END;

    BEGIN
        SELECT
            vtc_event_msg_type
        INTO v_event_msg_type
        FROM
            vms_trans_configuration
        WHERE
            vtc_inst_code = p_instcode
            AND vtc_tran_code = p_txn_code
            AND vtc_delivery_channel = p_delv_chnl
            AND vtc_prod_code = v_prod_code
            AND vtc_card_type = v_card_type
            AND vtc_trans_conf_code = 'E';

    EXCEPTION
        WHEN no_data_found THEN
        Return;
        WHEN OTHERS THEN
        p_errmsg := 'ERROR WHILE SELECTING FROM TRANS CONFIGURATION '
                        || substr(sqlerrm, 1, 200);
        RAISE exp_reject_record;
    END;

    BEGIN
        SELECT
            cip_param_value
        INTO v_queue_name
        FROM
            cms_inst_param
        WHERE
            cip_inst_code = 1
            AND cip_param_key = 'EVENT_PROCESS_QueueName';

    EXCEPTION 
        WHEN OTHERS THEN
            p_errmsg := 'ERROR WHILE SELECTING FROM TRANS CONFIGURATION '
                        || substr(sqlerrm, 1, 200);
            RAISE exp_reject_record;
    END;





    BEGIN
        SELECT
            JSON_OBJECT ( KEY 'payload' VALUE ''
                                              || JSON_OBJECT ( KEY 'proxyNumber' VALUE v_proxy_number, 
                                                               KEY 'lastFourPAN' VALUE v_last_four_pan,
                                                               KEY 'productName' VALUE v_product_name, 
                                                               KEY 'transactionReferenceNumber' VALUE p_rrn,
                                                               KEY 'ledgerBalance' VALUE TRIM(TO_CHAR(p_ledger_bal, '99999999999999999.99')),
                                                               KEY 'availableBalance' VALUE TRIM(TO_CHAR(p_acct_bal, '99999999999999999.99')), 
                                                               KEY 'transactionAmount' VALUE TRIM(TO_CHAR(p_hold_amount, '99999999999999999.99')), 
                                                               KEY 'transactionDescription' VALUE v_tran_desc, KEY 'transactionType' VALUE DECODE(v_tran_type, 'DR', 'DEBIT', 'CREDIT'), 
                                                               KEY 'transactionDateTime' VALUE TO_CHAR(p_ins_date, 'YYYY-MM-DD HH24:MI:SS'), 
                                                               KEY 'transactionPostedDate' VALUE TO_CHAR(p_ins_date, 'YYYY-MM-DD HH24:MI:SS'), 
                                                               KEY 'merchantName' VALUE p_merchant_name,
                                                               KEY 'customerId' VALUE v_customer_id, 
                                                               KEY 'cardStatus' VALUE v_card_status))
        INTO v_pay_load
        FROM
            dual;

    EXCEPTION
        WHEN OTHERS THEN
            p_errmsg := 'ERROR WHILE FORMING PAYLOAD'
                        || substr(sqlerrm, 1, 200);
            RAISE exp_reject_record;
    END;

    BEGIN
        INSERT INTO vms_event_processing (
            vep_record_id,
            vep_req_payload,
            vep_partner_name,
            vep_msg_type,
            vep_queue_name,
            vep_status,
            vep_retry_count,
            vep_ins_date
        ) VALUES (
            p_rrn,
            v_pay_load,
            v_partner_name,
            v_event_msg_type,
            v_queue_name,
            p_event_status, 
            1,
            SYSDATE
        );
    EXCEPTION
        WHEN OTHERS THEN
            p_errmsg := 'ERROR WHILE INSERTING INTO EVENT '
                        || substr(sqlerrm, 1, 200);
            RAISE exp_reject_record;
    END;

EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
         P_ERRMSG :='PROBLEM WHILE ENQUEUE MSG INTO QUEUE-'|| P_ERRMSG;         
    WHEN OTHERS THEN
        P_ERRMSG := 'Main Excp-'
                    || substr(sqlerrm, 1, 100);
END;
/
SHOW ERROR