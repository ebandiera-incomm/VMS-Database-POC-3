create or replace PACKAGE     vmscms.PKG_EVENT_PUSH_NOTIFICATION 
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
    p_errmsg          OUT               VARCHAR2);
    
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
    p_errmsg_out          OUT               VARCHAR2);    
    
PROCEDURE INSERT_EVENT_PROCESSING (
    p_rrn             IN                VARCHAR2,        
    p_payload         IN                VARCHAR2,
    p_partner_name    IN                VARCHAR2,       
    p_event_msg_type  IN                VARCHAR2,
    p_queue_name      IN                VARCHAR2,
    p_status          IN                VARCHAR2,
    p_errmsg          OUT               VARCHAR2
);

END PKG_EVENT_PUSH_NOTIFICATION;
/
SHOW ERROR;
