create or replace PACKAGE BODY vmscms.PKG_EVENT_PUSH_NOTIFICATION 
AS 

PROCEDURE CHECK_PUSH_NOTIFICATION_CONFIG (
    p_instcode        IN                NUMBER,
    p_prod_code       IN                VARCHAR2,        
    p_card_type       IN                NUMBER,
    p_delv_chnl       IN                VARCHAR2,    
    p_txn_code        IN                VARCHAR2, 
    p_partner_name    OUT               VARCHAR2,
    p_event_msg_type  OUT               VARCHAR2,
    p_push_config	  OUT				VARCHAR2,
    p_errmsg          OUT               VARCHAR2
) AS

/******************************************************************************************************************************
   * CREATED BY          : UBAIDUR RAHMAN.H
   * CREATED DATE        : 16-JUNE-2021
   * CREATED FOR         : VMS-4559 - Replacement Push Notification (Physical via CCA)-B2B Spec Consolidation
*******************************************************************************************************************************/
    
    V_EVENT_NOTIFICATION   CMS_PROD_CATTYPE.CPC_EVENT_NOTIFICATION%type; 
    EXP_REJECT_RECORD      exception;
    
    
BEGIN
    p_errmsg := 'OK';
    p_push_config :='Y';

    BEGIN
        SELECT            
            nvl(cpc_event_notification, 'N'),cpc_partner_name            
        INTO            
            v_event_notification,p_partner_name            
        FROM
            cms_prod_cattype
        WHERE
            cpc_prod_code = p_prod_code
            AND cpc_card_type = p_card_type
            AND cpc_inst_code = p_instcode;

    EXCEPTION
        WHEN OTHERS THEN
            P_ERRMSG := 'ERROR IN GETTING PRODUCT DETAILS'
                        || substr(sqlerrm, 1, 200);
            RAISE exp_reject_record;
    END;

    IF v_event_notification = 'N' THEN
    p_push_config := 'N';     
        return;
    END IF;
    
    
    BEGIN
        SELECT
            vtc_event_msg_type
        INTO p_event_msg_type
        FROM
            vms_trans_configuration
        WHERE
            vtc_inst_code = p_instcode
            AND vtc_tran_code = p_txn_code
            AND vtc_delivery_channel = p_delv_chnl
            AND vtc_prod_code = p_prod_code
            AND vtc_card_type = p_card_type
            AND vtc_trans_conf_code = 'E';  ---- Event Notification.

    EXCEPTION
        WHEN no_data_found THEN
         p_push_config := 'N';               
        WHEN OTHERS THEN
        P_ERRMSG := 'ERROR WHILE SELECTING FROM TRANS CONFIGURATION '
                        || substr(sqlerrm, 1, 200);
        RAISE exp_reject_record;
    END; 

EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
        NULL;
    WHEN OTHERS THEN
        P_ERRMSG := 'Main Excp-'
                    || substr(sqlerrm, 1, 100);
END CHECK_PUSH_NOTIFICATION_CONFIG;



PROCEDURE FORM_PUSH_NOTIFICATION_PAYLOAD (
    p_customer_id_in      IN                VARCHAR2, 
    p_email_in            IN                VARCHAR2, 
    p_curr_bal_in         IN                NUMBER,
    p_available_bal_in    IN                NUMBER,  
    p_datetime_in         IN                DATE,
    p_trans_desc          IN                VARCHAR2,       
    p_order_stat_in       IN                VARCHAR2,       
    p_proxy_no_in         IN                VARCHAR2,                      
    p_serl_no_in          IN                VARCHAR2,
    p_encrypted_str_in    IN                VARCHAR2,
    p_card_stat_in        IN                VARCHAR2,
    p_tracking_numb_in    IN                VARCHAR2,
    p_shipdatetime_in     IN                DATE,
    p_print_resp_in       IN                VARCHAR2,
    p_payload_type_in     IN                VARCHAR2,
    p_last_four_pan_in    IN                VARCHAR2,
    p_payload_out         OUT               VARCHAR2,
    p_errmsg_out          OUT               VARCHAR2
) AS

/******************************************************************************************************************************
   * CREATED BY          : UBAIDUR RAHMAN.H
   * CREATED DATE        : 16-JUNE-2021
   * CREATED FOR         : VMS-4559 - Replacement Push Notification (Physical via CCA)-B2B Spec Consolidation
   
   * Modified By      : Ubaidur Rahman H
     * Modified Date    : 26-JUN-2021
     * Purpose          : VMS-4565 - Resend Email - Virtual Push Notification (Physical via CCA)-B2B Spec Consolidation.
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOST_R48_B3
	 
     * Modified By      : SanthoshKumar Chigullapally
     * Modified Date    : 24-AUG-2021
     * Purpose          : VMS-4682 - Replacement PushNOtification add LastFourPAN
     * Reviewer         : Puvanesh
     * Release Number   : VMSGPRHOST_R50_B2

*******************************************************************************************************************************/
    
    EXP_REJECT_RECORD      exception;
    
    
BEGIN
    p_errmsg_out := 'OK';

     IF p_payload_type_in in ('REPLACE','RESEND EMAIL')   --- Modified for VMS-4565
     THEN

      BEGIN
         SELECT
            ---JSON_OBJECT ( KEY 'payload' VALUE ''   || 
                                              JSON_OBJECT ( KEY 'customerId' VALUE p_customer_id_in,
                                                                KEY 'email' VALUE p_email_in,
                                                                KEY 'currentBalance' VALUE TRIM(TO_CHAR(p_curr_bal_in, '99999999999999990.99')),
                                                                KEY 'availableBalance' VALUE TRIM(TO_CHAR(p_available_bal_in, '99999999999999990.99')),                                                                
                                                                KEY 'transactionDateTime' VALUE TO_CHAR(p_datetime_in, 'YYYY-MM-DD HH24:MI:SS'),
                                                                KEY 'transactionDescription' VALUE p_trans_desc,
                                                                KEY 'transactionType' VALUE p_payload_type_in,                                                               
                                                                KEY 'status' VALUE p_order_stat_in,
                                                                'card' VALUE json_array (                                                                
                                                                JSON_OBJECT
                                                                (
                                                                KEY 'proxyNumber' VALUE p_proxy_no_in,
								KEY 'lastFourPAN' VALUE p_last_four_pan_in,
                                                                KEY 'encryptedString' VALUE p_encrypted_str_in,
                                                                KEY 'serialNumber' VALUE p_serl_no_in,
                                                                KEY 'cardStatus' VALUE p_card_stat_in, 
                                                                KEY 'trackingNumber' VALUE p_tracking_numb_in,
                                                                KEY 'shippingDateTime' VALUE p_shipdatetime_in,
                                                                KEY 'printerResponse' VALUE p_print_resp_in
                                                               ) 
                                                               ) )
                                                               into p_payload_out FROM dual;

    EXCEPTION
        WHEN OTHERS THEN
            p_errmsg_out := 'ERROR WHILE CREATING PAYLOAD '
                        || substr(sqlerrm, 1, 200);
            RAISE exp_reject_record;
    END;
    
    
    END IF;

EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
         NULL;
    WHEN OTHERS THEN
        P_ERRMSG_OUT := 'Main Excp-'
                    || substr(sqlerrm, 1, 100);
END FORM_PUSH_NOTIFICATION_PAYLOAD;


PROCEDURE INSERT_EVENT_PROCESSING (
    p_rrn             IN                VARCHAR2,        
    p_payload         IN                VARCHAR2,
    p_partner_name    IN                VARCHAR2,       
    p_event_msg_type  IN                VARCHAR2,
    p_queue_name      IN                VARCHAR2,
    p_status          IN                VARCHAR2,
    p_errmsg          OUT               VARCHAR2
) AS

/******************************************************************************************************************************
   * CREATED BY          : UBAIDUR RAHMAN.H
   * CREATED DATE        : 16-JUNE-2021
   * CREATED FOR         : VMS-4559 - Replacement Push Notification (Physical via CCA)-B2B Spec Consolidation
*******************************************************************************************************************************/
     
    EXP_REJECT_RECORD      exception;
    
    
BEGIN
    p_errmsg := 'OK';


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
            p_payload,
            p_partner_name,
            p_event_msg_type,
            p_queue_name,
            p_status,
            1,
            SYSDATE
        );
    EXCEPTION
        WHEN OTHERS THEN
            P_ERRMSG := 'ERROR WHILE INSERTING INTO EVENT '
                        || substr(sqlerrm, 1, 200);
            RAISE exp_reject_record;
    END;

EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
         NULL;
    WHEN OTHERS THEN
        P_ERRMSG := 'Main Excp-'
                    || substr(sqlerrm, 1, 100);
END INSERT_EVENT_PROCESSING;

END PKG_EVENT_PUSH_NOTIFICATION;

  
/
SHOW ERRORS;