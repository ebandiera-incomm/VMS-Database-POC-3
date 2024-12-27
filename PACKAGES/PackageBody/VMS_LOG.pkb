create or replace
PACKAGE BODY               vmscms.VMS_LOG
IS
   -- Private type declarations
   -- Private constant declarations
   -- Private variable declarations
   -- Function and procedure implementations
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
	    p_api_partner_id_in       IN     transactionlog.req_partner_id%TYPE,
      p_resp_msg_out            OUT    VARCHAR2,
      p_return_recievedDate_in  in    transactionlog.IMPDATE%type default null,
      p_return_Reason_in    in    transactionlog.REASON%type default null,
      p_return_filename_in   in  transactionlog.RETURNACHFILENAME%type default null
      )
   AS
   /*---------------------------------------------------------------------------------------
      * Modified By      :  Siva Kumar M
      * Modified Date    :  03-Sep-2018
      * Modified Reason  :  VMS-520
      * Reviewer         :  Saravana Kumar 
      * Reviewed Date    :  03-Sep-2018
      * Build Number     : VMSGPRHOST_R05_B0006
 
-----------------------------------------------------------------------------------------*/
   BEGIN
         p_resp_msg_out := 'OK';
      BEGIN
         INSERT INTO transactionlog (instcode,
                                     msgtype,
                                     rrn,
                                     delivery_channel,
                                     txn_code,
                                     date_time,
                                     txn_type,
                                     txn_mode,
                                     txn_status,
                                     business_date,
                                     business_time,
                                     reversal_code,
                                     customer_card_no,
                                     customer_card_no_encr,
                                     error_msg,
                                     add_ins_date,
                                     add_ins_user,
                                     cardstatus,
                                     trans_desc,
                                     time_stamp,
                                     ipaddress,
                                     ani,
                                     dni,
                                     customer_acct_no,
                                     productid,
                                     categoryid,
                                     cr_dr_flag,
                                     acct_balance,
                                     ledger_balance,
                                     acct_type,
                                     proxy_number,
                                     auth_id,
                                     amount,
                                     total_amount,
                                     feecode,
                                     tranfee_amt,
                                     fee_plan,
                                     feeattachtype,
                                     response_id,
                                     response_code,
                                     currencycode,
                                     add_lupd_user,
                                     uuid,
                                     os_name,
                                     os_version,
                                     gps_coordinates,
                                     display_resolution,
                                     physical_memory,
                                     app_name,
                                     app_version,
                                     session_id,
                                     device_country,
                                     device_region,
                                     ip_country,
                                     proxy_flag,
									 REQ_PARTNER_ID,
									 TRAN_REVERSE_FLAG,
									 IMPDATE,REASON,
									 RETURNACHFILENAME)
              VALUES (
                        p_inst_code_in,
                        p_msg_type_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_txn_code_in,
                        SYSDATE,
                        p_txn_type_in,
                        p_txn_mode_in,
                        DECODE (p_resp_code_in, '00', 'C', 'F'),
                        p_tran_date_in,
                        p_tran_time_in,
                        p_rvsl_code_in,
                        p_hash_pan_in,
                        p_encr_pan_in,
                        DECODE (p_resp_code_in, '00', 'Success', p_err_msg_in),
                        SYSDATE,
                        1,
                        p_card_stat_in,
                        p_trans_desc_in,
                        p_time_stamp_in,
                        p_ip_addr_in,
                        p_ani_in,
                        p_dni_in,
                        p_acct_no_in,
                        p_prod_code_in,
                        p_card_type_in,
                        p_drcr_flag_in,
                        p_acct_bal_in,
                        p_ledger_bal_in,
                        p_acct_type_in,
                        p_proxy_number_in,
                        p_auth_id_in,
                        TRIM (
                           TO_CHAR (NVL (p_amount_in, 0),
                                    '99999999999999990.99')),
                        TRIM (
                           TO_CHAR (NVL (p_total_amount_in, 0),
                                    '99999999999999990.99')),
                        p_fee_code_in,
                        TRIM (
                           TO_CHAR (NVL (p_tranfee_amt_in, 0),
                                    '99999999999999990.99')),
                        p_fee_plan_in,
                        p_fee_attachtype_in,
                        DECODE (p_resp_code_in, '00', '1', p_resp_id_in),
                        p_resp_code_in,
                        p_curr_code_in,
                        1,
                        p_uuid_in,
                        p_os_name_in,
                        p_os_version_in,
                        p_gps_coordinates_in,
                        p_display_resolution_in,
                        p_physical_memory_in,
                        p_app_name_in,
                        p_app_version_in,
                        p_session_id_in,
                        p_device_country_in,
                        p_device_region_in,
                        p_ip_country_in,
                        p_proxy_flag_in,
						p_api_partner_id_in,
						'N',
						p_return_recievedDate_in,
						p_return_Reason_in,
						p_return_filename_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Problem while inserting data into transaction log  '
               || SUBSTR (SQLERRM, 1, 300);
      END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl (ctd_inst_code,
                                              ctd_msg_type,
                                              ctd_rrn,
                                              ctd_delivery_channel,
                                              ctd_txn_code,
                                              ctd_txn_type,
                                              ctd_txn_mode,
                                              ctd_business_date,
                                              ctd_business_time,
                                              ctd_customer_card_no,
                                              ctd_customer_card_no_encr,
                                              ctd_process_msg,
                                              ctd_process_flag,
                                              ctd_ins_date,
                                              ctd_ins_user,
                                              ctd_hashkey_id,
                                              ctd_auth_id,
                                              ctd_txn_amount,
                                              ctd_cust_acct_number)
              VALUES (p_inst_code_in,
                      p_msg_type_in,
                      p_rrn_in,
                      p_delivery_channel_in,
                      p_txn_code_in,
                      p_txn_type_in,
                      p_txn_mode_in,
                      p_tran_date_in,
                      p_tran_time_in,
                      p_hash_pan_in,
                      p_encr_pan_in,
                     DECODE (p_resp_code_in, '00', 'Success', p_err_msg_in),
                      DECODE (p_resp_code_in, '00', 'C', 'F'),
                      SYSDATE,
                      1,
                      p_hashkey_id_in,
                      p_auth_id_in,
                      p_amount_in,
                      p_acct_no_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Problem while inserting data into log dtl '
               || SUBSTR (SQLERRM, 1, 300);
      END;


   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_msg_out := 'Error in main ' || SUBSTR (SQLERRM, 1, 300);
   END log_transactionlog;

   PROCEDURE log_transactionlog_audit (
      p_msg_type_in             IN     transactionlog_audit.msgtype%TYPE,
      p_rrn_in                  IN     transactionlog_audit.rrn%TYPE,
      p_delivery_channel_in     IN     transactionlog_audit.delivery_channel%TYPE,
      p_txn_code_in             IN     transactionlog_audit.txn_code%TYPE,
      p_txn_mode_in             IN     transactionlog_audit.txn_mode%TYPE,
      p_tran_date_in            IN     transactionlog_audit.business_date%TYPE,
      p_tran_time_in            IN     transactionlog_audit.business_time%TYPE,
      p_rvsl_code_in            IN     transactionlog_audit.reversal_code%TYPE,
      p_pan_in             IN     transactionlog_audit.customer_card_no%TYPE,
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
      )
   AS

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
    V_TXN_TYPE              TRANSACTIONLOG.TXN_TYPE%TYPE;
	V_CR_DR_FLAG			CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
	V_TRAN_TYPE				CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
	V_RESPONSE_CODE			TRANSACTIONLOG_AUDIT.RESPONSE_CODE%TYPE;
    V_API_PARTNER_ID_IN     CMS_PRODUCT_PARAM.CPP_PARTNER_ID%TYPE;
    --SN: Added for VMS-6071
	v_toggle_value  cms_inst_param.cip_param_value%TYPE;
	v_prd_chk       NUMBER :=0;
   --EN: Added for VMS-6071
BEGIN
    P_RESP_MSG_OUT  := 'OK';
    V_TIMESTAMP 	:= SYSTIMESTAMP;

	BEGIN
        --SN CREATE HASH PAN
        BEGIN
            V_HASH_PAN := GETHASH (P_PAN_IN);
        EXCEPTION
            WHEN OTHERS
            THEN
                P_RESP_MSG_OUT := 'ERROR WHILE CONVERTING PAN ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --EN CREATE HASH PAN

        --SN CREATE ENCR PAN
        BEGIN
            V_ENCR_PAN := FN_EMAPS_MAIN (P_PAN_IN);
        EXCEPTION
            WHEN OTHERS
            THEN
                P_RESP_MSG_OUT := 'ERROR WHILE CONVERTING PAN ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        --EN CREATE ENCR PAN

        BEGIN
            V_HASHKEY_ID :=
                GETHASH (
                        P_DELIVERY_CHANNEL_IN
                     || P_TXN_CODE_IN
                     || P_PAN_IN
                     || P_RRN_IN
                     || TO_CHAR (V_TIMESTAMP, 'YYYYMMDDHH24MISSFF5'));
        EXCEPTION
            WHEN OTHERS
            THEN
                P_RESP_MSG_OUT := 'ERROR WHILE CONVERTING MASTER DATA '|| SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

		BEGIN
            SELECT CTM_TRAN_DESC,CTM_CREDIT_DEBIT_FLAG,DECODE (CTM_TRAN_TYPE,  'N', '0',  'F', '1')
              INTO V_TRANS_DESC,V_CR_DR_FLAG,V_TRAN_TYPE
              FROM CMS_TRANSACTION_MAST
             WHERE      CTM_TRAN_CODE = P_TXN_CODE_IN
                     AND CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL_IN
                     AND CTM_INST_CODE = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN                     
                P_RESP_MSG_OUT :=
                        'Transflag  not defined for txn code '
                    || P_TXN_CODE_IN
                    || ' and delivery channel '
                    || P_DELIVERY_CHANNEL_IN;
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                P_RESP_MSG_OUT :=
                    'Error while selecting transflag ' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

		--SN GENERATE AUTH ID
        BEGIN
            SELECT LPAD (SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;
        EXCEPTION
            WHEN OTHERS
            THEN
                P_RESP_MSG_OUT :=
                    'ERROR WHILE GENERATING AUTHID ' || SUBSTR (SQLERRM, 1, 300);
                RAISE EXP_REJECT_RECORD;
        END;

        --EN GENERATE AUTH ID
        
        --SN GET DATE
        BEGIN
            V_TRAN_DATE :=
                TO_DATE (
                        SUBSTR (TRIM (P_TRAN_DATE_IN), 1, 8)
                    || ' '
                    || SUBSTR (TRIM (P_TRAN_TIME_IN), 1, 10),
                    'YYYYMMDD HH24:MI:SS');
        EXCEPTION
            WHEN OTHERS
            THEN
                P_RESP_MSG_OUT :=
                    'PROBLEM WHILE CONVERTING TRANSACTION DATE '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;
        --EN GET DATE

		BEGIN
            SELECT CAP_PROD_CODE, CAP_CARD_TYPE, CAP_CARD_STAT,CAP_PROXY_NUMBER, CAP_ACCT_NO
              INTO V_PROD_CODE, V_PROD_CATTYPE, V_APPLPAN_CARDSTAT,V_PROXUNUMBER, V_ACCT_NUMBER
              FROM CMS_APPL_PAN
             WHERE CAP_MBR_NUMB = '000' AND CAP_PAN_CODE = V_HASH_PAN;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                P_RESP_MSG_OUT := 'CARD NUMBER NOT FOUND ' || V_HASH_PAN;
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
                P_RESP_MSG_OUT :=
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
                AND CAM_INST_CODE = 1;
		EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                P_RESP_MSG_OUT := 'INVALID CARD ';
                RAISE EXP_REJECT_RECORD;
            WHEN OTHERS
            THEN
             
                P_RESP_MSG_OUT :='ERROR WHILE SELECTING DATA FROM CARD MASTER FOR CARD NUMBER ';

                RAISE EXP_REJECT_RECORD;
        END;
	
	EXCEPTION
		WHEN EXP_REJECT_RECORD THEN
			NULL;
		WHEN OTHERS THEN
			P_RESP_MSG_OUT := 'MAIN EXCEPTION - EXCEPTION WHILE INSERTING INTO AUDIT TRAN LOG '||SUBSTR (SQLERRM, 1, 200);
	END;	
    
       BEGIN
        IF P_API_PARTNER_ID_IN IS NULL THEN
        
            IF V_PROD_CODE IS NULL AND V_PROD_CATTYPE IS NULL THEN
               SELECT cpp_partner_id
                 INTO V_API_PARTNER_ID_IN
                 FROM cms_appl_pan, cms_product_param
                WHERE cap_pan_code = V_HASH_PAN
                  AND cpp_prod_code = cap_prod_code
                  AND cpp_inst_code = cap_inst_code;
            ELSE
               SELECT cpp_partner_id
                 INTO V_API_PARTNER_ID_IN
                 FROM cms_product_param
                WHERE cpp_prod_code = V_PROD_CODE
                  AND cpp_inst_code = V_PROD_CATTYPE;
            END IF;
        END IF;
         EXCEPTION
          WHEN OTHERS THEN
             NULL;
        END;
		
		BEGIN
                SELECT CMS_ISO_RESPCDE
                  INTO V_RESPONSE_CODE
                  FROM CMS_RESPONSE_MAST
                 WHERE      CMS_INST_CODE = 1
                         AND CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL_IN
                         AND CMS_RESPONSE_ID = P_RESP_ID_IN;

            EXCEPTION
                WHEN OTHERS
                THEN
                    P_RESP_MSG_OUT :=
                            'PROBLEM WHILE SELECTING DATA FROM RESPONSE MASTER '
                        || P_RESP_ID_IN
                        || SUBSTR (SQLERRM, 1, 300);
        END;
		
		BEGIN
			INSERT INTO TRANSACTIONLOG_AUDIT (
						MSGTYPE,
						RRN,
						DELIVERY_CHANNEL,
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
						ACCT_TYPE,
						TIME_STAMP,
						REMARK,
						ERROR_MSG,
						ADD_LUPD_USER,
						ADD_LUPD_DATE,
						CORRELATION_ID,
						FSAPI_USERNAME,
						IPADDRESS,
						PARTNER_ID,
                        HASHKEY_ID,
                        ANI,
                        DNI,                                            
                        TERMINAL_ID,
                        BANK_CODE,
                        ATM_NAME_LOCATION,
                        MERCHANT_NAME,
                        MERCHANT_CITY,
                        MERCHANT_STATE,
                        FEECODE,
                        TRANFEE_AMT,
                        FEE_PLAN,
                        FEEATTACHTYPE
					) VALUES (
						P_MSG_TYPE_IN,
						P_RRN_IN,
						P_DELIVERY_CHANNEL_IN,
						V_TRAN_DATE,
						P_TXN_CODE_IN,
						V_TRAN_TYPE,
						P_TXN_MODE_IN,
						P_TRAN_STATUS_in,
						V_RESPONSE_CODE,
						P_TRAN_DATE_IN,
						SUBSTR(P_TRAN_TIME_IN, 1, 10),
						V_HASH_PAN,
						TRIM(TO_CHAR(NVL(P_TOTAL_AMOUNT_IN, 0), '99999999999999990.99')),
						P_CURR_CODE_IN,
						V_PROD_CODE,
						V_PROD_CATTYPE,
						V_AUTH_ID,
						V_TRANS_DESC,
						TRIM(TO_CHAR(NVL(P_AMOUNT_IN, 0), '99999999999999990.99')),
						P_STAN_IN,
						1,
						V_CR_DR_FLAG,
						V_ENCR_PAN,
						V_PROXUNUMBER,
						0,
						V_ACCT_NUMBER,
						ROUND(V_ACCT_BALANCE, 2),
						ROUND(V_LEDGER_BAL, 2),
						P_RESP_ID_IN,
						SYSDATE,
						1,
						V_APPLPAN_CARDSTAT,
						V_CAM_TYPE_CODE,
						V_TIMESTAMP,
						P_REMARK_IN,
						P_ERR_MSG_IN,
						1,
						SYSDATE,
						P_CORRELATION_ID_IN,
						P_FSAPI_USERNAME_IN,
						P_IP_ADDR_IN,
						P_API_PARTNER_ID_IN,
                        V_HASHKEY_ID,
                        P_ANI_IN,
                        P_DNI_IN,
                        P_TERMINAL_ID_IN,
                        P_BANK_CODE_IN,
                        P_ATM_NAME_LOCATION_IN,
                        P_MERCHANT_NAME_IN,
                        P_MERCHANT_CITY_IN,
                        P_MERCHANT_STATE_IN,
                        P_FEE_CODE_IN,
                        P_TRANFEE_AMT_IN,
                        P_FEE_PLAN_IN,
                        P_FEE_ATTACHTYPE_IN);
		EXCEPTION
			WHEN OTHERS THEN
            P_RESP_MSG_OUT := 'Exception while inserting to transaction log audit'||SQLCODE||'---'||SQLERRM; 
		END;
        
        IF V_HASH_PAN IS NOT NULL THEN
        
         --SN: Added for VMS-6071
         BEGIN
          SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
            INTO v_toggle_value
            FROM cms_inst_param
           WHERE cip_inst_code = 1
             AND cip_param_key = 'VMS_5657_TOGGLE';
         EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
              v_toggle_value := 'Y';
         END;

         IF v_toggle_value = 'Y' THEN
           BEGIN
            SELECT COUNT(1)
              INTO v_prd_chk
              FROM vms_dormantfee_txns_config
             WHERE vdt_prod_code = v_prod_code
               AND vdt_card_type = v_prod_cattype
               AND vdt_is_active = 1;
           EXCEPTION
            WHEN OTHERS THEN
              NULL;
           END;
         END IF;
         --EN: Added for VMS-6071        
        
        BEGIN
        IF NOT (P_DELIVERY_CHANNEL_IN = '05' AND P_TXN_CODE_IN IN ('04','06','07','13', '16', '17', '18', '97')
                    OR (P_DELIVERY_CHANNEL_IN = '17' AND P_TXN_CODE_IN ='04'))
                AND v_prd_chk = 0 --Added for VMS-6071  
          THEN
          
             UPDATE CMS_APPL_PAN
                SET CAP_LAST_TXNDATE = SYSDATE
              WHERE CAP_PAN_CODE = V_HASH_PAN
                     AND TRUNC(NVL(CAP_LAST_TXNDATE,SYSDATE-1))<TRUNC(SYSDATE)
                     AND CAP_PROXY_NUMBER IS NOT NULL;
    
                                                                        
           END IF;
        EXCEPTION
            WHEN OTHERS THEN
            P_RESP_MSG_OUT := 'Exception while updating Last TXN Date in CMS_APPL_PAN Table'||SQLCODE||'---'||SQLERRM; 
        END;
        END IF;
        
EXCEPTION
WHEN OTHERS THEN
         P_RESP_MSG_OUT := 'Error in main ' || SUBSTR (SQLERRM, 1, 300);
END LOG_TRANSACTIONLOG_AUDIT;		

END;
/
show error;