create or replace PROCEDURE         vmscms.sp_mob_check_depositaccepted (
   p_inst_code          IN       VARCHAR2,
   p_msg_type           IN       VARCHAR2,
   p_rrn                IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_txn_mode           IN       VARCHAR2,
   p_tran_date          IN       VARCHAR2,
   p_tran_time          IN       VARCHAR2,
   p_pan_code           IN       VARCHAR2, 
   p_mbr_numb           IN       VARCHAR2,
   p_rvsl_code          IN       VARCHAR2,
   p_customerid         IN       VARCHAR2,
   p_curr_code          IN       VARCHAR2,
   p_tran_amount        IN       VARCHAR2,
   p_mobil_no           IN       VARCHAR2,
   p_device_id          IN       VARCHAR2,
   p_chcek_acctno       IN       VARCHAR2,
   p_routing_no         IN       VARCHAR2,
   p_check_no           IN       VARCHAR2,
   p_deposit_id         IN       VARCHAR2,
   p_resp_code          OUT      VARCHAR2,
   p_resmsg             OUT      VARCHAR2,
   p_acct_bal           OUT      VARCHAR2,
   p_prev_balance       OUT      VARCHAR2,
   p_match_rule         OUT      NUMBER,
   p_image_front        OUT      BLOB,
   p_image_back         OUT      BLOB,
   p_check_name         OUT      VARCHAR2,
   p_email_id           OUT      VARCHAR2
)
AS
   /*************************************************
   * Created by       : Raja Gopal G
   * modified Date    : 01-Aug-14
   * Modified Reason  : Created this procedure for check deposit accepted Transaction.
   * Reviewer         : SpankajDuplicate SPIL handling
   * Release Number   : RI0027.3.1_B0002

   * Modified by      : Raja Gopal G
   * modified Date    : 13-Aug-14
   * Modified Reason  : For the Internal Defect ID 15669 & also Handled the Exception Properly
   * Reviewer         : Spankaj
   * Release Number   : RI0027.3.1_B0003

    * Modified by     : Raja Gopal G
   * modified Date    : 20-Aug-14
   * Modified Reason  : For the Internal Defect ID 15689
   * Reviewer         : Spankaj
   * Release Number   : RI0027.3.1_B0005

     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01
	 
	  * Modified by                 : DHINAKARAN B
  * Modified Date               : 26-NOV-2019
  * Modified For                : VMS-1415
  * Reviewer                    :  Saravana Kumar A
  * Build Number                :  VMSGPRHOST_R23_B1 
   /*************************************************/
   v_auth_savepoint    NUMBER                                       DEFAULT 0;
   v_count             NUMBER;
   v_err_msg           VARCHAR2 (500);
   v_hash_pan          cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan          cms_appl_pan.cap_pan_code_encr%TYPE;
   v_cust_code         cms_pan_acct.cpa_cust_code%TYPE;
   v_txn_type          transactionlog.txn_type%TYPE;
   v_auth_id           transactionlog.auth_id%TYPE;
   exp_reject_record   EXCEPTION;
   v_dr_cr_flag        VARCHAR2 (2);
   v_tran_type         VARCHAR2 (2);
  -- v_tran_amt          NUMBER (9, 3);
   v_prod_code         cms_appl_pan.cap_prod_code%TYPE;
   v_card_type         cms_appl_pan.cap_card_type%TYPE;
   v_resp_cde          VARCHAR2 (5);
   v_time_stamp        TIMESTAMP;
   v_hashkey_id        cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   v_trans_desc        cms_transaction_mast.ctm_tran_desc%TYPE;
   v_prfl_flag         cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_acct_number       cms_appl_pan.cap_acct_no%TYPE;
   v_prfl_code         cms_appl_pan.cap_prfl_code%TYPE;
   v_card_stat         cms_appl_pan.cap_card_stat%TYPE;
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
   v_pre_acct_bal      cms_acct_mast.cam_acct_bal%TYPE;
   v_cap_cust_code     cms_appl_pan.cap_cust_code%TYPE;
   v_email_id          cms_cust_mast.ccm_email_one%TYPE;
   v_cust_id           cms_cust_mast.ccm_cust_id%TYPE;
   v_accepted_mode     NUMBER;
   p_txn_flag          NUMBER;
   v_login_txn         cms_transaction_mast.ctm_login_txn%TYPE;
   v_limit_mode_val    VARCHAR2 (1)                                  := 'N';
   v_tran_amt         transactionlog.total_amount%TYPE;
   v_logdtl_resp       VARCHAR2 (500);
   v_encrypt_enable  CMS_PROD_CATTYPE.cpc_encrypt_enable%TYPE;
      v_compl_fee varchar2(10);
   v_compl_feetxn_excd varchar2(10);
   v_compl_feecode varchar2(10);
BEGIN
   v_resp_cde := '1';
   v_time_stamp := SYSTIMESTAMP;
   v_tran_amt:=  nvl(ROUND(p_tran_amount ,2),'0.00');

   BEGIN
      SAVEPOINT v_auth_savepoint;

      --Sn Get the HashPan
      BEGIN
         v_hash_pan := gethash (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                    'Error while converting Hash pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get the HashPan
      --Sn Create encr pan
      BEGIN
         v_encr_pan := fn_emaps_main (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                    'Error while converting Encrypted pan ' || SUBSTR (SQLERRM, 1, 200);
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
                  'Error while converting hashkey id data '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

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
            v_err_msg := 'Error while selecting transaction details'|| SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;

      --EN Check For Duplicate Transaction
        --Sn Get the card details
      BEGIN
         SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                cap_prfl_code, cap_expry_date, cap_cust_code
           INTO v_card_stat, v_prod_code, v_card_type, v_acct_number,
                v_prfl_code, v_expry_date, v_cap_cust_code
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg := 'Card number not found ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Problem while selecting card detail'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --End Get the card details

     BEGIN
      SELECT upper(cpc_encrypt_enable)
        INTO v_encrypt_enable
        FROM cms_prod_cattype
       WHERE cpc_inst_code = p_inst_code
         AND cpc_prod_code = v_prod_code and cpc_card_type = v_card_type;

   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
               'Error while selecting the encrypt enable flag '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

      --End finding the original transactions
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

         IF v_err_msg <> 'OK'
         THEN
            IF INSTR (v_err_msg, 'MATCHRULEFAILED') != 0
            THEN
               v_limit_mode_val:= 'Y';
               v_err_msg:= 'OK';
             ELSE
              RAISE exp_reject_record;
            END IF;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error from auth procedure  '
               || SUBSTR (SQLERRM, 1, 200)
               || v_resp_cde
               || v_err_msg;
            RAISE exp_reject_record;
      END;

      --START finding the original transactions
      BEGIN
         v_accepted_mode := 0;

         SELECT cct_check_imagefs, cct_check_imagebs, cct_check_desc, --For the Internal Defect ID 15689
                cct_txn_flag
           INTO p_image_front, p_image_back, p_check_name,
                p_txn_flag
           FROM cms_checkdeposit_transaction
          WHERE cct_delv_chnl = p_delivery_channel
            AND cct_rrn = p_rrn
            AND cct_inst_code = p_inst_code;

         IF p_txn_flag IN ('1', '2')
         THEN
            v_err_msg :=
                  'Check Deposited Accepted/Rejected Already Done for this RRN:'
               || p_rrn;
            v_resp_cde := '211';
            RAISE exp_reject_record;
         END IF;

         IF v_accepted_mode = 0 AND v_limit_mode_val = 'Y'
         THEN
            v_accepted_mode:= 3;
         END IF;
      EXCEPTION
      WHEN  exp_reject_record THEN
        RAISE;
      WHEN TOO_MANY_ROWS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Too Many Records found for this RRN:' || p_rrn;
            RAISE exp_reject_record;
      WHEN NO_DATA_FOUND
         THEN
            BEGIN
               v_accepted_mode := 1;

               SELECT cct_check_imagefs, cct_check_imagebs, cct_check_desc,--For the Internal Defect ID 15689
                      cct_txn_flag
                 INTO p_image_front, p_image_back, p_check_name,
                      p_txn_flag
                 FROM cms_checkdeposit_transaction
                WHERE cct_delv_chnl = p_delivery_channel
                  AND cct_deposit_id = p_deposit_id
                  AND cct_inst_code = p_inst_code;

               IF p_txn_flag IN ('1', '2')
               THEN
                  v_err_msg :=
                        'Check Deposit Already Accepted/Rejected for this deposit ID:'
                     || p_deposit_id;
                  v_resp_cde := '211';
                  RAISE exp_reject_record;
               END IF;

               IF v_accepted_mode = 1 AND v_limit_mode_val = 'Y'
               THEN
                  v_accepted_mode:= 4;
               END IF;
            EXCEPTION
            WHEN  exp_reject_record THEN
              RAISE;
            WHEN TOO_MANY_ROWS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Too Many Records found for this Deposit ID:'
                     || p_deposit_id;
                  RAISE ;
            WHEN NO_DATA_FOUND
               THEN
                  v_accepted_mode := 2;

                  IF v_accepted_mode = 2 AND v_limit_mode_val = 'Y'
                  THEN
                     v_accepted_mode:= 5;
                  END IF;

                  p_check_name := NULL;
                  p_image_front := NULL;
                  p_image_back := NULL;

                  BEGIN
                     INSERT INTO cms_checkdeposit_transaction
                                 (cct_inst_code, cct_card_no,
                                  cct_card_no_encr, cct_acct_no,
                                  cct_cust_id, cct_delv_chnl,
                                  cct_check_imagefs, cct_check_imagebs,
                                  cct_txn_amnt, cct_rrn, cct_check_no,
                                  cct_routing_no, cct_deposit_id,
                                  cct_check_desc, cct_ins_date,
                                  cct_pend_amt, cct_act_date, cct_txn_flag,
                                  cct_act_time, cct_time_stamp,
                                  cct_pend_date, cct_pend_time,
                                  cct_match_rule
                                 )
                          VALUES (p_inst_code, v_hash_pan,
                                  v_encr_pan, p_chcek_acctno,
                                  p_customerid, p_delivery_channel,
                                  NULL, NULL,
                                  v_tran_amt, p_rrn, p_check_no,
                                  p_routing_no, p_deposit_id,
                                  NULL, SYSDATE,
                                  NULL, p_tran_date, 1,
                                  p_tran_time, v_time_stamp,
                                  NULL, NULL,
                                  v_accepted_mode
                                 );

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_err_msg :=
                              'Records not inserted into Deposit Table';
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                  WHEN  exp_reject_record THEN
                    RAISE;
                  WHEN OTHERS
                     THEN
                        v_resp_cde := '21';
                        v_err_msg :=
                              'Error while inserting data into Deposit table'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;


            when  others then

                 v_resp_cde := '21';
                 v_err_msg :='Error while selecting the depsoit ID Qry'|| SUBSTR (SQLERRM, 1, 200);
                  raise exp_reject_record;

            END;

      when others then
        v_resp_cde := '21';
        v_err_msg :='Error while Selecting the RRN Qry'|| SUBSTR (SQLERRM, 1, 200);
         raise exp_reject_record;


      END;

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

      v_pre_acct_bal := v_acct_bal;

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
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
           -- DBMS_OUTPUT.put_line ('P_RESMSG = ' || v_err_msg);
            v_err_msg :=
                  'Error from sp_fee_calc '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      v_resp_cde := 1;

      BEGIN
         SELECT decode(v_encrypt_enable,'Y',fn_dmaps_main(cam_email),cam_email)
           INTO v_email_id
           FROM cms_addr_mast
          WHERE cam_inst_code = p_inst_code
            AND cam_cust_code = v_cap_cust_code
            AND cam_addr_flag = 'P';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '89';
            v_err_msg := 'Email Id not found ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            v_err_msg :=
                  'Problem while selecting Email Id '|| SUBSTR (SQLERRM, 1, 300);
                  raise;
      END;

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
      END IF;

        --Sn updating the records in deposit table
   IF v_accepted_mode not in('2','5')
   THEN
      BEGIN
         UPDATE cms_checkdeposit_transaction
            SET cct_deposit_id = p_deposit_id,
                cct_txn_flag = '1',
                cct_match_rule = v_accepted_mode,
                cct_act_time = p_tran_time,
                cct_act_date = p_tran_date,
                cct_txn_amnt = v_tran_amt,
                cct_time_stamp = v_time_stamp,
                cct_acct_no = p_chcek_acctno
          WHERE cct_inst_code = p_inst_code
            AND cct_delv_chnl = p_delivery_channel
            AND 1 =
                   (CASE
                       WHEN v_accepted_mode IN ('0','3') AND cct_rrn = p_rrn
                          THEN 1
                       WHEN v_accepted_mode IN ('1','4')
                       AND cct_deposit_id = p_deposit_id
                          THEN 1
                       ELSE 0
                    END
                   );
        IF SQL%ROWCOUNT = 0 THEN
           v_err_msg   := 'Error while Updating Check Deposit Transaction';
           p_resp_code := '21';
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
            p_resp_code := '89';
            RAISE exp_reject_record;
      END;
   END IF;
 --ST Commented the below block for this defect ID 15669
   /*   BEGIN
         SELECT cms_iso_respcde
           INTO v_resp_cde
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_resp_cde;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '89';
            v_err_msg := 'Responce code not found ' || p_resp_code;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            p_resp_code := '89';
            v_err_msg :=
                  'Problem while selecting data from response master '
               || p_resp_code
               || SUBSTR (SQLERRM, 1, 300);


		RAISE exp_reject_record;
      END;*/
       --END Commented the below block for this defect ID 15669
       v_err_msg := 'SUCCESS';
   EXCEPTION
      WHEN exp_reject_record
      THEN
         ROLLBACK TO v_auth_savepoint;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg := 'Main Exception 1' || SQLCODE || '---' || SQLERRM;
         ROLLBACK TO v_auth_savepoint;
   END;

   --Sn Get responce code fomr master
   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code
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
                     p_curr_code,
                     v_err_msg
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
        -- RAISE exp_reject_record;
   END;

   --En Inserting data in transactionlog
   --Sn Inserting data in transactionlog dtl
   BEGIN
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
                         NULL,
                         p_routing_no,
                         p_chcek_acctno,
                         p_resp_code,
                         p_deposit_id,
                         NULL,
                         NULL,
                         v_logdtl_resp
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '89';
        -- RAISE exp_reject_record;
   END;


   --En Inserting data in transactionlog dtl


   --Sn Inserting data in Pending transaction table
   --Assign output variable
   p_acct_bal := v_acct_bal;
   p_resmsg := v_err_msg;
   p_prev_balance := v_pre_acct_bal;
   p_match_rule := v_accepted_mode;
   p_email_id := v_email_id;
EXCEPTION
   WHEN OTHERS
   THEN
      p_resp_code := '69';                                 -- Server Declined
      p_resmsg :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END;
/
show error