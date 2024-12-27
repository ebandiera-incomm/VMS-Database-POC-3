create or replace
PROCEDURE        vmscms.sp_log_txnlog (
   p_inst_code          IN       transactionlog.instcode%TYPE,
   p_msg                IN       transactionlog.msgtype%TYPE,
   p_rrn                IN       transactionlog.rrn%TYPE,
   p_delivery_channel   IN       transactionlog.delivery_channel%TYPE,
   p_txn_code           IN       transactionlog.txn_code%TYPE,
   p_txn_type           IN       transactionlog.txn_type%TYPE,
   p_txn_mode           IN       transactionlog.txn_mode%TYPE,
   p_tran_date          IN       transactionlog.business_date%TYPE,
   p_tran_time          IN       transactionlog.business_time%TYPE,
   p_rvsl_code          IN       transactionlog.reversal_code%TYPE,
   p_hash_pan           IN       transactionlog.customer_card_no%TYPE,
   p_encr_pan           IN       transactionlog.customer_card_no_encr%TYPE,
   p_err_msg            IN       transactionlog.error_msg%TYPE,
   p_ip_addr            IN       transactionlog.ipaddress%TYPE,
   p_card_stat          IN       transactionlog.cardstatus%TYPE,
   p_trans_desc         IN       transactionlog.trans_desc%TYPE,
   p_ani                IN       transactionlog.ani%TYPE,
   p_dni                IN       transactionlog.dni%TYPE,
   p_time_stamp         IN       transactionlog.time_stamp%TYPE,
   p_acct_no            IN       transactionlog.customer_acct_no%TYPE,
   p_prod_code          IN       transactionlog.productid%TYPE,
   p_card_type          IN       transactionlog.categoryid%TYPE,
   p_drcr_flag          IN       transactionlog.cr_dr_flag%TYPE,
   p_acct_bal           IN       transactionlog.acct_balance%TYPE,
   p_ledger_bal         IN       transactionlog.ledger_balance%TYPE,
   p_acct_type          IN       transactionlog.acct_type%TYPE,
   p_proxy_number       IN       transactionlog.proxy_number%TYPE,
   p_auth_id            IN       transactionlog.auth_id%TYPE,
   p_amount             IN       transactionlog.amount%TYPE,
   p_total_amount       IN       transactionlog.amount%TYPE,
   p_fee_code           IN       transactionlog.feecode%TYPE,
   p_tranfee_amt        IN       transactionlog.tranfee_amt%TYPE,
   p_fee_plan           IN       transactionlog.fee_plan%TYPE,
   p_fee_attachtype     IN       transactionlog.feeattachtype%TYPE,
   p_resp_id            IN       transactionlog.response_id%TYPE,
   p_resp_code          IN       transactionlog.response_code%TYPE,
   p_curr_code          IN       transactionlog.currencycode%TYPE DEFAULT NULL,
   p_resp_msg           OUT      VARCHAR2,
   p_orgnl_rrn          IN       transactionlog.orgnl_rrn%TYPE DEFAULT NULL,
   v_match_rule         IN       transactionlog.match_rule%TYPE DEFAULT NULL, --Added for MYVIVR-73
   p_remarks            in       transactionlog.remark%TYPE DEFAULT NULL,
   p_reason             in       transactionlog.reason%TYPE DEFAULT NULL,
   p_reason_code        in       transactionlog.reason_code%TYPE DEFAULT NULL,
   p_addins_user        in       transactionlog.add_ins_user%TYPE DEFAULT 1,
   p_lupd_user          in       transactionlog.add_lupd_user%TYPE DEFAULT null,
   p_partnerid_in       in       transactionlog.partner_id%TYPE DEFAULT null, --Added for VP-177 of 3.3R
   p_req_partnerid_in   in       transactionlog.req_partner_id%TYPE DEFAULT null, --Added for FSS-4005
   p_stan_in            in       transactionlog.SYSTEM_TRACE_AUDIT_NO%TYPE DEFAULT null,
   p_ntw_settl_date     in       transactionlog.network_settl_date%TYPE DEFAULT null

)
AS
/**********************************************************************************************
                  * Created Date     :08-August-2014
                  * Created By       :  Dhinakaran B
                  * PURPOSE          : FWR-67

                  * Modified Date     :13-August-2014
                  * Modified By       :  Dhinakaran B
                  * PURPOSE          : FWR-67 & review changes &  MANTIS ID-15671

                  * Modified Date     :22-August-2014
                 * Modified By       :Dhinakaran B
                 * PURPOSE          : JH=3005
				 
				 * Modified Date     :01-September-2014
                 * Modified By       :MageshKumar S
                 * PURPOSE           : MYVIVR-73
			*Build              :RI0027.4_B0001
		
		 * Modified by       : Abdul Hameed M.A
   		 * Modified Date     : 23-June-15
   		 * Modified For      : FSS 1960
  		 * Reviewer          : Pankaj S
    		 * Build Number      : VMSGPRHOSTCSD_3.1_B0001	

		 * Modified by       : Abdul Hameed M.A
   		 * Modified Date     : 24-Aug-15
   		 * Modified For      : FSS-3589 
  		 * Reviewer          : Pankaj S
    		 * Build Number      : VMSGPRHOSTCSD_3.1_B0005	
		 		  
            
   * Modified by          :Siva Kumar M
   * Modified Date        : 05-JAN-16
   * Modified For         : MVHOST-1255
   * Modified reason      : reason code logging
   * Reviewer             : Saravans kumar 
   * Build Number         : RI0027.3.3_B0002
   
   * Created Date     :  07-DEC-2016
   * Created By       :  MAGESHKUMAR S
   * Created For      :  VP-177
   * Reviewer         :  Saravanakumar/SPankaj
   * Build Number     :  VMSGPRHOSTCSD_B00003
   
   * Modified by      : Ramesh A
   * Modified Date    : 27-Jan-2016
   * PURPOSE          : RDC
   * Review           : Saravana
   * Build Number     : 3.3.1
   
   * Created Date     :  06-Jun-2016
   * Created By       :  MAGESHKUMAR S
   * Created For      :  VISA Tokenization Changes
   * Reviewer         :  Saravanakumar/SPankaj
   * Build Number     :  VMSGPRHOSTCSD4.4_B00002

/**********************************************************************************************/
BEGIN
   INSERT INTO transactionlog
               (instcode, msgtype, rrn, delivery_channel, txn_code,
                date_time, txn_type, txn_mode,
                txn_status, business_date,
                business_time, reversal_code, customer_card_no,
                customer_card_no_encr, error_msg, ipaddress, add_ins_date,
                add_ins_user, cardstatus, trans_desc, time_stamp, ani, dni,
                customer_acct_no, productid, categoryid, cr_dr_flag,
                acct_balance, ledger_balance, acct_type, proxy_number,
                auth_id,
                amount,
                total_amount,
                feecode,
                TRANFEE_AMT,
                FEE_PLAN, FEEATTACHTYPE, RESPONSE_ID, RESPONSE_CODE,
                CURRENCYCODE, ORGNL_RRN,MATCH_RULE,REMARK --Added for MYVIVR-73
                ,REASON,ADD_LUPD_USER,REASON_CODE,PARTNER_ID,--Added for VP-177 of 3.3R
                req_partner_id,SYSTEM_TRACE_AUDIT_NO,network_settl_date                
               )
        VALUES (p_inst_code, p_msg, p_rrn, p_delivery_channel, p_txn_code,
                SYSDATE, p_txn_type, p_txn_mode,
                DECODE (p_resp_code, '00', 'C', 'F'), p_tran_date,
                p_tran_time, p_rvsl_code, p_hash_pan,
                p_encr_pan, p_err_msg, p_ip_addr, SYSDATE,
                nvl(p_addins_user,1), p_card_stat, p_trans_desc, p_time_stamp, p_ani, p_dni,
                p_acct_no, p_prod_code, p_card_type, p_drcr_flag,
                p_acct_bal, p_ledger_bal, p_acct_type, p_proxy_number,
                p_auth_id,
                TRIM (TO_CHAR (NVL (p_amount, 0), '99999999999999990.99')),
                TRIM (TO_CHAR (NVL (p_total_amount, 0),
                               '99999999999999990.99')
                     ),
                p_fee_code,
                TRIM (TO_CHAR (NVL (P_TRANFEE_AMT, 0), '99999999999999990.99')),
                p_fee_plan, p_fee_attachtype, p_resp_id, p_resp_code,
                P_CURR_CODE, P_ORGNL_RRN,V_MATCH_RULE,P_REMARKS --Added for MYVIVR-73
                ,SUBSTR(P_REASON, 0, 100),P_LUPD_USER,P_REASON_CODE,P_PARTNERID_IN, --Added for VP-177 of 3.3R
                p_req_partnerid_in,p_stan_in,p_ntw_settl_date
               );

   p_resp_msg := p_err_msg;
EXCEPTION
   WHEN OTHERS
   THEN
      p_resp_msg :=
            p_err_msg
         || 'Problem while inserting data into transaction log  '
         || SUBSTR (SQLERRM, 1, 300);
END; 
/
show error