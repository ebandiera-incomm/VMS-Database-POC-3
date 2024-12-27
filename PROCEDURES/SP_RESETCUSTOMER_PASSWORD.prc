create or replace PROCEDURE        VMSCMS.sp_resetcustomer_password (
   p_inst_code          IN       NUMBER,
   p_pan_code           IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_rrn                IN       VARCHAR2,
   p_password           IN       VARCHAR2,
   p_txn_mode           IN       VARCHAR2,
   p_tran_date          IN       VARCHAR2,
   p_tran_time          IN       VARCHAR2,
   p_ipaddress          IN       VARCHAR2,
   p_curr_code          IN       VARCHAR2,
   p_rvsl_code          IN       VARCHAR2,
   p_bank_code          IN       VARCHAR2,
   p_msg                IN       VARCHAR2,
   p_mbrnumb            IN       VARCHAR2,
   p_stan               IN       VARCHAR2,
   p_call_id            IN       NUMBER,
   p_ins_user           IN       NUMBER,
   p_remark             IN       VARCHAR2,
   p_resp_code          OUT      VARCHAR2,
   p_resmsg             OUT      VARCHAR2
)
AS
/*******************************************************************************
  * VERSION          :  1.0
  * Created Date     : 09/May/2012
  * Created By       : Dhiraj G.
  * PURPOSE          : Reset Password
  * Modified By      : Amit Sonar
  * Modified Reason  : Log ipaddress,lupduser,remark,cr-dr flag in tranactionlog table.
  * Modified Date    : 03-Oct-2012
  * Reviewer         : B.Besky Anand
  * Reviewed Date    : 03-Oct-2012
  * Build Number     : CMS3.5.1_RI0021
  
  * Modified By      : Dnyaneshwar J
  * Modified Reason  : 0011696: Defect : Incomm : Proper response id not logged in case for CSR Reset online password transaction 
  * Modified Date    : 22-July-2013
  * Reviewer         : 
  * Reviewed Date    : 
  * Build Number     : RI0024.3_B0005


       * Modified By      : Akhil
      * Modified Date    : 24-jan-2018
      * Purpose          : VMS-162
      * Reviewer         : Saravanakumar
      * Build Number     : VMSGPRHOST_18.1
****************************************************************************/
   v_tran_date              DATE;
   v_auth_savepoint         NUMBER                                  DEFAULT 0;
   v_rrn_count              NUMBER;
   v_errmsg                 VARCHAR2 (500);
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan_from          cms_appl_pan.cap_pan_code_encr%TYPE;
   v_cust_code              cms_pan_acct.cpa_cust_code%TYPE;
   v_spnd_acct_no           cms_acct_mast.cam_acct_no%TYPE;
   v_txn_type               transactionlog.txn_type%TYPE;
   v_cust_name              cms_cust_mast.ccm_user_name%TYPE;
   v_card_expry             VARCHAR2 (20);
   v_stan                   VARCHAR2 (20);
   v_capture_date           DATE;
   v_term_id                VARCHAR2 (20);
   v_mcc_code               VARCHAR2 (20);
   v_txn_amt                NUMBER;
   v_acct_number            NUMBER;
   v_auth_id                transactionlog.auth_id%TYPE;
   v_cust_id                cms_cust_mast.ccm_cust_id%TYPE;
   v_startercard_flag       cms_appl_pan.cap_startercard_flag%TYPE;
   v_card_stat              cms_appl_pan.cap_card_stat%TYPE;
   v_count                  NUMBER;
   v_hash_password          VARCHAR2 (100);
   v_hash_oldpassword       VARCHAR2 (100);
   v_oldpwdhash             VARCHAR2 (100);
   v_cardstat               NUMBER (5);
   exp_auth_reject_record   EXCEPTION;
   exp_reject_record        EXCEPTION;
   v_cap_cust_code          cms_appl_pan.cap_cust_code%TYPE;
   v_dr_cr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_output_type            cms_transaction_mast.ctm_output_type%TYPE;
   v_tran_type              cms_transaction_mast.ctm_tran_type%TYPE;
   v_ccs_card_status        cms_cardissuance_status.ccs_card_status%TYPE;
   v_call_seq               cms_calllog_details.ccd_call_seq%TYPE;
   v_ccm_user_name          cms_cust_mast.ccm_user_name%TYPE;
   v_ccm_password_hash      cms_cust_mast.ccm_password_hash%TYPE;
   v_spnd_acctno            cms_appl_pan.cap_acct_no%TYPE;
                                              -- ADDED BY GANESH ON 19-JUL-12
    v_trans_desc             CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
    v_resp_code              VARCHAR2 (5);
    v_prod_code cms_appl_pan.cap_prod_code%type;
    v_card_type cms_appl_pan.cap_card_type%type;
    v_encrypt_enable cms_prod_cattype.cpc_encrypt_enable%type;
    v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
    
BEGIN
   BEGIN
      v_hash_pan := gethash (p_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      v_encr_pan_from := fn_emaps_main (p_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_code := '12';
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

  BEGIN
      SELECT ctm_credit_debit_flag, ctm_output_type,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
             ctm_tran_type,CTM_TRAN_DESC
        INTO v_dr_cr_flag, v_output_type,
             v_txn_type,
             v_tran_type,v_trans_desc
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delivery_channel
         AND ctm_inst_code = p_inst_code;
  EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE exp_reject_record;
      WHEN NO_DATA_FOUND
      THEN
         v_resp_code := '21';
         v_errmsg := 'Not a valid transaction code for Reset user password';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_errmsg :=
                   'Error while selecting transaction codedetails' || SQLERRM;
         RAISE exp_reject_record;
  END;

   BEGIN
   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN

      SELECT COUNT (1)
        INTO v_rrn_count
        FROM transactionlog
       WHERE instcode = p_inst_code
         AND customer_card_no = v_hash_pan
         AND rrn = p_rrn
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND business_date = p_tran_date
         AND business_time = p_tran_time;
ELSE
		SELECT COUNT (1)
        INTO v_rrn_count
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
       WHERE instcode = p_inst_code
         AND customer_card_no = v_hash_pan
         AND rrn = p_rrn
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND business_date = p_tran_date
         AND business_time = p_tran_time;
END IF;		 

      IF v_rrn_count > 0
      THEN
         v_resp_code := '22';
         v_errmsg := 'Duplicate RRN on ' || p_tran_date;
         RAISE exp_reject_record;
      END IF;
   END;

   BEGIN
      v_tran_date :=
         TO_DATE (   SUBSTR (TRIM (p_tran_date), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_tran_time), 1, 8),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_errmsg :=
               'Problem while converting transaction date '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

 

   BEGIN
      v_hash_password := gethash (TRIM (p_password));
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_code := '12';
         v_errmsg :=
               'Error while converting password ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cap_card_stat, cap_cust_code,cap_prod_code,cap_card_type
        INTO v_cardstat, v_cap_cust_code,v_prod_code,v_card_type
        FROM cms_appl_pan
       WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_code := '16';
         v_errmsg := 'Card number not found ' || p_pan_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_errmsg :=
            'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   BEGIN
        SELECT cpc_encrypt_enable
          INTO v_encrypt_enable
          FROM cms_prod_cattype
         WHERE cpc_inst_code=p_inst_code
         and cpc_prod_code=v_prod_code
         and cpc_card_type=v_card_type;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_errmsg :=
            'Problem while selecting prod cattype' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --
   BEGIN
      SELECT decode(v_encrypt_enable,'Y',fn_dmaps_main(ccm_user_name),ccm_user_name),
      ccm_password_hash
        INTO v_ccm_user_name, v_ccm_password_hash
        FROM cms_cust_mast
       WHERE ccm_inst_code = p_inst_code AND ccm_cust_code = v_cap_cust_code;

      IF v_ccm_user_name IS NULL OR v_ccm_password_hash IS NULL
      THEN
         v_resp_code := '22';
         v_errmsg := 'Customer Not Registered';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_resp_code := '16';
         v_errmsg := 'Customer Code not found For ' || p_pan_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_errmsg :=
               'Problem while Fetching Customer Data '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --
   BEGIN
      SELECT ccs_card_status
        INTO v_ccs_card_status
        FROM cms_cardissuance_status
       WHERE ccs_pan_code = v_hash_pan;
       
   EXCEPTION WHEN NO_DATA_FOUND
      THEN
         v_resp_code := '89';
         v_errmsg :=
                    'Card Number Not Found In CardIssuence :- ' || v_hash_pan;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_errmsg :=
               'Error while selecting card number from CardIssuence  '
            || v_hash_pan
            || ' '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   IF v_ccs_card_status <> '15'
   THEN
      v_resp_code := '146';--Changed by Dnyaneshwar J on 22 July 2013 Mantis-0011696
      v_errmsg := 'Not valid Card application status for Reset Password';
      RAISE exp_reject_record;
   END IF;

   BEGIN
      sp_authorize_txn_cms_auth (p_inst_code,
                                 p_msg,
                                 p_rrn,
                                 p_delivery_channel,
                                 v_term_id,
                                 p_txn_code,
                                 p_txn_mode,
                                 p_tran_date,
                                 p_tran_time,
                                 p_pan_code,
                                 p_bank_code,
                                 v_txn_amt,
                                 NULL,
                                 NULL,
                                 NULL,
                                 p_curr_code,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 p_stan,
                                 p_mbrnumb,
                                 p_rvsl_code,
                                 NULL,
                                 v_auth_id,
                                 p_resp_code,
                                 p_resmsg,
                                 v_capture_date
                                );

      IF p_resp_code <> '00' AND p_resmsg <> 'OK'
      THEN
         --v_resp_code := '21';
         --v_errmsg := 'Error from auth process' || v_errmsg;
         --RAISE exp_auth_reject_record;
         
         Return;
         
      END IF;
      
   EXCEPTION WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      UPDATE cms_cust_mast
         SET ccm_password_hash = v_hash_password
       WHERE ccm_inst_code = p_inst_code AND ccm_cust_code = v_cap_cust_code;

      IF SQL%ROWCOUNT = 0
      THEN
         v_resp_code := '21';
         v_errmsg := 'Not udpated new password ';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_errmsg :=
               'Error from while updating new password '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   v_resp_code := '1';
   v_errmsg := 'SUCCESS';

   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code
         AND cms_delivery_channel = p_delivery_channel
         AND cms_response_id = v_resp_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_code := '21';
         v_errmsg := 'Responce code not found ' || p_resp_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_code := '69';
         v_errmsg :=
               'Problem while selecting data from response master '
            || p_resp_code
            || SUBSTR (SQLERRM, 1, 300);
   END;

-- SN : ADDED BY Ganesh on 18-JUL-12
   BEGIN
      SELECT cap_acct_no
        INTO v_spnd_acctno
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan
         AND cap_inst_code = p_inst_code
         AND cap_mbr_numb = p_mbrnumb;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_code := '21';
         v_errmsg :=
              'Spending Account Number Not Found For the Card in PAN Master ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_errmsg :=
               'Error While Selecting Spending account Number for Card '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_reject_record;
   END;

-- EN : ADDED BY Ganesh on 18-JUL-12
   BEGIN
      BEGIN
         SELECT NVL (MAX (ccd_call_seq), 0) + 1
           INTO v_call_seq
           FROM cms_calllog_details
          WHERE ccd_inst_code = ccd_inst_code
            AND ccd_call_id = p_call_id
            AND ccd_pan_code = v_hash_pan;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'record is not present in cms_calllog_details  ';
            v_resp_code := '49';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting frmo cms_calllog_details '
               || SUBSTR (SQLERRM, 1, 100);
            v_resp_code := '21';
            RAISE exp_reject_record;
      END;

      INSERT INTO cms_calllog_details
                  (ccd_inst_code, ccd_call_id, ccd_pan_code, ccd_call_seq,
                   ccd_rrn, ccd_devl_chnl, ccd_txn_code, ccd_tran_date,
                   ccd_tran_time, ccd_tbl_names, ccd_colm_name,
                   ccd_old_value, ccd_new_value, ccd_comments, ccd_ins_user,
                   ccd_ins_date, ccd_lupd_user, ccd_lupd_date,
                   ccd_acct_no   -- CCD_ACCT_NO ADDED BY GANESH ON 18-JUL-2012
                  )
           VALUES (p_inst_code, p_call_id, v_hash_pan, v_call_seq,
                   p_rrn, p_delivery_channel, p_txn_code, p_tran_date,
                   p_tran_time, NULL, NULL,
                   NULL, NULL, p_remark, p_ins_user,
                   SYSDATE, p_ins_user, SYSDATE,
                   v_spnd_acctno
                               -- V_SPND_ACCTNO ADDED BY GANESH ON 18-JUL-2012
                  );
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_resp_code := '21';
         v_errmsg :=
               ' Error while inserting into cms_calllog_details '
            || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_reject_record;
   END;
   
   ---Sn to log ipaddress,lupduser and remark in transaction log table for successful record. added by amit on 06-Oct-2012 
   BEGIN 
   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
         UPDATE transactionlog
            SET remark = p_remark,
                ipaddress = p_ipaddress,
                add_lupd_user = p_ins_user
          WHERE instcode = p_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = p_rrn
            AND business_date = p_tran_date
            AND business_time = p_tran_time
            AND delivery_channel = p_delivery_channel
            AND txn_code = p_txn_code;
ELSE
		UPDATE 
VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
            SET remark = p_remark,
                ipaddress = p_ipaddress,
                add_lupd_user = p_ins_user
          WHERE instcode = p_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = p_rrn
            AND business_date = p_tran_date
            AND business_time = p_tran_time
            AND delivery_channel = p_delivery_channel
            AND txn_code = p_txn_code;
END IF;			

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_code := '21';
            v_errmsg :=
                     'Txn not updated in transactiolog for remark,ipaddress and lupduser';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_code := '21';
            v_errmsg :=
                  'Error while updating into transactiolog '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   ---En to log ipaddress,lupduser and remark in transaction log table for successful record.
EXCEPTION
   WHEN exp_reject_record
   THEN
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_resp_code;

         p_resmsg := v_errmsg;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resmsg :=
                  'Problem while selecting data from response master '
               || p_resp_code
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
      END;

      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr, customer_acct_no,
                      error_msg, ipaddress, add_ins_date, add_ins_user,
                      cardstatus,trans_desc,response_id,
                      auth_id, -- Added by sagar on 03-10-2012
                      remark,  --added by amit on 06-Oct-2012 to log remark
                      add_lupd_user, --added by amit on 06-Oct-2012 to log lupd user
                      cr_dr_flag --added by amit on 06-Oct-2012 to log cr-dr flag
                     )
              VALUES (p_msg, p_rrn, p_delivery_channel, TO_DATE (p_tran_date || ' ' || p_tran_time,'yyyymmdd hh24miss'), p_txn_code,
                      v_txn_type, p_txn_mode, 'F', p_resp_code,
                      p_tran_date, p_tran_time, v_hash_pan,
                      p_inst_code, v_encr_pan_from, v_spnd_acct_no,
                      v_errmsg, p_ipaddress, SYSDATE, 1,
                      v_cardstat,v_trans_desc,v_resp_code,
                      v_auth_id, -- Added by sagar on 03-10-2012
                      p_remark, --added by amit on 06-Oct-2012 to log remark
                      p_ins_user, --added by amit on 06-Oct-2012 to log lupd user
                      v_dr_cr_flag --added by amit on 06-Oct-2012 to log cr-dr flag
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '21';
            p_resmsg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
            RETURN;
      END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_fee_amount,
                      ctd_waiver_amount, ctd_servicetax_amount,
                      ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_ins_date, ctd_ins_user,
                      ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                      ctd_cust_acct_number, ctd_addr_verify_response
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_txn_mode, p_tran_date, p_tran_time,
                      v_hash_pan, NULL,
                      NULL, NULL,
                      NULL, 'E', v_errmsg,
                      p_rrn, p_inst_code, SYSDATE, 1,
                      v_encr_pan_from, '000', '',
                      v_spnd_acct_no, ''
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
            RETURN;
      END;
   WHEN OTHERS
   THEN
      v_resp_code := '21';
      v_errmsg := 'Main Exception ' || SQLCODE || '---' || SQLERRM;

      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_resp_code;

         p_resmsg := v_errmsg;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resmsg :=
                  'Problem while selecting data from response master '
               || p_resp_code
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
      END;

      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr, customer_acct_no,
                      error_msg, ipaddress, add_ins_date, add_ins_user,
                      cardstatus,trans_desc,response_id,
                      auth_id, -- Added by sagar on 03-10-2012
                      remark,  --added by amit on 06-Oct-2012 to log remark
                      add_lupd_user, --added by amit on 06-Oct-2012 to log lupd user
                      cr_dr_flag --added by amit on 06-Oct-2012 to log cr-dr flag
                     )
              VALUES (p_msg, p_rrn, p_delivery_channel, TO_DATE (p_tran_date || ' ' || p_tran_time,'yyyymmdd hh24miss'), p_txn_code,
                      v_txn_type, p_txn_mode, 'F', p_resp_code,
                      p_tran_date, p_tran_time, v_hash_pan,
                      p_inst_code, v_encr_pan_from, v_spnd_acct_no,
                      v_errmsg, p_ipaddress, SYSDATE, p_ins_user,
                      v_cardstat,v_trans_desc,v_resp_code,
                      v_auth_id, -- Added by sagar on 03-10-2012
                      p_remark, --added by amit on 06-Oct-2012 to log remark
                      p_ins_user, --added by amit on 06-Oct-2012 to log lupd user
                      v_dr_cr_flag --added by amit on 06-Oct-2012 to log cr-dr flag
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            p_resmsg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
            RETURN;
      END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_fee_amount,
                      ctd_waiver_amount, ctd_servicetax_amount,
                      ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_ins_date, ctd_ins_user,
                      ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                      ctd_cust_acct_number, ctd_addr_verify_response
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_txn_mode, p_tran_date, p_tran_time,
                      v_hash_pan, NULL,
                      NULL, NULL,
                      NULL, 'E', v_errmsg,
                      p_rrn, p_inst_code, SYSDATE, 1,
                      v_encr_pan_from, '000', '',
                      v_spnd_acct_no, ''
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '89';
            RETURN;
      END;
END;
/
SHOW ERROR;