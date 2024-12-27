CREATE OR REPLACE PACKAGE BODY VMSCMS.VMSMOBILE 
IS
   PROCEDURE hold_auth_amount (
      p_inst_code_in          IN       NUMBER,
      p_msg_type_in           IN       VARCHAR2,
      p_rrn_in                IN       VARCHAR2,
      p_delivery_channel_in   IN       VARCHAR2,
      p_txn_code_in           IN       VARCHAR2,
      p_txn_mode_in           IN       VARCHAR2,
      p_tran_date_in          IN       VARCHAR2,
      p_tran_time_in          IN       VARCHAR2,
      p_mbr_numb_in           IN       VARCHAR2,
      p_rvsl_code_in          IN       VARCHAR2,
      p_txn_amt_in            IN       NUMBER,
      p_cust_id_in            IN       NUMBER,
      p_pan_code_in           IN       VARCHAR2,
      p_curr_code_in          IN       VARCHAR2,
      p_partner_id_in         IN       VARCHAR2,
      p_payee_id_in           IN       VARCHAR2,
      p_resubmit_flag_in      IN       VARCHAR2,
      p_remarks_in            IN       VARCHAR2,
      p_reason_code_in        IN       VARCHAR2,
      p_resp_code_out          OUT      VARCHAR2,
      p_resmsg_out             OUT      VARCHAR2,
      p_org_rrn_out            OUT      VARCHAR2
   )
   IS
      /************************************************************************************************************
       * Created Date     :  15-JUNE-2015
       * Created By       :  Abdul Hameed M.A
       * Created For      :  FSS 1960
       * Reviewer         :  SPankaj
       * Build Number     :     VMSGPRHOSTCSD_3.1_B0001

       * modified  Date     : 08-August-2016
       * Modified By       : Saravanakumar A
       * Modified  For      : mobile deposit concurrent transaction
       * Reviewer         :  SPankaj
       * Build Number     :     VMSGPRHOSTCSD_4.7_B0001

           * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07
		 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07

  * Modified by                 : DHINAKARAN B
  * Modified Date               : 26-NOV-2019
  * Modified For                : VMS-1415
  * Reviewer                    :  Saravana Kumar A
  * Build Number                :  VMSGPRHOST_R23_B1
  
      ************************************************************************************************************/
      l_auth_savepoint       NUMBER                                 DEFAULT 0;
      l_err_msg              VARCHAR2 (500);
      l_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
      l_txn_type             transactionlog.txn_type%TYPE;
      l_auth_id              transactionlog.auth_id%TYPE;
      exp_reject_record      EXCEPTION;
      l_dr_cr_flag           VARCHAR2 (2);
      l_tran_type            VARCHAR2 (2);
      l_tran_amt             NUMBER;
      l_prod_code            cms_appl_pan.cap_prod_code%TYPE;
      l_card_type            cms_appl_pan.cap_card_type%TYPE;
      l_resp_cde             VARCHAR2 (5);
      l_time_stamp           TIMESTAMP;
      l_hashkey_id           cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_trans_desc           cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag            cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_acct_number          cms_appl_pan.cap_acct_no%TYPE;
      l_prfl_code            cms_appl_pan.cap_prfl_code%TYPE;
      l_card_stat            cms_appl_pan.cap_card_stat%TYPE;
      l_cust_code            cms_appl_pan.cap_cust_code%TYPE;
      v_Retperiod  date;  --Added for VMS-5739/FSP-991
        v_Retdate  date; --Added for VMS-5739/FSP-991
      l_preauth_flag         cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_acct_bal             cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal           cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type            cms_acct_mast.cam_type_code%TYPE;
      l_proxy_number         cms_appl_pan.cap_proxy_number%TYPE;
      l_fee_code             transactionlog.feecode%TYPE;
      l_fee_plan             transactionlog.fee_plan%TYPE;
      l_feeattach_type       transactionlog.feeattachtype%TYPE;
      l_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_total_amt            transactionlog.total_amount%TYPE;
      l_expry_date           cms_appl_pan.cap_expry_date%TYPE;
      l_comb_hash            pkg_limits_check.type_hash;
      l_login_txn            cms_transaction_mast.ctm_login_txn%TYPE;
      l_logdtl_resp          VARCHAR2 (500);
      l_preauth_type         cms_transaction_mast.ctm_preauth_type%TYPE;
      l_preauth_exp_period   CMS_PROD_CATTYPE.CPC_ONUS_AUTH_EXPIRY%TYPE;
      l_tran_date            DATE;
      l_preauth_hold         VARCHAR2 (1);
      l_preauth_period       NUMBER;
      l_preauth_date         DATE;
      l_cnt                  NUMBER                                      := 0;
      v_compl_fee varchar2(10);
      v_compl_feetxn_excd varchar2(10);
       v_compl_feecode varchar2(10);
      l_reason_code_desc     vms_reason_mast.VRM_REASON_DESC%TYPE;
   BEGIN
      l_resp_cde := '1';
      l_time_stamp := SYSTIMESTAMP;

      BEGIN
         SAVEPOINT l_auth_savepoint;
         l_tran_amt := NVL (ROUND (p_txn_amt_in, 2), 0);

         --Sn Get the HashPan
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Error while converting hash pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En Get the HashPan

         --Sn Create encr pan
         BEGIN
            l_encr_pan := fn_emaps_main (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Error while converting emcrypted pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --Start Generate HashKEY value
         BEGIN
            l_hashkey_id :=
               GETHASH (   P_DELIVERY_CHANNEL_IN
                        || p_txn_code_in
                        || p_pan_code_in
                        || p_rrn_in
                        || TO_CHAR (l_time_stamp, 'YYYYMMDDHH24MISSFF5')
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error while Generating  hashkey id data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --End Generate HashKEY

         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   cap_prfl_code, cap_expry_date, cap_proxy_number,
                   cap_cust_code
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   l_prfl_code, l_expry_date, l_proxy_number,
                   l_cust_code
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'Card number not found ' || l_encr_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Problem while selecting card detail'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --End Get the card details

         --Sn find debit and credit flag
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag, ctm_login_txn, ctm_preauth_type
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag, l_login_txn, l_preauth_type
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Transaction not defined for txn code '
                  || p_txn_code_in
                  || ' and delivery channel '
                  || p_delivery_channel_in;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg := 'Error while selecting transaction details';
               RAISE exp_reject_record;
         END;

         --En find debit and credit flag

         --Sn generate auth id
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO l_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';                         -- Server Declined
               RAISE exp_reject_record;
         END;

         --En generate auth id

         IF l_tran_amt <=0 THEN
               l_resp_cde := '25';
               l_err_msg := 'INVALID AMOUNT';
               RAISE exp_reject_record;
         END IF;

         IF UPPER (TRIM (p_resubmit_flag_in)) = 'Y'
         THEN
            BEGIN
               SELECT COUNT (1)
                 INTO l_cnt
                 FROM vms_ild_data
                WHERE cid_customer_id = p_cust_id_in
                 -- AND cid_payee_id = p_payee_id_in
                  AND cid_txn_code = p_txn_code_in
                  AND cid_delivery_channel = p_delivery_channel_in
                  AND cid_txn_amount = p_txn_amt_in
                  AND cid_partner_id = p_partner_id_in
                  AND cid_tran_date = p_tran_date_in
                  AND cid_tran_time = p_tran_time_in;

               IF (l_cnt > 0)
               THEN
                  l_err_msg := 'Duplicate Request';
                  l_resp_cde := '22';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
               WHEN OTHERS
               THEN
                  l_err_msg :=
                        'Error while selecting vms_ild_data '
                     || SUBSTR (SQLERRM, 1, 300);
                  l_resp_cde := '21';
                  RAISE exp_reject_record;
            END;
         END IF;

         BEGIN
            sp_cmsauth_check (p_inst_code_in,
                              p_msg_type_in,
                              p_rrn_in,
                              p_delivery_channel_in,
                              p_txn_code_in,
                              p_txn_mode_in,
                              p_tran_date_in,
                              p_tran_time_in,
                              p_mbr_numb_in,
                              p_rvsl_code_in,
                              l_tran_type,
                              p_curr_code_in,
                              l_tran_amt,
                              p_pan_code_in,
                              l_hash_pan,
                              l_encr_pan,
                              l_card_stat,
                              l_expry_date,
                              l_prod_code,
                              l_card_type,
                              l_prfl_flag,
                              l_prfl_code,
                              NULL,
                              NULL,
                              NULL,
                              l_resp_cde,
                              l_err_msg,
                              l_comb_hash
                             );

            IF l_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error from  cmsauth Check Procedure  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in
            FOR UPDATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account  detail '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            sp_fee_calc (p_inst_code_in,
                         p_msg_type_in,
                         p_rrn_in,
                         p_delivery_channel_in,
                         p_txn_code_in,
                         p_txn_mode_in,
                         p_tran_date_in,
                         p_tran_time_in,
                         p_mbr_numb_in,
                         p_rvsl_code_in,
                         l_txn_type,
                         p_curr_code_in,
                         l_tran_amt,
                         p_pan_code_in,
                         l_hash_pan,
                         l_encr_pan,
                         l_acct_number,
                         l_prod_code,
                         l_card_type,
                         l_preauth_flag,
                         NULL,
                         NULL,
                         NULL,
                         l_trans_desc,
                         l_dr_cr_flag,
                         l_acct_bal,
                         l_ledger_bal,
                         l_acct_type,
                         l_login_txn,
                         l_auth_id,
                         l_time_stamp,
                         l_resp_cde,
                         l_err_msg,
                         l_fee_code,
                         l_fee_plan,
                         l_feeattach_type,
                         l_tranfee_amt,
                         l_total_amt,
                         v_compl_fee ,
                         v_compl_feetxn_excd,
                         v_compl_feecode,
                         l_preauth_type,
                         null,
                         null
                        );

            IF l_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                       'Error from sp_fee_calc  ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         l_resp_cde := '1';

         BEGIN
            l_tran_date :=
               TO_DATE (   SUBSTR (TRIM (p_tran_date_in), 1, 8)
                        || ' '
                        || SUBSTR (TRIM (p_tran_time_in), 1, 10),
                        'yyyymmdd hh24:mi:ss'
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while converting transaction date '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT NVL (CPC_ONUS_AUTH_EXPIRY, '201')
              INTO l_preauth_exp_period
			 FROM CMS_PROD_CATTYPE
			 WHERE CPC_PROD_CODE=l_prod_code
			 AND CPC_CARD_TYPE= l_card_type
			AND CPC_INST_CODE=p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_preauth_exp_period := '201';
            WHEN OTHERS
            THEN
               l_preauth_exp_period := '201';
         END;

         l_preauth_hold :=
                        TO_NUMBER (SUBSTR (TRIM (l_preauth_exp_period), 1, 1));
         l_preauth_period :=
                        TO_NUMBER (SUBSTR (TRIM (l_preauth_exp_period), 2, 2));

         IF l_preauth_hold = '0'
         THEN
            l_preauth_date := l_tran_date + (l_preauth_period * (1 / 1440));
         END IF;

         IF l_preauth_hold = '1'
         THEN
            l_preauth_date := l_tran_date + (l_preauth_period * (1 / 24));
         END IF;

         IF l_preauth_hold = '2'
         THEN
            l_preauth_date := l_tran_date + l_preauth_period;
         END IF;

         BEGIN
            INSERT INTO cms_preauth_transaction
                        (cpt_card_no, cpt_txn_amnt, cpt_expiry_date,
                         cpt_sequence_no, cpt_preauth_validflag,
                         cpt_inst_code, cpt_mbr_no, cpt_card_no_encr,
                         cpt_completion_flag,
                         cpt_approve_amt,
                         cpt_rrn, cpt_txn_date, cpt_txn_time,
                         cpt_expiry_flag,
                         cpt_totalhold_amt,
                         cpt_transaction_flag, cpt_acct_no, cpt_preauth_type,CPT_COMPLETION_FEE, cpt_complfree_flag
                        )
                 VALUES (l_hash_pan, l_tran_amt, l_preauth_date,
                         '1', 'Y',
                         p_inst_code_in, p_mbr_numb_in, l_encr_pan,
                         'N',
                         TRIM (TO_CHAR (NVL (l_tran_amt, 0),
                                        '999999999999999990.99'
                                       )
                              ),
                         p_rrn_in, p_tran_date_in, p_tran_time_in,
                         'N',
                         TRIM (TO_CHAR (NVL (l_tran_amt, 0),
                                        '999999999999999990.99'
                                       )
                              ),
                         'N', l_acct_number, l_preauth_type,v_compl_fee,v_compl_feetxn_excd
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Error while inserting PREAUTH TRANSACTION '
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         BEGIN
            INSERT INTO cms_preauth_trans_hist
                        (cph_card_no, cph_txn_amnt, cph_expiry_date,
                         cph_sequence_no, cph_preauth_validflag,
                         cph_inst_code, cph_mbr_no, cph_card_no_encr,
                         cph_completion_flag,
                         cph_approve_amt,
                         cph_rrn, cph_txn_date, cph_expiry_flag,
                         cph_transaction_flag,
                         cph_totalhold_amt,
                         cph_transaction_rrn, cph_acct_no,
                         cph_delivery_channel, cph_tran_code,
                         cph_panno_last4digit,CPH_COMPLETION_FEE
                        )
                 VALUES (l_hash_pan, l_tran_amt, l_preauth_date,
                         p_rrn_in, 'Y',
                         p_inst_code_in, p_mbr_numb_in, l_encr_pan,
                         'N',
                         TRIM (TO_CHAR (NVL (l_tran_amt, 0),
                                        '999999999999999990.99'
                                       )
                              ),
                         p_rrn_in, p_tran_date_in, 'N',
                         'N',
                         TRIM (TO_CHAR (NVL (l_tran_amt, 0),
                                        '999999999999999990.99'
                                       )
                              ),
                         p_rrn_in, l_acct_number,
                         p_delivery_channel_in, p_txn_code_in,
                         (SUBSTR (p_pan_code_in,
                                  LENGTH (p_pan_code_in) - 3,
                                  LENGTH (p_pan_code_in)
                                 )
                         ),v_compl_fee
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Error while inserting  CMS_PREAUTH_TRANS_HIST '
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         IF l_prfl_code IS NOT NULL AND l_prfl_flag = 'Y'
         THEN
            BEGIN
               pkg_limits_check.sp_limitcnt_reset (p_inst_code_in,
                                                   l_hash_pan,
                                                   l_tran_amt,
                                                   l_comb_hash,
                                                   l_resp_cde,
                                                   l_err_msg
                                                  );

               IF l_err_msg <> 'OK'
               THEN
                  l_err_msg :=
                              'From Procedure sp_limitcnt_reset' || l_err_msg;
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_err_msg :=
                        'Error from Limit Reset Count Process '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK TO l_auth_savepoint;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK TO l_auth_savepoint;
      END;






         --Sn Get responce code fomr master
         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code_in
               AND cms_delivery_channel = p_delivery_channel_in
               AND cms_response_id = l_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Problem while selecting data from response master '
                  || l_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '89';
         END;


      --En Get responce code fomr master
      IF l_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in
               AND cap_pan_code = gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO l_acct_bal, l_ledger_bal, l_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_number AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_acct_bal := 0;
            l_ledger_bal := 0;
      END;

      IF l_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      BEGIN
         IF l_cnt = 0
         THEN
            INSERT INTO vms_ild_data
                        (cid_rrn, cid_customer_id, cid_payee_id,
                         cid_txn_code, cid_delivery_channel,
                         cid_txn_amount,
                         cid_partner_id, cid_remarks, cid_resubmit_flag,
                         cid_tran_date, cid_tran_time, cid_ins_timestamp,
                         cid_resp_code
                        )
                 VALUES (p_rrn_in, p_cust_id_in, p_payee_id_in,
                         p_txn_code_in, p_delivery_channel_in,
                         TRIM (TO_CHAR (NVL (l_tran_amt, 0),
                                        '999999999999999990.99'
                                       )
                              ),
                         p_partner_id_in, p_remarks_in, p_resubmit_flag_in,
                         p_tran_date_in, p_tran_time_in, l_time_stamp,
                         p_resp_code_out
                        );
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Error while inserting into ild data table '
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

      --Sn Inserting data in transactionlog
      BEGIN
         sp_log_txnlog (p_inst_code_in,
                        p_msg_type_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_txn_code_in,
                        l_txn_type,
                        p_txn_mode_in,
                        p_tran_date_in,
                        p_tran_time_in,
                        p_rvsl_code_in,
                        l_hash_pan,
                        l_encr_pan,
                        l_err_msg,
                        NULL,
                        l_card_stat,
                        l_trans_desc,
                        NULL,
                        NULL,
                        l_time_stamp,
                        l_acct_number,
                        l_prod_code,
                        l_card_type,
                        l_dr_cr_flag,
                        l_acct_bal,
                        l_ledger_bal,
                        l_acct_type,
                        l_proxy_number,
                        l_auth_id,
                        l_tran_amt,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg,
                        NULL,
                        NULL,
                        p_remarks_in
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '89';
            l_err_msg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         l_reason_code_desc := get_reason_code_desc(p_reason_code_in);
         sp_log_txnlogdetl (p_inst_code_in,
                            p_msg_type_in,
                            p_rrn_in,
                            p_delivery_channel_in,
                            p_txn_code_in,
                            l_txn_type,
                            p_txn_mode_in,
                            p_tran_date_in,
                            p_tran_time_in,
                            l_hash_pan,
                            l_encr_pan,
                            l_err_msg,
                            l_acct_number,
                            l_auth_id,
                            l_tran_amt,
                            NULL,
                            NULL,
                            l_hashkey_id,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            p_resp_code_out,
                            NULL,
                            p_reason_code_in,
                            l_reason_code_desc,
                            l_logdtl_resp,
                            NULL,v_compl_feecode
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

--Sn Inserting data in transactionlog dtl
      IF l_cnt > 0
      THEN
         BEGIN
            SELECT *
              INTO p_resp_code_out, p_org_rrn_out
              FROM (SELECT   cid_resp_code, cid_rrn
                        FROM vms_ild_data
                       WHERE cid_customer_id = p_cust_id_in
                       --  AND cid_payee_id = p_payee_id_in
                         AND cid_txn_code = p_txn_code_in
                         AND cid_delivery_channel = p_delivery_channel_in
                         AND cid_txn_amount = p_txn_amt_in
                         AND cid_partner_id = p_partner_id_in
                         AND cid_tran_date = p_tran_date_in
                         AND cid_tran_time = p_tran_time_in
                    ORDER BY cid_ins_timestamp)
             WHERE ROWNUM = 1;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Problem while selecting data from ild data table '
                  || l_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '89';
         END;
           BEGIN
                UPDATE  vms_ild_data
                     SET cid_resubmit_flag=UPPER(p_resubmit_flag_in)
                     WHERE cid_customer_id = p_cust_id_in
                       --AND cid_payee_id = p_payee_id_in
                       AND cid_txn_code = p_txn_code_in
                       AND cid_delivery_channel = p_delivery_channel_in
                       AND cid_txn_amount = p_txn_amt_in
                       AND cid_partner_id = p_partner_id_in
                       AND cid_tran_date = p_tran_date_in
                       AND cid_tran_time = p_tran_time_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resmsg_out :=
                     'Problem while updating the ild data'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '89';
         END;
      END IF;

      --Assign output variable
      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   END;

   PROCEDURE release_auth_amount (
      p_inst_code_in          IN       NUMBER,
      p_msg_type_in           IN       VARCHAR2,
      p_rrn_in                IN       VARCHAR2,
      p_delivery_channel_in   IN       VARCHAR2,
      p_txn_code_in           IN       VARCHAR2,
      p_txn_mode_in           IN       VARCHAR2,
      p_tran_date_in          IN       VARCHAR2,
      p_tran_time_in          IN       VARCHAR2,
      p_mbr_numb_in           IN       VARCHAR2,
      p_rvsl_code_in          IN       VARCHAR2,
      p_txn_amt_in            IN       NUMBER,
      p_cust_id_in            IN       NUMBER,
      p_pan_code_in           IN       VARCHAR2,
      p_curr_code_in          IN       VARCHAR2,
      p_resubmit_flag_in      IN       VARCHAR2,
      p_remarks_in            IN       VARCHAR2,
      p_reason_code_in        IN       VARCHAR2,
      p_resp_code_out          OUT      VARCHAR2,
      p_resmsg_out             OUT      VARCHAR2,
      p_reversal_amount_out    OUT      VARCHAR2
   )
   IS
      /************************************************************************************************************
       * Created Date     :  15-JUNE-2015
       * Created By       :  Abdul Hameed M.A
       * Created For      :  FSS 1960
       * Reviewer         :  SPankaj
       * Build Number     :  VMSGPRHOSTCSD_3.1_B0001

	    * Modified by                 : DHINAKARAN B
  * Modified Date               : 26-NOV-2019
  * Modified For                : VMS-1415
  * Reviewer                    :  Saravana Kumar A
  * Build Number                :  VMSGPRHOST_R23_B1
  
    * Modified By      : Karthick/Jey
    * Modified Date    : 05-18-2022
    * Purpose          : Archival changes.
    * Reviewer         : Venkat Singamaneni
    * Release Number   : VMSGPRHOST60 for VMS-5739/FSP-991
      ************************************************************************************************************/
      l_auth_savepoint            NUMBER                            DEFAULT 0;
      l_err_msg                   VARCHAR2 (500);
      l_hash_pan                  cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan                  cms_appl_pan.cap_pan_code_encr%TYPE;
      l_txn_type                  transactionlog.txn_type%TYPE;
      l_auth_id                   transactionlog.auth_id%TYPE;
      l_tran_amt                  NUMBER;
      l_prod_code                 cms_appl_pan.cap_prod_code%TYPE;
      l_card_type                 cms_appl_pan.cap_card_type%TYPE;
      l_resp_cde                  VARCHAR2 (5);
      l_hashkey_id                cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_trans_desc                cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag                 cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_acct_number               cms_appl_pan.cap_acct_no%TYPE;
      l_prfl_code                 cms_appl_pan.cap_prfl_code%TYPE;
      l_card_stat                 cms_appl_pan.cap_card_stat%TYPE;
      l_cust_code                 cms_appl_pan.cap_cust_code%TYPE;
      l_preauth_flag              cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_acct_bal                  cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal                cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type                 cms_acct_mast.cam_type_code%TYPE;
      l_proxy_number              cms_appl_pan.cap_proxy_number%TYPE;
      l_fee_code                  transactionlog.feecode%TYPE;
      l_fee_plan                  transactionlog.fee_plan%TYPE;
      l_feeattach_type            transactionlog.feeattachtype%TYPE;
      l_tranfee_amt               transactionlog.tranfee_amt%TYPE;
      l_expry_date                cms_appl_pan.cap_expry_date%TYPE;
      l_login_txn                 cms_transaction_mast.ctm_login_txn%TYPE;
      l_logdtl_resp               VARCHAR2 (500);
      l_preauth_type              cms_transaction_mast.ctm_preauth_type%TYPE;
      l_tran_date                 DATE;
      l_orgnl_delivery_channel    transactionlog.delivery_channel%TYPE;
      l_orgnl_resp_code           transactionlog.response_code%TYPE;
      l_orgnl_txn_code            transactionlog.txn_code%TYPE;
      l_orgnl_txn_mode            transactionlog.txn_mode%TYPE;
      l_orgnl_business_date       transactionlog.business_date%TYPE;
      l_orgnl_business_time       transactionlog.business_time%TYPE;
      l_orgnl_customer_card_no    transactionlog.customer_card_no%TYPE;
      l_reversal_amt              NUMBER (9, 2);
      l_orgnl_txn_feecode         cms_fee_mast.cfm_fee_code%TYPE;
      l_orgnl_txn_totalfee_amt    transactionlog.tranfee_amt%TYPE;
      l_orgnl_transaction_type    transactionlog.cr_dr_flag%TYPE;
      l_actual_dispatched_amt     transactionlog.amount%TYPE;
      l_dr_cr_flag                transactionlog.cr_dr_flag%TYPE;
      l_rvsl_trandate             DATE;
      l_actual_feecode            transactionlog.feecode%TYPE;
      l_orgnl_tranfee_amt         transactionlog.tranfee_amt%TYPE;
      l_orgnl_servicetax_amt      transactionlog.servicetax_amt%TYPE;
      l_orgnl_cess_amt            transactionlog.cess_amt%TYPE;
      l_orgnl_cr_dr_flag          transactionlog.cr_dr_flag%TYPE;
      l_orgnl_tranfee_cr_acctno   transactionlog.tranfee_cr_acctno%TYPE;
      l_orgnl_tranfee_dr_acctno   transactionlog.tranfee_dr_acctno%TYPE;
      l_orgnl_st_calc_flag        transactionlog.tran_st_calc_flag%TYPE;
      l_orgnl_cess_calc_flag      transactionlog.tran_cess_calc_flag%TYPE;
      l_orgnl_st_cr_acctno        transactionlog.tran_st_cr_acctno%TYPE;
      l_orgnl_st_dr_acctno        transactionlog.tran_st_dr_acctno%TYPE;
      l_orgnl_cess_cr_acctno      transactionlog.tran_cess_cr_acctno%TYPE;
      l_orgnl_cess_dr_acctno      transactionlog.tran_cess_dr_acctno%TYPE;
      l_gl_upd_flag               transactionlog.gl_upd_flag%TYPE;
      l_tran_reverse_flag         transactionlog.tran_reverse_flag%TYPE;
      l_cutoff_time               VARCHAR2 (5);
      l_business_time             VARCHAR2 (5);
      exp_rvsl_reject_record      EXCEPTION;
      l_card_curr                 VARCHAR2 (5);
      l_preauth_expiry_flag       CHARACTER (1);
      l_hold_amount               NUMBER;
      l_max_card_bal              NUMBER;
      l_fee_narration             cms_statements_log.csl_trans_narrration%TYPE;
      l_tot_fee_amount            transactionlog.tranfee_amt%TYPE;
      l_tot_amount                transactionlog.amount%TYPE;
      l_fee_amt                   NUMBER;
      l_chnge_crdstat             VARCHAR2 (2)                         := 'N';
      l_time_stamp                 TIMESTAMP ( 3 );
      l_orgnl_txn_fee_plan        transactionlog.fee_plan%TYPE;
      l_feecap_flag               VARCHAR2 (1);
      l_orgnl_fee_amt             cms_fee_mast.cfm_fee_amt%TYPE;
      l_reversal_amt_flag         VARCHAR2 (1)                         := 'F';
      l_tran_type                 cms_transaction_mast.ctm_tran_type%TYPE;
      l_add_ins_date              transactionlog.add_ins_date%TYPE;
        l_profile_code   cms_prod_cattype.cpc_profile_code%type;
l_badcredit_flag             cms_prod_cattype.cpc_badcredit_flag%TYPE;
   l_badcredit_transgrpid       vms_group_tran_detl.vgd_group_id%TYPE;
     l_cnt       number;
         l_cap_card_stat                  cms_appl_pan.cap_card_stat%TYPE   := '12';
     l_enable_flag                VARCHAR2 (20)                          := 'Y';
   l_initialload_amt         cms_acct_mast.cam_new_initialload_amt%type;
    v_completion_fee             cms_preauth_transaction.cpt_completion_fee%TYPE;
        v_complfree_flag             cms_preauth_transaction.cpt_complfree_flag%TYPE;
        v_comp_fee_code              cms_fee_mast.cfm_fee_code%TYPE;
      l_reason_code_desc     vms_reason_mast.VRM_REASON_DESC%TYPE;
	  v_Retperiod  date;  --Added for VMS-5739/FSP-991
      v_Retdate  date; --Added for VMS-5739/FSP-991
     
	 CURSOR l_cur_stmnts_log
      IS
         SELECT csl_trans_narrration, csl_merchant_name, csl_merchant_city,
                csl_merchant_state, csl_trans_amount
           FROM VMSCMS.CMS_STATEMENTS_LOG_VW    								--Added for VMS-5739/FSP-991
          WHERE csl_business_date = l_orgnl_business_date
            AND csl_rrn = p_rrn_in
            AND csl_delivery_channel = l_orgnl_delivery_channel
            AND csl_txn_code = l_orgnl_txn_code
            AND csl_pan_no = l_orgnl_customer_card_no
            AND csl_inst_code = p_inst_code_in
            AND txn_fee_flag = 'Y';
   BEGIN
      l_resp_cde := '1';
      l_time_stamp := SYSTIMESTAMP;

      BEGIN
         SAVEPOINT l_auth_savepoint;

         --Sn Get the HashPan
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Error while converting hash pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --En Get the HashPan
         --Sn Create encr pan
         BEGIN
            l_encr_pan := fn_emaps_main (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Error while converting emcrypted pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --Start Generate HashKEY value
         BEGIN
            l_hashkey_id :=
               gethash (   p_delivery_channel_in
                        || p_txn_code_in
                        || p_pan_code_in
                        || p_rrn_in
                        || TO_CHAR (l_time_stamp, 'YYYYMMDDHH24MISSFF5')
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error while Generating  hashkey id data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --End Generate HashKEY
             --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   cap_prfl_code, cap_expry_date, cap_proxy_number,
                   cap_cust_code
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   l_prfl_code, l_expry_date, l_proxy_number,
                   l_cust_code
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'Card number not found ' || l_encr_pan;
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Problem while selecting card detail'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --End Get the card details
         --Sn find debit and credit flag
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag, ctm_login_txn
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag, l_login_txn
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Transaction not defined for txn code '
                  || p_txn_code_in
                  || ' and delivery channel '
                  || p_delivery_channel_in;
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg := 'Error while selecting transaction details';
               RAISE exp_rvsl_reject_record;
         END;

         --En find debit and credit flag
         --Sn generate auth id
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO l_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';                         -- Server Declined
               RAISE exp_rvsl_reject_record;
         END;
         BEGIN
            SELECT cpc_profile_code,cpc_badcredit_flag,cpc_badcredit_transgrpid
            into l_profile_code,l_badcredit_flag,l_badcredit_transgrpid
              FROM cms_prod_cattype
             WHERE cpc_inst_code = p_inst_code_in
               AND cpc_prod_code = l_prod_code
               AND cpc_card_type = l_card_type;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Error while selecting from cms_prod_cattype '
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';                         -- Server Declined
               RAISE exp_rvsl_reject_record;
         END;

         --En generate auth id
         BEGIN
            l_rvsl_trandate :=
               TO_DATE (   SUBSTR (TRIM (p_tran_date_in), 1, 8)
                        || ' '
                        || SUBSTR (TRIM (p_tran_time_in), 1, 8),
                        'yyyymmdd hh24:mi:ss'
                       );
            l_tran_date := l_rvsl_trandate;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while converting transaction date '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --Sn check msg type
         IF (p_msg_type_in != '0400') OR (p_rvsl_code_in = '00')
         THEN
            l_resp_cde := '12';
            l_err_msg := 'Not a valid reversal request';
            RAISE exp_rvsl_reject_record;
         END IF;

         --En check msg type
         --Sn check orginal transaction
         BEGIN
            SELECT delivery_channel, response_code,
                   txn_code, txn_mode,
                   business_date, business_time,
                   customer_card_no, feecode,
                   fee_plan, tranfee_amt,
                   cr_dr_flag, feecode,
                   tranfee_amt, servicetax_amt,
                   cess_amt, tranfee_cr_acctno,
                   tranfee_dr_acctno, tran_st_calc_flag,
                   tran_cess_calc_flag, tran_st_cr_acctno,
                   tran_st_dr_acctno, tran_cess_cr_acctno,
                   tran_cess_dr_acctno, tran_reverse_flag,
                   gl_upd_flag, add_ins_date
              INTO l_orgnl_delivery_channel, l_orgnl_resp_code,
                   l_orgnl_txn_code, l_orgnl_txn_mode,
                   l_orgnl_business_date, l_orgnl_business_time,
                   l_orgnl_customer_card_no, l_orgnl_txn_feecode,
                   l_orgnl_txn_fee_plan, l_orgnl_txn_totalfee_amt,
                   l_orgnl_transaction_type, l_actual_feecode,
                   l_orgnl_tranfee_amt, l_orgnl_servicetax_amt,
                   l_orgnl_cess_amt, l_orgnl_tranfee_cr_acctno,
                   l_orgnl_tranfee_dr_acctno, l_orgnl_st_calc_flag,
                   l_orgnl_cess_calc_flag, l_orgnl_st_cr_acctno,
                   l_orgnl_st_dr_acctno, l_orgnl_cess_cr_acctno,
                   l_orgnl_cess_dr_acctno, l_tran_reverse_flag,
                   l_gl_upd_flag, l_add_ins_date
              FROM VMSCMS.TRANSACTIONLOG  							 --Added for VMS-5739/FSP-991
             WHERE rrn = p_rrn_in
               AND customer_card_no = l_hash_pan
               AND instcode = p_inst_code_in
               AND delivery_channel = p_delivery_channel_in
               AND txn_code = p_txn_code_in
               AND msgtype='0100';
			    IF SQL%ROWCOUNT = 0 THEN
				
            SELECT delivery_channel, response_code,
                   txn_code, txn_mode,
                   business_date, business_time,
                   customer_card_no, feecode,
                   fee_plan, tranfee_amt,
                   cr_dr_flag, feecode,
                   tranfee_amt, servicetax_amt,
                   cess_amt, tranfee_cr_acctno,
                   tranfee_dr_acctno, tran_st_calc_flag,
                   tran_cess_calc_flag, tran_st_cr_acctno,
                   tran_st_dr_acctno, tran_cess_cr_acctno,
                   tran_cess_dr_acctno, tran_reverse_flag,
                   gl_upd_flag, add_ins_date
              INTO l_orgnl_delivery_channel, l_orgnl_resp_code,
                   l_orgnl_txn_code, l_orgnl_txn_mode,
                   l_orgnl_business_date, l_orgnl_business_time,
                   l_orgnl_customer_card_no, l_orgnl_txn_feecode,
                   l_orgnl_txn_fee_plan, l_orgnl_txn_totalfee_amt,
                   l_orgnl_transaction_type, l_actual_feecode,
                   l_orgnl_tranfee_amt, l_orgnl_servicetax_amt,
                   l_orgnl_cess_amt, l_orgnl_tranfee_cr_acctno,
                   l_orgnl_tranfee_dr_acctno, l_orgnl_st_calc_flag,
                   l_orgnl_cess_calc_flag, l_orgnl_st_cr_acctno,
                   l_orgnl_st_dr_acctno, l_orgnl_cess_cr_acctno,
                   l_orgnl_cess_dr_acctno, l_tran_reverse_flag,
                   l_gl_upd_flag, l_add_ins_date
              FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST  							 --Added for VMS-5739/FSP-991
             WHERE rrn = p_rrn_in
               AND customer_card_no = l_hash_pan
               AND instcode = p_inst_code_in
               AND delivery_channel = p_delivery_channel_in
               AND txn_code = p_txn_code_in
               AND msgtype='0100';
				END IF;

            IF l_orgnl_resp_code <> '00'
            THEN
               l_resp_cde := '23';
               l_err_msg := ' The original transaction was not successful';
               RAISE exp_rvsl_reject_record;
            END IF;

            IF l_tran_reverse_flag = 'Y'
            THEN
               l_resp_cde := '52';
               l_err_msg :=
                      'The reversal already done for the orginal transaction';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '53';
               l_err_msg := 'Matching transaction not found';
               RAISE exp_rvsl_reject_record;
            WHEN TOO_MANY_ROWS
            THEN
               BEGIN
                  SELECT SUM (tranfee_amt), SUM (amount)
                    INTO l_tot_fee_amount, l_tot_amount
                    FROM VMSCMS.TRANSACTIONLOG                                            --Added for VMS-5739/FSP-991
                   WHERE rrn = p_rrn_in
                     AND customer_card_no = l_hash_pan
                     AND instcode = p_inst_code_in
                     AND response_code = '00';
					 IF SQL%ROWCOUNT = 0 THEN
					  SELECT SUM (tranfee_amt), SUM (amount)
                    INTO l_tot_fee_amount, l_tot_amount
                    FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                             --Added for VMS-5739/FSP-991
                   WHERE rrn = p_rrn_in
                     AND customer_card_no = l_hash_pan
                     AND instcode = p_inst_code_in
                     AND response_code = '00';
					 END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_resp_cde := '21';
                     l_err_msg :=
                           'Error while selecting TRANSACTIONLOG '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;

               IF (l_tot_fee_amount IS NULL) AND (l_tot_amount IS NULL)
               THEN
                  l_resp_cde := '21';
                  l_err_msg :=
                     'More than one failure matching record found in the master';
                  RAISE exp_rvsl_reject_record;


               ELSE
                  BEGIN
                     SELECT delivery_channel, response_code,
                            txn_code, txn_mode,
                            business_date, business_time,
                            customer_card_no, feecode,
                            fee_plan, tranfee_amt,
                            cr_dr_flag, feecode,
                            tranfee_amt, servicetax_amt,
                            cess_amt, tranfee_cr_acctno,
                            tranfee_dr_acctno, tran_st_calc_flag,
                            tran_cess_calc_flag, tran_st_cr_acctno,
                            tran_st_dr_acctno, tran_cess_cr_acctno,
                            tran_cess_dr_acctno, tran_reverse_flag,
                            gl_upd_flag, add_ins_date
                       INTO l_orgnl_delivery_channel, l_orgnl_resp_code,
                            l_orgnl_txn_code, l_orgnl_txn_mode,
                            l_orgnl_business_date, l_orgnl_business_time,
                            l_orgnl_customer_card_no, l_orgnl_txn_feecode,
                            l_orgnl_txn_fee_plan, l_orgnl_txn_totalfee_amt,
                            l_orgnl_transaction_type, l_actual_feecode,
                            l_orgnl_tranfee_amt, l_orgnl_servicetax_amt,
                            l_orgnl_cess_amt, l_orgnl_tranfee_cr_acctno,
                            l_orgnl_tranfee_dr_acctno, l_orgnl_st_calc_flag,
                            l_orgnl_cess_calc_flag, l_orgnl_st_cr_acctno,
                            l_orgnl_st_dr_acctno, l_orgnl_cess_cr_acctno,
                            l_orgnl_cess_dr_acctno, l_tran_reverse_flag,
                            l_gl_upd_flag, l_add_ins_date
                       FROM VMSCMS.TRANSACTIONLOG                                            --Added for VMS-5739/FSP-991
                      WHERE rrn = p_rrn_in
                        AND customer_card_no = l_hash_pan
                        AND instcode = p_inst_code_in
                        AND response_code = '00'
                        AND delivery_channel = p_delivery_channel_in
                        AND txn_code = p_txn_code_in
                        AND msgtype='0100'
                        AND ROWNUM = 1;
						IF SQL%ROWCOUNT = 0 THEN
						SELECT delivery_channel, response_code,
                            txn_code, txn_mode,
                            business_date, business_time,
                            customer_card_no, feecode,
                            fee_plan, tranfee_amt,
                            cr_dr_flag, feecode,
                            tranfee_amt, servicetax_amt,
                            cess_amt, tranfee_cr_acctno,
                            tranfee_dr_acctno, tran_st_calc_flag,
                            tran_cess_calc_flag, tran_st_cr_acctno,
                            tran_st_dr_acctno, tran_cess_cr_acctno,
                            tran_cess_dr_acctno, tran_reverse_flag,
                            gl_upd_flag, add_ins_date
                       INTO l_orgnl_delivery_channel, l_orgnl_resp_code,
                            l_orgnl_txn_code, l_orgnl_txn_mode,
                            l_orgnl_business_date, l_orgnl_business_time,
                            l_orgnl_customer_card_no, l_orgnl_txn_feecode,
                            l_orgnl_txn_fee_plan, l_orgnl_txn_totalfee_amt,
                            l_orgnl_transaction_type, l_actual_feecode,
                            l_orgnl_tranfee_amt, l_orgnl_servicetax_amt,
                            l_orgnl_cess_amt, l_orgnl_tranfee_cr_acctno,
                            l_orgnl_tranfee_dr_acctno, l_orgnl_st_calc_flag,
                            l_orgnl_cess_calc_flag, l_orgnl_st_cr_acctno,
                            l_orgnl_st_dr_acctno, l_orgnl_cess_cr_acctno,
                            l_orgnl_cess_dr_acctno, l_tran_reverse_flag,
                            l_gl_upd_flag, l_add_ins_date
                       FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                                            --Added for VMS-5739/FSP-991
                      WHERE rrn = p_rrn_in
                        AND customer_card_no = l_hash_pan
                        AND instcode = p_inst_code_in
                        AND response_code = '00'
                        AND delivery_channel = p_delivery_channel_in
                        AND txn_code = p_txn_code_in
                        AND msgtype='0100'
                        AND ROWNUM = 1;
						END IF;

                     l_orgnl_txn_totalfee_amt := l_tot_fee_amount;
                     l_orgnl_tranfee_amt := l_tot_fee_amount;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        l_resp_cde := '21';
                        l_err_msg := 'NO DATA IN TRANSACTIONLOG2';
                        RAISE exp_rvsl_reject_record;
                     WHEN OTHERS
                     THEN
                        l_resp_cde := '21';
                        l_err_msg :=
                              'Error while selecting TRANSACTIONLOG2 '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_rvsl_reject_record;
                  END;

                  --Added to check the reversal already done
                  IF l_tran_reverse_flag = 'Y'
                  THEN
                     l_resp_cde := '52';
                     l_err_msg :=
                        'The reversal already done for the orginal transaction';
                     RAISE exp_rvsl_reject_record;
                  END IF;
               END IF;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error while selecting master data'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --En check orginal transaction
              --Sn find the converted tran amt
         l_tran_amt := p_txn_amt_in;

         IF (p_txn_amt_in >= 0)
         THEN
            BEGIN
               sp_convert_curr (p_inst_code_in,
                                p_curr_code_in,
                                p_pan_code_in,
                                p_txn_amt_in,
                                l_rvsl_trandate,
                                l_tran_amt,
                                l_card_curr,
                                l_err_msg,
								l_prod_code,
								l_card_type
                               );

               IF l_err_msg <> 'OK'
               THEN
                  l_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';              -- Server Declined -220509
                  l_err_msg :=
                        'Error from currency conversion '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         ELSE
            l_resp_cde := '25';
            l_err_msg := 'INVALID AMOUNT';
            RAISE exp_rvsl_reject_record;
         END IF;

         --En find the  converted tran amt
          ---Sn check card number
         IF l_orgnl_customer_card_no <> l_hash_pan
         THEN
            l_resp_cde := '21';
            l_err_msg :=
               'Customer card number is not matching in reversal and orginal transaction';
            RAISE exp_rvsl_reject_record;
         END IF;

         --En check card number
         --Sn check amount with orginal transaction
         IF (l_tran_amt IS NULL OR l_tran_amt = 0)
         THEN
            l_actual_dispatched_amt := 0;
         ELSE
            l_actual_dispatched_amt := l_tran_amt;
         END IF;

         --En check amount with orginal transaction
         --Sn Check PreAuth Completion txn
         BEGIN
		 --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_PREAUTH_TRANSACTION_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
            SELECT cpt_totalhold_amt, cpt_expiry_flag,
                   NVL (cpt_preauth_type, 'D'),cpt_completion_fee,nvl(cpt_complfree_flag,'N')
              INTO l_hold_amount, l_preauth_expiry_flag,
                   l_preauth_type,v_completion_fee,v_complfree_flag
              FROM VMSCMS.CMS_PREAUTH_TRANSACTION                                           --Added for VMS-5739/FSP-991
             WHERE cpt_rrn = p_rrn_in
               AND cpt_txn_date = l_orgnl_business_date
               AND cpt_inst_code = p_inst_code_in
               AND cpt_mbr_no = p_mbr_numb_in
               AND cpt_card_no = l_hash_pan;
	ELSE
	 SELECT cpt_totalhold_amt, cpt_expiry_flag,
                   NVL (cpt_preauth_type, 'D'),cpt_completion_fee,nvl(cpt_complfree_flag,'N')
              INTO l_hold_amount, l_preauth_expiry_flag,
                   l_preauth_type,v_completion_fee,v_complfree_flag
              FROM VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST                                           --Added for VMS-5739/FSP-991
             WHERE cpt_rrn = p_rrn_in
               AND cpt_txn_date = l_orgnl_business_date
               AND cpt_inst_code = p_inst_code_in
               AND cpt_mbr_no = p_mbr_numb_in
               AND cpt_card_no = l_hash_pan;
END IF;	
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '53';
               l_err_msg := 'Matching transaction not found';
               RAISE exp_rvsl_reject_record;
            WHEN TOO_MANY_ROWS
            THEN
               l_resp_cde := '21';                   --Ineligible Transaction
               l_err_msg := 'More than one record found ';
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';                   --Ineligible Transaction
               l_err_msg := 'Error while selecting the PreAuth details';
               RAISE exp_rvsl_reject_record;
         END;

         --En Check PreAuth Completion txn
         BEGIN
            IF l_hold_amount <= 0
            THEN
               l_resp_cde := '58';
               l_err_msg := 'There is no hold amount for reversal';
               RAISE exp_rvsl_reject_record;
            ELSE
               IF (l_hold_amount < l_actual_dispatched_amt)
               THEN
                  l_resp_cde := '59';
                  l_err_msg :=
                     'Reversal amount exceeds the original transaction amount';
                  RAISE exp_rvsl_reject_record;
               END IF;
            END IF;

            l_reversal_amt := l_hold_amount - l_actual_dispatched_amt;

            IF l_reversal_amt < l_hold_amount
            THEN
               l_reversal_amt_flag := 'P';
            END IF;
         END;

         --Sn Check the Flag for Reversal transaction
         IF l_preauth_flag != 'Y'
         THEN
            IF l_dr_cr_flag = 'NA'
            THEN
               l_resp_cde := '21';
               l_err_msg := 'Not a valid orginal transaction for reversal';
               RAISE exp_rvsl_reject_record;
            END IF;
         END IF;

         --En Check the Flag for Reversal transaction
          --Sn Check the transaction type with Original txn type
         IF l_dr_cr_flag <> l_orgnl_transaction_type
         THEN
            l_resp_cde := '21';
            l_err_msg :=
               'Orginal transaction type is not matching with actual transaction type';
            RAISE exp_rvsl_reject_record;
         END IF;

         --En Check the transaction type
         ---Sn find cutoff time
         BEGIN
            SELECT cip_param_value
              INTO l_cutoff_time
              FROM cms_inst_param
             WHERE cip_param_key = 'CUTOFF' AND cip_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_cutoff_time := 0;
               l_resp_cde := '21';
               l_err_msg := 'Cutoff time is not defined in the system';
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg := 'Error while selecting cutoff  dtl  from system ';
               RAISE exp_rvsl_reject_record;
         END;

         ---En find cutoff time
         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code,
            nvl(cam_new_initialload_amt,cam_initialload_amt)
                  INTO l_acct_bal, l_ledger_bal, l_acct_type,l_initialload_amt
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in
            FOR UPDATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account  detail '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --Sn Check for maximum card balance configured for the product profile.
         BEGIN
            SELECT TO_NUMBER (cbp_param_value)
              INTO l_max_card_bal
              FROM cms_bin_param
             WHERE cbp_inst_code = p_inst_code_in
               AND cbp_param_name = 'Max Card Balance'
               AND cbp_profile_code=l_profile_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'NO CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ';
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;
IF l_badcredit_flag = 'Y'
         THEN
            EXECUTE IMMEDIATE    'SELECT  count(*)
              FROM vms_group_tran_detl
              WHERE vgd_group_id ='
                              || l_badcredit_transgrpid
                              || '
              AND vgd_tran_detl LIKE
              (''%'
                              || p_delivery_channel_in
                              || ':'
                              || p_txn_code_in
                              || '%'')'
                         INTO l_cnt;

            IF l_cnt = 1
               THEN
               l_enable_flag := 'N';
               IF    ((l_acct_bal + l_reversal_amt) > l_initialload_amt
                     )                                     --initialloadamount
                  OR ((l_ledger_bal + l_reversal_amt) > l_initialload_amt
                     )
               THEN                                        --initialloadamount
                  UPDATE cms_appl_pan
                     SET cap_card_stat = '18'
                   WHERE cap_inst_code = p_inst_code_in
                     AND cap_pan_code = l_hash_pan;

                  l_chnge_crdstat := 'Y';
               END IF;
            END IF;
         END IF;
         IF l_enable_flag = 'Y'
                  THEN
            IF    ((l_acct_bal + l_reversal_amt) > l_max_card_bal)
               OR ((l_ledger_bal + l_reversal_amt) > l_max_card_bal)
            THEN
               l_resp_cde := '30';
               l_err_msg := 'EXCEEDING MAXIMUM CARD BALANCE';
                     RAISE exp_rvsl_reject_record;
                  END IF;

               END IF;
         -- En Check for maximum card balance configured for the product profile.
--         IF    ((l_acct_bal + l_reversal_amt) > l_max_card_bal)
--            OR ((l_ledger_bal + l_reversal_amt) > l_max_card_bal)
--         THEN
--            BEGIN
--               IF l_card_stat <> '12'
--               THEN
--              IF l_badcredit_flag = 'Y' THEN
--             execute immediate 'SELECT  count(*)
--                FROM vms_group_tran_detl
--                WHERE vgd_group_id ='|| l_badcredit_transgrpid||'
--                AND vgd_tran_detl LIKE
--                (''%'||p_delivery_channel_in ||':'|| p_txn_code_in||'%'')'
--            into l_cnt;
--                IF l_cnt = 1 THEN
--                     l_cap_card_stat := '18';
--               END IF;
--            END IF;
--                  UPDATE cms_appl_pan
--                     SET cap_card_stat = l_cap_card_stat
--                   WHERE cap_pan_code = l_hash_pan
--                     AND cap_inst_code = p_inst_code_in;
--
--                  IF SQL%ROWCOUNT = 0
--                  THEN
--                     l_err_msg := 'Error while updating the card status';
--                     l_resp_cde := '21';
--                     RAISE exp_rvsl_reject_record;
--                  END IF;
--
--                  l_chnge_crdstat := 'Y';
--               END IF;
--            EXCEPTION
--               WHEN OTHERS
--               THEN
--                  l_resp_cde := '21';
--                  l_err_msg :=
--                        'Error while updating cms_appl_pan '
--                     || SUBSTR (SQLERRM, 1, 200);
--                  RAISE exp_rvsl_reject_record;
--            END;
--         END IF;

         IF l_preauth_type != 'C'
         THEN
            BEGIN
               sp_reverse_card_amount (p_inst_code_in,
                                       NULL,
                                       p_rrn_in,
                                       p_delivery_channel_in,
                                       NULL,
                                       NULL,
                                       p_txn_code_in,
                                       l_rvsl_trandate,
                                       p_txn_mode_in,
                                       p_pan_code_in,
                                       (l_reversal_amt+v_completion_fee),
                                       p_rrn_in,
                                       l_acct_number,
                                       p_tran_date_in,
                                       p_tran_time_in,
                                       l_auth_id,
                                       NULL,
                                       l_orgnl_business_date,
                                       l_orgnl_business_time,
                                       NULL,
                                       NULL,
                                       NULL,
                                       l_resp_cde,
                                       l_err_msg
                                      );

               IF l_resp_cde <> '00' OR l_err_msg <> 'OK'
               THEN
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_err_msg :=
                        'Error while reversing the amount '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         --En reverse the amount
         END IF;

         --Added For Reversal Fees
         IF l_reversal_amt_flag <> 'P'
         THEN
            IF l_orgnl_txn_totalfee_amt > 0
               OR l_orgnl_txn_feecode IS NOT NULL
            THEN
               BEGIN
                  SELECT cfm_feecap_flag, cfm_fee_amt
                    INTO l_feecap_flag, l_orgnl_fee_amt
                    FROM cms_fee_mast
                   WHERE cfm_inst_code = p_inst_code_in
                     AND cfm_fee_code = l_orgnl_txn_feecode;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     l_feecap_flag := '';
                  WHEN OTHERS
                  THEN
                     l_err_msg :=
                           'Error in feecap flag fetch '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;

               BEGIN
                  FOR l_row_idx IN l_cur_stmnts_log
                  LOOP
                     l_orgnl_tranfee_amt := l_row_idx.csl_trans_amount;

                     IF l_feecap_flag = 'Y'
                     THEN
                        BEGIN
                           sp_tran_fees_revcapcheck (p_inst_code_in,
                                                     l_acct_number,
                                                     l_orgnl_business_date,
                                                     l_orgnl_tranfee_amt,
                                                     l_orgnl_fee_amt,
                                                     l_orgnl_txn_fee_plan,
                                                     l_orgnl_txn_feecode,
                                                     l_err_msg
                                                    );
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              l_resp_cde := '21';
                              l_err_msg :=
                                    'Error while reversing the fee Cap amount '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE exp_rvsl_reject_record;
                        END;
                     END IF;

                     BEGIN
                        sp_reverse_fee_amount (p_inst_code_in,
                                               p_rrn_in,
                                               p_delivery_channel_in,
                                               NULL,
                                               NULL,
                                               p_txn_code_in,
                                               l_rvsl_trandate,
                                               p_txn_mode_in,
                                               l_orgnl_tranfee_amt,
                                               p_pan_code_in,
                                               l_actual_feecode,
                                               l_orgnl_tranfee_amt,
                                               l_orgnl_tranfee_cr_acctno,
                                               l_orgnl_tranfee_dr_acctno,
                                               l_orgnl_st_calc_flag,
                                               l_orgnl_servicetax_amt,
                                               l_orgnl_st_cr_acctno,
                                               l_orgnl_st_dr_acctno,
                                               l_orgnl_cess_calc_flag,
                                               l_orgnl_cess_amt,
                                               l_orgnl_cess_cr_acctno,
                                               l_orgnl_cess_dr_acctno,
                                               p_rrn_in,
                                               l_acct_number,
                                               p_tran_date_in,
                                               p_tran_time_in,
                                               l_auth_id,
                                               l_row_idx.csl_trans_narrration,
                                               NULL,
                                               NULL,
                                               NULL,
                                               l_resp_cde,
                                               l_err_msg
                                              );
                        l_fee_narration := l_row_idx.csl_trans_narrration;

                        IF l_resp_cde <> '00' OR l_err_msg <> 'OK'
                        THEN
                           RAISE exp_rvsl_reject_record;
                        END IF;
                     EXCEPTION
                        WHEN exp_rvsl_reject_record
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           l_resp_cde := '21';
                           l_err_msg :=
                                 'Error while reversing the fee amount '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_rvsl_reject_record;
                     END;
                  END LOOP;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     l_fee_narration := NULL;
                  WHEN OTHERS
                  THEN
                     l_fee_narration := NULL;
               END;
            END IF;

            --Added For Reversal Fees
            IF l_fee_narration IS NULL
            THEN
               IF l_feecap_flag = 'Y'
               THEN
                  BEGIN
                     sp_tran_fees_revcapcheck (p_inst_code_in,
                                               l_acct_number,
                                               l_orgnl_business_date,
                                               l_orgnl_tranfee_amt,
                                               l_orgnl_fee_amt,
                                               l_orgnl_txn_fee_plan,
                                               l_orgnl_txn_feecode,
                                               l_err_msg
                                              );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_resp_cde := '21';
                        l_err_msg :=
                              'Error while reversing the fee Cap amount '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_rvsl_reject_record;
                  END;
               END IF;

               BEGIN
                  sp_reverse_fee_amount (p_inst_code_in,
                                         p_rrn_in,
                                         p_delivery_channel_in,
                                         NULL,
                                         NULL,
                                         p_txn_code_in,
                                         l_rvsl_trandate,
                                         p_txn_mode_in,
                                         l_orgnl_txn_totalfee_amt,
                                         p_pan_code_in,
                                         l_actual_feecode,
                                         l_orgnl_tranfee_amt,
                                         l_orgnl_tranfee_cr_acctno,
                                         l_orgnl_tranfee_dr_acctno,
                                         l_orgnl_st_calc_flag,
                                         l_orgnl_servicetax_amt,
                                         l_orgnl_st_cr_acctno,
                                         l_orgnl_st_dr_acctno,
                                         l_orgnl_cess_calc_flag,
                                         l_orgnl_cess_amt,
                                         l_orgnl_cess_cr_acctno,
                                         l_orgnl_cess_dr_acctno,
                                         p_rrn_in,
                                         l_acct_number,
                                         p_tran_date_in,
                                         p_tran_time_in,
                                         l_auth_id,
                                         l_fee_narration,
                                         NULL,
                                         NULL,
                                         NULL,
                                         l_resp_cde,
                                         l_err_msg
                                        );

                  IF l_resp_cde <> '00' OR l_err_msg <> 'OK'
                  THEN
                     RAISE exp_rvsl_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_rvsl_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     l_resp_cde := '21';
                     l_err_msg :=
                           'Error while reversing the fee amount '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;
            END IF;
         END IF;

         --En reverse the fee
         IF l_gl_upd_flag = 'Y'
         THEN
            --Sn find business date
            l_business_time := TO_CHAR (l_rvsl_trandate, 'HH24:MI');

            IF l_business_time > l_cutoff_time
            THEN
               l_rvsl_trandate := TRUNC (l_rvsl_trandate) + 1;
            ELSE
               l_rvsl_trandate := TRUNC (l_rvsl_trandate);
            END IF;
         --En find businesses date
         END IF;

         l_resp_cde := '1';

         BEGIN
		--Added for VMS-5735/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date_in), 1, 8), 'yyyymmdd');
	   
	   IF (v_Retdate>v_Retperiod)THEN											--Added for VMS-5739/FSP-991

            UPDATE cms_statements_log
               SET csl_prod_code = l_prod_code,
                    csl_card_type=l_card_type,
                   csl_acct_type = l_acct_type,
                   csl_time_stamp = l_time_stamp
             WHERE csl_inst_code = p_inst_code_in
               AND csl_pan_no = l_hash_pan
               AND csl_rrn = p_rrn_in
               AND csl_txn_code = p_txn_code_in
               AND csl_delivery_channel = p_delivery_channel_in
               AND csl_business_date = p_tran_date_in
               AND csl_business_time = p_tran_time_in;
		
		ELSE
			
			UPDATE VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST 					--Added for VMS-5739/FSP-991
               SET csl_prod_code = l_prod_code,
                    csl_card_type=l_card_type,
                   csl_acct_type = l_acct_type,
                   csl_time_stamp = l_time_stamp
             WHERE csl_inst_code = p_inst_code_in
               AND csl_pan_no = l_hash_pan
               AND csl_rrn = p_rrn_in
               AND csl_txn_code = p_txn_code_in
               AND csl_delivery_channel = p_delivery_channel_in
               AND csl_business_date = p_tran_date_in
               AND csl_business_time = p_tran_time_in;	
		
		END IF;	

            IF SQL%ROWCOUNT = 0
            THEN
               NULL;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error while updating timestamp in statementlog-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --Sn Logging of system initiated card status change
         IF l_chnge_crdstat = 'Y'
         THEN
            BEGIN
               sp_log_cardstat_chnge (p_inst_code_in,
                                      l_hash_pan,
                                      l_encr_pan,
                                      l_auth_id,
                                      '10',
                                      p_rrn_in,
                                      p_tran_date_in,
                                      p_tran_time_in,
                                      l_resp_cde,
                                      l_err_msg
                                     );

               IF l_resp_cde <> '00' AND l_err_msg <> 'OK'
               THEN
                  RAISE exp_rvsl_reject_record;
               END IF;

               l_resp_cde := '1';
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_err_msg :=
                        'Error while logging system initiated card status change '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         END IF;

           --En Logging of system initiated card status change
         --Sn generate response code
         BEGIN
            INSERT INTO cms_preauth_trans_hist
                        (cph_card_no, cph_mbr_no, cph_inst_code,
                         cph_card_no_encr, cph_preauth_validflag,
                         cph_completion_flag, cph_txn_amnt, cph_rrn,
                         cph_txn_date, cph_txn_time, cph_orgnl_rrn,
                         cph_orgnl_txn_date, cph_orgnl_txn_time,
                         cph_orgnl_card_no, cph_transaction_flag,
                         cph_delivery_channel, cph_tran_code,
                         cph_panno_last4digit,
                         cph_acct_no
                        )
                 VALUES (l_hash_pan, p_mbr_numb_in, p_inst_code_in,
                         l_encr_pan, 'N',
                         'N', p_txn_amt_in, p_rrn_in,
                         p_tran_date_in, p_tran_time_in, p_rrn_in,
                         l_orgnl_business_date, l_orgnl_business_time,
                         l_hash_pan, 'R',
                         p_delivery_channel_in, p_txn_code_in,
                         (SUBSTR (p_pan_code_in,
                                  LENGTH (p_pan_code_in) - 3,
                                  LENGTH (p_pan_code_in)
                                 )
                         ),
                         l_acct_number
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Error while inserting  CMS_PREAUTH_TRANS_HIST'
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';
               RAISE exp_rvsl_reject_record;
         END;

         BEGIN
            IF l_preauth_expiry_flag = 'N'
            THEN
               IF l_actual_dispatched_amt = 0
               THEN
                  BEGIN
				  
				  --Added for VMS-5739/FSP-991
			 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
				   INTO   v_Retperiod 
				   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
				   WHERE  OPERATION_TYPE='ARCHIVE' 
				   AND OBJECT_NAME='CMS_PREAUTH_TRANSACTION_EBR';
				   
				   v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


			IF (v_Retdate>v_Retperiod)
				THEN
                     UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION						--Added for VMS-5739/FSP-991
                        SET cpt_totalhold_amt =
                               TRIM (TO_CHAR (l_actual_dispatched_amt,
                                              '999999999999999990.99'
                                             )
                                    ),
                            cpt_transaction_rrn = p_rrn_in,
                            cpt_preauth_validflag = 'N',
                            cpt_transaction_flag = 'R'
                      WHERE cpt_rrn = p_rrn_in
                        AND cpt_txn_date = l_orgnl_business_date
                        AND cpt_txn_time = l_orgnl_business_time
                        AND cpt_mbr_no = p_mbr_numb_in
                        AND cpt_inst_code = p_inst_code_in
                        AND cpt_card_no = l_hash_pan;
						
			ELSE
			
			  UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST              --Added for VMS-5739/FSP-991
                        SET cpt_totalhold_amt =
                               TRIM (TO_CHAR (l_actual_dispatched_amt,
                                              '999999999999999990.99'
                                             )
                                    ),
                            cpt_transaction_rrn = p_rrn_in,
                            cpt_preauth_validflag = 'N',
                            cpt_transaction_flag = 'R'
                      WHERE cpt_rrn = p_rrn_in
                        AND cpt_txn_date = l_orgnl_business_date
                        AND cpt_txn_time = l_orgnl_business_time
                        AND cpt_mbr_no = p_mbr_numb_in
                        AND cpt_inst_code = p_inst_code_in
                        AND cpt_card_no = l_hash_pan;
			
			END IF ;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        l_err_msg :=
                              'RECORD NOT UPDATED IN CMS_PREAUTH_TRANSACTION';
                        l_resp_cde := '21';
                        RAISE exp_rvsl_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_rvsl_reject_record
                     THEN
                        RAISE exp_rvsl_reject_record;
                     WHEN OTHERS
                     THEN
                        l_err_msg :=
                              'Error while updating  CMS_PREAUTH_TRANSACTION'
                           || SUBSTR (SQLERRM, 1, 300);
                        l_resp_cde := '21';
                        RAISE exp_rvsl_reject_record;
                  END;
               ELSE
                  BEGIN
				  
				  IF (v_Retdate>v_Retperiod)
				THEN
				
                     UPDATE VMSCMS.CMS_PREAUTH_TRANSACTION							--Added for VMS-5739/FSP-991
                        SET cpt_totalhold_amt =
                               TRIM (TO_CHAR (l_actual_dispatched_amt,
                                              '999999999999999990.99'
                                             )
                                    ),
                            cpt_transaction_rrn = p_rrn_in,
                            cpt_transaction_flag = 'R'
                      WHERE cpt_rrn = p_rrn_in
                        AND cpt_txn_date = l_orgnl_business_date
                        AND cpt_txn_time = l_orgnl_business_time
                        AND cpt_mbr_no = p_mbr_numb_in
                        AND cpt_inst_code = p_inst_code_in
                        AND cpt_card_no = l_hash_pan;
                 ELSE
				 
				 UPDATE VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST --Added for VMS-5739/FSP-991
                        SET cpt_totalhold_amt =
                               TRIM (TO_CHAR (l_actual_dispatched_amt,
                                              '999999999999999990.99'
                                             )
                                    ),
                            cpt_transaction_rrn = p_rrn_in,
                            cpt_transaction_flag = 'R'
                      WHERE cpt_rrn = p_rrn_in
                        AND cpt_txn_date = l_orgnl_business_date
                        AND cpt_txn_time = l_orgnl_business_time
                        AND cpt_mbr_no = p_mbr_numb_in
                        AND cpt_inst_code = p_inst_code_in
                        AND cpt_card_no = l_hash_pan;
				 				 
				 END IF;
                     IF SQL%ROWCOUNT = 0
                     THEN
                        l_err_msg :=
                             'RECORD NOT UPDATED IN CMS_PREAUTH_TRANSACTION1';
                        l_resp_cde := '21';
                        RAISE exp_rvsl_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_rvsl_reject_record
                     THEN
                        RAISE exp_rvsl_reject_record;
                     WHEN OTHERS
                     THEN
                        l_err_msg :=
                              'Error while updating  CMS_PREAUTH_TRANSACTION1 '
                           || SUBSTR (SQLERRM, 1, 300);
                        l_resp_cde := '21';
                        RAISE exp_rvsl_reject_record;
                  END;
               END IF;

            END IF;
         END;

         --Sn update reverse flag
         BEGIN
		 
		 --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');
		 
		 IF (v_Retdate>v_Retperiod)
				THEN
				
            UPDATE VMSCMS.TRANSACTIONLOG    									--Added for VMS-5739/FSP-991
               SET tran_reverse_flag = 'Y'
             WHERE rrn = p_rrn_in
               AND business_date = l_orgnl_business_date
               AND business_time = l_orgnl_business_time
               AND customer_card_no = l_hash_pan
               AND instcode = p_inst_code_in;
			   
		  ELSE
		  
		   UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5739/FSP-991
               SET tran_reverse_flag = 'Y'
             WHERE rrn = p_rrn_in
               AND business_date = l_orgnl_business_date
               AND business_time = l_orgnl_business_time
               AND customer_card_no = l_hash_pan
               AND instcode = p_inst_code_in;
		  
		  END IF;

            IF SQL%ROWCOUNT = 0
            THEN
               l_resp_cde := '21';
               l_err_msg := 'Reverse flag is not updated ';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error while updating gl flag ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

          --En update reverse flag


           IF
                v_complfree_flag = 'Y' AND v_completion_fee = 0 THEN
            BEGIN
			--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
             SELECT
                    ctd_compfee_code
                INTO
                    v_comp_fee_code
                FROM
                    VMSCMS.CMS_TRANSACTION_LOG_DTL										--Added for VMS-5739/FSP-991
                WHERE
                    ctd_rrn = p_rrn_in
                    AND   ctd_business_date = l_orgnl_business_date
                    AND   ctd_business_time = l_orgnl_business_time
                    AND   ctd_customer_card_no = l_hash_pan
                    AND   ctd_inst_code = p_inst_code_in
                    AND   ctd_txn_code = p_txn_code_in
                    AND   ctd_delivery_channel = p_delivery_channel_in;
			ELSE
			  SELECT
                    ctd_compfee_code
                INTO
                    v_comp_fee_code
                FROM
                    VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST										--Added for VMS-5739/FSP-991
                WHERE
                    ctd_rrn = p_rrn_in
                    AND   ctd_business_date = l_orgnl_business_date
                    AND   ctd_business_time = l_orgnl_business_time
                    AND   ctd_customer_card_no = l_hash_pan
                    AND   ctd_inst_code = p_inst_code_in
                    AND   ctd_txn_code = p_txn_code_in
                    AND   ctd_delivery_channel = p_delivery_channel_in;
END IF;			
               vmsfee.fee_freecnt_reverse (l_acct_number, l_orgnl_txn_feecode, l_err_msg);

               IF l_err_msg <> 'OK' THEN
                  l_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record THEN
                  RAISE;
               WHEN OTHERS THEN
                  l_resp_cde := '21';
                  l_err_msg :='Error while reversing freefee count-'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
          END IF;


         --Sn Added  for enabling limit validation
         IF     l_add_ins_date IS NOT NULL
            AND l_prfl_code IS NOT NULL
            AND l_prfl_flag = 'Y'
         THEN
            BEGIN
               pkg_limits_check.sp_limitcnt_rever_reset (p_inst_code_in,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         p_txn_code_in,
                                                         l_tran_type,
                                                         NULL,
                                                         NULL,
                                                         l_prfl_code,
                                                         l_reversal_amt,
                                                         l_hold_amount,
                                                         p_delivery_channel_in,
                                                         l_hash_pan,
                                                         l_add_ins_date,
                                                         l_resp_cde,
                                                         l_err_msg
                                                        );

               IF l_err_msg <> 'OK'
               THEN
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_err_msg :=
                        'Error from Limit count rever Process '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         END IF;
      EXCEPTION
         WHEN exp_rvsl_reject_record
         THEN
            ROLLBACK TO l_auth_savepoint;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK TO l_auth_savepoint;
      END;

      --Sn Get responce code fomr master
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code_out
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code_in
            AND cms_delivery_channel = p_delivery_channel_in
            AND cms_response_id = l_resp_cde;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while selecting data from response master '
               || l_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

      --En Get responce code fomr master
      IF l_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in
               AND cap_pan_code = gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO l_acct_bal, l_ledger_bal, l_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_number AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_acct_bal := 0;
            l_ledger_bal := 0;
      END;

      IF l_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      --Sn Inserting data in transactionlog
      BEGIN
         sp_log_txnlog (p_inst_code_in,
                        p_msg_type_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_txn_code_in,
                        l_txn_type,
                        p_txn_mode_in,
                        p_tran_date_in,
                        p_tran_time_in,
                        p_rvsl_code_in,
                        l_hash_pan,
                        l_encr_pan,
                        l_err_msg,
                        NULL,
                        l_card_stat,
                        l_trans_desc,
                        NULL,
                        NULL,
                        l_time_stamp,
                        l_acct_number,
                        l_prod_code,
                        l_card_type,
                        l_dr_cr_flag,
                        l_acct_bal,
                        l_ledger_bal,
                        l_acct_type,
                        l_proxy_number,
                        l_auth_id,
                        NVL (l_reversal_amt, l_tran_amt),
                          NVL (l_reversal_amt, l_tran_amt)
                        + NVL (l_orgnl_txn_totalfee_amt, 0),
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg,
                        NULL,
                        NULL,
                        p_remarks_in
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '89';
            l_err_msg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
      END;

      --En Inserting data in transactionlog
      --Sn Inserting data in transactionlog dtl
      BEGIN
         l_reason_code_desc := get_reason_code_desc(p_reason_code_in);
         sp_log_txnlogdetl (p_inst_code_in,
                            p_msg_type_in,
                            p_rrn_in,
                            p_delivery_channel_in,
                            p_txn_code_in,
                            l_txn_type,
                            p_txn_mode_in,
                            p_tran_date_in,
                            p_tran_time_in,
                            l_hash_pan,
                            l_encr_pan,
                            l_err_msg,
                            l_acct_number,
                            l_auth_id,
                            NVL (l_reversal_amt, l_tran_amt),
                            NULL,
                            NULL,
                            l_hashkey_id,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            p_resp_code_out,
                            NULL,
                            p_reason_code_in,
                            l_reason_code_desc,
                            l_logdtl_resp
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

--Sn Inserting data in transactionlog dtl
      IF UPPER (TRIM (p_resubmit_flag_in)) = 'Y' AND l_resp_cde = '52'
      THEN
         p_resp_code_out := l_orgnl_resp_code;

           BEGIN
                UPDATE  vms_ild_data
                     SET cid_resubmit_flag=UPPER(p_resubmit_flag_in)
                     WHERE cid_customer_id = p_cust_id_in
                       AND cid_txn_code = p_txn_code_in
                       AND cid_delivery_channel = p_delivery_channel_in
                       AND cid_txn_amount = p_txn_amt_in
                       AND cid_rrn = p_rrn_in
                       AND cid_tran_date = l_orgnl_business_date
                       AND cid_tran_time = l_orgnl_business_time;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resmsg_out :=
                     'Problem while updating the ild data'
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '89';
         END;

      END IF;

      p_resmsg_out := l_err_msg;
      p_reversal_amount_out := l_reversal_amt;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   END;

   PROCEDURE settle_auth_amount (
      p_inst_code_in          IN       NUMBER,
      p_msg_type_in           IN       VARCHAR2,
      p_rrn_in                IN       VARCHAR2,
      p_delivery_channel_in   IN       VARCHAR2,
      p_txn_code_in           IN       VARCHAR2,
      p_txn_mode_in           IN       VARCHAR2,
      p_tran_date_in          IN       VARCHAR2,
      p_tran_time_in          IN       VARCHAR2,
      p_mbr_numb_in           IN       VARCHAR2,
      p_rvsl_code_in          IN       VARCHAR2,
      p_txn_amt_in            IN       NUMBER,
      p_cust_id_in            IN       NUMBER,
      p_pan_code_in           IN       VARCHAR2,
      p_curr_code_in          IN       VARCHAR2,
      p_remarks_in            IN       VARCHAR2,
      p_reason_code_in        IN       VARCHAR2,
      p_resp_code_out          OUT      VARCHAR2,
      p_resmsg_out             OUT      VARCHAR2
   )
   IS
      /************************************************************************************************************
       * Created Date     :  15-JUNE-2015
       * Created By       :  Abdul Hameed M.A
       * Created For      :  FSS 1960
       * Reviewer         :  SPankaj
       * Build Number     :  VMSGPRHOSTCSD_3.1_B0001

	    * Modified by                 : DHINAKARAN B
  * Modified Date               : 26-NOV-2019
  * Modified For                : VMS-1415
  * Reviewer                    :  Saravana Kumar A
  * Build Number                :  VMSGPRHOST_R23_B1
      ************************************************************************************************************/
      l_auth_savepoint        NUMBER                                DEFAULT 0;
      l_err_msg               VARCHAR2 (500);
      l_hash_pan              cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan              cms_appl_pan.cap_pan_code_encr%TYPE;
      l_txn_type              transactionlog.txn_type%TYPE;
      l_auth_id               transactionlog.auth_id%TYPE;
      exp_reject_record       EXCEPTION;
      l_dr_cr_flag            VARCHAR2 (2);
      l_tran_type             VARCHAR2 (2);
      l_tran_amt              NUMBER;
      l_prod_code             cms_appl_pan.cap_prod_code%TYPE;
      l_card_type             cms_appl_pan.cap_card_type%TYPE;
      l_resp_cde              VARCHAR2 (5);
      l_time_stamp            TIMESTAMP;
      l_hashkey_id            cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_trans_desc            cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag             cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_acct_number           cms_appl_pan.cap_acct_no%TYPE;
      l_prfl_code             cms_appl_pan.cap_prfl_code%TYPE;
      l_card_stat             cms_appl_pan.cap_card_stat%TYPE;
      l_cust_code             cms_appl_pan.cap_cust_code%TYPE;
      l_preauth_flag          cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_acct_bal              cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal            cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type             cms_acct_mast.cam_type_code%TYPE;
      l_proxy_number          cms_appl_pan.cap_proxy_number%TYPE;
      l_fee_code              transactionlog.feecode%TYPE;
      l_fee_plan              transactionlog.fee_plan%TYPE;
      l_feeattach_type        transactionlog.feeattachtype%TYPE;
      l_tranfee_amt           transactionlog.tranfee_amt%TYPE;
      l_total_amt             transactionlog.total_amount%TYPE;
      l_expry_date            cms_appl_pan.cap_expry_date%TYPE;
      l_comb_hash             pkg_limits_check.type_hash;
      l_login_txn             cms_transaction_mast.ctm_login_txn%TYPE;
      l_logdtl_resp           VARCHAR2 (500);
      l_preauth_type          cms_transaction_mast.ctm_preauth_type%TYPE;
      l_preauth_exp_period    CMS_PROD_CATTYPE.CPC_ONUS_AUTH_EXPIRY%TYPE;
      l_tran_date             DATE;
      l_preauth_hold          VARCHAR2 (1);
      l_preauth_period        NUMBER;
      l_preauth_date          DATE;
      l_cnt                   NUMBER                                     := 0;
      l_card_curr             VARCHAR2 (5);
      l_pre_auth_check        CHAR (1)                                 := 'N';
      l_expired_auth_count    NUMBER;
      l_rowid                 VARCHAR2 (40);
      l_preauth_amount        NUMBER;
      l_preauth_valid_flag    CHARACTER (1);
      l_preauth_expiry_flag   CHARACTER (1);
      l_hold_amount           NUMBER                                     := 0;
      l_cpt_rrn               cms_preauth_transaction.cpt_rrn%TYPE;
      l_proxy_hold_amount     VARCHAR2 (12)                             := '';
      l_max_card_bal          NUMBER;
      l_dup_compl_cnt         NUMBER;
      v_completion_fee cms_preauth_transaction.cpt_completion_fee%TYPE;
      v_compl_feetxn_excd varchar2(10);
      v_compl_feecode varchar2(10);
      l_reason_code_desc     vms_reason_mast.VRM_REASON_DESC%TYPE;
   BEGIN
      l_resp_cde := '1';
      l_time_stamp := SYSTIMESTAMP;

      BEGIN
         SAVEPOINT l_auth_savepoint;
         l_tran_amt := NVL (ROUND (p_txn_amt_in, 2), 0);

         --Sn Get the HashPan
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Error while converting hash pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En Get the HashPan

         --Sn Create encr pan
         BEGIN
            l_encr_pan := fn_emaps_main (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Error while converting emcrypted pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --Start Generate HashKEY value
         BEGIN
            l_hashkey_id :=
               gethash (   p_delivery_channel_in
                        || p_txn_code_in
                        || p_pan_code_in
                        || p_rrn_in
                        || TO_CHAR (l_time_stamp, 'YYYYMMDDHH24MISSFF5')
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error while Generating  hashkey id data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --End Generate HashKEY

         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   cap_prfl_code, cap_expry_date, cap_proxy_number,
                   cap_cust_code
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   l_prfl_code, l_expry_date, l_proxy_number,
                   l_cust_code
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'Card number not found ' || l_encr_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Problem while selecting card detail'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --End Get the card details

         --Sn find debit and credit flag
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag, ctm_login_txn, ctm_preauth_type
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag, l_login_txn, l_preauth_type
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Transaction not defined for txn code '
                  || p_txn_code_in
                  || ' and delivery channel '
                  || p_delivery_channel_in;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg := 'Error while selecting transaction details';
               RAISE exp_reject_record;
         END;

         --En find debit and credit flag

         --Sn generate auth id
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO l_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';                         -- Server Declined
               RAISE exp_reject_record;
         END;

         --En generate auth id
         BEGIN
            l_tran_date :=
               TO_DATE (   SUBSTR (TRIM (p_tran_date_in), 1, 8)
                        || ' '
                        || SUBSTR (TRIM (p_tran_time_in), 1, 10),
                        'yyyymmdd hh24:mi:ss'
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while converting transaction date '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;


         -- To Convert Currency
         IF p_txn_amt_in IS NOT NULL
         THEN
            IF (p_txn_amt_in > 0)
            THEN
               l_tran_amt := p_txn_amt_in;

               BEGIN
                  sp_convert_curr (p_inst_code_in,
                                   p_curr_code_in,
                                   p_pan_code_in,
                                   p_txn_amt_in,
                                   l_tran_date,
                                   l_tran_amt,
                                   l_card_curr,
                                   l_err_msg,
								   l_prod_code,
								   l_card_type
                                  );

                  IF l_err_msg <> 'OK'
                  THEN
                     l_resp_cde := '21';
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     l_resp_cde := '21';
                     l_err_msg :=
                           'Error from currency conversion '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            ELSE
               l_resp_cde := '25';
               l_err_msg := 'INVALID AMOUNT';
               RAISE exp_reject_record;
            END IF;
         END IF;

         -- End  Convert Currency

           BEGIN

         SELECT count(1)
           INTO l_dup_compl_cnt
           FROM VMSCMS.TRANSACTIONLOG								--Added for VMS-5739/FSP-991
          WHERE rrn = p_rrn_in
            AND customer_card_no = l_hash_pan
            AND delivery_channel = p_delivery_channel_in
            AND txn_code=p_txn_code_in
            AND response_code='00';
			IF SQL%ROWCOUNT = 0 THEN
			  SELECT count(1)
           INTO l_dup_compl_cnt
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST								--Added for VMS-5739/FSP-991
          WHERE rrn = p_rrn_in
            AND customer_card_no = l_hash_pan
            AND delivery_channel = p_delivery_channel_in
            AND txn_code=p_txn_code_in
            AND response_code='00';
			END IF;

            IF l_dup_compl_cnt > 0 THEN

                l_resp_cde := '244';
                l_err_msg := 'Successful settlement already done';
                RAISE exp_reject_record;

            END IF;

      EXCEPTION

         WHEN exp_reject_record
         THEN
         RAISE;

         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg :=
               'Error while selecting duplicate settlement count'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;


         BEGIN
            SELECT ROWID, cpt_txn_amnt, cpt_preauth_validflag,
                   cpt_totalhold_amt, cpt_expiry_flag, cpt_rrn,nvl(cpt_completion_fee,'0')
              INTO l_rowid, l_preauth_amount, l_preauth_valid_flag,
                   l_hold_amount, l_preauth_expiry_flag, l_cpt_rrn,v_completion_fee
              FROM  VMSCMS.CMS_PREAUTH_TRANSACTION											--Added for VMS-5739/FSP-991		
             WHERE cpt_mbr_no = p_mbr_numb_in
               AND cpt_inst_code = p_inst_code_in
               AND cpt_rrn = p_rrn_in
               AND cpt_card_no = l_hash_pan
               AND cpt_preauth_validflag <> 'N'
               AND cpt_expiry_flag = 'N'
               AND cpt_preauth_type = l_preauth_type;
			    IF SQL%ROWCOUNT = 0 THEN
				    SELECT ROWID, cpt_txn_amnt, cpt_preauth_validflag,
                   cpt_totalhold_amt, cpt_expiry_flag, cpt_rrn,nvl(cpt_completion_fee,'0')
              INTO l_rowid, l_preauth_amount, l_preauth_valid_flag,
                   l_hold_amount, l_preauth_expiry_flag, l_cpt_rrn,v_completion_fee
              FROM  VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST										--Added for VMS-5739/FSP-991		
             WHERE cpt_mbr_no = p_mbr_numb_in
               AND cpt_inst_code = p_inst_code_in
               AND cpt_rrn = p_rrn_in
               AND cpt_card_no = l_hash_pan
               AND cpt_preauth_validflag <> 'N'
               AND cpt_expiry_flag = 'N'
               AND cpt_preauth_type = l_preauth_type;
				END IF;

            l_pre_auth_check := 'Y';
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN NO_DATA_FOUND
            THEN
               SELECT COUNT (1)
                 INTO l_expired_auth_count
                 FROM VMSCMS.CMS_PREAUTH_TRANSACTION										--Added for VMS-5739/FSP-991
                WHERE cpt_mbr_no = p_mbr_numb_in
                  AND cpt_inst_code = p_inst_code_in
                  AND cpt_rrn = p_rrn_in
                  AND cpt_card_no = l_hash_pan
                  AND cpt_preauth_type = l_preauth_type
                  AND cpt_expiry_flag = 'Y';
				  IF SQL%ROWCOUNT = 0 THEN
				    SELECT COUNT (1)
                 INTO l_expired_auth_count
                 FROM VMSCMS_HISTORY.CMS_PREAUTH_TRANSACTION_HIST										--Added for VMS-5739/FSP-991
                WHERE cpt_mbr_no = p_mbr_numb_in
                  AND cpt_inst_code = p_inst_code_in
                  AND cpt_rrn = p_rrn_in
                  AND cpt_card_no = l_hash_pan
                  AND cpt_preauth_type = l_preauth_type
                  AND cpt_expiry_flag = 'Y';
				  END IF;

               IF l_expired_auth_count > 0
               THEN
                  l_pre_auth_check := 'N';
               ELSE
                  l_resp_cde := '243';
                  l_err_msg := 'Matching Transaction not Found';
                  RAISE exp_reject_record;
               END IF;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';                   --Ineligible Transaction
               l_err_msg :=
                     'Error while selecting  PreAuth details '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;



         BEGIN
            SELECT DECODE (l_pre_auth_check,
                           'Y', l_hold_amount || l_preauth_expiry_flag || 'L',
                           0
                          )
              INTO l_proxy_hold_amount
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Error while generating V_PROXY_HOLD_AMOUNT '
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in
            FOR UPDATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account  detail '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            sp_fee_calc (p_inst_code_in,
                         p_msg_type_in,
                         p_rrn_in,
                         p_delivery_channel_in,
                         p_txn_code_in,
                         p_txn_mode_in,
                         p_tran_date_in,
                         p_tran_time_in,
                         p_mbr_numb_in,
                         p_rvsl_code_in,
                         l_txn_type,
                         p_curr_code_in,
                         l_tran_amt,
                         p_pan_code_in,
                         l_hash_pan,
                         l_encr_pan,
                         l_acct_number,
                         l_prod_code,
                         l_card_type,
                         l_preauth_flag,
                         NULL,
                         NULL,
                         NULL,
                         l_trans_desc,
                         l_dr_cr_flag,
                         l_acct_bal,
                         l_ledger_bal,
                         l_acct_type,
                         l_login_txn,
                         l_auth_id,
                         l_time_stamp,
                         l_resp_cde,
                         l_err_msg,
                         l_fee_code,
                         l_fee_plan,
                         l_feeattach_type,
                         l_tranfee_amt,
                         l_total_amt,
                         v_completion_fee,
                         v_compl_feetxn_excd ,
                         v_compl_feecode,
                         l_preauth_type,
                         l_card_stat,
                         l_proxy_hold_amount
                        );

            IF l_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                       'Error from sp_fee_calc  ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         l_resp_cde := '1';

         BEGIN
            INSERT INTO cms_preauth_trans_hist
                        (cph_card_no, cph_txn_amnt,
                         cph_sequence_no, cph_preauth_validflag,
                         cph_inst_code, cph_mbr_no, cph_card_no_encr,
                         cph_completion_flag,
                         cph_approve_amt,
                         cph_rrn, cph_txn_date, cph_expiry_flag,
                         cph_transaction_flag,
                         cph_totalhold_amt,
                         cph_transaction_rrn, cph_acct_no,
                         cph_delivery_channel, cph_tran_code,
                         cph_panno_last4digit,cph_txn_time,cph_orgnl_rrn,cph_preauth_type
                        )
                 VALUES (l_hash_pan, l_tran_amt,
                         p_rrn_in, 'N',
                         p_inst_code_in, p_mbr_numb_in, l_encr_pan,
                         'C',
                         TRIM (TO_CHAR (NVL (l_tran_amt, 0),
                                        '999999999999999990.99'
                                       )
                              ),
                         p_rrn_in, p_tran_date_in, 'N',
                         'C',
                         TRIM (TO_CHAR (NVL (l_tran_amt, 0),
                                        '999999999999999990.99'
                                       )
                              ),
                         p_rrn_in, l_acct_number,
                         p_delivery_channel_in, p_txn_code_in,
                         (SUBSTR (p_pan_code_in,
                                  LENGTH (p_pan_code_in) - 3,
                                  LENGTH (p_pan_code_in)
                                 )
                         ),p_tran_time_in,p_rrn_in,l_preauth_type
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Error while inserting  CMS_PREAUTH_TRANS_HIST '
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         BEGIN
            IF l_pre_auth_check = 'Y'
            THEN
               UPDATE cms_preauth_transaction
                  SET cpt_preauth_validflag = 'N',
                      cpt_totalhold_amt = '0.00',
                      cpt_exp_release_amount = (l_hold_amount - l_tran_amt),
                      cpt_completion_flag = 'Y'
                WHERE ROWID = l_rowid AND cpt_preauth_validflag = 'Y';

               IF SQL%ROWCOUNT = 0
               THEN
                  l_err_msg :=
                        'Problem while updating data in CMS_PREAUTH_TRANSACTION 4 '
                     || SUBSTR (SQLERRM, 1, 300);
                  l_resp_cde := '21';
                  RAISE exp_reject_record;
               END IF;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Problem While Updating the Pre-Auth Completion transaction details of the card'
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';
               RAISE exp_reject_record;
         END;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK TO l_auth_savepoint;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK TO l_auth_savepoint;
      END;

      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code_out
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code_in
            AND cms_delivery_channel = p_delivery_channel_in
            AND cms_response_id = l_resp_cde;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while selecting data from response master '
               || l_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

      --En Get responce code fomr master
      IF l_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in
               AND cap_pan_code = gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO l_acct_bal, l_ledger_bal, l_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_number AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_acct_bal := 0;
            l_ledger_bal := 0;
      END;

      IF l_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      --Sn Inserting data in transactionlog
      BEGIN
         sp_log_txnlog (p_inst_code_in,
                        p_msg_type_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_txn_code_in,
                        l_txn_type,
                        p_txn_mode_in,
                        p_tran_date_in,
                        p_tran_time_in,
                        p_rvsl_code_in,
                        l_hash_pan,
                        l_encr_pan,
                        l_err_msg,
                        NULL,
                        l_card_stat,
                        l_trans_desc,
                        NULL,
                        NULL,
                        l_time_stamp,
                        l_acct_number,
                        l_prod_code,
                        l_card_type,
                        l_dr_cr_flag,
                        l_acct_bal,
                        l_ledger_bal,
                        l_acct_type,
                        l_proxy_number,
                        l_auth_id,
                        l_tran_amt,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg,
                        NULL,
                        NULL,
                        p_remarks_in
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '89';
            l_err_msg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         l_reason_code_desc := get_reason_code_desc(p_reason_code_in);
         sp_log_txnlogdetl (p_inst_code_in,
                            p_msg_type_in,
                            p_rrn_in,
                            p_delivery_channel_in,
                            p_txn_code_in,
                            l_txn_type,
                            p_txn_mode_in,
                            p_tran_date_in,
                            p_tran_time_in,
                            l_hash_pan,
                            l_encr_pan,
                            l_err_msg,
                            l_acct_number,
                            l_auth_id,
                            l_tran_amt,
                            NULL,
                            NULL,
                            l_hashkey_id,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            p_resp_code_out,
                            NULL,
                            p_reason_code_in,
                            l_reason_code_desc,
                            l_logdtl_resp
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   END;
    PROCEDURE  inquire_cellphone_number (
          p_inst_code_in         in    number,
          p_msg_type_in          in       varchar2,
          p_rrn_in               in      varchar2,
          p_delivery_channel_in  in      varchar2,
          p_txn_code_in          in      varchar2,
          p_txn_mode_in          in      varchar2,
          p_tran_date_in         in      varchar2,
          p_tran_time_in         in      varchar2,
          p_mbr_numb_in          in      varchar2,
          p_rvsl_code_in         in      varchar2,
          p_cust_id_in           in      number,
          p_pan_code_in          in      varchar2,
          p_curr_code_in         in      varchar2,
          p_reason_code_in       IN      VARCHAR2,
          p_resp_code_out         out     varchar2,
          p_resmsg_out            out     varchar2,
          p_cell_no_out           out     varchar2
   )
   IS
      /************************************************************************************************************
       * Created Date     :  15-JUNE-2015
       * Created By       :  Abdul Hameed M.A
       * Created For      :  FSS 1960
       * Reviewer         :  SPankaj
       * Build Number     :  VMSGPRHOSTCSD_3.1_B0001

	   	 * Modified By      : Sreeja D
     * Modified Date    : 25/01/2018
     * Purpose          : VMS-162
     * Reviewer         : SaravanaKumar A/Vini Pushkaran
     * Release Number   : VMSGPRHOST18.01

	   * Modified by                 : DHINAKARAN B
  * Modified Date               : 26-NOV-2019
  * Modified For                : VMS-1415
  * Reviewer                    :  Saravana Kumar A
  * Build Number                :  VMSGPRHOST_R23_B1
      ************************************************************************************************************/
      l_auth_savepoint       NUMBER                                 DEFAULT 0;
      l_err_msg              VARCHAR2 (500);
      l_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
      l_txn_type             transactionlog.txn_type%TYPE;
      l_auth_id              transactionlog.auth_id%TYPE;
      exp_reject_record      EXCEPTION;
      l_dr_cr_flag           VARCHAR2 (2);
      l_tran_type            VARCHAR2 (2);
      l_tran_amt             NUMBER;
      l_prod_code            cms_appl_pan.cap_prod_code%TYPE;
      l_card_type            cms_appl_pan.cap_card_type%TYPE;
      l_resp_cde             VARCHAR2 (5);
      l_time_stamp           TIMESTAMP;
      l_hashkey_id           cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_trans_desc           cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag            cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_acct_number          cms_appl_pan.cap_acct_no%TYPE;
      l_prfl_code            cms_appl_pan.cap_prfl_code%TYPE;
      l_card_stat            cms_appl_pan.cap_card_stat%TYPE;
      l_cust_code            cms_appl_pan.cap_cust_code%TYPE;
      l_preauth_flag         cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_acct_bal             cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal           cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type            cms_acct_mast.cam_type_code%TYPE;
      l_proxy_number         cms_appl_pan.cap_proxy_number%TYPE;
      l_fee_code             transactionlog.feecode%TYPE;
      l_fee_plan             transactionlog.fee_plan%TYPE;
      l_feeattach_type       transactionlog.feeattachtype%TYPE;
      l_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_total_amt            transactionlog.total_amount%TYPE;
      l_expry_date           cms_appl_pan.cap_expry_date%TYPE;
      l_comb_hash            pkg_limits_check.type_hash;
      l_login_txn            cms_transaction_mast.ctm_login_txn%TYPE;
      l_logdtl_resp          VARCHAR2 (500);
      l_preauth_type         cms_transaction_mast.ctm_preauth_type%TYPE;
      l_cell_no              cms_cust_mast.CCM_MOBL_ONE%TYPE;
	  L_ENCRYPT_ENABLE       cms_prod_cattype.cpc_encrypt_enable%TYPE;
      v_compl_fee            varchar2(10);
      v_compl_feetxn_excd varchar2(10);
       v_compl_feecode varchar2(10);
      l_reason_code_desc     vms_reason_mast.VRM_REASON_DESC%TYPE;
   BEGIN
      l_resp_cde := '1';
      l_time_stamp := SYSTIMESTAMP;
      BEGIN
         SAVEPOINT l_auth_savepoint;
         l_tran_amt :=  0;
         --Sn Get the HashPan
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Error while converting hash pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         --En Get the HashPan
         --Sn Create encr pan
         BEGIN
            l_encr_pan := fn_emaps_main (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Error while converting emcrypted pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         --Start Generate HashKEY value
         BEGIN
            l_hashkey_id :=
               gethash (   p_delivery_channel_in
                        || p_txn_code_in
                        || p_pan_code_in
                        || p_rrn_in
                        || TO_CHAR (l_time_stamp, 'YYYYMMDDHH24MISSFF5')
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error while Generating  hashkey id data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         --End Generate HashKEY
         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   cap_prfl_code, cap_expry_date, cap_proxy_number,
                   cap_cust_code
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   l_prfl_code, l_expry_date, l_proxy_number,
                   l_cust_code
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'Card number not found ' || l_encr_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Problem while selecting card detail'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         --End Get the card details

	 BEGIN
		SELECT  CPC_ENCRYPT_ENABLE
		INTO  L_ENCRYPT_ENABLE
		FROM CMS_PROD_CATTYPE
		WHERE CPC_INST_CODE = P_INST_CODE_IN
		AND CPC_PROD_CODE = L_PROD_CODE
		AND CPC_CARD_TYPE = L_card_type;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       l_resp_cde := '21';
       l_err_msg  := 'No data found in CMS_PROD_CATTYPE for encrpt enable flag' || SUBSTR (SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       l_resp_cde := '21';
       l_err_msg  := 'Error while selcting encrypt enable flag' || SUBSTR (SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;
         --Sn find debit and credit flag
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag, ctm_login_txn, ctm_preauth_type
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag, l_login_txn, l_preauth_type
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Transaction not defined for txn code '
                  || p_txn_code_in
                  || ' and delivery channel '
                  || p_delivery_channel_in;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg := 'Error while selecting transaction details';
               RAISE exp_reject_record;
         END;
         --En find debit and credit flag
         --Sn generate auth id
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO l_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';                         -- Server Declined
               RAISE exp_reject_record;
         END;
         --En generate auth id
          BEGIN
            sp_cmsauth_check (p_inst_code_in,
                              p_msg_type_in,
                              p_rrn_in,
                              p_delivery_channel_in,
                              p_txn_code_in,
                              p_txn_mode_in,
                              p_tran_date_in,
                              p_tran_time_in,
                              p_mbr_numb_in,
                              p_rvsl_code_in,
                              l_tran_type,
                              p_curr_code_in,
                              l_tran_amt,
                              p_pan_code_in,
                              l_hash_pan,
                              l_encr_pan,
                              l_card_stat,
                              l_expry_date,
                              l_prod_code,
                              l_card_type,
                              l_prfl_flag,
                              l_prfl_code,
                              NULL,
                              NULL,
                              NULL,
                              l_resp_cde,
                              l_err_msg,
                              l_comb_hash
                             );
            IF l_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error from  cmsauth Check Procedure  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in
            FOR UPDATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account  detail '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
       BEGIN

     /*  SELECT CCM_MOBL_ONE into l_cell_no
       FROM cms_cust_mast
        WHERE CCM_CUST_ID =p_cust_id_in
           and CCM_INST_CODE=p_inst_code_in;*/

           SELECT decode(l_encrypt_enable,'Y', fn_dmaps_main(cam_mobl_one),cam_mobl_one)
           into l_cell_no
          FROM CMS_ADDR_MAST
         WHERE CAM_INST_CODE=1
         AND CAM_CUST_CODE  = l_cust_code
           AND CAM_ADDR_FLAG='P';

           IF l_cell_no IS NULL THEN
              l_err_msg := 'CELL PHONE NUMBER NOT FOUND';
              l_resp_cde := '245';
              RAISE exp_reject_record;
          ELSE
                p_cell_no_out:=l_cell_no;
          END IF;
          EXCEPTION
            WHEN  exp_reject_record THEN
            RAISE;
            when NO_DATA_FOUND then
              l_err_msg := 'Invalid Customer ID';
              l_resp_cde := '118';
              RAISE exp_reject_record;
            WHEN OTHERS THEN
            l_resp_cde := '21';
            l_err_msg  := 'Error from Address Verify flag' ||
            SUBSTR(SQLERRM, 1, 200);
           RAISE exp_reject_record;
         END;
         BEGIN
            sp_fee_calc (p_inst_code_in,
                         p_msg_type_in,
                         p_rrn_in,
                         p_delivery_channel_in,
                         p_txn_code_in,
                         p_txn_mode_in,
                         p_tran_date_in,
                         p_tran_time_in,
                         p_mbr_numb_in,
                         p_rvsl_code_in,
                         l_txn_type,
                         p_curr_code_in,
                         l_tran_amt,
                         p_pan_code_in,
                         l_hash_pan,
                         l_encr_pan,
                         l_acct_number,
                         l_prod_code,
                         l_card_type,
                         l_preauth_flag,
                         NULL,
                         NULL,
                         NULL,
                         l_trans_desc,
                         l_dr_cr_flag,
                         l_acct_bal,
                         l_ledger_bal,
                         l_acct_type,
                         l_login_txn,
                         l_auth_id,
                         l_time_stamp,
                         l_resp_cde,
                         l_err_msg,
                         l_fee_code,
                         l_fee_plan,
                         l_feeattach_type,
                         l_tranfee_amt,
                         l_total_amt,
                         v_compl_fee,
                         v_compl_feetxn_excd,
                         v_compl_feecode,
                         l_preauth_type
                        );
            IF l_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                       'Error from sp_fee_calc  ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
         l_resp_cde := '1';
     EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK TO l_auth_savepoint;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK TO l_auth_savepoint;
      END;
   --Sn Get responce code fomr master
         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code_in
               AND cms_delivery_channel = p_delivery_channel_in
               AND cms_response_id = l_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Problem while selecting data from response master '
                  || l_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '89';
         END;
      --En Get responce code fomr master
      IF l_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in
               AND cap_pan_code = gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO l_acct_bal, l_ledger_bal, l_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_number AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_acct_bal := 0;
            l_ledger_bal := 0;
      END;
      IF l_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;
        --Sn Inserting data in transactionlog
      BEGIN
         sp_log_txnlog (p_inst_code_in,
                        p_msg_type_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_txn_code_in,
                        l_txn_type,
                        p_txn_mode_in,
                        p_tran_date_in,
                        p_tran_time_in,
                        p_rvsl_code_in,
                        l_hash_pan,
                        l_encr_pan,
                        l_err_msg,
                        NULL,
                        l_card_stat,
                        l_trans_desc,
                        NULL,
                        NULL,
                        l_time_stamp,
                        l_acct_number,
                        l_prod_code,
                        l_card_type,
                        l_dr_cr_flag,
                        l_acct_bal,
                        l_ledger_bal,
                        l_acct_type,
                        l_proxy_number,
                        l_auth_id,
                        l_tran_amt,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '89';
            l_err_msg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
      END;
      --En Inserting data in transactionlog
      --Sn Inserting data in transactionlog dtl
      BEGIN
         l_reason_code_desc := get_reason_code_desc(p_reason_code_in);
         sp_log_txnlogdetl (p_inst_code_in,
                            p_msg_type_in,
                            p_rrn_in,
                            p_delivery_channel_in,
                            p_txn_code_in,
                            l_txn_type,
                            p_txn_mode_in,
                            p_tran_date_in,
                            p_tran_time_in,
                            l_hash_pan,
                            l_encr_pan,
                            l_err_msg,
                            l_acct_number,
                            l_auth_id,
                            l_tran_amt,
                            NULL,
                            NULL,
                            l_hashkey_id,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            p_resp_code_out,
                            NULL,
                            p_reason_code_in,
                            l_reason_code_desc,
                            l_logdtl_resp
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;
        --Assign output variable
      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   END;


   PROCEDURE  validate_partnerid_customerid (
          p_inst_code_in         in    number,
          p_msg_type_in          in       varchar2,
          p_rrn_in               in      varchar2,
          p_delivery_channel_in  in      varchar2,
          p_txn_code_in          in      varchar2,
          p_txn_mode_in          in      varchar2,
          p_tran_date_in         in      varchar2,
          p_tran_time_in         in      varchar2,
          p_mbr_numb_in          in      varchar2,
          p_rvsl_code_in         in      varchar2,
          p_cust_id_in           in    number,
          p_pan_code_in               in      varchar2,
          p_curr_code_in         in      varchar2,
          p_partner_id_in        in      varchar2,
          p_device_id_in         in      varchar2,
          p_mobile_no_in         in      varchar2,
          p_ip_address_in        in      varchar2,
          p_reason_code_in       IN       VARCHAR2,
          p_resp_code_out        out     varchar2,
          p_resmsg_out           out     varchar2


   )
   IS
      /************************************************************************************************************
       * Created Date     :  12-JULY-2015
       * Created By       :  MAGESHKUMAR S
       * Created For      :  DFCTNM-44
       * Reviewer         :  SPankaj
       * Build Number     :
      ************************************************************************************************************/
      l_auth_savepoint       NUMBER                                 DEFAULT 0;
      l_err_msg              VARCHAR2 (500);
      l_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
      l_txn_type             transactionlog.txn_type%TYPE;
      l_auth_id              transactionlog.auth_id%TYPE;
      exp_reject_record      EXCEPTION;
      l_dr_cr_flag           VARCHAR2 (2);
      l_tran_type            VARCHAR2 (2);
      l_tran_amt             NUMBER;
      l_prod_code            cms_appl_pan.cap_prod_code%TYPE;
      l_card_type            cms_appl_pan.cap_card_type%TYPE;
      l_resp_cde             VARCHAR2 (5);
      l_time_stamp           TIMESTAMP;
      l_hashkey_id           cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_trans_desc           cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag            cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_acct_number          cms_appl_pan.cap_acct_no%TYPE;
      l_prfl_code            cms_appl_pan.cap_prfl_code%TYPE;
      l_card_stat            cms_appl_pan.cap_card_stat%TYPE;
      l_cust_code            cms_appl_pan.cap_cust_code%TYPE;
      l_preauth_flag         cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_acct_bal             cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal           cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type            cms_acct_mast.cam_type_code%TYPE;
      l_proxy_number         cms_appl_pan.cap_proxy_number%TYPE;
      l_fee_code             transactionlog.feecode%TYPE;
      l_fee_plan             transactionlog.fee_plan%TYPE;
      l_feeattach_type       transactionlog.feeattachtype%TYPE;
      l_tranfee_amt          transactionlog.tranfee_amt%TYPE;
      l_total_amt            transactionlog.total_amount%TYPE;
      l_expry_date           cms_appl_pan.cap_expry_date%TYPE;
      l_comb_hash            pkg_limits_check.type_hash;
      l_login_txn            cms_transaction_mast.ctm_login_txn%TYPE;
      l_logdtl_resp          VARCHAR2 (500);
      l_preauth_type         cms_transaction_mast.ctm_preauth_type%TYPE;
      l_partner_id  cms_product_param.cpp_partner_id%TYPE;
      v_compl_fee  varchar2(10);
        v_compl_feetxn_excd varchar2(10);
       v_compl_feecode varchar2(10);
      l_reason_code_desc     vms_reason_mast.VRM_REASON_DESC%TYPE;
   BEGIN
      l_resp_cde := '1';
      l_time_stamp := SYSTIMESTAMP;

      BEGIN
         SAVEPOINT l_auth_savepoint;
         l_tran_amt :=  0;

         --Sn Get the HashPan
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Error while converting hash pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En Get the HashPan

         --Sn Create encr pan
         BEGIN
            l_encr_pan := fn_emaps_main (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Error while converting emcrypted pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --Start Generate HashKEY value
         BEGIN
            l_hashkey_id :=
               gethash (   p_delivery_channel_in
                        || p_txn_code_in
                        || p_pan_code_in
                        || p_rrn_in
                        || TO_CHAR (l_time_stamp, 'YYYYMMDDHH24MISSFF5')
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error while Generating  hashkey id data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --End Generate HashKEY

         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   cap_prfl_code, cap_expry_date, cap_proxy_number,
                   cap_cust_code
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   l_prfl_code, l_expry_date, l_proxy_number,
                   l_cust_code
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'Card number not found ' || l_encr_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Problem while selecting card detail'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --End Get the card details

         --Sn find debit and credit flag
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag, ctm_login_txn, ctm_preauth_type
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag, l_login_txn, l_preauth_type
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Transaction not defined for txn code '
                  || p_txn_code_in
                  || ' and delivery channel '
                  || p_delivery_channel_in;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg := 'Error while selecting transaction details';
               RAISE exp_reject_record;
         END;

         --En find debit and credit flag

         --Sn generate auth id
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO l_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';                         -- Server Declined
               RAISE exp_reject_record;
         END;

         --En generate auth id

          BEGIN
            sp_cmsauth_check (p_inst_code_in,
                              p_msg_type_in,
                              p_rrn_in,
                              p_delivery_channel_in,
                              p_txn_code_in,
                              p_txn_mode_in,
                              p_tran_date_in,
                              p_tran_time_in,
                              p_mbr_numb_in,
                              p_rvsl_code_in,
                              l_tran_type,
                              p_curr_code_in,
                              l_tran_amt,
                              p_pan_code_in,
                              l_hash_pan,
                              l_encr_pan,
                              l_card_stat,
                              l_expry_date,
                              l_prod_code,
                              l_card_type,
                              l_prfl_flag,
                              l_prfl_code,
                              NULL,
                              NULL,
                              NULL,
                              l_resp_cde,
                              l_err_msg,
                              l_comb_hash
                             );

            IF l_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error from  cmsauth Check Procedure  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in
            FOR UPDATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account  detail '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

      BEGIN

      SELECT c.cpp_partner_id
        INTO l_partner_id
        FROM cms_cust_mast a, cms_appl_mast b, cms_product_param c
       WHERE a.ccm_cust_id = p_cust_id_in
         AND a.ccm_inst_code = b.cam_inst_code
         AND a.ccm_cust_code = b.cam_cust_code
         AND b.cam_inst_code = c.cpp_inst_code
         AND b.cam_prod_code = c.cpp_prod_code;

      IF l_partner_id = p_partner_id_in
      THEN
         l_err_msg := 'SUCCESS';
         l_resp_cde := '1';
      ELSE
          l_err_msg := 'Customer ID and Partner ID combination not valid';
          l_resp_cde := '242';
          RAISE exp_reject_record;
      END IF;

      EXCEPTION
        WHEN  exp_reject_record THEN
        RAISE;

        WHEN NO_DATA_FOUND THEN
          l_err_msg := 'Customer ID and Partner ID combination not valid';
          l_resp_cde := '242';
          RAISE exp_reject_record;

        WHEN OTHERS THEN
        l_resp_cde := '21';
        l_err_msg  := 'Error from partner id Verify flag' ||
        SUBSTR(SQLERRM, 1, 200);
       RAISE exp_reject_record;
     END;


         BEGIN
            sp_fee_calc (p_inst_code_in,
                         p_msg_type_in,
                         p_rrn_in,
                         p_delivery_channel_in,
                         p_txn_code_in,
                         p_txn_mode_in,
                         p_tran_date_in,
                         p_tran_time_in,
                         p_mbr_numb_in,
                         p_rvsl_code_in,
                         l_txn_type,
                         p_curr_code_in,
                         l_tran_amt,
                         p_pan_code_in,
                         l_hash_pan,
                         l_encr_pan,
                         l_acct_number,
                         l_prod_code,
                         l_card_type,
                         l_preauth_flag,
                         NULL,
                         NULL,
                         NULL,
                         l_trans_desc,
                         l_dr_cr_flag,
                         l_acct_bal,
                         l_ledger_bal,
                         l_acct_type,
                         l_login_txn,
                         l_auth_id,
                         l_time_stamp,
                         l_resp_cde,
                         l_err_msg,
                         l_fee_code,
                         l_fee_plan,
                         l_feeattach_type,
                         l_tranfee_amt,
                         l_total_amt,
                         v_compl_fee,
                         v_compl_feetxn_excd,
                         v_compl_feecode,
                         l_preauth_type
                        );

            IF l_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                       'Error from sp_fee_calc  ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;


         l_resp_cde := '1';
         l_err_msg := 'SUCCESS';
     EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK TO l_auth_savepoint;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK TO l_auth_savepoint;
      END;

  IF p_delivery_channel_in = '10' AND p_txn_code_in = '49'
   THEN
      BEGIN
         SELECT DECODE (l_resp_cde, '242', '252',l_resp_cde)
           INTO l_resp_cde
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg :=
                  'Error while getting CHW specific responses '
               || SUBSTR (SQLERRM, 1, 300);
      END;
   END IF;

   --Sn Get responce code fomr master
         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code_out
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code_in
               AND cms_delivery_channel = p_delivery_channel_in
               AND cms_response_id = l_resp_cde;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                     'Problem while selecting data from response master '
                  || l_resp_cde
                  || SUBSTR (SQLERRM, 1, 300);
               p_resp_code_out := '89';
         END;


      --En Get responce code fomr master
      IF l_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in
               AND cap_pan_code = gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO l_acct_bal, l_ledger_bal, l_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_number AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_acct_bal := 0;
            l_ledger_bal := 0;
      END;

      IF l_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

        --Sn Inserting data in transactionlog
      BEGIN
         sp_log_txnlog (p_inst_code_in,
                        p_msg_type_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_txn_code_in,
                        l_txn_type,
                        p_txn_mode_in,
                        p_tran_date_in,
                        p_tran_time_in,
                        p_rvsl_code_in,
                        l_hash_pan,
                        l_encr_pan,
                        l_err_msg,
                        p_ip_address_in,
                        l_card_stat,
                        l_trans_desc,
                        NULL,
                        NULL,
                        l_time_stamp,
                        l_acct_number,
                        l_prod_code,
                        l_card_type,
                        l_dr_cr_flag,
                        l_acct_bal,
                        l_ledger_bal,
                        l_acct_type,
                        l_proxy_number,
                        l_auth_id,
                        l_tran_amt,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '89';
            l_err_msg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         l_reason_code_desc := get_reason_code_desc(p_reason_code_in);
         sp_log_txnlogdetl (p_inst_code_in,
                            p_msg_type_in,
                            p_rrn_in,
                            p_delivery_channel_in,
                            p_txn_code_in,
                            l_txn_type,
                            p_txn_mode_in,
                            p_tran_date_in,
                            p_tran_time_in,
                            l_hash_pan,
                            l_encr_pan,
                            l_err_msg,
                            l_acct_number,
                            l_auth_id,
                            l_tran_amt,
                            p_device_id_in,
                            p_mobile_no_in,
                            l_hashkey_id,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            p_resp_code_out,
                            NULL,
                            p_reason_code_in,
                            l_reason_code_desc,
                            l_logdtl_resp
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

        --Assign output variable
      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   END;


   PROCEDURE  fund_credit_debit (
      p_inst_code_in          IN       NUMBER,
      p_msg_type_in           IN       VARCHAR2,
      p_rrn_in                IN       VARCHAR2,
      p_delivery_channel_in   IN       VARCHAR2,
      p_txn_code_in           IN       VARCHAR2,
      p_txn_mode_in           IN       VARCHAR2,
      p_tran_date_in          IN       VARCHAR2,
      p_tran_time_in          IN       VARCHAR2,
      p_mbr_numb_in           IN       VARCHAR2,
      p_rvsl_code_in          IN       VARCHAR2,
      p_txn_amt_in            IN       NUMBER,
      p_cust_id_in            IN       NUMBER,
      p_pan_code_in           IN       VARCHAR2,
      p_curr_code_in          IN       VARCHAR2,
      p_partner_id_in         IN       VARCHAR2,
      p_payee_id_in           IN       VARCHAR2,
      p_remarks_in            IN       VARCHAR2,
      p_mobile_no_in          IN       VARCHAR2,
      p_device_id_in          IN       VARCHAR2,
      p_reason_code_in        IN       VARCHAR2,
      p_resp_code_out         OUT      VARCHAR2,
      p_resmsg_out            OUT      VARCHAR2
      )
  IS
      /************************************************************************************************************
       * Created Date     :  07-DEC-2016
       * Created By       :  MAGESHKUMAR S
       * Created For      :  VP-177
       * Reviewer         :  Saravanakumar/SPankaj
       * Build Number     :  VMSGPRHOSTCSD_B00003
      ************************************************************************************************************/
      l_auth_savepoint        NUMBER                                DEFAULT 0;
      l_err_msg               VARCHAR2 (500);
      l_hash_pan              cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan              cms_appl_pan.cap_pan_code_encr%TYPE;
      l_txn_type              transactionlog.txn_type%TYPE;
      l_auth_id               transactionlog.auth_id%TYPE;
      exp_reject_record       EXCEPTION;
      l_dr_cr_flag            VARCHAR2 (2);
      l_tran_type             VARCHAR2 (2);
      l_tran_amt              NUMBER;
      l_prod_code             cms_appl_pan.cap_prod_code%TYPE;
      l_card_type             cms_appl_pan.cap_card_type%TYPE;
      l_resp_cde              VARCHAR2 (5);
      l_time_stamp            TIMESTAMP;
      l_hashkey_id            cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_trans_desc            cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag             cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_acct_number           cms_appl_pan.cap_acct_no%TYPE;
      l_prfl_code             cms_appl_pan.cap_prfl_code%TYPE;
      l_card_stat             cms_appl_pan.cap_card_stat%TYPE;
      l_cust_code             cms_appl_pan.cap_cust_code%TYPE;
      l_preauth_flag          cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_acct_bal              cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal            cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type             cms_acct_mast.cam_type_code%TYPE;
      l_proxy_number          cms_appl_pan.cap_proxy_number%TYPE;
      l_fee_code              transactionlog.feecode%TYPE;
      l_fee_plan              transactionlog.fee_plan%TYPE;
      l_feeattach_type        transactionlog.feeattachtype%TYPE;
      l_tranfee_amt           transactionlog.tranfee_amt%TYPE;
      l_total_amt             transactionlog.total_amount%TYPE;
      l_expry_date            cms_appl_pan.cap_expry_date%TYPE;
      l_comb_hash             pkg_limits_check.type_hash;
      l_login_txn             cms_transaction_mast.ctm_login_txn%TYPE;
      l_logdtl_resp           VARCHAR2 (500);
      l_preauth_type          cms_transaction_mast.ctm_preauth_type%TYPE;
      l_preauth_exp_period    CMS_PROD_CATTYPE.CPC_ONUS_AUTH_EXPIRY%TYPE;
      l_tran_date             DATE;
      l_card_curr             VARCHAR2 (5);
      v_compl_fee             VARCHAR2 (5);
        v_compl_feetxn_excd varchar2(10);
       v_compl_feecode varchar2(10);
      l_reason_code_desc     vms_reason_mast.VRM_REASON_DESC%TYPE;
   BEGIN
      l_resp_cde := '1';
      l_time_stamp := SYSTIMESTAMP;

      BEGIN
         SAVEPOINT l_auth_savepoint;
         l_tran_amt := NVL (ROUND (p_txn_amt_in, 2), 0);

         --Sn Get the HashPan
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Error while converting hash pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En Get the HashPan

         --Sn Create encr pan
         BEGIN
            l_encr_pan := fn_emaps_main (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Error while converting emcrypted pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --Start Generate HashKEY value
         BEGIN
            l_hashkey_id :=
               gethash (   p_delivery_channel_in
                        || p_txn_code_in
                        || p_pan_code_in
                        || p_rrn_in
                        || TO_CHAR (l_time_stamp, 'YYYYMMDDHH24MISSFF5')
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error while Generating  hashkey id data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --End Generate HashKEY

         --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   cap_prfl_code, cap_expry_date, cap_proxy_number,
                   cap_cust_code
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   l_prfl_code, l_expry_date, l_proxy_number,
                   l_cust_code
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'Card number not found ' || l_encr_pan;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Problem while selecting card detail'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --End Get the card details

         --Sn find debit and credit flag
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag, ctm_login_txn, ctm_preauth_type
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag, l_login_txn, l_preauth_type
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Transaction not defined for txn code '
                  || p_txn_code_in
                  || ' and delivery channel '
                  || p_delivery_channel_in;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg := 'Error while selecting transaction details';
               RAISE exp_reject_record;
         END;

         --En find debit and credit flag

   IF l_dr_cr_flag = 'CR' THEN

    BEGIN

          SELECT  VRM_REASON_DESC
           INTO l_trans_desc
           FROM VMS_REASON_MAST
          WHERE VRM_REASON_CODE=upper(p_reason_code_in);

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

        BEGIN
                   SELECT  VRM_REASON_DESC
                   INTO l_trans_desc
                   FROM vms_reason_mast
                  WHERE VRM_REASON_CODE=upper(substr(p_reason_code_in,1,1));

               EXCEPTION  WHEN NO_DATA_FOUND THEN

               l_trans_desc := l_trans_desc;

              WHEN OTHERS THEN
                 l_resp_cde := '21';
                l_err_msg := 'Error while transaction description '  || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;

              END;

     WHEN exp_reject_record THEN
        RAISE;
     WHEN OTHERS
       THEN
         l_resp_cde := '21';
         l_err_msg := 'Error while transaction description '  || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
     END;
        -- Fast<<AMNT>>
       begin

        SELECT REPLACE(l_trans_desc,'<<AMNT>>',p_txn_amt_in)
        INTO l_trans_desc FROM dual;
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
          l_trans_desc := l_trans_desc;
         WHEN OTHERS
             THEN
             l_resp_cde := '21';
              l_err_msg := 'Error while transaction description '  || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
        END;

    END IF;

        IF l_tran_amt <=0 THEN

               l_resp_cde := '25';
               l_err_msg := 'INVALID AMOUNT';
               RAISE exp_reject_record;

         END IF;

         --Sn generate auth id
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO l_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';                         -- Server Declined
               RAISE exp_reject_record;
         END;

         --En generate auth id
         BEGIN
            l_tran_date :=
               TO_DATE (   SUBSTR (TRIM (p_tran_date_in), 1, 8)
                        || ' '
                        || SUBSTR (TRIM (p_tran_time_in), 1, 10),
                        'yyyymmdd hh24:mi:ss'
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while converting transaction date '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         -- To Convert Currency
         IF p_txn_amt_in IS NOT NULL
         THEN
            IF (p_txn_amt_in > 0)
            THEN
               l_tran_amt := p_txn_amt_in;

               BEGIN
                  sp_convert_curr (p_inst_code_in,
                                   p_curr_code_in,
                                   p_pan_code_in,
                                   p_txn_amt_in,
                                   l_tran_date,
                                   l_tran_amt,
                                   l_card_curr,
                                   l_err_msg,
								   l_prod_code,
								   l_card_type
                                  );

                  IF l_err_msg <> 'OK'
                  THEN
                     l_resp_cde := '21';
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     l_resp_cde := '21';
                     l_err_msg :=
                           'Error from currency conversion '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            ELSE
               l_resp_cde := '25';
               l_err_msg := 'INVALID AMOUNT';
               RAISE exp_reject_record;
            END IF;
         END IF;

         -- End  Convert Currency

           BEGIN
            sp_cmsauth_check (p_inst_code_in,
                              p_msg_type_in,
                              p_rrn_in,
                              p_delivery_channel_in,
                              p_txn_code_in,
                              p_txn_mode_in,
                              p_tran_date_in,
                              p_tran_time_in,
                              p_mbr_numb_in,
                              p_rvsl_code_in,
                              l_tran_type,
                              p_curr_code_in,
                              l_tran_amt,
                              p_pan_code_in,
                              l_hash_pan,
                              l_encr_pan,
                              l_card_stat,
                              l_expry_date,
                              l_prod_code,
                              l_card_type,
                              l_prfl_flag,
                              l_prfl_code,
                              NULL,
                              NULL,
                              NULL,
                              l_resp_cde,
                              l_err_msg,
                              l_comb_hash
                             );

            IF l_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error from  cmsauth Check Procedure  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in
            FOR UPDATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account  detail '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            sp_fee_calc (p_inst_code_in,
                         p_msg_type_in,
                         p_rrn_in,
                         p_delivery_channel_in,
                         p_txn_code_in,
                         p_txn_mode_in,
                         p_tran_date_in,
                         p_tran_time_in,
                         p_mbr_numb_in,
                         p_rvsl_code_in,
                         l_txn_type,
                         p_curr_code_in,
                         l_tran_amt,
                         p_pan_code_in,
                         l_hash_pan,
                         l_encr_pan,
                         l_acct_number,
                         l_prod_code,
                         l_card_type,
                         l_preauth_flag,
                         NULL,
                         NULL,
                         NULL,
                         l_trans_desc,
                         l_dr_cr_flag,
                         l_acct_bal,
                         l_ledger_bal,
                         l_acct_type,
                         l_login_txn,
                         l_auth_id,
                         l_time_stamp,
                         l_resp_cde,
                         l_err_msg,
                         l_fee_code,
                         l_fee_plan,
                         l_feeattach_type,
                         l_tranfee_amt,
                         l_total_amt,
                         v_compl_fee,
                         v_compl_feetxn_excd,
                         v_compl_feecode,
                         l_preauth_type,
                         l_card_stat,
                         NULL
                        );

            IF l_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                       'Error from sp_fee_calc  ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         IF l_prfl_code IS NOT NULL AND l_prfl_flag = 'Y'
         THEN
            BEGIN
               pkg_limits_check.sp_limitcnt_reset (p_inst_code_in,
                                                   l_hash_pan,
                                                   l_tran_amt,
                                                   l_comb_hash,
                                                   l_resp_cde,
                                                   l_err_msg
                                                  );

               IF l_err_msg <> 'OK'
               THEN
                  l_err_msg :=
                              'From Procedure sp_limitcnt_reset' || l_err_msg;
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_err_msg :=
                        'Error from Limit Reset Count Process '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         END IF;

         l_resp_cde := '1';


      EXCEPTION
         WHEN exp_reject_record
         THEN
            ROLLBACK TO l_auth_savepoint;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK TO l_auth_savepoint;
      END;

      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code_out
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code_in
            AND cms_delivery_channel = p_delivery_channel_in
            AND cms_response_id = l_resp_cde;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while selecting data from response master '
               || l_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

      --En Get responce code fomr master
      IF l_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in
               AND cap_pan_code = gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO l_acct_bal, l_ledger_bal, l_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_number AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_acct_bal := 0;
            l_ledger_bal := 0;
      END;

      IF l_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      --Sn Inserting data in transactionlog
      BEGIN
         sp_log_txnlog (p_inst_code_in,
                        p_msg_type_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_txn_code_in,
                        l_txn_type,
                        p_txn_mode_in,
                        p_tran_date_in,
                        p_tran_time_in,
                        p_rvsl_code_in,
                        l_hash_pan,
                        l_encr_pan,
                        l_err_msg,
                        NULL,
                        l_card_stat,
                        l_trans_desc,
                        NULL,
                        NULL,
                        l_time_stamp,
                        l_acct_number,
                        l_prod_code,
                        l_card_type,
                        l_dr_cr_flag,
                        l_acct_bal,
                        l_ledger_bal,
                        l_acct_type,
                        l_proxy_number,
                        l_auth_id,
                        l_tran_amt,
                        l_total_amt,
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg,
                        NULL,
                        NULL,
                        p_remarks_in,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_partner_id_in
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '89';
            l_err_msg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         l_reason_code_desc := get_reason_code_desc(p_reason_code_in);
         sp_log_txnlogdetl (p_inst_code_in,
                            p_msg_type_in,
                            p_rrn_in,
                            p_delivery_channel_in,
                            p_txn_code_in,
                            l_txn_type,
                            p_txn_mode_in,
                            p_tran_date_in,
                            p_tran_time_in,
                            l_hash_pan,
                            l_encr_pan,
                            l_err_msg,
                            l_acct_number,
                            l_auth_id,
                            l_tran_amt,
                            p_mobile_no_in,
                            p_device_id_in,
                            l_hashkey_id,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            p_resp_code_out,
                            NULL,
                            p_reason_code_in,
                            l_reason_code_desc,
                            l_logdtl_resp
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

      p_resmsg_out := l_err_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   END;

    PROCEDURE  fund_creditdebit_rvsl (
      p_inst_code_in          IN       NUMBER,
      p_msg_type_in           IN       VARCHAR2,
      p_rrn_in                IN       VARCHAR2,
      p_delivery_channel_in   IN       VARCHAR2,
      p_txn_code_in           IN       VARCHAR2,
      p_txn_mode_in           IN       VARCHAR2,
      p_tran_date_in          IN       VARCHAR2,
      p_tran_time_in          IN       VARCHAR2,
      p_mbr_numb_in           IN       VARCHAR2,
      p_rvsl_code_in          IN       VARCHAR2,
      p_txn_amt_in            IN       NUMBER,
      p_cust_id_in            IN       NUMBER,
      p_pan_code_in           IN       VARCHAR2,
      p_curr_code_in          IN       VARCHAR2,
      p_partner_id_in         IN       VARCHAR2,
      p_payee_id_in           IN       VARCHAR2,
      p_remarks_in            IN       VARCHAR2,
      p_mobile_no_in          IN       VARCHAR2,
      p_device_id_in          IN       VARCHAR2,
      p_reason_code_in        IN       VARCHAR2,
      p_resp_code_out         OUT      VARCHAR2,
      p_resmsg_out            OUT      VARCHAR2,
      p_reversal_amount_out   OUT      VARCHAR2

   )

   IS
      /************************************************************************************************************
       * Created Date     :  07-DEC-2015
       * Created By       :  MAGESHKUMAR S
       * Created For      :  VP-177
       * Reviewer         :  Saravanakumar/SPankaj
       * Build Number     :  VMSGPRHOSTCSD3.3_B00003

       * Created Date     :  08-FEB-2016
       * Created By       :  MAGESHKUMAR S
       * Created For      :  Mantis Id:0016259
       * Reviewer         :  Saravanakumar/SPankaj
       * Build Number     :  VMSGPRHOSTCSD_3.3.2_B00001

       * Modified by          : Spankaj
       * Modified Date        : 21-Nov-2016
       * Modified For         :FSS-4762:VMS OTC Support for Instant Payroll Card
       * Reviewer             : Saravanakumar
       * Build Number         : VMSGPRHOSTCSD4.11
      ************************************************************************************************************/
      l_auth_savepoint            NUMBER                            DEFAULT 0;
      l_err_msg                   VARCHAR2 (500);
      l_hash_pan                  cms_appl_pan.cap_pan_code%TYPE;
      l_encr_pan                  cms_appl_pan.cap_pan_code_encr%TYPE;
      l_txn_type                  transactionlog.txn_type%TYPE;
      l_auth_id                   transactionlog.auth_id%TYPE;
      l_tran_amt                  NUMBER;
      l_prod_code                 cms_appl_pan.cap_prod_code%TYPE;
      l_card_type                 cms_appl_pan.cap_card_type%TYPE;
      l_resp_cde                  VARCHAR2 (5);
      l_hashkey_id                cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
      l_trans_desc                cms_transaction_mast.ctm_tran_desc%TYPE;
      l_prfl_flag                 cms_transaction_mast.ctm_prfl_flag%TYPE;
      l_acct_number               cms_appl_pan.cap_acct_no%TYPE;
      l_prfl_code                 cms_appl_pan.cap_prfl_code%TYPE;
      l_card_stat                 cms_appl_pan.cap_card_stat%TYPE;
      l_cust_code                 cms_appl_pan.cap_cust_code%TYPE;
      l_preauth_flag              cms_transaction_mast.ctm_preauth_flag%TYPE;
      l_acct_bal                  cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal                cms_acct_mast.cam_ledger_bal%TYPE;
      l_acct_type                 cms_acct_mast.cam_type_code%TYPE;
      l_proxy_number              cms_appl_pan.cap_proxy_number%TYPE;
      l_fee_code                  transactionlog.feecode%TYPE;
      l_fee_plan                  transactionlog.fee_plan%TYPE;
      l_feeattach_type            transactionlog.feeattachtype%TYPE;
      l_tranfee_amt               transactionlog.tranfee_amt%TYPE;
      l_expry_date                cms_appl_pan.cap_expry_date%TYPE;
      l_login_txn                 cms_transaction_mast.ctm_login_txn%TYPE;
      l_logdtl_resp               VARCHAR2 (500);
      l_preauth_type              cms_transaction_mast.ctm_preauth_type%TYPE;
      l_tran_date                 DATE;
      l_orgnl_delivery_channel    transactionlog.delivery_channel%TYPE;
      l_orgnl_resp_code           transactionlog.response_code%TYPE;
      l_orgnl_txn_code            transactionlog.txn_code%TYPE;
      l_orgnl_txn_mode            transactionlog.txn_mode%TYPE;
      l_orgnl_business_date       transactionlog.business_date%TYPE;
      l_orgnl_business_time       transactionlog.business_time%TYPE;
      l_orgnl_customer_card_no    transactionlog.customer_card_no%TYPE;
      l_reversal_amt              NUMBER (9, 2);
      l_orgnl_txn_feecode         cms_fee_mast.cfm_fee_code%TYPE;
      l_orgnl_txn_totalfee_amt    transactionlog.tranfee_amt%TYPE;
      l_orgnl_transaction_type    transactionlog.cr_dr_flag%TYPE;
      l_actual_dispatched_amt     transactionlog.amount%TYPE;
      l_dr_cr_flag                transactionlog.cr_dr_flag%TYPE;
      l_rvsl_trandate             DATE;
      l_actual_feecode            transactionlog.feecode%TYPE;
      l_orgnl_tranfee_amt         transactionlog.tranfee_amt%TYPE;
      l_orgnl_servicetax_amt      transactionlog.servicetax_amt%TYPE;
      l_orgnl_cess_amt            transactionlog.cess_amt%TYPE;
      l_orgnl_cr_dr_flag          transactionlog.cr_dr_flag%TYPE;
      l_orgnl_tranfee_cr_acctno   transactionlog.tranfee_cr_acctno%TYPE;
      l_orgnl_tranfee_dr_acctno   transactionlog.tranfee_dr_acctno%TYPE;
      l_orgnl_st_calc_flag        transactionlog.tran_st_calc_flag%TYPE;
      l_orgnl_cess_calc_flag      transactionlog.tran_cess_calc_flag%TYPE;
      l_orgnl_st_cr_acctno        transactionlog.tran_st_cr_acctno%TYPE;
      l_orgnl_st_dr_acctno        transactionlog.tran_st_dr_acctno%TYPE;
      l_orgnl_cess_cr_acctno      transactionlog.tran_cess_cr_acctno%TYPE;
      l_orgnl_cess_dr_acctno      transactionlog.tran_cess_dr_acctno%TYPE;
      l_gl_upd_flag               transactionlog.gl_upd_flag%TYPE;
      l_tran_reverse_flag         transactionlog.tran_reverse_flag%TYPE;
      l_cutoff_time               VARCHAR2 (5);
      l_business_time             VARCHAR2 (5);
      exp_rvsl_reject_record      EXCEPTION;
      l_card_curr                 VARCHAR2 (5);
      l_preauth_expiry_flag       CHARACTER (1);
      l_hold_amount               NUMBER;
      l_max_card_bal              NUMBER;
      l_fee_narration             cms_statements_log.csl_trans_narrration%TYPE;
      l_tot_fee_amount            transactionlog.tranfee_amt%TYPE;
      l_tot_amount                transactionlog.amount%TYPE;
      l_fee_amt                   NUMBER;
      l_chnge_crdstat             VARCHAR2 (2)                         := 'N';
      l_time_stamp                 TIMESTAMP ( 3 );
      l_orgnl_txn_fee_plan        transactionlog.fee_plan%TYPE;
      l_feecap_flag               VARCHAR2 (1);
      l_orgnl_fee_amt             cms_fee_mast.cfm_fee_amt%TYPE;
      l_reversal_amt_flag         VARCHAR2 (1)                         := 'F';
      l_tran_type                 cms_transaction_mast.ctm_tran_type%TYPE;
      l_add_ins_date              transactionlog.add_ins_date%TYPE;
      l_original_amnt             transactionlog.amount%TYPE;
      l_reason_code_desc     vms_reason_mast.VRM_REASON_DESC%TYPE;
	  v_Retperiod  date;  --Added for VMS-5739/FSP-991
	  v_Retdate  date; --Added for VMS-5739/FSP-991
      CURSOR l_cur_stmnts_log
      IS
         SELECT csl_trans_narrration, csl_merchant_name, csl_merchant_city,
                csl_merchant_state, csl_trans_amount
           FROM VMSCMS.CMS_STATEMENTS_LOG_VW  											 --Added for VMS-5739/FSP-991
          WHERE csl_business_date = l_orgnl_business_date
            AND csl_rrn = p_rrn_in
            AND csl_delivery_channel = l_orgnl_delivery_channel
            AND csl_txn_code = l_orgnl_txn_code
            AND csl_pan_no = l_orgnl_customer_card_no
            AND csl_inst_code = p_inst_code_in
            AND txn_fee_flag = 'Y';
   BEGIN
      l_resp_cde := '1';
      l_time_stamp := SYSTIMESTAMP;

      BEGIN
         SAVEPOINT l_auth_savepoint;

         --Sn Get the HashPan
         BEGIN
            l_hash_pan := gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Error while converting hash pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --En Get the HashPan
         --Sn Create encr pan
         BEGIN
            l_encr_pan := fn_emaps_main (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Error while converting emcrypted pan '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --Start Generate HashKEY value
         BEGIN
            l_hashkey_id :=
               gethash (   p_delivery_channel_in
                        || p_txn_code_in
                        || p_pan_code_in
                        || p_rrn_in
                        || TO_CHAR (l_time_stamp, 'YYYYMMDDHH24MISSFF5')
                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error while Generating  hashkey id data '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --End Generate HashKEY
             --Sn Get the card details
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                   cap_prfl_code, cap_expry_date, cap_proxy_number,
                   cap_cust_code
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number,
                   l_prfl_code, l_expry_date, l_proxy_number,
                   l_cust_code
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in AND cap_pan_code = l_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '16';
               l_err_msg := 'Card number not found ' || l_encr_pan;
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Problem while selecting card detail'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --End Get the card details
         --Sn find debit and credit flag
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag, ctm_login_txn
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag, l_login_txn
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '12';
               l_err_msg :=
                     'Transaction not defined for txn code '
                  || p_txn_code_in
                  || ' and delivery channel '
                  || p_delivery_channel_in;
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg := 'Error while selecting transaction details';
               RAISE exp_rvsl_reject_record;
         END;

         --En find debit and credit flag
         --Sn generate auth id
         BEGIN
            SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
              INTO l_auth_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_msg :=
                  'Error while generating authid '
                  || SUBSTR (SQLERRM, 1, 300);
               l_resp_cde := '21';                         -- Server Declined
               RAISE exp_rvsl_reject_record;
         END;

         --En generate auth id
         BEGIN
            l_rvsl_trandate :=
               TO_DATE (   SUBSTR (TRIM (p_tran_date_in), 1, 8)
                        || ' '
                        || SUBSTR (TRIM (p_tran_time_in), 1, 8),
                        'yyyymmdd hh24:mi:ss'
                       );
            l_tran_date := l_rvsl_trandate;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while converting transaction date '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --Sn check msg type
         IF (p_msg_type_in != '0400') OR (p_rvsl_code_in = '00')
         THEN
            l_resp_cde := '12';
            l_err_msg := 'Not a valid reversal request';
            RAISE exp_rvsl_reject_record;
         END IF;

         --En check msg type

          --En check orginal transaction
              --Sn find the converted tran amt
         l_tran_amt := p_txn_amt_in;

         IF (p_txn_amt_in >= 0)
         THEN
            BEGIN
               sp_convert_curr (p_inst_code_in,
                                p_curr_code_in,
                                p_pan_code_in,
                                p_txn_amt_in,
                                l_rvsl_trandate,
                                l_tran_amt,
                                l_card_curr,
                                l_err_msg,
								l_prod_code,
								l_card_type
                               );

               IF l_err_msg <> 'OK'
               THEN
                  l_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';              -- Server Declined -220509
                  l_err_msg :=
                        'Error from currency conversion '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         ELSE
            l_resp_cde := '25';
            l_err_msg := 'INVALID AMOUNT';
            RAISE exp_rvsl_reject_record;
         END IF;

         --En find the  converted tran amt

         --Sn check orginal transaction
         BEGIN
            SELECT delivery_channel, response_code,
                   txn_code, txn_mode,
                   business_date, business_time,
                   customer_card_no, feecode,
                   fee_plan, tranfee_amt,
                   cr_dr_flag, feecode,
                   tranfee_amt, servicetax_amt,
                   cess_amt, tranfee_cr_acctno,
                   tranfee_dr_acctno, tran_st_calc_flag,
                   tran_cess_calc_flag, tran_st_cr_acctno,
                   tran_st_dr_acctno, tran_cess_cr_acctno,
                   tran_cess_dr_acctno, tran_reverse_flag,
                   gl_upd_flag, add_ins_date,AMOUNT
              INTO l_orgnl_delivery_channel, l_orgnl_resp_code,
                   l_orgnl_txn_code, l_orgnl_txn_mode,
                   l_orgnl_business_date, l_orgnl_business_time,
                   l_orgnl_customer_card_no, l_orgnl_txn_feecode,
                   l_orgnl_txn_fee_plan, l_orgnl_txn_totalfee_amt,
                   l_orgnl_transaction_type, l_actual_feecode,
                   l_orgnl_tranfee_amt, l_orgnl_servicetax_amt,
                   l_orgnl_cess_amt, l_orgnl_tranfee_cr_acctno,
                   l_orgnl_tranfee_dr_acctno, l_orgnl_st_calc_flag,
                   l_orgnl_cess_calc_flag, l_orgnl_st_cr_acctno,
                   l_orgnl_st_dr_acctno, l_orgnl_cess_cr_acctno,
                   l_orgnl_cess_dr_acctno, l_tran_reverse_flag,
                   l_gl_upd_flag, l_add_ins_date,l_original_amnt
              FROM VMSCMS.TRANSACTIONLOG								--Added for VMS-5739/FSP-991
             WHERE rrn = p_rrn_in
              -- AND AMOUNT = l_tran_amt
               AND customer_card_no = l_hash_pan
               AND instcode = p_inst_code_in
               AND delivery_channel = p_delivery_channel_in
               AND txn_code = p_txn_code_in
               AND msgtype='0200';
			    IF SQL%ROWCOUNT = 0 THEN
				SELECT delivery_channel, response_code,
                   txn_code, txn_mode,
                   business_date, business_time,
                   customer_card_no, feecode,
                   fee_plan, tranfee_amt,
                   cr_dr_flag, feecode,
                   tranfee_amt, servicetax_amt,
                   cess_amt, tranfee_cr_acctno,
                   tranfee_dr_acctno, tran_st_calc_flag,
                   tran_cess_calc_flag, tran_st_cr_acctno,
                   tran_st_dr_acctno, tran_cess_cr_acctno,
                   tran_cess_dr_acctno, tran_reverse_flag,
                   gl_upd_flag, add_ins_date,AMOUNT
              INTO l_orgnl_delivery_channel, l_orgnl_resp_code,
                   l_orgnl_txn_code, l_orgnl_txn_mode,
                   l_orgnl_business_date, l_orgnl_business_time,
                   l_orgnl_customer_card_no, l_orgnl_txn_feecode,
                   l_orgnl_txn_fee_plan, l_orgnl_txn_totalfee_amt,
                   l_orgnl_transaction_type, l_actual_feecode,
                   l_orgnl_tranfee_amt, l_orgnl_servicetax_amt,
                   l_orgnl_cess_amt, l_orgnl_tranfee_cr_acctno,
                   l_orgnl_tranfee_dr_acctno, l_orgnl_st_calc_flag,
                   l_orgnl_cess_calc_flag, l_orgnl_st_cr_acctno,
                   l_orgnl_st_dr_acctno, l_orgnl_cess_cr_acctno,
                   l_orgnl_cess_dr_acctno, l_tran_reverse_flag,
                   l_gl_upd_flag, l_add_ins_date,l_original_amnt
              FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST								--Added for VMS-5739/FSP-991
             WHERE rrn = p_rrn_in
              -- AND AMOUNT = l_tran_amt
               AND customer_card_no = l_hash_pan
               AND instcode = p_inst_code_in
               AND delivery_channel = p_delivery_channel_in
               AND txn_code = p_txn_code_in
               AND msgtype='0200';
				END IF;

            IF l_orgnl_resp_code <> '00'
            THEN
               l_resp_cde := '23';
               l_err_msg := ' The original transaction was not successful';
               RAISE exp_rvsl_reject_record;
            END IF;

            IF l_tran_reverse_flag = 'Y'
            THEN
               l_resp_cde := '52';
               l_err_msg :=
                      'The reversal already done for the orginal transaction';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '53';
               l_err_msg := 'Matching transaction not found';
               RAISE exp_rvsl_reject_record;
            WHEN TOO_MANY_ROWS
            THEN
               BEGIN
                  SELECT SUM (tranfee_amt), SUM (amount)
                    INTO l_tot_fee_amount, l_tot_amount
                    FROM VMSCMS.TRANSACTIONLOG								--Added for VMS-5739/FSP-991
                   WHERE rrn = p_rrn_in
                     AND customer_card_no = l_hash_pan
                     AND instcode = p_inst_code_in
                     AND response_code = '00';
					 IF SQL%ROWCOUNT = 0 THEN
					    SELECT SUM (tranfee_amt), SUM (amount)
                    INTO l_tot_fee_amount, l_tot_amount
                    FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST								--Added for VMS-5739/FSP-991
                   WHERE rrn = p_rrn_in
                     AND customer_card_no = l_hash_pan
                     AND instcode = p_inst_code_in
                     AND response_code = '00';
					 END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_resp_cde := '21';
                     l_err_msg :=
                           'Error while selecting TRANSACTIONLOG '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;

               IF (l_tot_fee_amount IS NULL) AND (l_tot_amount IS NULL)
               THEN
                  l_resp_cde := '21';
                  l_err_msg :=
                     'More than one failure matching record found in the master';
                  RAISE exp_rvsl_reject_record;
                 ELSE
                  BEGIN
                     SELECT delivery_channel, response_code,
                            txn_code, txn_mode,
                            business_date, business_time,
                            customer_card_no, feecode,
                            fee_plan, tranfee_amt,
                            cr_dr_flag, feecode,
                            tranfee_amt, servicetax_amt,
                            cess_amt, tranfee_cr_acctno,
                            tranfee_dr_acctno, tran_st_calc_flag,
                            tran_cess_calc_flag, tran_st_cr_acctno,
                            tran_st_dr_acctno, tran_cess_cr_acctno,
                            tran_cess_dr_acctno, tran_reverse_flag,
                            gl_upd_flag, add_ins_date,AMOUNT
                       INTO l_orgnl_delivery_channel, l_orgnl_resp_code,
                            l_orgnl_txn_code, l_orgnl_txn_mode,
                            l_orgnl_business_date, l_orgnl_business_time,
                            l_orgnl_customer_card_no, l_orgnl_txn_feecode,
                            l_orgnl_txn_fee_plan, l_orgnl_txn_totalfee_amt,
                            l_orgnl_transaction_type, l_actual_feecode,
                            l_orgnl_tranfee_amt, l_orgnl_servicetax_amt,
                            l_orgnl_cess_amt, l_orgnl_tranfee_cr_acctno,
                            l_orgnl_tranfee_dr_acctno, l_orgnl_st_calc_flag,
                            l_orgnl_cess_calc_flag, l_orgnl_st_cr_acctno,
                            l_orgnl_st_dr_acctno, l_orgnl_cess_cr_acctno,
                            l_orgnl_cess_dr_acctno, l_tran_reverse_flag,
                            l_gl_upd_flag, l_add_ins_date,l_original_amnt
                       FROM VMSCMS.TRANSACTIONLOG								--Added for VMS-5739/FSP-991
                      WHERE rrn = p_rrn_in
                       -- AND AMOUNT = l_tran_amt
                        AND customer_card_no = l_hash_pan
                        AND instcode = p_inst_code_in
                        AND response_code = '00'
                        AND delivery_channel = p_delivery_channel_in
                        AND txn_code = p_txn_code_in
                        AND msgtype='0200'
                        AND ROWNUM = 1;
						IF SQL%ROWCOUNT = 0 THEN
						SELECT delivery_channel, response_code,
                            txn_code, txn_mode,
                            business_date, business_time,
                            customer_card_no, feecode,
                            fee_plan, tranfee_amt,
                            cr_dr_flag, feecode,
                            tranfee_amt, servicetax_amt,
                            cess_amt, tranfee_cr_acctno,
                            tranfee_dr_acctno, tran_st_calc_flag,
                            tran_cess_calc_flag, tran_st_cr_acctno,
                            tran_st_dr_acctno, tran_cess_cr_acctno,
                            tran_cess_dr_acctno, tran_reverse_flag,
                            gl_upd_flag, add_ins_date,AMOUNT
                       INTO l_orgnl_delivery_channel, l_orgnl_resp_code,
                            l_orgnl_txn_code, l_orgnl_txn_mode,
                            l_orgnl_business_date, l_orgnl_business_time,
                            l_orgnl_customer_card_no, l_orgnl_txn_feecode,
                            l_orgnl_txn_fee_plan, l_orgnl_txn_totalfee_amt,
                            l_orgnl_transaction_type, l_actual_feecode,
                            l_orgnl_tranfee_amt, l_orgnl_servicetax_amt,
                            l_orgnl_cess_amt, l_orgnl_tranfee_cr_acctno,
                            l_orgnl_tranfee_dr_acctno, l_orgnl_st_calc_flag,
                            l_orgnl_cess_calc_flag, l_orgnl_st_cr_acctno,
                            l_orgnl_st_dr_acctno, l_orgnl_cess_cr_acctno,
                            l_orgnl_cess_dr_acctno, l_tran_reverse_flag,
                            l_gl_upd_flag, l_add_ins_date,l_original_amnt
                       FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST								--Added for VMS-5739/FSP-991
                      WHERE rrn = p_rrn_in
                       -- AND AMOUNT = l_tran_amt
                        AND customer_card_no = l_hash_pan
                        AND instcode = p_inst_code_in
                        AND response_code = '00'
                        AND delivery_channel = p_delivery_channel_in
                        AND txn_code = p_txn_code_in
                        AND msgtype='0200'
                        AND ROWNUM = 1;
						END IF;

                     l_orgnl_txn_totalfee_amt := l_tot_fee_amount;
                     l_orgnl_tranfee_amt := l_tot_fee_amount;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        l_resp_cde := '21';
                        l_err_msg := 'NO DATA IN TRANSACTIONLOG2';
                        RAISE exp_rvsl_reject_record;
                     WHEN OTHERS
                     THEN
                        l_resp_cde := '21';
                        l_err_msg :=
                              'Error while selecting TRANSACTIONLOG2 '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_rvsl_reject_record;
                  END;

                  --Added to check the reversal already done
                  IF l_tran_reverse_flag = 'Y'
                  THEN
                     l_resp_cde := '52';
                     l_err_msg :=
                        'The reversal already done for the orginal transaction';
                     RAISE exp_rvsl_reject_record;
                  END IF;
               END IF;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error while selecting master data'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;


          ---Sn check card number
         IF l_orgnl_customer_card_no <> l_hash_pan
         THEN
            l_resp_cde := '21';
            l_err_msg :=
               'Customer card number is not matching in reversal and orginal transaction';
            RAISE exp_rvsl_reject_record;
         END IF;

         --En check card number


         --Sn Check the Flag for Reversal transaction

            IF l_dr_cr_flag = 'NA'
            THEN
               l_resp_cde := '21';
               l_err_msg := 'Not a valid orginal transaction for reversal';
               RAISE exp_rvsl_reject_record;
            END IF;


         --En Check the Flag for Reversal transaction
          --Sn Check the transaction type with Original txn type
         IF l_dr_cr_flag <> l_orgnl_transaction_type
         THEN
            l_resp_cde := '21';
            l_err_msg :=
               'Orginal transaction type is not matching with actual transaction type';
            RAISE exp_rvsl_reject_record;
         END IF;

         --En Check the transaction type
         ---Sn find cutoff time
         BEGIN
            SELECT cip_param_value
              INTO l_cutoff_time
              FROM cms_inst_param
             WHERE cip_param_key = 'CUTOFF' AND cip_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_cutoff_time := 0;
               l_resp_cde := '21';
               l_err_msg := 'Cutoff time is not defined in the system';
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg := 'Error while selecting cutoff  dtl  from system ';
               RAISE exp_rvsl_reject_record;
         END;

         ---En find cutoff time
         BEGIN
            SELECT     cam_acct_bal, cam_ledger_bal, cam_type_code
                  INTO l_acct_bal, l_ledger_bal, l_acct_type
                  FROM cms_acct_mast
                 WHERE cam_acct_no = l_acct_number
                   AND cam_inst_code = p_inst_code_in
            FOR UPDATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Problem while selecting Account detail '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --Sn Check for maximum card balance configured for the product profile.

        IF l_dr_cr_flag = 'DR' AND p_rvsl_code_in <>0 THEN

         BEGIN
            SELECT TO_NUMBER (cbp_param_value)
              INTO l_max_card_bal
              FROM cms_bin_param
             WHERE cbp_inst_code = p_inst_code_in
               AND cbp_param_name = 'Max Card Balance'
               AND cbp_profile_code IN (
                      SELECT cpc_profile_code
                        FROM cms_prod_cattype
                       WHERE cpc_inst_code = p_inst_code_in
                         AND cpc_prod_code = l_prod_code
                         AND cpc_card_type = l_card_type);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'NO CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ';
               RAISE exp_rvsl_reject_record;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;



     IF ((l_acct_bal + (l_original_amnt + l_orgnl_txn_totalfee_amt)) >l_max_card_bal) OR
        ((l_ledger_bal + (l_original_amnt + l_orgnl_txn_totalfee_amt)) >l_max_card_bal) THEN

         l_resp_cde := '30';
         l_err_msg :='Exceeding Maximum Card Balance '|| SUBSTR (SQLERRM, 1, 200);

        RAISE exp_rvsl_reject_record;

         END IF;

  END IF;

         -- En Check for maximum card balance configured for the product profile.



            BEGIN
               sp_reverse_card_amount (p_inst_code_in,
                                       NULL,
                                       p_rrn_in,
                                       p_delivery_channel_in,
                                       NULL,
                                       NULL,
                                       p_txn_code_in,
                                       l_rvsl_trandate,
                                       p_txn_mode_in,
                                       p_pan_code_in,
                                       l_original_amnt,
                                       p_rrn_in,
                                       l_acct_number,
                                       p_tran_date_in,
                                       p_tran_time_in,
                                       l_auth_id,
                                       l_trans_desc,
                                       l_orgnl_business_date,
                                       l_orgnl_business_time,
                                       NULL,
                                       NULL,
                                       NULL,
                                       l_resp_cde,
                                       l_err_msg
                                      );

               IF l_resp_cde <> '00' OR l_err_msg <> 'OK'
               THEN
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_err_msg :=
                        'Error while reversing the amount '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         --En reverse the amount


         --Added For Reversal Fees
         IF l_reversal_amt_flag <> 'P'
         THEN
            IF l_orgnl_txn_totalfee_amt > 0
               OR l_orgnl_txn_feecode IS NOT NULL
            THEN
               BEGIN
                  SELECT cfm_feecap_flag, cfm_fee_amt
                    INTO l_feecap_flag, l_orgnl_fee_amt
                    FROM cms_fee_mast
                   WHERE cfm_inst_code = p_inst_code_in
                     AND cfm_fee_code = l_orgnl_txn_feecode;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     l_feecap_flag := '';
                  WHEN OTHERS
                  THEN
                     l_err_msg :=
                           'Error in feecap flag fetch '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;

               BEGIN
                  FOR l_row_idx IN l_cur_stmnts_log
                  LOOP
                     l_orgnl_tranfee_amt := l_row_idx.csl_trans_amount;

                     IF l_feecap_flag = 'Y'
                     THEN
                        BEGIN
                           sp_tran_fees_revcapcheck (p_inst_code_in,
                                                     l_acct_number,
                                                     l_orgnl_business_date,
                                                     l_orgnl_tranfee_amt,
                                                     l_orgnl_fee_amt,
                                                     l_orgnl_txn_fee_plan,
                                                     l_orgnl_txn_feecode,
                                                     l_err_msg
                                                    );
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              l_resp_cde := '21';
                              l_err_msg :=
                                    'Error while reversing the fee Cap amount '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE exp_rvsl_reject_record;
                        END;
                     END IF;

                     BEGIN
                        sp_reverse_fee_amount (p_inst_code_in,
                                               p_rrn_in,
                                               p_delivery_channel_in,
                                               NULL,
                                               NULL,
                                               p_txn_code_in,
                                               l_rvsl_trandate,
                                               p_txn_mode_in,
                                               l_orgnl_tranfee_amt,
                                               p_pan_code_in,
                                               l_actual_feecode,
                                               l_orgnl_tranfee_amt,
                                               l_orgnl_tranfee_cr_acctno,
                                               l_orgnl_tranfee_dr_acctno,
                                               l_orgnl_st_calc_flag,
                                               l_orgnl_servicetax_amt,
                                               l_orgnl_st_cr_acctno,
                                               l_orgnl_st_dr_acctno,
                                               l_orgnl_cess_calc_flag,
                                               l_orgnl_cess_amt,
                                               l_orgnl_cess_cr_acctno,
                                               l_orgnl_cess_dr_acctno,
                                               p_rrn_in,
                                               l_acct_number,
                                               p_tran_date_in,
                                               p_tran_time_in,
                                               l_auth_id,
                                               l_row_idx.csl_trans_narrration,
                                               NULL,
                                               NULL,
                                               NULL,
                                               l_resp_cde,
                                               l_err_msg
                                              );
                        l_fee_narration := l_row_idx.csl_trans_narrration;

                        IF l_resp_cde <> '00' OR l_err_msg <> 'OK'
                        THEN
                           RAISE exp_rvsl_reject_record;
                        END IF;
                     EXCEPTION
                        WHEN exp_rvsl_reject_record
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           l_resp_cde := '21';
                           l_err_msg :=
                                 'Error while reversing the fee amount '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_rvsl_reject_record;
                     END;
                  END LOOP;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     l_fee_narration := NULL;
                  WHEN OTHERS
                  THEN
                     l_fee_narration := NULL;
               END;
            END IF;

            --Added For Reversal Fees
            IF l_fee_narration IS NULL
            THEN
               IF l_feecap_flag = 'Y'
               THEN
                  BEGIN
                     sp_tran_fees_revcapcheck (p_inst_code_in,
                                               l_acct_number,
                                               l_orgnl_business_date,
                                               l_orgnl_tranfee_amt,
                                               l_orgnl_fee_amt,
                                               l_orgnl_txn_fee_plan,
                                               l_orgnl_txn_feecode,
                                               l_err_msg
                                              );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_resp_cde := '21';
                        l_err_msg :=
                              'Error while reversing the fee Cap amount '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_rvsl_reject_record;
                  END;
               END IF;

               BEGIN
                  sp_reverse_fee_amount (p_inst_code_in,
                                         p_rrn_in,
                                         p_delivery_channel_in,
                                         NULL,
                                         NULL,
                                         p_txn_code_in,
                                         l_rvsl_trandate,
                                         p_txn_mode_in,
                                         l_orgnl_txn_totalfee_amt,
                                         p_pan_code_in,
                                         l_actual_feecode,
                                         l_orgnl_tranfee_amt,
                                         l_orgnl_tranfee_cr_acctno,
                                         l_orgnl_tranfee_dr_acctno,
                                         l_orgnl_st_calc_flag,
                                         l_orgnl_servicetax_amt,
                                         l_orgnl_st_cr_acctno,
                                         l_orgnl_st_dr_acctno,
                                         l_orgnl_cess_calc_flag,
                                         l_orgnl_cess_amt,
                                         l_orgnl_cess_cr_acctno,
                                         l_orgnl_cess_dr_acctno,
                                         p_rrn_in,
                                         l_acct_number,
                                         p_tran_date_in,
                                         p_tran_time_in,
                                         l_auth_id,
                                         l_fee_narration,
                                         NULL,
                                         NULL,
                                         NULL,
                                         l_resp_cde,
                                         l_err_msg
                                        );

                  IF l_resp_cde <> '00' OR l_err_msg <> 'OK'
                  THEN
                     RAISE exp_rvsl_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_rvsl_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     l_resp_cde := '21';
                     l_err_msg :=
                           'Error while reversing the fee amount '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_rvsl_reject_record;
               END;
            END IF;
         END IF;

         --En reverse the fee
         IF l_gl_upd_flag = 'Y'
         THEN
            --Sn find business date
            l_business_time := TO_CHAR (l_rvsl_trandate, 'HH24:MI');

            IF l_business_time > l_cutoff_time
            THEN
               l_rvsl_trandate := TRUNC (l_rvsl_trandate) + 1;
            ELSE
               l_rvsl_trandate := TRUNC (l_rvsl_trandate);
            END IF;
         --En find businesses date
         END IF;

         l_resp_cde := '1';

         BEGIN
		--Added for VMS-5735/FSP-991
	   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date_in), 1, 8), 'yyyymmdd');


		IF (v_Retdate>v_Retperiod)THEN 													   --Added for VMS-5735/FSP-991
			
			UPDATE cms_statements_log
               SET csl_prod_code = l_prod_code,
                    csl_card_type=l_card_type,
                   csl_acct_type = l_acct_type,
                   csl_time_stamp = l_time_stamp
             WHERE csl_inst_code = p_inst_code_in
               AND csl_pan_no = l_hash_pan
               AND csl_rrn = p_rrn_in
               AND csl_txn_code = p_txn_code_in
               AND csl_delivery_channel = p_delivery_channel_in
               AND csl_business_date = p_tran_date_in
               AND csl_business_time = p_tran_time_in;
		ELSE
			
			UPDATE VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST							 --Added for VMS-5739/FSP-991
               SET csl_prod_code = l_prod_code,
                    csl_card_type=l_card_type,
                   csl_acct_type = l_acct_type,
                   csl_time_stamp = l_time_stamp
             WHERE csl_inst_code = p_inst_code_in
               AND csl_pan_no = l_hash_pan
               AND csl_rrn = p_rrn_in
               AND csl_txn_code = p_txn_code_in
               AND csl_delivery_channel = p_delivery_channel_in
               AND csl_business_date = p_tran_date_in
               AND csl_business_time = p_tran_time_in;
		END IF;

            IF SQL%ROWCOUNT = 0
            THEN
               NULL;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                     'Error while updating timestamp in statementlog-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

         --Sn update reverse flag
         BEGIN
		 
		 --Added for VMS-5739/FSP-991
		 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
			   INTO   v_Retperiod 
			   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
			   WHERE  OPERATION_TYPE='ARCHIVE' 
			   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
			   
			   v_Retdate := TO_DATE(SUBSTR(TRIM(l_orgnl_business_date), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)
		THEN
			UPDATE VMSCMS.TRANSACTIONLOG								--Added for VMS-5739/FSP-991
               SET tran_reverse_flag = 'Y'
             WHERE rrn = p_rrn_in
               AND business_date = l_orgnl_business_date
               AND business_time = l_orgnl_business_time
               AND customer_card_no = l_hash_pan
               AND instcode = p_inst_code_in;
			   
     ELSE
	 
	 UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5739/FSP-991
               SET tran_reverse_flag = 'Y'
             WHERE rrn = p_rrn_in
               AND business_date = l_orgnl_business_date
               AND business_time = l_orgnl_business_time
               AND customer_card_no = l_hash_pan
               AND instcode = p_inst_code_in;
	 	 
	 END IF;

            IF SQL%ROWCOUNT = 0
            THEN
               l_resp_cde := '21';
               l_err_msg := 'Reverse flag is not updated ';
               RAISE exp_rvsl_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_rvsl_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               l_resp_cde := '21';
               l_err_msg :=
                  'Error while updating gl flag ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_rvsl_reject_record;
         END;

          --En update reverse flag

          IF l_orgnl_txn_totalfee_amt=0 AND l_orgnl_txn_feecode IS NOT NULL THEN
            BEGIN
               vmsfee.fee_freecnt_reverse (l_acct_number, l_orgnl_txn_feecode, l_err_msg);

               IF l_err_msg <> 'OK' THEN
                  l_resp_cde := '21';
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record THEN
                  RAISE;
               WHEN OTHERS THEN
                  l_resp_cde := '21';
                  l_err_msg :='Error while reversing freefee count-'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
          END IF;
         --Sn Added  for enabling limit validation
         IF     l_add_ins_date IS NOT NULL
            AND l_prfl_code IS NOT NULL
            AND l_prfl_flag = 'Y'
         THEN
            BEGIN
               pkg_limits_check.sp_limitcnt_rever_reset (p_inst_code_in,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         p_txn_code_in,
                                                         l_tran_type,
                                                         NULL,
                                                         NULL,
                                                         l_prfl_code,
                                                         l_original_amnt,
                                                         l_hold_amount,
                                                         p_delivery_channel_in,
                                                         l_hash_pan,
                                                         l_add_ins_date,
                                                         l_resp_cde,
                                                         l_err_msg
                                                        );

               IF l_err_msg <> 'OK'
               THEN
                  RAISE exp_rvsl_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_rvsl_reject_record
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_resp_cde := '21';
                  l_err_msg :=
                        'Error from Limit count rever Process '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_rvsl_reject_record;
            END;
         END IF;

      --START Condition added for Mantis id:0016259
      IF l_dr_cr_flag = 'CR' THEN
      l_dr_cr_flag := 'DR';
      ELSE
      l_dr_cr_flag := 'CR';
      END IF;
      --END Condition Added for Mantis id:0016259

      EXCEPTION
         WHEN exp_rvsl_reject_record
         THEN
            ROLLBACK TO l_auth_savepoint;
         WHEN OTHERS
         THEN
            l_resp_cde := '21';
            l_err_msg := ' Exception ' || SQLCODE || '---' || SQLERRM;
            ROLLBACK TO l_auth_savepoint;
      END;

      --Sn Get responce code fomr master
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code_out
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code_in
            AND cms_delivery_channel = p_delivery_channel_in
            AND cms_response_id = l_resp_cde;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while selecting data from response master '
               || l_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

      --En Get responce code fomr master
      IF l_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
              INTO l_card_stat, l_prod_code, l_card_type, l_acct_number
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code_in
               AND cap_pan_code = gethash (p_pan_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO l_acct_bal, l_ledger_bal, l_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = l_acct_number AND cam_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_acct_bal := 0;
            l_ledger_bal := 0;
      END;

      IF l_dr_cr_flag IS NULL
      THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                   ctm_preauth_flag
              INTO l_dr_cr_flag,
                   l_txn_type,
                   l_tran_type, l_trans_desc, l_prfl_flag,
                   l_preauth_flag
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code_in
               AND ctm_delivery_channel = p_delivery_channel_in
               AND ctm_inst_code = p_inst_code_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      --Sn Inserting data in transactionlog
      BEGIN
         sp_log_txnlog (p_inst_code_in,
                        p_msg_type_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_txn_code_in,
                        l_txn_type,
                        p_txn_mode_in,
                        p_tran_date_in,
                        p_tran_time_in,
                        p_rvsl_code_in,
                        l_hash_pan,
                        l_encr_pan,
                        l_err_msg,
                        NULL,
                        l_card_stat,
                        l_trans_desc,
                        NULL,
                        NULL,
                        l_time_stamp,
                        l_acct_number,
                        l_prod_code,
                        l_card_type,
                        l_dr_cr_flag,
                        l_acct_bal,
                        l_ledger_bal,
                        l_acct_type,
                        l_proxy_number,
                        l_auth_id,
                        NVL (l_original_amnt, l_tran_amt),
                          NVL (l_original_amnt, l_tran_amt)
                        + NVL (l_orgnl_txn_totalfee_amt, 0),
                        l_fee_code,
                        l_tranfee_amt,
                        l_fee_plan,
                        l_feeattach_type,
                        l_resp_cde,
                        p_resp_code_out,
                        p_curr_code_in,
                        l_err_msg,
                        NULL,
                        NULL,
                        p_remarks_in,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_partner_id_in
                       );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code_out := '89';
            l_err_msg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
      END;

      --En Inserting data in transactionlog
      --Sn Inserting data in transactionlog dtl
      BEGIN
         l_reason_code_desc := get_reason_code_desc(p_reason_code_in);
         sp_log_txnlogdetl (p_inst_code_in,
                            p_msg_type_in,
                            p_rrn_in,
                            p_delivery_channel_in,
                            p_txn_code_in,
                            l_txn_type,
                            p_txn_mode_in,
                            p_tran_date_in,
                            p_tran_time_in,
                            l_hash_pan,
                            l_encr_pan,
                            l_err_msg,
                            l_acct_number,
                            l_auth_id,
                            NVL (l_original_amnt, l_tran_amt),
                            p_mobile_no_in,
                            p_device_id_in,
                            l_hashkey_id,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            p_resp_code_out,
                            NULL,
                            p_reason_code_in,
                            l_reason_code_desc,
                            l_logdtl_resp
                           );
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '89';
      END;

      p_resmsg_out := l_err_msg;
      p_reversal_amount_out := l_reversal_amt;

   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_resp_code_out := '69';                              -- Server Declined
         p_resmsg_out :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
   END;



PROCEDURE        sp_mob_check_deposit(
   P_INST_CODE          IN       NUMBER,
   P_MSG_TYPE           IN       VARCHAR2,
   P_RRN                IN       VARCHAR2,
   P_DELIVERY_CHANNEL   IN       VARCHAR2,
   P_TXN_CODE           IN       VARCHAR2,
   P_TXN_MODE           IN       VARCHAR2,
   P_TRAN_DATE          IN       VARCHAR2,
   P_TRAN_TIME          IN       VARCHAR2,
   P_PAN_CODE           IN       VARCHAR2,
   P_MBR_NUMB           IN       VARCHAR2,
   P_RVSL_CODE          IN       VARCHAR2,
   P_CUSTOMERID         IN       VARCHAR2,
   P_CURR_CODE          IN       VARCHAR2,
   P_TRAN_AMOUNT        IN       VARCHAR2,
   P_DEPOSIT_ID         IN       VARCHAR2,
   P_PARTNER_ID         IN       VARCHAR2,
   P_MOBIL_NO           IN       VARCHAR2,
   P_DEVICE_ID          IN       VARCHAR2,
   P_CHCEK_ACCTNO       IN       VARCHAR2,
   P_CHECK_NO           IN       VARCHAR2,
   P_USER_CHECKDESC     IN       VARCHAR2,
   P_CHECK_IMAGEFS      IN       BLOB,
   P_CHECK_IMAGEBS      IN       BLOB,
   P_EXPRYDATE          IN       VARCHAR2,
   P_ROUTING_NO         IN       VARCHAR2,
   p_reason_code_in     IN       VARCHAR2,
   P_RESP_CODE          OUT      VARCHAR2,
   P_RESMSG             OUT      VARCHAR2,
   P_ACCT_BAL           OUT      VARCHAR2,
   P_PREV_BALANCE       OUT      VARCHAR2,
   P_EMAIL_ID           OUT      VARCHAR2,
   P_ORG_RESP_CODE      OUT      VARCHAR2,
   P_ORG_RESP_DESC      OUT      VARCHAR2
   )
as
   --v_auth_savepoint    NUMBER  DEFAULT 0;
   v_count             NUMBER;
   v_err_msg           VARCHAR2 (500);
   v_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
   v_txn_type          transactionlog.txn_type%TYPE;
   v_auth_id           transactionlog.auth_id%TYPE;
   exp_reject_record   EXCEPTION;
   v_dr_cr_flag        VARCHAR2 (2);
   v_tran_type         VARCHAR2 (2);
   v_tran_amt          NUMBER;
   v_prod_code         cms_appl_pan.cap_prod_code%TYPE;
   v_card_type         cms_appl_pan.cap_card_type%TYPE;
   v_resp_cde          VARCHAR2 (5);
   v_time_stamp        TIMESTAMP;
   v_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   v_trans_desc        VARCHAR2 (100);
   v_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_rrn_count         NUMBER;
   v_acct_number       cms_appl_pan.cap_acct_no%TYPE;
   v_prfl_code         cms_appl_pan.cap_prfl_code%TYPE;
   v_card_stat         cms_appl_pan.cap_card_stat%TYPE;
   v_cust_code         cms_appl_pan.cap_cust_code%TYPE;
   v_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
   v_acct_bal          cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
   v_acct_type         cms_acct_mast.cam_type_code%TYPE;
   v_proxy_number      cms_appl_pan.cap_proxy_number%TYPE;
   v_fee_code          transactionlog.feecode%TYPE;
   v_fee_plan          transactionlog.fee_plan%TYPE;
   v_feeattach_type    transactionlog.feeattachtype%TYPE;
   v_tranfee_amt       transactionlog.tranfee_amt%TYPE;
   v_total_amt         transactionlog.total_amount%TYPE;
   v_expry_date        cms_appl_pan.cap_expry_date%TYPE;
   v_comb_hash         pkg_limits_check.type_hash;
   v_email_id          cms_addr_mast.CAM_EMAIL%TYPE;
   v_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
   V_LOGDTL_RESP       varchar2 (500);
   V_TXN_FLAG         CMS_CHECKDEPOSIT_TRANSACTION.CCT_TXN_FLAG%type;
   V_RRN              CMS_CHECKDEPOSIT_TRANSACTION.CCT_RRN%type;
   V_ACT_DATE         CMS_CHECKDEPOSIT_TRANSACTION.CCT_ACT_DATE%type;
   V_ACT_TIME         CMS_CHECKDEPOSIT_TRANSACTION.CCT_ACT_TIME%type;
   V_RESPONSE_CODE    CMS_CHECKDEPOSIT_TRANSACTION.CCT_RESPONSE_CODE%type;
   V_RESPONSE_DESC    CMS_CHECKDEPOSIT_TRANSACTION.CCT_RESPONSE_DESC%type;
   V_PRE_ACCT_BAL      CMS_ACCT_MAST.CAM_ACCT_BAL%type;
   V_PARTNER_NAME     VMS_PARTNER_MAST.VPM_PARTNER_NAME%TYPE;
   V_concurrent_flag  NUMBER; --Added by saravanakumar for 4.7(performance changes)
   v_encrypt_enable   cms_prod_cattype.cpc_encrypt_enable%TYPE;
   v_compl_fee varchar2(10);
   v_compl_feetxn_excd varchar2(10);
   v_compl_feecode varchar2(10);
   l_reason_code_desc     vms_reason_mast.VRM_REASON_DESC%TYPE;
   /**********************************************************************************************
        * Created Date      : 22-Jan-2016
        * Created By        : Ramesh
        * PURPOSE           : RDC
        * Review            : Saravana
        * Build Number      : 3.3.1

			 * Modified By      : Sreeja D
     * Modified Date    : 25/01/2018
     * Purpose          : VMS-162
     * Reviewer         : SaravanaKumar A/Vini Pushkaran
     * Release Number   : VMSGPRHOST18.01

     * Modified by                 : DHINAKARAN B
  * Modified Date               : 26-NOV-2019
  * Modified For                : VMS-1415
  * Reviewer                    :  Saravana Kumar A
  * Build Number                :  VMSGPRHOST_R23_B1
  
  * Modified By      : John Gingrich
    * Modified Date    : 08-28-2023
    * Purpose          : Concurrent Pre-Auth Reversals
    * Reviewer         : 
    * Release Number   : VMSGPRHOSTR85 for VMS-5551
    
/**********************************************************************************************/
BEGIN
   v_resp_cde := '1';
   v_time_stamp := SYSTIMESTAMP;

   begin
      --SAVEPOINT v_auth_savepoint;
      v_tran_amt := NVL (ROUND (p_tran_amount, 2), 0);

      --Sn Get the HashPan
      BEGIN
         v_hash_pan := gethash (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         then
            v_resp_cde := '21';
            v_err_msg :=
               'Error while converting hash pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get the HashPan

      --Sn Create encr pan
      BEGIN
         v_encr_pan := fn_emaps_main (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while converting emcrypted pan '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --Start Generate HashKEY value
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
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while Generating  hashkey id data '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --End Generate HashKEY

      --Sn find debit and credit flag
      BEGIN
         SELECT ctm_credit_debit_flag,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                ctm_preauth_flag, ctm_login_txn
           INTO v_dr_cr_flag,
                v_txn_type,
                v_tran_type, v_trans_desc, v_prfl_flag,
                v_preauth_flag, v_login_txn
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
          WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while selecting transaction details '|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En find debit and credit flag

      --Sn Get the card details
      BEGIN
         SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                cap_prfl_code, cap_expry_date, cap_proxy_number,
                cap_cust_code
           INTO v_card_stat, v_prod_code, v_card_type, v_acct_number,
                v_prfl_code, v_expry_date, v_proxy_number,
                v_cust_code
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting card detail'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --End Get the card details

	  BEGIN
     SELECT   CPC_ENCRYPT_ENABLE
       INTO  V_ENCRYPT_ENABLE
       FROM CMS_PROD_CATTYPE
      WHERE CPC_INST_CODE = p_inst_code AND
	        CPC_PROD_CODE = V_PROD_CODE AND
            CPC_CARD_TYPE = V_card_type;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       v_resp_cde := '21';
       v_err_msg  := 'No data found in CMS_PROD_CATTYPE for encrpt enable flag' || SUBSTR (SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       v_resp_cde := '21';
       v_err_msg  := 'Error while selcting encrypt enable flag' || SUBSTR (SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

       BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_bal, v_ledger_bal, v_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting Account  detail '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      end;
      v_pre_acct_bal :=v_acct_bal;


      BEGIN
      SELECT '-'||VPM_PARTNER_NAME INTO V_PARTNER_NAME
      from VMS_PARTNER_MAST
      WHERE VPM_PARTNER_ID=P_PARTNER_ID;

      EXCEPTION
       when NO_DATA_FOUND then
           V_PARTNER_NAME :='';
       when OTHERS then
            V_RESP_CDE := '21';
            V_ERR_MSG :='Problem while selecting partner mast' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      V_TRANS_DESC := V_TRANS_DESC || V_PARTNER_NAME;

      if length(V_TRANS_DESC)>50 then
      V_TRANS_DESC := substr(V_TRANS_DESC,1,50);
      end if;

      begin

      select CCT_TXN_FLAG,CCT_RRN,CCT_ACT_DATE,CCT_ACT_TIME,CCT_RESPONSE_CODE,CCT_RESPONSE_DESC
      into V_TXN_FLAG,V_RRN ,V_ACT_DATE,V_ACT_TIME,V_RESPONSE_CODE,V_RESPONSE_DESC
      FROM CMS_CHECKDEPOSIT_TRANSACTION
      where CCT_DELV_CHNL = P_DELIVERY_CHANNEL
      and CCT_PARTNER_ID=P_PARTNER_ID
      and CCT_DEPOSIT_ID = P_DEPOSIT_ID
      and CCT_INST_CODE = P_INST_CODE;

      if V_TXN_FLAG in('1','3') then

         V_RESP_CDE := '252';
         V_ERR_MSG :='Duplicate Deposit ID';

         P_ORG_RESP_CODE :=V_RESPONSE_CODE;
         P_ORG_RESP_DESC :=V_RESPONSE_DESC;

       RAISE EXP_REJECT_RECORD;

     END IF;

       EXCEPTION
       WHEN NO_DATA_FOUND THEN
         NULL;
       when EXP_REJECT_RECORD then
         RAISE;
       when OTHERS then
            v_resp_cde := '21';
            v_err_msg :='Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      end;

      if P_EXPRYDATE is not null then
        begin
         IF substr(P_EXPRYDATE,1,7) <> TO_CHAR(v_expry_date, 'YYYY-MM') THEN
            V_RESP_CDE := '47';
            V_ERR_MSG  := 'Invalid Expiry Date';
        RAISE EXP_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERR_MSG  := 'ERROR IN EXPIRY DATE CHECK ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     end;
    end if;


      --Sn generate auth id
      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      BEGIN
        sp_autonomous_preauth_log(V_AUTH_ID,P_DEPOSIT_ID||'~'||p_partner_id, P_TRAN_DATE, v_hash_pan, p_inst_code, p_delivery_channel , v_err_msg);
       --Added VMS-5551
       IF v_err_msg != 'OK' THEN
       V_RESP_CDE     := '191';
       RAISE exp_reject_record;
       END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        v_resp_cde := '12';
        v_err_msg  := 'Concurrent check Failed' || SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;

      --En generate auth id
      BEGIN
         sp_cmsauth_check (p_inst_code,
                           p_msg_type,
                           p_rrn,
                           p_delivery_channel,
                           p_txn_code,
                           p_txn_mode,
                           p_tran_date,
                           p_tran_time,
                           p_mbr_numb,
                           p_rvsl_code,
                           v_tran_type,
                           p_curr_code,
                           v_tran_amt,
                           p_pan_code,
                           v_hash_pan,
                           v_encr_pan,
                           v_card_stat,
                           v_expry_date,
                           v_prod_code,
                           v_card_type,
                           v_prfl_flag,
                           v_prfl_code,
                           NULL,
                           NULL,
                           NULL,
                           v_resp_cde,
                           v_err_msg,
                           v_comb_hash
                          );

         if V_ERR_MSG <> 'OK'
         THEN
            v_err_msg :='Error in sp_cmsauth_check  ' ||v_err_msg;
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
                  'Error from  cmsauth Check Procedure  '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         sp_fee_calc (p_inst_code,
                      p_msg_type,
                      p_rrn,
                      p_delivery_channel,
                      p_txn_code,
                      p_txn_mode,
                      p_tran_date,
                      p_tran_time,
                      p_mbr_numb,
                      p_rvsl_code,
                      v_txn_type,
                      p_curr_code,
                      v_tran_amt,
                      p_pan_code,
                      v_hash_pan,
                      v_encr_pan,
                      v_acct_number,
                      v_prod_code,
                      v_card_type,
                      v_preauth_flag,
                      NULL,
                      NULL,
                      NULL,
                      v_trans_desc,
                      v_dr_cr_flag,
                      v_acct_bal,
                      v_ledger_bal,
                      v_acct_type,
                      v_login_txn,
                      v_auth_id,
                      v_time_stamp,
                      v_resp_cde,
                      v_err_msg,
                      v_fee_code,
                      v_fee_plan,
                      v_feeattach_type,
                      v_tranfee_amt,
                      v_total_amt,
                      v_compl_fee,
                      v_compl_feetxn_excd,
                      v_compl_feecode
                     );

         IF v_err_msg <> 'OK'
         THEN
            v_err_msg :='Error in sp_fee_calc  ' ||v_err_msg;
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
                       'Error from sp_fee_calc  ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      v_resp_cde := 1;

      IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y'
      THEN
         BEGIN
            pkg_limits_check.sp_limitcnt_reset (p_inst_code,
                                                v_hash_pan,
                                                v_tran_amt,
                                                v_comb_hash,
                                                v_resp_cde,
                                                v_err_msg
                                               );

            IF v_err_msg <> 'OK'
            THEN
               v_err_msg := 'From Procedure sp_limitcnt_reset' || v_err_msg;
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
                     'Error from Limit Reset Count Process '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      end if;

      v_err_msg := 'SUCCESS';
   EXCEPTION
      WHEN exp_reject_record
      then
         ROLLBACK;-- TO v_auth_savepoint;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         V_ERR_MSG := ' Exception ' || V_ERR_MSG;
         ROLLBACK;-- TO v_auth_savepoint;
   END;

   --Sn Get responce code fomr master
   BEGIN
      select CMS_ISO_RESPCDE,CMS_RESP_DESC
        INTO p_resp_code,V_RESPONSE_DESC
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code
         AND cms_delivery_channel = p_delivery_channel
         AND cms_response_id = v_resp_cde;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Problem while selecting data from response master '
            || v_resp_cde
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '89';
   END;

   --En Get responce code fomr master
  IF v_prod_code IS NULL
   THEN
      BEGIN
         SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
           INTO v_card_stat, v_prod_code, v_card_type, v_acct_number
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code
            AND cap_pan_code = gethash (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END IF;

     BEGIN
        SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
          INTO v_acct_bal, v_ledger_bal, v_acct_type
          FROM cms_acct_mast
         WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
     EXCEPTION
        WHEN OTHERS
        THEN
           v_acct_bal := 0;
           v_ledger_bal := 0;
     end;

   IF v_dr_cr_flag IS NULL
   THEN
      BEGIN
         SELECT ctm_credit_debit_flag,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_tran_desc, ctm_prfl_flag, ctm_preauth_flag
           INTO v_dr_cr_flag,
                v_txn_type,
                v_tran_type, v_trans_desc, v_prfl_flag, v_preauth_flag
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      end;
   END IF;


    BEGIN
         SELECT decode(v_encrypt_enable,'Y', fn_dmaps_main(cam_email),cam_email)
           INTO v_email_id
           FROM cms_addr_mast
          WHERE cam_inst_code = p_inst_code
            AND cam_cust_code = v_cust_code
            AND cam_addr_flag = 'P';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_resp_code := '89';
            V_ERR_MSG := 'Email Id not found ';
           -- RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            v_err_msg :=
                  'Problem while selecting Email Id '|| SUBSTR (SQLERRM, 1, 300);
                --  raise;
      end;

    if V_RESP_CDE != '252'then
    BEGIN
         INSERT INTO cms_checkdeposit_transaction
                     (cct_inst_code, cct_card_no, cct_card_no_encr,
                      cct_acct_no, cct_cust_id, cct_delv_chnl,
                      cct_check_imagefs, cct_check_imagebs, cct_pend_amt,
                      CCT_RRN, cct_act_date, cct_act_time, CCT_CHECK_NO,
                      CCT_PARTNER_ID, CCT_TXN_FLAG, CCT_AUTH_ID,
                      cct_check_desc, cct_txn_amnt,cct_deposit_id,CCT_RESPONSE_CODE,CCT_RESPONSE_DESC,cct_routing_no
                     )
              VALUES (p_inst_code, v_hash_pan, v_encr_pan,
                      p_chcek_acctno, p_customerid, p_delivery_channel,
                      p_check_imagefs, p_check_imagebs, v_tran_amt,
                      p_rrn, p_tran_date, p_tran_time, p_check_no,
                      P_PARTNER_ID, '1', V_AUTH_ID,
                      p_user_checkdesc, v_tran_amt,p_deposit_id,p_resp_code,V_RESPONSE_DESC,p_routing_no
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Problem while inserting deposit transaction details '
               || SUBSTR (SQLERRM, 1, 300);
            P_RESP_CODE := '89';
           -- RAISE EXP_REJECT_RECORD;
      end;
      end if;

   --Sn Inserting data in transactionlog
   BEGIN
      sp_log_txnlog (p_inst_code,
                     p_msg_type,
                     p_rrn,
                     p_delivery_channel,
                     p_txn_code,
                     v_tran_type,
                     p_txn_mode,
                     p_tran_date,
                     p_tran_time,
                     p_rvsl_code,
                     v_hash_pan,
                     v_encr_pan,
                     v_err_msg,
                     NULL,
                     v_card_stat,
                     v_trans_desc,
                     NULL,
                     NULL,
                     v_time_stamp,
                     v_acct_number,
                     v_prod_code,
                     v_card_type,
                     v_dr_cr_flag,
                     v_acct_bal,
                     v_ledger_bal,
                     v_acct_type,
                     v_proxy_number,
                     v_auth_id,
                     v_tran_amt,
                     v_total_amt,
                     v_fee_code,
                     v_tranfee_amt,
                     v_fee_plan,
                     v_feeattach_type,
                     v_resp_cde,
                     p_resp_code,
                     P_CURR_CODE,
                     V_ERR_MSG,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      P_PARTNER_ID
                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '89';
         v_err_msg :=
               'Exception while inserting to transaction log '
            || SQLCODE
            || '---'
            || SQLERRM;
   END;

   --En Inserting data in transactionlog

   --Sn Inserting data in transactionlog dtl
   BEGIN
      l_reason_code_desc := get_reason_code_desc(p_reason_code_in);
      sp_log_txnlogdetl (p_inst_code,
                         p_msg_type,
                         p_rrn,
                         p_delivery_channel,
                         p_txn_code,
                         v_txn_type,
                         p_txn_mode,
                         p_tran_date,
                         p_tran_time,
                         v_hash_pan,
                         v_encr_pan,
                         v_err_msg,
                         v_acct_number,
                         v_auth_id,
                         v_tran_amt,
                         p_mobil_no,
                         p_device_id,
                         v_hashkey_id,
                         p_check_no,
                         P_USER_CHECKDESC,
                         null,
                         p_chcek_acctno,
                         p_resp_code,
                         p_deposit_id,
                         p_reason_code_in,
                         l_reason_code_desc,
                         v_logdtl_resp
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '89';
   END;

    Begin
      sp_autonomous_preauth_logclear(v_auth_id);
    exception
      When others then
        null;
    End;

--Sn Inserting data in transactionlog dtl
   --Assign output variable
   p_prev_balance := v_pre_acct_bal;
   P_ACCT_BAL := V_ACCT_BAL;
   p_resmsg := V_RESPONSE_DESC;
   p_email_id := v_email_id;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_resp_code := '89';                                 -- Server Declined
      p_resmsg :='Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END sp_mob_check_deposit;

PROCEDURE        sp_mob_check_deposit_rvsl(
   P_INST_CODE          IN       NUMBER,
   P_MSG_TYPE           IN       VARCHAR2,
   P_RRN                IN       VARCHAR2,
   P_DELIVERY_CHANNEL   IN       VARCHAR2,
   P_TXN_CODE           IN       VARCHAR2,
   P_TXN_MODE           IN       VARCHAR2,
   P_TRAN_DATE          IN       VARCHAR2,
   P_TRAN_TIME          IN       VARCHAR2,
   P_PAN_CODE           IN       VARCHAR2,
   P_MBR_NUMB           IN       VARCHAR2,
   P_RVSL_CODE          IN       VARCHAR2,
   P_CUSTOMERID         IN       VARCHAR2,
   P_CURR_CODE          IN       VARCHAR2,
   P_TRAN_AMOUNT        IN       VARCHAR2,
   P_DEPOSIT_ID         IN       VARCHAR2,
   P_PARTNER_ID         IN       VARCHAR2,
   P_MOBIL_NO           IN       VARCHAR2,
   P_DEVICE_ID          IN       VARCHAR2,
   P_CHCEK_ACCTNO       IN       VARCHAR2,
   P_CHECK_NO           IN       VARCHAR2,
   P_USER_CHECKDESC     IN       VARCHAR2,
   P_CHECK_IMAGEFS      IN       BLOB,
   P_CHECK_IMAGEBS      IN       BLOB,
   P_EXPRYDATE          IN       VARCHAR2,
   P_ROUTING_NO         IN       VARCHAR2,
   p_reason_code_in     IN       VARCHAR2,
   P_RESP_CODE          OUT      VARCHAR2,
   P_RESMSG             OUT      VARCHAR2,
   P_ACCT_BAL           OUT      VARCHAR2,
   P_PREV_BALANCE       OUT      VARCHAR2,
   P_EMAIL_ID           OUT      VARCHAR2,
   P_ORG_RESP_CODE      OUT      VARCHAR2,
   P_ORG_RESP_DESC      OUT      VARCHAR2
   )
as
   --v_auth_savepoint    NUMBER  DEFAULT 0;
   v_count             NUMBER;
   v_err_msg           VARCHAR2 (500);
   v_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
   v_txn_type          transactionlog.txn_type%TYPE;
   v_auth_id           transactionlog.auth_id%TYPE;
   exp_reject_record   EXCEPTION;
   v_dr_cr_flag        VARCHAR2 (2);
   v_tran_type         VARCHAR2 (2);
   v_tran_amt          NUMBER;
   v_prod_code         cms_appl_pan.cap_prod_code%TYPE;
   v_card_type         cms_appl_pan.cap_card_type%TYPE;
   v_resp_cde          VARCHAR2 (5);
   v_time_stamp        TIMESTAMP;
   v_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   v_trans_desc        VARCHAR2 (100);
   v_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_rrn_count         NUMBER;
   v_acct_number       cms_appl_pan.cap_acct_no%TYPE;
   v_prfl_code         cms_appl_pan.cap_prfl_code%TYPE;
   v_card_stat         cms_appl_pan.cap_card_stat%TYPE;
   v_cust_code         cms_appl_pan.cap_cust_code%TYPE;
   v_preauth_flag      cms_transaction_mast.ctm_preauth_flag%TYPE;
   v_acct_bal          cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal        cms_acct_mast.cam_ledger_bal%TYPE;
   v_acct_type         cms_acct_mast.cam_type_code%TYPE;
   v_proxy_number      cms_appl_pan.cap_proxy_number%TYPE;
   v_tranfee_amt       transactionlog.tranfee_amt%TYPE;
   v_total_amt         transactionlog.total_amount%TYPE;
   v_expry_date        cms_appl_pan.cap_expry_date%TYPE;
   v_comb_hash         pkg_limits_check.type_hash;
   v_email_id          cms_cust_mast.ccm_email_one%TYPE;
   v_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
   V_LOGDTL_RESP       varchar2 (500);
   V_TXN_FLAG         CMS_CHECKDEPOSIT_TRANSACTION.CCT_TXN_FLAG%type;
   V_RRN              CMS_CHECKDEPOSIT_TRANSACTION.CCT_RRN%type;
   V_ACT_DATE         CMS_CHECKDEPOSIT_TRANSACTION.CCT_ACT_DATE%type;
   V_ACT_TIME         CMS_CHECKDEPOSIT_TRANSACTION.CCT_ACT_TIME%type;
   V_RESPONSE_CODE    CMS_CHECKDEPOSIT_TRANSACTION.CCT_RESPONSE_CODE%type;
   V_PRE_ACCT_BAL     CMS_ACCT_MAST.CAM_ACCT_BAL%type;
   V_ORG_TRAN_AMT     CMS_CHECKDEPOSIT_TRANSACTION.CCT_TXN_AMNT%type;
   V_TXN_NARRATION    CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%type;
   V_PARTNER_NAME     VMS_PARTNER_MAST.VPM_PARTNER_NAME%type;
   V_RESPONSE_DESC    CMS_CHECKDEPOSIT_TRANSACTION.CCT_RESPONSE_DESC%type;
   V_FEE_NARRATION      CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%type;
    V_RVSL_TRANDATE    date;

    V_ACTUAL_FEECODE          TRANSACTIONLOG.FEECODE%type;
    v_orgnl_tranfee_amt          TRANSACTIONLOG.tranfee_amt%type;
    v_orgnl_servicetax_amt       TRANSACTIONLOG.servicetax_amt%type;
    v_orgnl_cess_amt             TRANSACTIONLOG.cess_amt%type;
    V_ORGNL_TRANFEE_CR_ACCTNO    TRANSACTIONLOG.tranfee_cr_acctno%type;
    V_ORGNL_TRANFEE_DR_ACCTNO    TRANSACTIONLOG.tranfee_dr_acctno%type;
    V_ORGNL_ST_CALC_FLAG         TRANSACTIONLOG.tran_st_calc_flag%type;
    V_ORGNL_CESS_CALC_FLAG       TRANSACTIONLOG.tran_cess_calc_flag%type;
    V_ORGNL_ST_CR_ACCTNO         TRANSACTIONLOG.tran_st_cr_acctno%type;
    V_ORGNL_ST_DR_ACCTNO         TRANSACTIONLOG.tran_st_dr_acctno%type;
    V_ORGNL_CESS_CR_ACCTNO       TRANSACTIONLOG.tran_cess_cr_acctno%type;
    V_ORGNL_CESS_DR_ACCTNO       TRANSACTIONLOG.TRAN_CESS_DR_ACCTNO%type;
    V_CURR_CODE                  TRANSACTIONLOG.CURRENCYCODE%type;
    v_add_ins_date               TRANSACTIONLOG.add_ins_date%TYPE;
    V_concurrent_flag             number;
    l_reason_code_desc     vms_reason_mast.VRM_REASON_DESC%TYPE;
    v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
   /**********************************************************************************************
        * Created Date      : 22-Jan-2016
        * Created By        : Ramesh
        * PURPOSE           : RDC
        * Review            : Saravana
        * Build Number      : 3.3.1

        * Modified by          : Spankaj
        * Modified Date        : 21-Nov-2016
        * Modified For         :FSS-4762:VMS OTC Support for Instant Payroll Card
        * Reviewer             : Saravanakumar
        * Build Number         : VMSGPRHOSTCSD4.11

        * Modified By      : John Gingrich
        * Modified Date    : 08-28-2023
        * Purpose          : Concurrent Pre-Auth Reversals
        * Reviewer         : 
        * Release Number   : VMSGPRHOSTR85 for VMS-5551

/**********************************************************************************************/
BEGIN
   v_resp_cde := '1';
   v_time_stamp := SYSTIMESTAMP;

   begin
     -- SAVEPOINT v_auth_savepoint;
      v_tran_amt := NVL (ROUND (P_TRAN_AMOUNT, 2), 0);

      --Sn Get the HashPan
      BEGIN
         v_hash_pan := gethash (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
               'Error while converting hash pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get the HashPan

      --Sn Create encr pan
      BEGIN
         v_encr_pan := fn_emaps_main (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while converting emcrypted pan '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --Start Generate HashKEY value
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
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while Generating  hashkey id data '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --End Generate HashKEY

     BEGIN
     V_RVSL_TRANDATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
                        SUBSTR(TRIM(P_TRAN_TIME), 1, 10),
                         'yyyymmdd hh24:mi:ss');

    EXCEPTION
     WHEN OTHERS THEN
       v_resp_cde := '21';
       v_err_msg  := 'Problem while converting V_RVSL_TRANDATE date ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    end;

      --Sn find debit and credit flag
      BEGIN
         SELECT ctm_credit_debit_flag,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                ctm_preauth_flag, ctm_login_txn
           INTO v_dr_cr_flag,
                v_txn_type,
                v_tran_type, v_trans_desc, v_prfl_flag,
                v_preauth_flag, v_login_txn
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while selecting transaction details '|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En find debit and credit flag

      --Sn Get the card details
      BEGIN
         SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                cap_prfl_code, cap_expry_date, cap_proxy_number,
                cap_cust_code
           INTO v_card_stat, v_prod_code, v_card_type, v_acct_number,
                v_prfl_code, v_expry_date, v_proxy_number,
                v_cust_code
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting card detail'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --End Get the card details

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_bal, v_ledger_bal, v_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Problem while selecting Account  detail '|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      v_pre_acct_bal := v_acct_bal;


      BEGIN
      SELECT '-'||VPM_PARTNER_NAME INTO V_PARTNER_NAME
      from VMS_PARTNER_MAST
      WHERE VPM_PARTNER_ID=P_PARTNER_ID;

      EXCEPTION
       when NO_DATA_FOUND then
           V_PARTNER_NAME :='';
       WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERR_MSG :='Problem while selecting partner mast' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
      END;

      V_TRANS_DESC := V_TRANS_DESC || V_PARTNER_NAME;
       if length(V_TRANS_DESC)>50 then
      V_TRANS_DESC := substr(V_TRANS_DESC,1,50);
      end if;

      BEGIN

      select CCT_TXN_FLAG,CCT_RRN,CCT_ACT_DATE,CCT_ACT_TIME,CCT_RESPONSE_CODE,CCT_TXN_AMNT
      into V_TXN_FLAG,V_RRN ,V_ACT_DATE,V_ACT_TIME,V_RESPONSE_CODE,V_ORG_TRAN_AMT
      from CMS_CHECKDEPOSIT_TRANSACTION
      WHERE CCT_DELV_CHNL = P_DELIVERY_CHANNEL
      and CCT_PARTNER_ID=P_PARTNER_ID
      and CCT_DEPOSIT_ID = P_DEPOSIT_ID
      AND CCT_INST_CODE = P_INST_CODE;

      if V_TXN_FLAG ='3' then   --reversal already done
         V_RESP_CDE := '254';
         V_ERR_MSG :='Original already reversed';
         RAISE EXP_REJECT_RECORD;
       END IF;

       if V_TXN_FLAG ='1' and V_RESPONSE_CODE != '00' then --original trasnaction was declined
         V_RESP_CDE := '253';
         V_ERR_MSG :='Original cannot be reversed';
         RAISE EXP_REJECT_RECORD;
       END IF;


     if v_tran_amt > V_ORG_TRAN_AMT then
       V_RESP_CDE := '37';
       V_ERR_MSG   := 'Reversal amount exceeds the original transaction amount';
       RAISE EXP_REJECT_RECORD;
     END IF;


       EXCEPTION
       when NO_DATA_FOUND then
         V_RESP_CDE := '255';
         V_ERR_MSG :='Original not found';
        RAISE EXP_REJECT_RECORD;
       when EXP_REJECT_RECORD then
         RAISE;
       WHEN OTHERS THEN
            v_resp_cde := '21';
            v_err_msg :='Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      end;

      --Sn generate auth id
      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';                            -- Server Declined
            RAISE exp_reject_record;
      END;

      --En generate auth id
      --Sn Added for Concurrent Transaction check--Sn
      BEGIN
        sp_autonomous_preauth_log(V_AUTH_ID,P_DEPOSIT_ID||'~'||p_partner_id, P_TRAN_DATE, v_hash_pan, p_inst_code, p_delivery_channel , v_err_msg);
       --Added VMS-5551
       IF v_err_msg != 'OK' THEN
       V_RESP_CDE     := '191';
       RAISE exp_reject_record;
       END IF;
      EXCEPTION
      WHEN exp_reject_record THEN
        RAISE;
      WHEN OTHERS THEN
        v_resp_cde := '12';
        v_err_msg  := 'Concurrent check Failed' || SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;
      END;

        --En Added for Concurrent Transaction check--En

      BEGIN
      SELECT feecode,tranfee_amt,servicetax_amt,cess_amt,
             TRANFEE_CR_ACCTNO,TRANFEE_DR_ACCTNO,TRAN_ST_CALC_FLAG, TRAN_CESS_CALC_FLAG,
             tran_st_cr_acctno, tran_st_dr_acctno,tran_cess_cr_acctno, tran_cess_dr_acctno, currencycode,add_ins_date
        INTO V_ACTUAL_FEECODE,v_orgnl_tranfee_amt,v_orgnl_servicetax_amt,v_orgnl_cess_amt,
             v_orgnl_tranfee_cr_acctno, v_orgnl_tranfee_dr_acctno,v_orgnl_st_calc_flag, v_orgnl_cess_calc_flag,
             v_orgnl_st_cr_acctno, v_orgnl_st_dr_acctno, v_orgnl_cess_cr_acctno, v_orgnl_cess_dr_acctno, v_curr_code,v_add_ins_date
        FROM VMSCMS.TRANSACTIONLOG																								--Added foR VMS-5739/FSP-991
       WHERE rrn = V_RRN
         AND business_date = V_ACT_DATE
         AND business_time = V_ACT_TIME
         AND customer_card_no = v_hash_pan
         AND delivery_channel = P_DELIVERY_CHANNEL
         AND instcode = p_inst_code
         AND response_code = '00';
		 IF SQL%ROWCOUNT = 0 THEN
		 SELECT feecode,tranfee_amt,servicetax_amt,cess_amt,
             TRANFEE_CR_ACCTNO,TRANFEE_DR_ACCTNO,TRAN_ST_CALC_FLAG, TRAN_CESS_CALC_FLAG,
             tran_st_cr_acctno, tran_st_dr_acctno,tran_cess_cr_acctno, tran_cess_dr_acctno, currencycode,add_ins_date
        INTO V_ACTUAL_FEECODE,v_orgnl_tranfee_amt,v_orgnl_servicetax_amt,v_orgnl_cess_amt,
             v_orgnl_tranfee_cr_acctno, v_orgnl_tranfee_dr_acctno,v_orgnl_st_calc_flag, v_orgnl_cess_calc_flag,
             v_orgnl_st_cr_acctno, v_orgnl_st_dr_acctno, v_orgnl_cess_cr_acctno, v_orgnl_cess_dr_acctno, v_curr_code,v_add_ins_date
        FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST																								--Added foR VMS-5739/FSP-991
       WHERE rrn = V_RRN
         AND business_date = V_ACT_DATE
         AND business_time = V_ACT_TIME
         AND customer_card_no = v_hash_pan
         AND delivery_channel = P_DELIVERY_CHANNEL
         AND instcode = p_inst_code
         AND response_code = '00';
		 END IF;

   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '53';
         v_err_msg := 'Matching transaction not found';
         RAISE exp_reject_record;
      WHEN TOO_MANY_ROWS
      THEN
         v_resp_cde := '21';
         v_err_msg := 'More than one matching record found in the master';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         V_RESP_CDE := '21';
         v_err_msg :='Error while selecting reversal master data' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   end;

      BEGIN
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(V_ACT_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
       select CSL_TRANS_NARRRATION
        INTO V_FEE_NARRATION
        FROM VMSCMS.CMS_STATEMENTS_LOG													--Added for VMS-5739/FSP-991
        where CSL_BUSINESS_DATE = V_ACT_DATE and
            CSL_BUSINESS_TIME = v_act_time AND
            CSL_RRN = V_RRN and
            CSL_DELIVERY_CHANNEL = p_delivery_channel AND
            CSL_TXN_CODE = P_TXN_CODE and
            CSL_PAN_NO = v_hash_pan AND
            CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'Y';
		ELSE
		select CSL_TRANS_NARRRATION
        INTO V_FEE_NARRATION
        FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST													--Added for VMS-5739/FSP-991
        where CSL_BUSINESS_DATE = V_ACT_DATE and
            CSL_BUSINESS_TIME = v_act_time AND
            CSL_RRN = V_RRN and
            CSL_DELIVERY_CHANNEL = p_delivery_channel AND
            CSL_TXN_CODE = P_TXN_CODE and
            CSL_PAN_NO = v_hash_pan AND
            CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'Y';

END IF;		

     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_FEE_NARRATION := null;
       WHEN OTHERS THEN
        V_FEE_NARRATION := NULL;
     end;

       BEGIN
        SP_REVERSE_FEE_AMOUNT(P_INST_CODE,
                          P_RRN,
                          P_DELIVERY_CHANNEL,
                          null,
                          null,
                          P_TXN_CODE,
                          V_RVSL_TRANDATE,
                          NULL,
                         V_ORGNL_TRANFEE_AMT, -- Modified for FWR-11
                          P_PAN_CODE,
                          V_ACTUAL_FEECODE,
                          --C1.CSL_TRANS_AMOUNT,
                          V_ORGNL_TRANFEE_AMT, -- Modified for FWR-11
                          V_ORGNL_TRANFEE_CR_ACCTNO,
                          V_ORGNL_TRANFEE_DR_ACCTNO,
                          V_ORGNL_ST_CALC_FLAG,
                          V_ORGNL_SERVICETAX_AMT,
                          V_ORGNL_ST_CR_ACCTNO,
                          V_ORGNL_ST_DR_ACCTNO,
                          V_ORGNL_CESS_CALC_FLAG,
                          V_ORGNL_CESS_AMT,
                          V_ORGNL_CESS_CR_ACCTNO,
                          V_ORGNL_CESS_DR_ACCTNO,
                          V_RRN,
                         -- V_CARD_ACCT_NO,--Commneted on 20/09/2013 for defect id :12309
                           v_acct_number,--Added for v_acct_number is already used and defect id :12309 on 20/09/2013
                          P_TRAN_DATE,
                          P_TRAN_TIME,
                          V_AUTH_ID,
                          V_FEE_NARRATION,
                          NULL, --MERCHANT_NAME
                          NULL, --MERCHANT_CITY
                          NULL, --MERCHANT_STATE
                          V_RESP_CDE,
                          V_ERR_MSG);

        IF V_RESP_CDE <> '00' OR V_ERR_MSG <> 'OK' THEN
          RAISE exp_reject_record;
        END IF;

       EXCEPTION
        WHEN exp_reject_record THEN
          RAISE;

        WHEN OTHERS THEN
          V_RESP_CDE := '21';
          V_ERR_MSG   := 'Error while reversing the fee amount ' ||
                     SUBSTR(SQLERRM, 1, 200);
          RAISE exp_reject_record;
       end;

      BEGIN
	  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(V_ACT_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN

        SELECT CSL_TRANS_NARRRATION
         INTO V_TXN_NARRATION
         FROM VMSCMS.CMS_STATEMENTS_LOG													--Added for VMS-5739/FSP-991
        where CSL_BUSINESS_DATE = V_ACT_DATE and
             CSL_BUSINESS_TIME = V_ACT_TIME AND
             CSL_RRN = V_RRN AND
             CSL_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
             CSL_TXN_CODE = P_TXN_CODE AND
             CSL_PAN_NO = v_hash_pan and
             CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'N';
	ELSE
	SELECT CSL_TRANS_NARRRATION
         INTO V_TXN_NARRATION
         FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST												--Added for VMS-5739/FSP-991
        where CSL_BUSINESS_DATE = V_ACT_DATE and
             CSL_BUSINESS_TIME = V_ACT_TIME AND
             CSL_RRN = V_RRN AND
             CSL_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
             CSL_TXN_CODE = P_TXN_CODE AND
             CSL_PAN_NO = v_hash_pan and
             CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'N';
END IF;	

      EXCEPTION
        WHEN OTHERS THEN
          V_RESP_CDE := '21';
            V_ERR_MSG :='Problem while selecting V_TXN_NARRATION ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;


      BEGIN
             UPDATE CMS_ACCT_MAST
             SET CAM_ACCT_BAL  = CAM_ACCT_BAL-v_tran_amt,
                 CAM_LEDGER_BAL =  CAM_LEDGER_BAL-v_tran_amt
                 WHERE CAM_INST_CODE = P_INST_CODE AND CAM_ACCT_NO = v_acct_number;

            IF SQL%ROWCOUNT = 0 THEN
             V_RESP_CDE := '21';
             V_ERR_MSG  := 'Account is not updated for reversal ' ;
             RAISE exp_reject_record;
            END IF;

        EXCEPTION
           when exp_reject_record then
           raise;
         WHEN OTHERS THEN
               V_RESP_CDE := '21';
               V_ERR_MSG  := 'Error while updating CMS_ACCT_MAST ' ||
                            SUBSTR(SQLERRM, 1, 250);
               RAISE exp_reject_record;
     END;

       BEGIN
          INSERT INTO cms_statements_log
                      (csl_pan_no, csl_opening_bal,
                       csl_trans_amount,
                       csl_trans_type, csl_trans_date,
                       csl_closing_balance,
                       csl_trans_narrration, csl_inst_code,
                       csl_pan_no_encr, csl_rrn, csl_auth_id,
                       CSL_BUSINESS_DATE, CSL_BUSINESS_TIME, TXN_FEE_FLAG,
                       csl_delivery_channel, csl_txn_code, csl_acct_no,
                       csl_ins_user, csl_ins_date,
                       csl_panno_last4digit,
                       csl_prod_code,csl_card_type, csl_acct_type,
                       csl_time_stamp
                      )
          VALUES      (v_hash_pan, v_ledger_bal,NVL (v_tran_amt, 0),'DR', sysdate,
                       v_ledger_bal - v_tran_amt,
                       'RVSL-' || V_TXN_NARRATION, P_INST_CODE,
                       v_encr_pan, p_rrn, V_auth_id,p_tran_date, p_tran_time, 'N',
                       P_DELIVERY_CHANNEL, P_TXN_CODE, V_ACCT_NUMBER,
                       1, SYSDATE,
                       (SUBSTR (p_pan_code,length (p_pan_code) - 3,length (p_pan_code))),
                       v_prod_code,v_card_type, v_acct_type,v_time_stamp
                      );
       EXCEPTION
          WHEN OTHERS THEN
             v_resp_cde := '21';
             V_ERR_MSG := 'Error while inserting into CMS_STATEMENTS_LOG 1.0-'|| SUBSTR (SQLERRM, 1, 200);
             RAISE exp_reject_record;
       END;

      BEGIN
         UPDATE cms_checkdeposit_transaction
            SET cct_txn_flag = '3',
                cct_txn_amnt = v_tran_amt
          WHERE cct_inst_code = p_inst_code
            and CCT_DELV_CHNL = P_DELIVERY_CHANNEL
            and CCT_PARTNER_ID = P_PARTNER_ID
            and CCT_DEPOSIT_ID = P_DEPOSIT_ID
            and CCT_RRN=V_RRN;

        if sql%ROWCOUNT = 0 then
           v_err_msg   := 'Error while Updating Check Deposit Transaction Reversal';
           v_resp_cde := '21';
           RAISE exp_reject_record;
         END IF;
          EXCEPTION
       WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Problem while updating the records into cms_checkdeposit_transaction table'
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '89';
            RAISE EXP_REJECT_RECORD;
      END;

      IF v_orgnl_tranfee_amt=0 AND v_actual_feecode IS NOT NULL THEN
        BEGIN
           vmsfee.fee_freecnt_reverse (v_acct_number, v_actual_feecode, v_err_msg);

           IF v_err_msg <> 'OK' THEN
              v_resp_cde := '21';
              RAISE exp_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_reject_record THEN
              RAISE;
           WHEN OTHERS THEN
              v_resp_cde := '21';
              v_err_msg :='Error while reversing freefee count-'|| SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;
      END IF;

      IF v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y'
         THEN
            BEGIN

               pkg_limits_check.sp_limitcnt_rever_reset (p_inst_code,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         P_TXN_CODE,
                                                         v_tran_type,
                                                         NULL,
                                                         NULL,
                                                         V_PRFL_CODE,
                                                         v_tran_amt,
                                                         v_tran_amt,
                                                         P_DELIVERY_CHANNEL,
                                                         v_hash_pan,
                                                         v_add_ins_date,
                                                         v_resp_cde,
                                                         v_err_msg
                                                        );

               IF v_err_msg <> 'OK'
               then
                  v_resp_cde :='21';
                  v_err_msg := 'From Procedure sp_limitcnt_reset' || v_err_msg;
                  RAISE EXP_REJECT_RECORD;
               END IF;
            EXCEPTION
               WHEN EXP_REJECT_RECORD
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Error from Limit Reset Count Process '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE EXP_REJECT_RECORD;
            end;
         END IF;

      V_RESP_CDE := 1;
      v_err_msg := 'SUCCESS';

   EXCEPTION
      WHEN exp_reject_record
      then
         ROLLBACK;-- TO v_auth_savepoint;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         V_ERR_MSG := ' Exception ' || V_ERR_MSG;
         ROLLBACK;-- TO v_auth_savepoint;
   END;

   --Sn Get responce code fomr master
   BEGIN
       select CMS_ISO_RESPCDE,CMS_RESP_DESC
        INTO p_resp_code,V_RESPONSE_DESC
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code
         AND cms_delivery_channel = p_delivery_channel
         AND cms_response_id = v_resp_cde;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Problem while selecting data from response master '
            || v_resp_cde
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '89';
   END;

   --En Get responce code fomr master
   IF v_prod_code IS NULL
   THEN
      BEGIN
         SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
           INTO v_card_stat, v_prod_code, v_card_type, v_acct_number
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code
            AND cap_pan_code = gethash (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END IF;


   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO v_acct_bal, v_ledger_bal, v_acct_type
        FROM cms_acct_mast
       WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_acct_bal := 0;
         v_ledger_bal := 0;
   END;

   IF v_dr_cr_flag IS NULL
   THEN
      BEGIN
         SELECT ctm_credit_debit_flag,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_tran_desc, ctm_prfl_flag, ctm_preauth_flag
           INTO v_dr_cr_flag,
                v_txn_type,
                v_tran_type, v_trans_desc, v_prfl_flag, v_preauth_flag
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

   --Sn Inserting data in transactionlog
   BEGIN
      sp_log_txnlog (p_inst_code,
                     p_msg_type,
                     p_rrn,
                     p_delivery_channel,
                     p_txn_code,
                     v_tran_type,
                     p_txn_mode,
                     p_tran_date,
                     p_tran_time,
                     p_rvsl_code,
                     v_hash_pan,
                     v_encr_pan,
                     v_err_msg,
                     NULL,
                     v_card_stat,
                     v_trans_desc,
                     NULL,
                     NULL,
                     v_time_stamp,
                     v_acct_number,
                     v_prod_code,
                     V_CARD_TYPE,
                     'DR',
                     v_acct_bal,
                     v_ledger_bal,
                     v_acct_type,
                     v_proxy_number,
                     v_auth_id,
                     v_tran_amt,
                     v_total_amt,
                     NULL,
                     v_tranfee_amt,
                     NULL,
                     NULL,
                     v_resp_cde,
                     p_resp_code,
                     P_CURR_CODE,
                     V_ERR_MSG,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      P_PARTNER_ID
                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '89';
         v_err_msg :=
               'Exception while inserting to transaction log '
            || SQLCODE
            || '---'
            || SQLERRM;
   END;

   --En Inserting data in transactionlog

   --Sn Inserting data in transactionlog dtl
   BEGIN
      l_reason_code_desc := get_reason_code_desc(p_reason_code_in);
      sp_log_txnlogdetl (p_inst_code,
                         p_msg_type,
                         p_rrn,
                         p_delivery_channel,
                         p_txn_code,
                         v_txn_type,
                         p_txn_mode,
                         p_tran_date,
                         p_tran_time,
                         v_hash_pan,
                         v_encr_pan,
                         v_err_msg,
                         v_acct_number,
                         v_auth_id,
                         v_tran_amt,
                         p_mobil_no,
                         p_device_id,
                         v_hashkey_id,
                         p_check_no,
                         P_USER_CHECKDESC,
                         null,
                         p_chcek_acctno,
                         p_resp_code,
                         p_deposit_id,
                         p_reason_code_in,
                         l_reason_code_desc,
                         v_logdtl_resp
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '89';
   END;

   Begin
      sp_autonomous_preauth_logclear(v_auth_id);
  exception
      When others then
        NULL;
  End;

--Sn Inserting data in transactionlog dtl
   --Assign output variable
   p_prev_balance := v_pre_acct_bal;
   p_acct_bal := v_acct_bal;
   P_RESMSG := V_RESPONSE_DESC;
   p_email_id := v_email_id;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_resp_code := '89';                                 -- Server Declined
      p_resmsg :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END sp_mob_check_deposit_rvsl;

   /************************************************************************************************************
   * Created Date     :  Sep 23, 2021
   * Created By       :  rdevkota
   * Created For      :  VMS 5099
   * Reviewer         :  Ubaidur
   * Validates the reason code and returns desc so that it can be logged later
   */

   FUNCTION get_reason_code_desc(p_reason_code_in VARCHAR2) RETURN VARCHAR2
   IS
      l_reason_code_desc vms_reason_mast.VRM_REASON_DESC%TYPE := NULL;
   BEGIN
      IF p_reason_code_in IS NOT NULL AND LENGTH(TRIM(p_reason_code_in)) > 0
      THEN
         SELECT vrm_reason_desc
           INTO l_reason_code_desc
           FROM vms_reason_mast
          WHERE UPPER(vrm_reason_code) = UPPER(TRIM(p_reason_code_in)) 
            AND ROWNUM = 1;
      END IF;
      RETURN l_reason_code_desc;
   EXCEPTION 
      WHEN NO_DATA_FOUND
      THEN
         RETURN 'Reason Code Not Found In The System';
      WHEN OTHERS
      THEN
         -- reason message is limited to 100 char
         RETURN SUBSTR('Reason Code Query Exception: ' || SQLCODE || ' ' || SQLERRM, 1, 100) ;
   END get_reason_code_desc;
end;

/
show error;