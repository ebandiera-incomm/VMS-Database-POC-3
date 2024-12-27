CREATE OR REPLACE PROCEDURE VMSCMS.SP_CHW_CARD_TO_CARD_FEE_AMT (
   p_instcode           IN       NUMBER,
   p_msg                IN       VARCHAR2,
   p_cardnum            IN       VARCHAR2,
   p_rrn                IN       VARCHAR2,
   p_trandate           IN       VARCHAR2,
   p_trantime           IN       VARCHAR2,
   p_ipaddress          IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_tran_mode          IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   P_CURR_CODE          in       varchar2,
   p_resp_code          OUT      VARCHAR2,
   p_resp_msg           OUT      VARCHAR2,
   p_feeamount          OUT      VARCHAR2
)
AS
   /*************************************************************************
      * Created by       : Sankar
      * Created Date     : 20-AUG-2013
      * Created for      : FWR-36
      * Created reason   : Prompt for Amount Available to Transfer
      * Reviewer         : Sachin P
      * Reviewed Date    : 23-AUG-2013
      * Build Number     :

      * Modified by       : Sankar
      * Modified Date     : 29-AUG-2013
      * Modified for      : 0012205
      * Modified reason   : Transaction configuration based
                            on card status as Decline is successfully processed
      * Reviewer          : Sachin P.
      * Reviewed Date     : 02-SEP-2013
      * Build Number      : RI0024.4_B0006

      * Modified by       : Shweta
      * Modified Date     : 12-SEP-2013
      * Modified for      : 12279
      * Modified reason   : To log txn_status value as 'C' for successful transaction in transactionlog table.
      * Reviewer          : Dhiraj
      * Reviewed Date     : 12-SEP-2013
      * Build Number      : RI0024.4_B0010

      * Modified Date    : 10-Dec-2013
      * Modified By      : Sagar More
      * Modified for     : Defect ID 13160
      * Modified reason  : To log below details in transactinlog if applicable
                           Tranfee amt with nvl function
      * Reviewer         : Dhiraj
      * Reviewed Date    : 10-Dec-2013
      * Release Number   : RI0024.7_B0001

      * Modified by       : Abdul Hameed M.A
     * Modified for      : Mantis ID 13641
     * Modified Reason   : to log tranfee amt as o because fee is not applicable for this tranmsaction
     * Modified Date     : 08-Jul-2014
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3_B0003
     
    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-15-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
     ***************************************************************************/
   v_resp_cde          VARCHAR2 (3);
   v_err_msg           VARCHAR (900);
   exp_reject_record   EXCEPTION;
   v_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
   v_rrn_count         NUMBER;
   v_trandatetime      DATE;
   v_dr_cr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_txn_type          cms_transaction_mast.ctm_tran_type%TYPE         := '1';
   v_tran_type         cms_transaction_mast.ctm_tran_type%TYPE;
   v_trans_desc        cms_transaction_mast.ctm_tran_desc%TYPE;
   v_auth_id           NUMBER;
   v_cardstat          cms_appl_pan.cap_card_stat%TYPE;
   v_prodcode          cms_appl_pan.cap_prod_code%TYPE;
   v_cardtype          cms_appl_pan.cap_card_type%TYPE;
   v_acct_no           cms_appl_pan.cap_acct_no%TYPE;
   v_acct_bal          cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
   v_acct_type         cms_acct_mast.cam_type_code%TYPE;
   v_timestamp         TIMESTAMP;
   v_count             NUMBER;
   v_curr_code         transactionlog.currencycode%TYPE;
   v_fee_desc          cms_fee_mast.cfm_fee_desc%TYPE;
   v_feeflag           VARCHAR2 (1 BYTE);
   v_avail_bal         cms_acct_mast.cam_acct_bal%TYPE;
   v_clawback_flag     cms_fee_mast.cfm_clawback_flag%TYPE;
   v_cardexp           cms_appl_pan.cap_expry_date%TYPE;  --Added on 29.08.2013 for Mentis id 0012205
   v_status_chk        NUMBER;  --Added on 29.08.2013 for Mentis id 0012205
   v_precheck_flag     pcms_tranauth_param.ptp_param_value%TYPE;  --Added on 29.08.2013 for Mentis id 0012205
    v_Retperiod  date;  --Added for VMS-5733/FSP-991
    v_Retdate  date; --Added for VMS-5733/FSP-991
   BEGIN
   --p_resp_code := '00';
   v_curr_code := p_curr_code;
   --v_resp_cde := '00';
   v_resp_cde := '1'; --Modified by Shweta for 12279 on 12-SEP-2013
   p_feeamount := 0;
   v_err_msg := 'OK';

   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (p_cardnum);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --EN CREATE HASH PAN
   --SN create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (p_cardnum);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --EN create encr pan
   --Sn get Date
   BEGIN
      v_trandatetime :=
         TO_DATE (   SUBSTR (TRIM (p_trandate), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_trantime), 1, 8),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
               'Problem while converting transaction date '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En get Date
   --Sn find debit and credit flag
   BEGIN
      SELECT ctm_credit_debit_flag,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
             ctm_tran_type, ctm_tran_desc
        INTO v_dr_cr_flag,
             v_txn_type,
             v_tran_type, v_trans_desc
        FROM cms_transaction_mast
       WHERE ctm_inst_code = p_instcode
         AND ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delivery_channel;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '12';
         v_err_msg :=
               'Transflag  not defined for txn code '
            || p_txn_code
            || ' and delivery channel '
            || p_delivery_channel;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg := 'Error while selecting transaction details';
         RAISE exp_reject_record;
   END;

   --En find debit and credit flag
   --Sn Duplicate RRN Check
   BEGIN
   
   --Added for VMS-5733/FSP-991
          select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');
      
  IF ( v_Retdate>v_Retperiod) --Added for VMS-5733/FSP-991
    THEN
      SELECT COUNT (1)
        INTO v_rrn_count
        FROM transactionlog
       WHERE rrn = p_rrn
         AND business_date = p_trandate
         AND delivery_channel = p_delivery_channel;      
    ELSE
        SELECT COUNT (1) --Added for VMS-5733/FSP-991
        INTO v_rrn_count
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST
       WHERE rrn = p_rrn
         AND business_date = p_trandate
         AND delivery_channel = p_delivery_channel;
    END IF;     
         IF v_rrn_count > 0
      THEN
         v_resp_cde := '22';
         v_err_msg := 'Duplicate RRN Number on ' || p_trandate;
         RAISE exp_reject_record;
  END IF;       
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
            'Error while checking  duplicate RRN-'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Duplicate RRN Check
   --Sn Generating authid
   BEGIN
      SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
        INTO v_auth_id
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   --En Generating authid
   BEGIN
      SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
             cap_expry_date
        INTO v_cardstat, v_prodcode, v_cardtype, v_acct_no,
             v_cardexp
        FROM cms_appl_pan
       WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '21';
         v_err_msg := 'Card number not found' || v_hash_pan;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
                    'Error while selecting data ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --SN find the acct balance
   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO v_acct_bal, v_ledger_bal, v_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = p_instcode AND cam_acct_no = v_acct_no;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '14';                                --Invalid account
         v_err_msg := 'Account number not found ' || p_cardnum;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
            'Problem while selecting acct balance'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En find the acct balance

   --Sn Added on 29.08.2013 for  Mentis id 0012205
     --Sn select authorization processe flag
   BEGIN
      SELECT ptp_param_value
        INTO v_precheck_flag
        FROM pcms_tranauth_param
       WHERE ptp_inst_code = p_instcode and  ptp_param_name = 'PRE CHECK';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '21';
         v_err_msg := 'Master set up is not done for Authorization Process';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
            'Error while selecting precheck flag' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En select authorization process flag

   --Sn GPR Card status check
   BEGIN
      sp_status_check_gpr (p_instcode,
                           p_cardnum,
                           p_delivery_channel,
                           v_cardexp,
                           v_cardstat,
                           p_txn_code,
                           p_tran_mode,
                           v_prodcode,
                           v_cardtype,
                           p_msg,
                           p_trandate,
                           p_trantime,
                           NULL,
                           null,
                           null,
                           v_resp_cde,
                           v_err_msg
                          );

      IF (   (v_resp_cde <> '1' AND v_err_msg <> 'OK')
          OR (v_resp_cde <> '0' AND v_err_msg <> 'OK')
         )
      THEN
         v_err_msg := 'For CARD -- ' || v_err_msg;
         RAISE exp_reject_record;
      ELSE
         v_status_chk := v_resp_cde;
         v_resp_cde := '1';
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
               'Error from GPR Card Status Check for CARD'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En GPR Card status check

   --Sn Expiry Check
   IF v_status_chk = '1'
   THEN

         BEGIN
            IF TO_DATE (p_trandate, 'YYYYMMDD') >
                                  LAST_DAY (TO_CHAR (v_cardexp, 'DD-MON-YY'))
            THEN
               v_resp_cde := '13';
               v_err_msg := 'CARD IS EXPIRED';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'ERROR IN EXPIRY DATE CHECK FOR CARD: Tran Date - '
                  || p_trandate
                  || ', Expiry Date - '
                  || v_cardexp
                  || ','
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;


      -- End Expiry Check

      --Sn check for precheck
      IF v_precheck_flag = 1
      THEN
         BEGIN
            sp_precheck_txn (p_instcode,
                             p_cardnum,
                             p_delivery_channel,
                             v_cardexp,
                             v_cardstat,
                             p_txn_code,
                             p_tran_mode,
                             p_trandate,
                             p_trantime,
                             NULL,
                             NULL,
                             NULL,
                             v_resp_cde,
                             v_err_msg
                            );

            IF (v_resp_cde <> '1' OR v_err_msg <> 'OK')
            THEN
               v_err_msg := 'For CARD -- ' || v_err_msg;
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Error from precheck processes for CARD'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;
   END IF;

   --En check for precheck

   --En Added on 29.08.2013 for Mentis id 0012205

   --Sn Get fee details
   BEGIN
      sp_getfee_details (p_instcode,
                         p_cardnum,
                         '000',
                         '07',
                         p_tran_mode,
                         p_delivery_channel,
                         NULL,
                         p_feeamount,
                         v_fee_desc,
                         v_feeflag,
                         v_avail_bal,
                         v_ledger_bal,
                         v_clawback_flag,
                         v_err_msg
                        );

      IF v_err_msg <> 'NO FEES ATTACHED'
      THEN
         IF v_err_msg <> 'OK'
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while geting Fee details-' || v_err_msg;
            RAISE exp_reject_record;
         END IF;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_resp_cde := '89';
         v_err_msg :=
                  'Error from sp_getfee_details ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

--En Get fee details
   BEGIN
      p_resp_msg := v_err_msg;

      SELECT cms_iso_respcde
        INTO p_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = p_instcode
         AND cms_delivery_channel = p_delivery_channel
         AND cms_response_id = v_resp_cde;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '21';
         v_err_msg :=
               'Response code not found for resp code ='
            || v_resp_cde
            || 'and Delivary channel ='
            || p_delivery_channel;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '89';
         v_err_msg :=
               'Problem while selecting data from response master '
            || v_resp_cde
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   p_feeamount := TRIM (TO_CHAR (NVL (p_feeamount, 0), '9999999999999990.00'));
   v_timestamp := SYSTIMESTAMP;

   BEGIN
      INSERT INTO transactionlog
                  (msgtype, rrn, delivery_channel, terminal_id, date_time,
                   txn_code, txn_type, txn_mode,
                   txn_status, response_code,
                   business_date, business_time, customer_card_no,
                   topup_card_no, topup_acct_no, topup_acct_type, bank_code,
                   currencycode, addcharge, productid, categoryid,
                   atm_name_location, auth_id, tranfee_amt, instcode,
                   customer_card_no_encr, proxy_number, reversal_code,
                   customer_acct_no, acct_balance, ledger_balance,
                   response_id, ipaddress, cardstatus, trans_desc,
                   error_msg,
                             --topup_acct_balance, topup_ledger_balance,
                             acct_type, time_stamp, cr_dr_flag
                  )
           VALUES (p_msg, p_rrn, p_delivery_channel, 0, v_trandatetime,
                   p_txn_code, v_txn_type, p_tran_mode,
                   --DECODE (v_resp_cde, '00', 'C', 'F'),--Modified by Shweta for 12279 on 12-SEP-2013
                   DECODE (p_resp_code, '00', 'C', 'F'),
                    p_resp_code,
                   p_trandate, SUBSTR (p_trantime, 1, 10), v_hash_pan,
                   NULL, NULL, NULL, p_instcode,
                   v_curr_code, NULL, v_prodcode, v_cardtype,
                   0, V_AUTH_ID,
                   --nvl(p_feeamount,0), --NVL added nvl(p_feeamount,0) for 13160 on 10-dec-2013
                   '0',p_instcode,
                   v_encr_pan, '', 0,
                   v_acct_no, NVL (v_acct_bal, 0), NVL (v_ledger_bal, 0),
                   v_resp_cde, p_ipaddress, v_cardstat, v_trans_desc,
                   v_err_msg,
                             --NVL (v_toacct_bal, 0), NVL (v_toledger_bal, 0),
                             v_acct_type, v_timestamp, v_dr_cr_flag
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '89';
         p_resp_msg :=
               'Problem while inserting data into transactionlog'
            || SUBSTR (SQLERRM, 1, 300);
         RETURN;
   END;

   BEGIN
      INSERT INTO cms_transaction_log_dtl
                  (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                   ctd_txn_mode, ctd_business_date, ctd_business_time,
                   ctd_customer_card_no, ctd_txn_curr, ctd_fee_amount,
                   ctd_servicetax_amount, ctd_process_flag, ctd_process_msg,
                   ctd_rrn, ctd_lupd_date, ctd_inst_code, ctd_lupd_user,
                   ctd_ins_date, ctd_ins_user, ctd_customer_card_no_encr,
                   ctd_msg_type, request_xml, ctd_cust_acct_number,
                   ctd_addr_verify_response
                  )
           VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                   p_tran_mode, p_trandate, p_trantime,
                   V_HASH_PAN, V_CURR_CODE,
                   --p_feeamount,
                   '0', --Modified for 13641
                   NULL, 'Y', 'Successful',
                   p_rrn, SYSDATE, p_instcode, 1,
                   SYSDATE, 1, v_encr_pan,
                   p_msg, '', v_acct_no,
                   ''
                  );

      p_resp_msg := v_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_msg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '99';
         RETURN;
   END;
--<<SN Main Exception>>
EXCEPTION
   WHEN exp_reject_record
   THEN
      ROLLBACK;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_bal, v_ledger_bal, v_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no =
                   (SELECT cap_acct_no
                      FROM cms_appl_pan
                     WHERE cap_inst_code = p_instcode
                       AND cap_pan_code = v_hash_pan)
            AND cam_inst_code = p_instcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_bal := 0;
            v_ledger_bal := 0;
      END;

      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_resp_cde;

         p_resp_msg := v_err_msg;

      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                  'Problem while selecting data from response master '
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
            RETURN;
      END;


     IF v_prodcode IS NULL
     THEN
        BEGIN
           SELECT cap_card_stat, cap_prod_code, cap_card_type,
                  cap_acct_no
             INTO v_cardstat, v_prodcode, v_cardtype,
                  v_acct_no
             FROM cms_appl_pan
            WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
        EXCEPTION
           WHEN OTHERS
           THEN
              NULL;
        END;
     END IF;

     IF v_dr_cr_flag IS NULL
     THEN
        BEGIN
           SELECT ctm_credit_debit_flag
             INTO v_dr_cr_flag
             FROM cms_transaction_mast
            WHERE ctm_inst_code = p_instcode
              AND ctm_tran_code = p_txn_code
              AND ctm_delivery_channel = p_delivery_channel;
        EXCEPTION
           WHEN OTHERS
           THEN
              NULL;
        END;
     END IF;

     v_timestamp := SYSTIMESTAMP;

     BEGIN
        INSERT INTO transactionlog
                    (msgtype, rrn, delivery_channel, terminal_id,
                     date_time, txn_code, txn_type,
                     txn_mode, txn_status,
                     response_code, business_date, business_time,
                     customer_card_no, topup_card_no, topup_acct_no,
                     topup_acct_type, bank_code, currencycode,
                     addcharge, productid, categoryid,
                     atm_name_location, auth_id, tranfee_amt, instcode,
                     customer_card_no_encr, proxy_number, reversal_code,
                     customer_acct_no, acct_balance,
                     ledger_balance, response_id, ipaddress,
                     cardstatus, trans_desc, error_msg,
                                                       --topup_acct_balance, topup_ledger_balance,
                                                       acct_type,
                     time_stamp, cr_dr_flag
                    )
             VALUES (p_msg, p_rrn, p_delivery_channel, 0,
                     v_trandatetime, p_txn_code, v_txn_type,
                     p_tran_mode,
                     --DECODE (v_resp_cde, '00', 'C', 'F'),--Modified by Shweta for 12279 on 12-SEP-2013
                     DECODE (p_resp_code, '00', 'C', 'F'),
                     p_resp_code, p_trandate, SUBSTR (p_trantime, 1, 10),
                     v_hash_pan, NULL, NULL,
                     NULL, p_instcode, v_curr_code,
                     NULL, v_prodcode, v_cardtype,
                     0, V_AUTH_ID,
                     --nvl(p_feeamount,0)             --NVL added nvl(p_feeamount,0) for 13160 on 10-dec-2013
                     '0', p_instcode,  --Modified for 13641
                     v_encr_pan, '', 0,
                     v_acct_no, NVL (v_acct_bal, 0),
                     NVL (v_ledger_bal, 0), v_resp_cde, p_ipaddress,
                     v_cardstat, v_trans_desc, v_err_msg,
                                                         --NVL (v_toacct_bal, 0), NVL (v_toledger_bal, 0),
                                                         v_acct_type,
                     v_timestamp, v_dr_cr_flag
                    );
     EXCEPTION
        WHEN OTHERS
        THEN
           p_resp_code := '89';
           p_resp_msg :=
                 'Problem while inserting data into transactionlog'
              || SUBSTR (SQLERRM, 1, 300);
           RETURN;
     END;


      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_curr, ctd_fee_amount,
                      ctd_servicetax_amount, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_lupd_date,
                      ctd_inst_code, ctd_lupd_user, ctd_ins_date,
                      ctd_ins_user, ctd_customer_card_no_encr, ctd_msg_type,
                      request_xml, ctd_cust_acct_number,
                      ctd_addr_verify_response
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      P_TRAN_MODE, P_TRANDATE, P_TRANTIME,
                      V_HASH_PAN, V_CURR_CODE,-- p_feeamount,
                      '0', --Modified for 13641
                      NULL, 'E',
                      v_err_msg, p_rrn, SYSDATE,
                      p_instcode, 1, SYSDATE,
                      1, v_encr_pan, p_msg,
                      '', v_acct_no,
                      ''
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '99';
            RETURN;
      END;
   WHEN OTHERS
   THEN
      ROLLBACK;
      v_resp_cde := '69';
      p_resp_msg :=
              'Error from transaction processing ' || SUBSTR (SQLERRM, 1, 90);

      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_resp_cde;

         p_resp_msg := v_err_msg;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Response code not found for resp code ='
               || v_resp_cde
               || 'and Delivary channel='
               || p_delivery_channel;
         --RAISE EXP_REJECT_RECORD;
         WHEN OTHERS
         THEN
            p_resp_msg :=
                  'Problem while selecting data from response master '
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '99';
            RETURN;
      END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_curr, ctd_fee_amount,
                      ctd_servicetax_amount, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_lupd_date,
                      ctd_inst_code, ctd_lupd_user, ctd_ins_date,
                      ctd_ins_user, ctd_customer_card_no_encr, ctd_msg_type,
                      request_xml, ctd_cust_acct_number,
                      ctd_addr_verify_response
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      P_TRAN_MODE, P_TRANDATE, P_TRANTIME,
                      V_HASH_PAN, V_CURR_CODE,-- p_feeamount,
                      '0', --Modified for 13641
                      NULL, 'E',
                      v_err_msg, p_rrn, SYSDATE,
                      p_instcode, 1, SYSDATE,
                      1, v_encr_pan, p_msg,
                      '', v_acct_no,
                      ''
                     );

         p_resp_msg := v_err_msg;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '99';
            RETURN;
      END;


     IF v_prodcode IS NULL
     THEN
        BEGIN
           SELECT cap_card_stat, cap_prod_code, cap_card_type,
                  cap_acct_no
             INTO v_cardstat, v_prodcode, v_cardtype,
                  v_acct_no
             FROM cms_appl_pan
            WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
        EXCEPTION
           WHEN OTHERS
           THEN
              NULL;
        END;
     END IF;

     IF v_dr_cr_flag IS NULL
     THEN
        BEGIN
           SELECT ctm_credit_debit_flag
             INTO v_dr_cr_flag
             FROM cms_transaction_mast
            WHERE ctm_inst_code = p_instcode
              AND ctm_tran_code = p_txn_code
              AND ctm_delivery_channel = p_delivery_channel;
        EXCEPTION
           WHEN OTHERS
           THEN
              NULL;
        END;
     END IF;

     v_timestamp := SYSTIMESTAMP;

     BEGIN
        INSERT INTO transactionlog
                    (msgtype, rrn, delivery_channel, terminal_id,
                     date_time, txn_code, txn_type,
                     txn_mode, txn_status,
                     response_code, business_date, business_time,
                     customer_card_no, topup_card_no, topup_acct_no,
                     topup_acct_type, bank_code, currencycode,
                     addcharge, productid, categoryid,
                     atm_name_location, auth_id, tranfee_amt, instcode,
                     customer_card_no_encr, proxy_number, reversal_code,
                     customer_acct_no, acct_balance,
                     ledger_balance, response_id, ipaddress,
                     cardstatus, trans_desc, error_msg,
                                                       --topup_acct_balance, topup_ledger_balance,
                                                       acct_type,
                     time_stamp, cr_dr_flag
                    )
             VALUES (p_msg, p_rrn, p_delivery_channel, 0,
                     v_trandatetime, p_txn_code, v_txn_type,
                     p_tran_mode,
                     --DECODE (v_resp_cde, '00', 'C', 'F'), --Modified by Shweta for 12279 on 12-SEP-2013
                     DECODE (p_resp_code, '00', 'C', 'F'),
                     p_resp_code, p_trandate, SUBSTR (p_trantime, 1, 10),
                     v_hash_pan, NULL, NULL,
                     NULL, p_instcode, v_curr_code,
                     null, V_PRODCODE, V_CARDTYPE,
                     0, V_AUTH_ID, --nvl(p_feeamount,0)              --NVL added nvl(p_feeamount,0) for 13160 on 10-dec-2013
                     '0', p_instcode,  --Modified for 13641
                     v_encr_pan, '', 0,
                     v_acct_no, NVL (v_acct_bal, 0),
                     NVL (v_ledger_bal, 0), v_resp_cde, p_ipaddress,
                     v_cardstat, v_trans_desc, v_err_msg,
                                                         --NVL (v_toacct_bal, 0), NVL (v_toledger_bal, 0),
                                                         v_acct_type,
                     v_timestamp, v_dr_cr_flag
                    );
     EXCEPTION
        WHEN OTHERS
        THEN
           p_resp_code := '89';
           p_resp_msg :=
                 'Problem while inserting data into transactionlog'
              || SUBSTR (SQLERRM, 1, 300);
           RETURN;
     END;

END;
/
show error