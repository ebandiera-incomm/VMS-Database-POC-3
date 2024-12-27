CREATE OR REPLACE PROCEDURE vmscms.sp_log_txnlogdetl (
   p_inst_code          IN       cms_transaction_log_dtl.ctd_inst_code%TYPE,
   p_msg_type           IN       cms_transaction_log_dtl.ctd_msg_type%TYPE,
   p_rrn                IN       cms_transaction_log_dtl.ctd_rrn%TYPE,
   p_delivery_channel   IN       cms_transaction_log_dtl.ctd_delivery_channel%TYPE,
   p_txn_code           IN       cms_transaction_log_dtl.ctd_txn_code%TYPE,
   p_txn_type           IN       cms_transaction_log_dtl.ctd_txn_type%TYPE,
   p_txn_mode           IN       cms_transaction_log_dtl.ctd_txn_mode%TYPE,
   p_tran_date          IN       cms_transaction_log_dtl.ctd_business_date%TYPE,
   p_tran_time          IN       cms_transaction_log_dtl.ctd_business_time%TYPE,
   p_hash_pan           IN       cms_transaction_log_dtl.ctd_customer_card_no%TYPE,
   p_encr_pan           IN       cms_transaction_log_dtl.ctd_customer_card_no_encr%TYPE,
   p_err_msg            IN       cms_transaction_log_dtl.ctd_process_msg%TYPE,
   p_acct_no            IN       cms_transaction_log_dtl.ctd_customer_card_no%TYPE,
   p_auth_id            IN       cms_transaction_log_dtl.ctd_auth_id%TYPE,
   p_amount             IN       cms_transaction_log_dtl.ctd_txn_amount%TYPE,
   p_mobil_no           IN       cms_transaction_log_dtl.ctd_mobile_number%TYPE,
   p_device_id          IN       cms_transaction_log_dtl.ctd_device_id%TYPE,
   p_hashkey_id         IN       cms_transaction_log_dtl.ctd_hashkey_id%TYPE,
   p_check_number       IN       cms_transaction_log_dtl.ctd_check_number%TYPE,
   p_check_desc         IN       cms_transaction_log_dtl.ctd_check_desc%TYPE,
   p_routing_number     IN       cms_transaction_log_dtl.ctd_routing_number%TYPE,
   p_chcek_acctno       IN       cms_transaction_log_dtl.ctd_check_acctno%TYPE,
   p_resp_code          IN       VARCHAR2,
   p_deposit_id         IN       cms_transaction_log_dtl.ctd_deposit_id%TYPE
         DEFAULT NULL,
   p_reason_code        IN       cms_transaction_log_dtl.ctd_reason_code%TYPE
         DEFAULT NULL,
   p_reason_desc        IN       cms_transaction_log_dtl.ctd_reason_msg%TYPE
         DEFAULT NULL,
   p_resp_msg           OUT      VARCHAR2,
   p_email_id           IN       cms_transaction_log_dtl.CTD_EMAIL%TYPE DEFAULT NULL,
   p_req_resp_code      IN       cms_transaction_log_dtl.ctd_req_resp_code%TYPE DEFAULT NULL,
   p_stan_in            IN       cms_transaction_log_dtl.CTD_SYSTEM_TRACE_AUDIT_NO%TYPE DEFAULT NULL
   
   
)
AS
/**********************************************************************************************
                  * Created Date     : 08-August-2014
                  * Created By       : Dhinakaran B
                  * PURPOSE          : FWR-67

                  * Modified Date    : 08-August-2014
                  * Modified By      : Dhinakaran B
                  * PURPOSE          : FWR-67 review changes &  MANTIS ID-15671
				  * Review           : Spankaj
                  * Build Number     : RI0027.3.1_B0003
                  
                  * Created Date     :  27-Jun-2016
                  * Created By       :  MAGESHKUMAR S
                  * Created For      :  VISA Tokenization Changes
                  * Reviewer         :  Saravanakumar/SPankaj
                  * Build Number     :  VMSGPRHOSTCSD4.3_B00001
		  
		  * Created Date     :  06-Jun-2016
                  * Created By       :  MAGESHKUMAR S
                  * Created For      :  VISA Tokenization Changes
                  * Reviewer         :  Saravanakumar/SPankaj
                  * Build Number     :  VMSGPRHOSTCSD4.3_B00002
		  
		  
                  
                  
/**********************************************************************************************/
BEGIN
   INSERT INTO cms_transaction_log_dtl
               (ctd_inst_code, ctd_msg_type, ctd_rrn, ctd_delivery_channel,
                ctd_txn_code, ctd_txn_type, ctd_txn_mode, ctd_business_date,
                ctd_business_time, ctd_customer_card_no,
                ctd_customer_card_no_encr, ctd_process_msg,
                ctd_process_flag, ctd_fee_amount, ctd_waiver_amount,
                ctd_servicetax_amount, ctd_cess_amount, ctd_ins_date,
                ctd_ins_user, ctd_mobile_number, ctd_device_id,
                ctd_hashkey_id, ctd_auth_id, ctd_txn_amount,
                ctd_check_number, ctd_check_desc, ctd_routing_number,
                ctd_check_acctno, ctd_deposit_id, ctd_cust_acct_number,
                ctd_reason_code, ctd_reason_msg,CTD_EMAIL,ctd_req_resp_code,CTD_SYSTEM_TRACE_AUDIT_NO
               )
        VALUES (p_inst_code, p_msg_type, p_rrn, p_delivery_channel,
                p_txn_code, p_txn_type, p_txn_mode, p_tran_date,
                p_tran_time, p_hash_pan,
                p_encr_pan, p_err_msg,
                DECODE (p_resp_code, '00', 'C', 'F'), NULL, NULL,
                NULL, NULL, SYSDATE,
                1, p_mobil_no, p_device_id,
                p_hashkey_id, p_auth_id, p_amount,
                p_check_number, p_check_desc, p_routing_number,
                p_chcek_acctno, p_deposit_id, p_acct_no,
                p_reason_code, p_reason_desc,p_email_id,p_req_resp_code,p_stan_in
               );

   p_resp_msg := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      p_resp_msg :=
            'Problem while inserting data into transaction log  '
         || SUBSTR (SQLERRM, 1, 300);
END;
/
SHOW ERROR