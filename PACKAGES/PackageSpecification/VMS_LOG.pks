create or replace
PACKAGE        vmscms.VMS_LOG
IS
   -- Public type declarations

   -- Public constant declarations

   -- Public variable declarations

   -- Public function and procedure declarations
   PROCEDURE log_transactionlog (
      p_inst_code_in            IN     transactionlog.instcode%TYPE,
      p_msg_type_in             IN     transactionlog.msgtype%TYPE,
      p_rrn_in                  IN     transactionlog.rrn%TYPE,
      p_delivery_channel_in     IN     transactionlog.delivery_channel%TYPE,
      p_txn_code_in             IN     transactionlog.txn_code%TYPE,
      p_txn_type_in             IN     transactionlog.txn_type%TYPE,
      p_txn_mode_in             IN     transactionlog.txn_mode%TYPE,
      p_tran_date_in            IN     transactionlog.business_date%TYPE,
      p_tran_time_in            IN     transactionlog.business_time%TYPE,
      p_rvsl_code_in            IN     transactionlog.reversal_code%TYPE,
      p_hash_pan_in             IN     transactionlog.customer_card_no%TYPE,
      p_encr_pan_in             IN     transactionlog.customer_card_no_encr%TYPE,
      p_err_msg_in              IN     transactionlog.error_msg%TYPE,
      p_ip_addr_in              IN     transactionlog.ipaddress%TYPE,
      p_card_stat_in            IN     transactionlog.cardstatus%TYPE,
      p_trans_desc_in           IN     transactionlog.trans_desc%TYPE,
      p_ani_in                  IN     transactionlog.ani%TYPE,
      p_dni_in                  IN     transactionlog.dni%TYPE,
      p_time_stamp_in           IN     transactionlog.time_stamp%TYPE,
      p_acct_no_in              IN     transactionlog.customer_acct_no%TYPE,
      p_prod_code_in            IN     transactionlog.productid%TYPE,
      p_card_type_in            IN     transactionlog.categoryid%TYPE,
      p_drcr_flag_in            IN     transactionlog.cr_dr_flag%TYPE,
      p_acct_bal_in             IN     transactionlog.acct_balance%TYPE,
      p_ledger_bal_in           IN     transactionlog.ledger_balance%TYPE,
      p_acct_type_in            IN     transactionlog.acct_type%TYPE,
      p_proxy_number_in         IN     transactionlog.proxy_number%TYPE,
      p_auth_id_in              IN     transactionlog.auth_id%TYPE,
      p_amount_in               IN     transactionlog.amount%TYPE,
      p_total_amount_in         IN     transactionlog.amount%TYPE,
      p_fee_code_in             IN     transactionlog.feecode%TYPE,
      p_tranfee_amt_in          IN     transactionlog.tranfee_amt%TYPE,
      p_fee_plan_in             IN     transactionlog.fee_plan%TYPE,
      p_fee_attachtype_in       IN     transactionlog.feeattachtype%TYPE,
      p_resp_id_in              IN     transactionlog.response_id%TYPE,
      p_resp_code_in            IN     transactionlog.response_code%TYPE,
      p_curr_code_in            IN     transactionlog.currencycode%TYPE,
      p_hashkey_id_in           IN     cms_transaction_log_dtl.ctd_hashkey_id%TYPE,
      p_uuid_in                 IN     transactionlog.uuid%TYPE,
      p_os_name_in              IN     transactionlog.os_name%TYPE,
      p_os_version_in           IN     transactionlog.os_version%TYPE,
      p_gps_coordinates_in      IN     transactionlog.gps_coordinates%TYPE,
      p_display_resolution_in   IN     transactionlog.display_resolution%TYPE,
      p_physical_memory_in      IN     transactionlog.physical_memory%TYPE,
      p_app_name_in             IN     transactionlog.app_name%TYPE,
      p_app_version_in          IN     transactionlog.app_version%TYPE,
      p_session_id_in           IN     transactionlog.session_id%TYPE,
      p_device_country_in       IN     transactionlog.device_country%TYPE,
      p_device_region_in        IN     transactionlog.device_region%TYPE,
      p_ip_country_in           IN     transactionlog.ip_country%TYPE,
      p_proxy_flag_in           IN     transactionlog.proxy_flag%TYPE,
	    p_api_partner_id_in     IN     transactionlog.req_partner_id%TYPE,
      p_resp_msg_out               OUT VARCHAR2,
      p_return_recievedDate_in  in    transactionlog.IMPDATE%type default null,
      p_return_Reason_in    in    transactionlog.REASON%type default null,
      p_return_filename_in   in  transactionlog.RETURNACHFILENAME%type default null);

	   PROCEDURE log_transactionlog_audit (
      p_msg_type_in             IN     transactionlog_audit.msgtype%TYPE,
      p_rrn_in                  IN     transactionlog_audit.rrn%TYPE,
      p_delivery_channel_in     IN     transactionlog_audit.delivery_channel%TYPE,
      p_txn_code_in             IN     transactionlog_audit.txn_code%TYPE,
      p_txn_mode_in             IN     transactionlog_audit.txn_mode%TYPE,
      p_tran_date_in            IN     transactionlog_audit.business_date%TYPE,
      p_tran_time_in            IN     transactionlog_audit.business_time%TYPE,
      p_rvsl_code_in            IN     transactionlog_audit.reversal_code%TYPE,
      p_pan_in                  IN     transactionlog_audit.customer_card_no%TYPE,
      p_err_msg_in              IN     transactionlog_audit.error_msg%TYPE,
      p_amount_in               IN     transactionlog_audit.amount%TYPE,
      p_total_amount_in         in     transactionlog_audit.total_amount%type,
      p_resp_id_in              IN     transactionlog_audit.response_id%TYPE,
      p_curr_code_in            IN     transactionlog_audit.currencycode%TYPE,
	  p_api_partner_id_in     	IN     transactionlog_audit.req_partner_id%TYPE,
      p_remark_in               in     transactionlog_audit.remark%type,
      p_resp_msg_out            OUT    VARCHAR2,
      p_correlation_id_in       IN     transactionlog_audit.correlation_id%type default null,
      p_ip_addr_in              IN     transactionlog_audit.ipaddress%TYPE default null,
      p_FSAPI_USERNAME_in       in     transactionlog_audit.fsapi_username%type default null,
      P_TRAN_STATUS_in          IN     transactionlog_audit.TXN_STATUS%type default null,
      P_ANI_IN                  IN     transactionlog_audit.ANI%type default null,
      P_DNI_IN                  IN     transactionlog_audit.DNI%type default null,
      P_TERMINAL_ID_IN          IN     transactionlog_audit.TERMINAL_ID%type default null,
      P_BANK_CODE_IN            IN     transactionlog_audit.BANK_CODE%type default null,
      P_ATM_NAME_LOCATION_IN    IN     transactionlog_audit.ATM_NAME_LOCATION%type default null,
      P_STAN_IN                 IN     transactionlog_audit.SYSTEM_TRACE_AUDIT_NO%type default null,
      P_MERCHANT_NAME_IN        IN     transactionlog_audit.MERCHANT_NAME%type default null,
      P_MERCHANT_CITY_IN        IN     transactionlog_audit.MERCHANT_CITY%type default null,
      P_MERCHANT_STATE_IN       IN     transactionlog_audit.MERCHANT_STATE%type default null,
      p_fee_code_in             IN     transactionlog.feecode%TYPE default null,
      p_tranfee_amt_in          IN     transactionlog.tranfee_amt%TYPE default null,
      p_fee_plan_in             IN     transactionlog.fee_plan%TYPE default null,
      p_fee_attachtype_in       IN     transactionlog.feeattachtype%TYPE default null
  );
END;


/
show error;