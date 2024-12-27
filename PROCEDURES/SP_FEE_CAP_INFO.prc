CREATE OR REPLACE PROCEDURE vmscms.sp_fee_cap_info (
   p_inst_code          IN       NUMBER,
   p_msg_type           IN       VARCHAR2,
   p_rrn                IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_term_id            IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_txn_mode           IN       VARCHAR2,
   p_tran_date          IN       VARCHAR2,
   p_tran_time          IN       VARCHAR2,
   p_pan_code           IN       VARCHAR2,
   p_bank_code          IN       VARCHAR2,
   p_curr_code          IN       VARCHAR2,
   p_ani                IN       VARCHAR2,
   p_dni                IN       VARCHAR2,
   p_ipaddress          IN       VARCHAR2,
   p_device_id          IN       VARCHAR2,
   p_mob_no             IN       VARCHAR2,
   p_user_name          IN       VARCHAR2,
   p_resp_code          OUT      VARCHAR2,
   p_fee_cap            OUT      VARCHAR2,
   p_fee_accrued        OUT      VARCHAR2,
   p_resmsg             OUT      VARCHAR2
)
AS
/*************************************************
       * Created Date     : 26-Aug-2013
       * Created By       : Magesh
       * Build Number     : RI0024.4_B0004

       * Modified by      : Sai Prasad
       * Modified Reason  : Mantis Id - 0012203 (FWR-11) & FSS-1144
       * Modified Date    : 29-Aug-2013
       * Reviewer         : Dhiraj
       * Reviewed Date    : 30-Aug-2013
       * Build Number     : RI0024.4_B0006

       * Modified Date    : 16-Dec-2013
       * Modified By      : Sagar More
       * Modified for     : Defect ID 13160
       * Modified reason  : To log below details in transactinlog if applicable
                             productcode,categoryid,dr_cr_dlag,acct_type,resp_id
       * Reviewer         : Dhiraj
       * Reviewed Date    : 16-Dec-2013
       * Release Number   : RI0024.7_B0001
       
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 21-FEB-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : SARAVA KUMAR.A
     * Release Number   : VMSGPRHOST18.01 

*************************************************/
   v_tran_date              DATE;
   v_auth_savepoint         NUMBER                                  DEFAULT 0;
   v_rrn_count              NUMBER;
   v_errmsg                 VARCHAR2 (500);
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan_from          cms_appl_pan.cap_pan_code_encr%TYPE;
   v_cust_code              cms_pan_acct.cpa_cust_code%TYPE;
   v_spnd_acct_no           cms_acct_mast.cam_acct_no%TYPE;
   v_txn_type               transactionlog.txn_type%TYPE;
--   v_cust_name              cms_cust_mast.ccm_user_name%TYPE;
   v_hash_password          VARCHAR2 (100);
   v_card_expry             VARCHAR2 (20);
   v_stan                   VARCHAR2 (20);
   v_capture_date           DATE;
   v_term_id                VARCHAR2 (20);
   v_mcc_code               VARCHAR2 (20);
   v_txn_amt                NUMBER;
   v_acct_number            cms_appl_pan.cap_acct_no%type;--NUMBER;   -- Modified during 13160 unit testing
   v_auth_id                transactionlog.auth_id%TYPE;
   v_cust_id                cms_cust_mast.ccm_cust_id%TYPE;
   v_startercard_flag       cms_appl_pan.cap_startercard_flag%TYPE;
   v_card_stat              cms_appl_pan.cap_card_stat%TYPE;
 --  v_user_name              cms_cust_mast.ccm_user_name%TYPE;
   v_dr_cr_flag             VARCHAR2 (2);
   v_output_type            VARCHAR2 (2);
   v_tran_type              VARCHAR2 (2);
   v_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
   v_cardstat               NUMBER (5);
   v_cfd_fee_cap            cms_feecap_dtl.cfd_fee_cap%TYPE;
   v_cfd_fee_accrued        cms_feecap_dtl.cfd_fee_accrued%TYPE;
   v_cfd_fee_waived         cms_feecap_dtl.cfd_fee_waived%TYPE;
   v_fee_plan               cms_fee_feeplan.cff_fee_plan%TYPE;
   v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   v_card_type              cms_appl_pan.cap_card_type%TYPE;
   exp_auth_reject_record   EXCEPTION;
   exp_reject_record        EXCEPTION;
   v_hashkey_id             cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
                                                       --  Added For FSS-1144
   v_time_stamp             TIMESTAMP;                  -- Added For FSS-1144
   --SN : Added for 13160
   v_acct_type              cms_acct_mast.cam_type_code%TYPE;
   v_resp_id                cms_response_mast.cms_response_id%TYPE;
   v_acct_bal               cms_acct_mast.cam_acct_bal%type;
   v_ledger_bal             cms_acct_mast.cam_ledger_bal%type;
   v_encrypt_enable         cms_prod_cattype.cpc_encrypt_enable%type;
   v_encrypt_user_name         cms_transaction_log_dtl.ctd_user_name%type;
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
--EN : Added for 13160

/*CURSOR C (ACCT_NO NUMBER,INST_CODE NUMBER) IS
     SELECT CFD_FEE_CAP,CFD_FEE_ACCRUED,CFD_FEE_WAIVED
     FROM CMS_FEECAP_DTL
     WHERE CFD_ACCT_NO=CUST_ID AND CFD_INST_CODE=INST_CODE;*/
BEGIN
   v_txn_type := '1';
   SAVEPOINT v_auth_savepoint;
   v_time_stamp := SYSTIMESTAMP;

   --Sn Get the HashPan
   BEGIN
      v_hash_pan := gethash (p_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Get the HashPan

   --Sn Create encr pan
   BEGIN
      v_encr_pan_from := fn_emaps_main (p_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --Start Generate HashKEY value for FSS-1144
   BEGIN
      v_hashkey_id :=
         gethash (   p_delivery_channel
                  || p_txn_code
                  || p_pan_code
                  || p_rrn
                  || TO_CHAR (v_time_stamp, 'YYYYMMDDHH24MISSFF5')
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
            'Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --End Generate HashKEY value for FSS-1144

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
         AND ctm_delivery_channel = p_delivery_channel
         AND ctm_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '12';                        --Ineligible Transaction
         v_errmsg :=
               'Transflag  not defined for txn code '
            || p_txn_code
            || ' and delivery channel '
            || p_delivery_channel;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';                        --Ineligible Transaction
         v_errmsg := 'Error while selecting transaction details';
         RAISE exp_reject_record;
   END;

   --En find debit and credit flag

   --Sn Duplicate RRN Check
   BEGIN
   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      SELECT COUNT (1)
        INTO v_rrn_count
        FROM transactionlog
       WHERE rrn = p_rrn
         AND business_date = p_tran_date
         AND instcode = p_inst_code
         AND delivery_channel = p_delivery_channel;
ELSE
		 SELECT COUNT (1)
        INTO v_rrn_count
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
       WHERE rrn = p_rrn
         AND business_date = p_tran_date
         AND instcode = p_inst_code
         AND delivery_channel = p_delivery_channel;

END IF;		 

      IF v_rrn_count > 0
      THEN
         p_resp_code := '22';
         v_errmsg := 'Duplicate RRN on ' || p_tran_date;
         RAISE exp_reject_record;
      END IF;
   END;

   --En Duplicate RRN Check

   --Sn Get Tran date
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
         p_resp_code := '21';
         v_errmsg :=
               'Problem while converting transaction date '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Get Tran date

   --Added by ramesh.a on 10/04/2012
   --Sn Get the card details
   BEGIN
      SELECT cap_card_stat, cap_acct_no, cap_prod_code, cap_card_type
        INTO v_cardstat, v_acct_number, v_prod_code, v_card_type
        FROM cms_appl_pan
       WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '16';                        --Ineligible Transaction
         v_errmsg := 'Card number not found ' || p_pan_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
            'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --End Get the card details
   
   
     --Sn Get the encrypt details for prod
   BEGIN
      SELECT cpc_encrypt_enable
        INTO v_encrypt_enable
        FROM cms_prod_cattype
       WHERE cpc_inst_code = p_inst_code AND cpc_card_type = v_card_type
              AND cpc_prod_code = v_prod_code ;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '16';                       
         v_errmsg := 'encrypt details not found ' || v_prod_code || v_card_type;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
            'Problem while selecting encrypt details' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   
   --End Get the encrypt details for product

   IF v_encrypt_enable = 'Y' then
   
      v_encrypt_user_name:=fn_emaps_main(p_user_name);     
   
   else
   
      v_encrypt_user_name:=p_user_name;     
   
   end if; 

   


   --Sn call to authorize procedure
   BEGIN
      sp_authorize_txn_cms_auth (p_inst_code,
                                 p_msg_type,
                                 p_rrn,
                                 p_delivery_channel,
                                 p_term_id,
                                 p_txn_code,
                                 p_txn_mode,
                                 p_tran_date,
                                 p_tran_time,
                                 p_pan_code,
                                 p_bank_code,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 p_curr_code,
                                 NULL,
                                 NULL,
                                 NULL,
                                 v_acct_number,
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
                                 '000',
                                 '00',
                                 NULL,
                                 v_auth_id,
                                 p_resp_code,
                                 v_errmsg,
                                 v_capture_date
                                );

      IF p_resp_code <> '00' AND v_errmsg <> 'OK'
      THEN
         --P_RESP_CODE := '21'; Commented by Besky on 06-nov-12
         --V_ERRMSG := 'Error from auth process' || V_ERRMSG;
         p_resmsg := 'Error from auth process' || v_errmsg;
         RAISE exp_auth_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_auth_reject_record
      THEN
         RAISE exp_auth_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En call to authorize procedure

   --St Get the questions using username
   BEGIN
      SELECT cfd_fee_cap, cfd_fee_accrued, cfd_fee_waived
        INTO v_cfd_fee_cap, v_cfd_fee_accrued, v_cfd_fee_waived
        FROM (SELECT   cfd_fee_cap, cfd_fee_accrued, cfd_fee_waived
                  FROM cms_feecap_dtl
                 WHERE cfd_acct_no = v_acct_number
                   AND cfd_inst_code = p_inst_code
                   AND cfd_fee_period >= v_tran_date
              ORDER BY cfd_fee_period)
       WHERE ROWNUM = 1;                                       -- Modified for
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         --V_CFD_FEE_CAP := '-';
         v_cfd_fee_accrued := 0;

         BEGIN
            SELECT cce_fee_plan
              INTO v_fee_plan
              FROM cms_card_excpfee
             WHERE cce_pan_code = v_hash_pan
               AND (   (    cce_valid_to IS NOT NULL
                        AND (SYSDATE BETWEEN cce_valid_from AND cce_valid_to
                            )
                       )
                    OR (cce_valid_to IS NULL AND SYSDATE >= cce_valid_from)
                   );
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  SELECT cpf_fee_plan
                    INTO v_fee_plan
                    FROM cms_prodcattype_fees
                   WHERE cpf_prod_code = v_prod_code
                     AND cpf_card_type = v_card_type
                     AND (   (    cpf_valid_to IS NOT NULL
                              AND (SYSDATE BETWEEN cpf_valid_from AND cpf_valid_to
                                  )
                             )
                          OR (    cpf_valid_to IS NULL
                              AND SYSDATE >= cpf_valid_from
                             )
                         );
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     BEGIN
                        SELECT cpf_fee_plan
                          INTO v_fee_plan
                          FROM cms_prod_fees
                         WHERE cpf_prod_code = v_prod_code
                           AND (   (    cpf_valid_to IS NOT NULL
                                    AND (SYSDATE BETWEEN cpf_valid_from
                                                     AND cpf_valid_to
                                        )
                                   )
                                OR (    cpf_valid_to IS NULL
                                    AND SYSDATE >= cpf_valid_from
                                   )
                               );
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_cfd_fee_cap := 0;
                        WHEN OTHERS
                        THEN
                           p_resp_code := '21';
                           v_errmsg :=
                                 'Error from while selecting customer id and questions'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;
                  WHEN OTHERS
                  THEN
                     p_resp_code := '21';
                     v_errmsg :=
                           'Error from while selecting customer id and questions'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            WHEN OTHERS
            THEN
               p_resp_code := '21';
               v_errmsg :=
                     'Error from while selecting customer id and questions'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT cfm_fee_amt
              INTO v_cfd_fee_cap
              FROM cms_fee_mast, cms_fee_types, cms_fee_feeplan
             WHERE cfm_inst_code = p_inst_code
               AND cfm_inst_code = cft_inst_code
               AND cff_fee_plan = v_fee_plan
               AND cff_fee_code = cfm_fee_code
               AND cfm_feetype_code = cft_feetype_code
               AND cft_fee_freq = 'M'
               AND cft_fee_type = 'C';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_cfd_fee_cap := 0;
            WHEN OTHERS
            THEN
               v_cfd_fee_cap := 0;
         END;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Error from while selecting customer id and questions'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   p_fee_cap := v_cfd_fee_cap;
   p_fee_accrued := v_cfd_fee_accrued;
   p_resp_code := 1;
   p_resmsg := 'SUCCESS';

   BEGIN
   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE transactionlog
         SET ani = p_ani,
             dni = p_dni,
             ipaddress = p_ipaddress
       WHERE rrn = p_rrn
         AND business_date = p_tran_date
         AND business_time = p_tran_time
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND msgtype = p_msg_type
         AND instcode = p_inst_code;
ELSE
		 UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
         SET ani = p_ani,
             dni = p_dni,
             ipaddress = p_ipaddress
       WHERE rrn = p_rrn
         AND business_date = p_tran_date
         AND business_time = p_tran_time
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND msgtype = p_msg_type
         AND instcode = p_inst_code;
END IF;		 

      IF SQL%ROWCOUNT = 0
      THEN
         v_errmsg := 'ERROR WHILE UPDATING Trasnsaction log ';
         p_resp_code := '21';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Problem on updated Trasnsaction log  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE cms_transaction_log_dtl
         SET ctd_user_name = v_encrypt_user_name,
             ctd_mobile_number = p_mob_no,
             ctd_device_id = p_device_id
       WHERE ctd_rrn = p_rrn
         AND ctd_business_date = p_tran_date
         AND ctd_business_time = p_tran_time
         AND ctd_delivery_channel = p_delivery_channel
         AND ctd_txn_code = p_txn_code
         AND ctd_msg_type = p_msg_type
         AND ctd_inst_code = p_inst_code;
ELSE
		 UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST  --Added for VMS-5733/FSP-991
         SET ctd_user_name = v_encrypt_user_name,
             ctd_mobile_number = p_mob_no,
             ctd_device_id = p_device_id
       WHERE ctd_rrn = p_rrn
         AND ctd_business_date = p_tran_date
         AND ctd_business_time = p_tran_time
         AND ctd_delivery_channel = p_delivery_channel
         AND ctd_txn_code = p_txn_code
         AND ctd_msg_type = p_msg_type
         AND ctd_inst_code = p_inst_code;
END IF;		 

      IF SQL%ROWCOUNT = 0
      THEN
         v_errmsg := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
         p_resp_code := '21';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Problem on updated cms_Transaction_log_dtl '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code
         AND cms_delivery_channel = p_delivery_channel
         AND cms_response_id = p_resp_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         v_errmsg := 'Responce code not found ' || p_resp_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '69';               ---ISO MESSAGE FOR DATABASE ERROR
         v_errmsg :=
               'Problem while selecting data from response master '
            || p_resp_code
            || SUBSTR (SQLERRM, 1, 200);
   END;
--
EXCEPTION
   WHEN exp_auth_reject_record
   THEN
      p_resmsg := v_errmsg;
      p_resp_code := p_resp_code;
   WHEN exp_reject_record
   THEN
      ROLLBACK;                                        --TO V_AUTH_SAVEPOINT;
      p_resmsg := v_errmsg;                   -- Added based on FWR-11 Review
      --END;
      v_resp_id := p_resp_code;                            -- Added for 13160

      --Sn Get responce code fomr master
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = p_resp_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while selecting data from response master '
               || p_resp_code
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
      END;

      --En Get responce code fomr master

      --SN : Added for 13160
      IF v_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag
              INTO v_dr_cr_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code
               AND ctm_delivery_channel = p_delivery_channel
               AND ctm_inst_code = p_inst_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      IF v_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_card_stat, cap_acct_no, cap_prod_code, cap_card_type
              INTO v_cardstat, v_acct_number, v_prod_code, v_card_type
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

         BEGIN
            SELECT cam_type_code,cam_acct_bal,cam_ledger_bal
              INTO v_acct_type,v_acct_bal,v_ledger_bal
              FROM cms_acct_mast
             WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_acct_number;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;


      --SN : Added for 13160

      --Sn Inserting data in transactionlog
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time,
                      txn_code, txn_type, txn_mode, txn_status,
                      response_code, business_date, business_time,
                      customer_card_no, instcode, customer_card_no_encr,
                      customer_acct_no, error_msg, add_ins_date,
                      add_ins_user, cardstatus, trans_desc, ipaddress, ani,
                      dni, time_stamp,                   -- Added For FSS-1144
                                      --SN:Added for 13160
                                      acct_type, productid,
                      categoryid, cr_dr_flag, response_id,
                      acct_balance,ledger_balance
                     --EN:Added for 13160
                     )
              VALUES (p_msg_type, p_rrn, p_delivery_channel, SYSDATE,
                      p_txn_code, v_txn_type, p_txn_mode, 'F',
                      p_resp_code, p_tran_date, p_tran_time,
                      v_hash_pan, p_inst_code, v_encr_pan_from,
                      --V_SPND_ACCT_NO,
                      v_acct_number, v_errmsg, SYSDATE,
                      1, v_cardstat, v_trans_desc, p_ipaddress, p_ani,
                      p_dni, v_time_stamp,               -- Added For FSS-1144
                                          --SN:Added for 13160
                                          v_acct_type, v_prod_code,
                      v_card_type, v_dr_cr_flag, v_resp_id,
                      v_acct_bal,v_ledger_bal
                     --EN:Added for 13160
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '12';
            v_errmsg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
            RAISE exp_reject_record;
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_fee_amount,
                      ctd_waiver_amount, ctd_servicetax_amount,
                      ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_ins_date, ctd_ins_user,
                      ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                      ctd_cust_acct_number, ctd_addr_verify_response,
                      ctd_mobile_number,
                       --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
                                        ctd_device_id,
                       --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
                                                      ctd_user_name,
                       --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
                      ctd_hashkey_id                 -- For regarding FSS-1144
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_txn_mode, p_tran_date, p_tran_time,
                      v_hash_pan, NULL,
                      NULL, NULL,
                      NULL, 'E', v_errmsg,
                      p_rrn, p_inst_code, SYSDATE, 1,
                      v_encr_pan_from, '000', '',
                      v_spnd_acct_no, '',
                      p_mob_no,
                       --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
                               p_device_id,
                       --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
                                           v_encrypt_user_name,
                       --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
                      v_hashkey_id                       -- Added For FSS-1144
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
            RETURN;
      END;
    --En Inserting data in transactionlog dtl
--En Handle EXP_REJECT_RECORD execption

   --Sn Handle OTHERS Execption
   WHEN OTHERS
   THEN
      p_resp_code := '21';
      v_errmsg := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
      ROLLBACK;                                       -- TO V_AUTH_SAVEPOINT;

--END;
    --Sn Get responce code from master
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = p_resp_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while selecting data from response master '
               || p_resp_code
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
      END;

      --En Get responce code fomr master

      --SN : Added for 13160
      IF v_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag
              INTO v_dr_cr_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code
               AND ctm_delivery_channel = p_delivery_channel
               AND ctm_inst_code = p_inst_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      IF v_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_card_stat, cap_acct_no, cap_prod_code, cap_card_type
              INTO v_cardstat, v_acct_number, v_prod_code, v_card_type
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;


         BEGIN
            SELECT cam_type_code,cam_acct_bal,cam_ledger_bal
              INTO v_acct_type,v_acct_bal,v_ledger_bal
              FROM cms_acct_mast
             WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_acct_number;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;


      --SN : Added for 13160

      --Sn Inserting data in transactionlog
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time,
                      txn_code, txn_type, txn_mode, txn_status,
                      response_code, business_date, business_time,
                      customer_card_no, instcode, customer_card_no_encr,
                      customer_acct_no, error_msg, add_ins_date,
                      add_ins_user, cardstatus,
                    --Added CARDSTATUS insert in transactionlog by srinivasu.k
                                               trans_desc, time_stamp,
                                                        --  Added For FSS-1144
                      --SN:Added for 13160
                      acct_type, productid, categoryid, cr_dr_flag,
                      response_id,acct_balance,ledger_balance
                     --EN:Added for 13160
                     )
              VALUES (p_msg_type, p_rrn, p_delivery_channel, SYSDATE,
                      p_txn_code, v_txn_type, p_txn_mode, 'F',
                      p_resp_code, p_tran_date, p_tran_time,
                      v_hash_pan, p_inst_code, v_encr_pan_from,
                      -- V_SPND_ACCT_NO,
                      v_acct_number,             --Added by Besky on 09-nov-12
                                    v_errmsg, SYSDATE,
                      1, v_cardstat,
                    --Added CARDSTATUS insert in transactionlog by srinivasu.k
                                    v_trans_desc, v_time_stamp,
                                                        --  Added For FSS-1144
                      --SN:Added for 13160
                      v_acct_type, v_prod_code, v_card_type, v_dr_cr_flag,
                      v_resp_id,v_acct_bal,v_ledger_bal
                     --EN:Added for 13160
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '12';
            v_errmsg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
            RAISE exp_reject_record;
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_fee_amount,
                      ctd_waiver_amount, ctd_servicetax_amount,
                      ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_ins_date, ctd_ins_user,
                      ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                      ctd_cust_acct_number, ctd_addr_verify_response,
                      ctd_mobile_number,
                       --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
                                        ctd_device_id,
                       --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
                                                      ctd_user_name,
                       --Added on 09-Aug-2013 by Ravi N for regarding Fss-1144
                      ctd_hashkey_id                    --  Added For FSS-1144
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_txn_mode, p_tran_date, p_tran_time,
                      v_hash_pan, NULL,
                      NULL, NULL,
                      NULL, 'E', v_errmsg,
                      p_rrn, p_inst_code, SYSDATE, 1,
                      v_encr_pan_from, '000', '',
                      v_spnd_acct_no, '',
                      p_mob_no, p_device_id,v_encrypt_user_name,
                      v_hashkey_id                       -- Added For FSS-1144
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
            RETURN;
      END;
   --En Inserting data in transactionlog dtl
--En Handle OTHERS Execption

-- --Added for FWR-11 Review
--  WHEN OTHERS THEN
--    ROLLBACK;
--    P_RESP_CODE := '69';
--    P_RESMSG  := 'Main exception from FEE CAP INFO ' ||
--                SUBSTR(SQLERRM, 1, 200);
END;
/
show error;