CREATE OR REPLACE PROCEDURE vmscms.sp_ivr_failedreg_inquiry (
   p_instcode        IN       NUMBER,
   p_rrn             IN       VARCHAR2,
   p_txn_code        IN       VARCHAR2,
   p_delivery_chnl   IN       VARCHAR2,
   p_msg_type        IN       VARCHAR2,
   p_revrsl_code     IN       VARCHAR2,
   p_txn_mode        IN       VARCHAR2,
   p_trandate        IN       VARCHAR2,
   p_trantime        IN       VARCHAR2,
   p_ani             IN       VARCHAR2,
   p_dni             IN       VARCHAR2,
   p_ipaddress       IN       VARCHAR2,
   p_mobilenumber    IN       VARCHAR2,
   p_resp_code       OUT      VARCHAR2,
   p_errmsg          OUT      VARCHAR2
)
AS
   /************************************************************************************************
    created by             : Siva kumar M
    Created for            : MYVIVR-52
    Created Date           : 10-Sept-2014
    Build                  : RI0027.4_B0001


    * Modified Date        : 01-October-2014
    * Modified By          : Siva Kumar M
    * PURPOSE              : MYVIVR-52 review comments incorporated
    * Build                : RI0027.4_B0002
    
    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-25-2022
    * Purpose          : Archival changes.
    * Reviewer         : Jyothi G
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991
   ********************************************************************************************/
   v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   v_card_type              cms_appl_pan.cap_card_type%TYPE;
   v_cap_card_stat          cms_appl_pan.cap_card_stat%TYPE;
   v_auth_id                transactionlog.auth_id%TYPE;
   v_errmsg                 VARCHAR2 (300);
   v_respcode               VARCHAR2 (5);
   v_respmsg                VARCHAR2 (500);
   exp_main_reject_record   EXCEPTION;
   v_hash_pan               cms_caf_info_entry.cci_pan_code%TYPE;
   v_encr_pan               cms_caf_info_entry.cci_pan_code_encr%TYPE;
   v_rrn_count              NUMBER;
   v_tran_date              DATE;
   v_proxunumber            cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
   v_dr_cr_flag             VARCHAR2 (2);
   v_output_type            VARCHAR2 (2);
   v_tran_type              VARCHAR2 (2);
   v_txn_type               VARCHAR2 (2);
   v_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
   v_time_stamp             TIMESTAMP;
   v_hashkey_id             cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   v_pan_code               cms_caf_info_entry.cci_pan_code%TYPE;
   v_logdtl_resp            VARCHAR2 (500);
v_Retperiod  date;  --Added for VMS-5735/FSP-991
v_Retdate  date; --Added for VMS-5735/FSP-991
BEGIN
   p_errmsg := 'OK';
   v_respcode := '00';

   --V_REMRK    := '';
   BEGIN
      SAVEPOINT v_auth_savepoint;
      v_time_stamp := SYSTIMESTAMP;

      --Sn find debit and credit flag
      BEGIN
         SELECT ctm_credit_debit_flag, ctm_output_type,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_tran_desc
           INTO v_dr_cr_flag, v_output_type,
                v_txn_type,
                v_tran_type, v_trans_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_chnl
            AND ctm_inst_code = p_instcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_respcode := '12';
            v_errmsg :=
                  'Transflag  not defined for txn code '
               || p_txn_code
               || ' and delivery channel '
               || p_delivery_chnl;
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_respcode := '21';                      --Ineligible Transaction
            v_errmsg := 'Error while selecting transaction details';
            RAISE exp_main_reject_record;
      END;

      --Sn generate auth id
      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            v_respcode := '21';                            -- Server Declined
            RAISE exp_main_reject_record;
      END;

      --En generate auth id
      BEGIN

--Added for VMS-5735/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
         SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog
          WHERE rrn = p_rrn
            AND business_date = p_trandate
            AND instcode = p_instcode
            AND delivery_channel = p_delivery_chnl;
ELSE
    SELECT COUNT (1)
           INTO v_rrn_count
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE rrn = p_rrn
            AND business_date = p_trandate
            AND instcode = p_instcode
            AND delivery_channel = p_delivery_chnl;
END IF;

         IF v_rrn_count > 0
         THEN
            v_respcode := '22';
            v_errmsg := 'Duplicate RRN ON ' || p_trandate;
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'Error while checking duplicate RRN-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;

      BEGIN
         v_tran_date :=
            TO_DATE (   SUBSTR (TRIM (p_trandate), 1, 8)
                     || ' '
                     || SUBSTR (TRIM (p_trantime), 1, 10),
                     'yyyymmdd hh24:mi:ss'
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_respcode := '32';
            v_errmsg :=
                  'Problem while converting transaction Time '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;

      BEGIN
         SELECT pan, cardnumber, cardnumber_encr
           INTO v_pan_code, v_hash_pan, v_encr_pan
           FROM (SELECT   fn_dmaps_main (cci_pan_code_encr) pan,
                          cci_pan_code cardnumber,
                          cci_pan_code_encr cardnumber_encr
                     FROM cms_caf_info_entry,
                          cms_kyctxn_log,
                          cms_kycstatus_mast,
                          cms_prod_bin
                    WHERE cci_row_id = ckl_row_id
                      AND cci_inst_code = cpb_inst_code
                      AND cci_prod_code = cpb_prod_code
                      AND cci_inst_code = ckl_inst_code
                      AND cci_kyc_flag = ckm_flag
                      AND cci_seg12_mobileno = p_mobilenumber
                      AND cci_kyc_flag IN ('E', 'F')
                      AND cci_approved = 'A'
                      AND cci_upld_stat = 'P'
                      AND ckl_kycres_date =
                             (SELECT MAX (ckl_kycres_date)
                                FROM cms_kyctxn_log
                               WHERE ckl_row_id = cci_row_id
                                 AND cci_inst_code = ckl_inst_code)
                      AND cpb_inst_bin IN (SELECT cpb_inst_bin
                                             FROM cms_prod_bin)
                 ORDER BY ckl_kycres_date DESC)
          WHERE ROWNUM = 1;

         p_errmsg := 'YES';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_errmsg := 'NO';
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Problem while selecting  moblile from caf info '
               || SUBSTR (SQLERRM, 1, 300);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;

      IF v_pan_code IS NOT NULL
      THEN
         BEGIN
            SELECT cap_prod_code, cap_card_type, cap_proxy_number,
                   cap_acct_no, cap_card_stat
              INTO v_prod_code, v_card_type, v_proxunumber,
                   v_acct_number, v_cap_card_stat
              FROM cms_appl_pan
             WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Problem while selecting data from app pan'
                  || SUBSTR (SQLERRM, 1, 300);
               v_respcode := '21';
               RAISE exp_main_reject_record;
         END;

         --Start Generate HashKEY value
         BEGIN
            v_hashkey_id :=
               gethash (   p_delivery_chnl
                        || p_txn_code
                        || v_pan_code
                        || p_rrn
                        || TO_CHAR (v_time_stamp, 'YYYYMMDDHH24MISSFF5')
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_respcode := '21';
               v_errmsg :=
                     'Error while Generating  hashkey id data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      END IF;

      v_respcode := 1;
      v_errmsg := 'SUCCESS';
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         ROLLBACK TO v_auth_savepoint;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := ' Exception ' || SQLCODE || '---' || SQLERRM;
         ROLLBACK TO v_auth_savepoint;
   END;

   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = p_instcode
         AND cms_delivery_channel = p_delivery_chnl
         AND cms_response_id = v_respcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Error while selecting CMS_RESPONSE_MAST '
            || v_respcode
            || SUBSTR (SQLERRM, 1, 200);
         p_resp_code := '89';
   END;

   --Sn Inserting data in transactionlog
   BEGIN
      sp_log_txnlog (p_instcode,
                     p_msg_type,
                     p_rrn,
                     p_delivery_chnl,
                     p_txn_code,
                     v_txn_type,
                     p_txn_mode,
                     p_trandate,
                     p_trantime,
                     0,
                     v_hash_pan,
                     v_encr_pan,
                     v_errmsg,
                     NULL,
                     v_cap_card_stat,
                     v_trans_desc,
                     p_ani,
                     p_dni,
                     v_time_stamp,
                     v_acct_number,
                     v_prod_code,
                     v_card_type,
                     v_dr_cr_flag,
                     NULL,
                     NULL,
                     NULL,
                     v_proxunumber,
                     v_auth_id,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     v_respcode,
                     p_resp_code,
                     NULL,
                     v_errmsg,
                     NULL,
                     NULL
                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '89';
         v_errmsg :=
               'Exception while inserting to transaction log '
            || SQLCODE
            || '---'
            || SQLERRM;
   END;

   --En Inserting data in transactionlog

   --Sn Inserting data in transactionlog dtl
   BEGIN
      sp_log_txnlogdetl (p_instcode,
                         p_msg_type,
                         p_rrn,
                         p_delivery_chnl,
                         p_txn_code,
                         v_txn_type,
                         p_txn_mode,
                         p_trandate,
                         p_trantime,
                         v_hash_pan,
                         v_encr_pan,
                         v_errmsg,
                         v_acct_number,
                         v_auth_id,
                         NULL,
                         NULL,
                         NULL,
                         v_hashkey_id,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         p_resp_code,
                         NULL,
                         NULL,
                         NULL,
                         v_logdtl_resp
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '89';
   END;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_resp_code := '69';
      p_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;
/
SHOW ERROR