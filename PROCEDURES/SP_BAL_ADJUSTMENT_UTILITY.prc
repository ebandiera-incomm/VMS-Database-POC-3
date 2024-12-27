CREATE OR REPLACE PROCEDURE VMSCMS.SP_BAL_ADJUSTMENT_UTILITY (
   p_instcode           IN       NUMBER,
   p_card_no            IN       VARCHAR2,
   p_trans_type         IN       VARCHAR2,
   p_trans_amount       IN       NUMBER,
   p_trans_narration    IN       VARCHAR2,
   p_reason_code        IN       NUMBER,
   p_txn_code           IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_adj_type           IN       VARCHAR2,
   p_ins_user           IN       NUMBER,
   p_rrn                IN       VARCHAR2,
   p_errmsg             OUT      VARCHAR2,
   p_auth_id            OUT      VARCHAR2
)
AS
   /*************************************************
       * p_adj_type
         ** A -- Debit/Credit Account balance only
         ** L -- Debit/Credit Ledger balance only
         ** B -- Debit/Credit  Account and Ledger Balance only
       * p_trans_type
          ** CR - To credit
          ** DR - To Debit
          
              * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
   *************************************************/
   v_transaction        NUMBER                                  DEFAULT 0;
   v_hash_pan           cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan           cms_appl_pan.cap_pan_code_encr%TYPE;
   v_business_date      VARCHAR2 (10);
   v_business_time      VARCHAR2 (10);
   v_rrn                transactionlog.rrn%TYPE;
   v_rrn_cnt            NUMBER                                  DEFAULT 0;
   v_errmsg             VARCHAR2 (300);
   v_excep              EXCEPTION;
   v_panno              VARCHAR2 (30);
   v_delivery_channel   transactionlog.delivery_channel%TYPE;
   v_txn_type           transactionlog.txn_type%TYPE;
   v_txn_code           transactionlog.txn_code%TYPE;
   --v_txn_mode           cms_func_mast.cfm_txn_mode%TYPE         DEFAULT '0';
   v_msg                VARCHAR2 (2)                            DEFAULT '00';
   v_txn_amount         NUMBER (20, 3);
   v_upd_amt            NUMBER;
   v_upd_acct_bal       NUMBER;
   v_cap_card_stat      cms_appl_pan.cap_card_stat%TYPE;
   v_prod_code          cms_appl_pan.cap_prod_code%TYPE;
   v_card_type          cms_appl_pan.cap_card_type%TYPE;
   v_acct_number        cms_appl_pan.cap_acct_no%TYPE;
   v_func_code          cms_func_mast.cfm_func_code%TYPE;
   --v_cracct_no          cms_func_prod.cfp_cracct_no%TYPE;
   --v_dracct_no          cms_func_prod.cfp_dracct_no%TYPE;
   v_acct_type          cms_acct_type.cat_type_code%TYPE;
   v_acct_bal           cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
   v_auth_id            transactionlog.auth_id%TYPE;
   v_narration          VARCHAR2 (300);
   v_commit_pnt         NUMBER (10)                             := 0;
   v_timestamp          TIMESTAMP;
   v_batch_seq          VARCHAR2 (6);
   exp_reject_batch     EXCEPTION;
   v_reason_count       NUMBER;
   v_reasondesc         cms_spprt_reasons.csr_reasondesc%TYPE;
   v_tranamt_toacct     NUMBER (20, 3);
   v_tranamt_toldgr     NUMBER (20, 3);
BEGIN
   BEGIN
      v_errmsg := 'OK';

      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                 'Error while generating authid-' || SUBSTR (SQLERRM, 1, 100);
            RAISE v_excep;
      END;

      BEGIN
         v_hash_pan := gethash (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while converting pan hash-' || SUBSTR (SQLERRM, 1, 200);
            RAISE v_excep;
      END;

      BEGIN
         v_encr_pan := fn_emaps_main (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while converting pan encr-' || SUBSTR (SQLERRM, 1, 200);
            RAISE v_excep;
      END;

      BEGIN
         SELECT TO_CHAR (SYSDATE, 'YYYYMMDD'),
                TO_CHAR (SYSDATE, 'HH24MISS')                              --,
            --    TO_CHAR (SYSDATE, 'DDHH24MISS')
           --  || LPAD (seq_rrn_manualadj.NEXTVAL, 5, 0)
         INTO   v_business_date,
                v_business_time                                            --,
           --  v_rrn
         FROM   DUAL;

         v_rrn := p_rrn;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                'Error while selecting txn dtls-' || SUBSTR (SQLERRM, 1, 200);
            RAISE v_excep;
      END;

      IF p_adj_type NOT IN ('B', 'L', 'A')
      THEN
         v_errmsg := 'Transaction rejected for Invalid adjustment type';
         RAISE v_excep;
      END IF;

      IF p_trans_amount = 0
      THEN
         v_errmsg := 'Transaction rejected for txn amount is zero';
         RAISE v_excep;
      --ELSE
      END IF;

      v_delivery_channel := p_delivery_channel;
      --v_txn_type := decode(p_adj_type,'A','0','1');
      v_txn_code := p_txn_code;
      v_txn_amount := ROUND (p_trans_amount, 2);

      --** <Reason Code vaildation Starts>
      BEGIN
         SELECT csr_reasondesc
           INTO v_reasondesc
           FROM cms_spprt_reasons
          WHERE csr_inst_code = p_instcode
            AND csr_spprt_key = 'MANADJDRCR'
            AND csr_spprt_rsncode = p_reason_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Inavlid Reason code ';
            RAISE v_excep;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting reason code from master'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE v_excep;
      END;

      --** <Reason Code validation Endz>
      BEGIN
         SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no
           INTO v_cap_card_stat, v_prod_code, v_card_type, v_acct_number
           FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_instcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Card Not Found In CMS';
            RAISE v_excep;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting card number-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE v_excep;
      END;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_bal, v_ledger_bal, v_acct_type
           FROM cms_acct_mast
          WHERE cam_inst_code = p_instcode AND cam_acct_no = v_acct_number;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Account Not Found In CMS';
            RAISE v_excep;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while selecting acct dtls-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE v_excep;
      END;
      /*
      BEGIN
         SELECT cfm_func_code
           INTO v_func_code
           FROM cms_func_mast
          WHERE cfm_txn_code = v_txn_code
            AND cfm_txn_mode = v_txn_mode
            AND cfm_delivery_channel = v_delivery_channel
            AND cfm_inst_code = p_instcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Function code not defined for txn code '
               || v_txn_code
               || ' '
               || v_delivery_channel;
            RAISE v_excep;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting function code-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE v_excep;
      END; */
      /*
      BEGIN
         SELECT cfp_cracct_no, cfp_dracct_no
           INTO v_cracct_no, v_dracct_no
           FROM cms_func_prod
          WHERE cfp_func_code = v_func_code
            AND cfp_prod_code = v_prod_code
            AND cfp_prod_cattype = v_card_type
            AND cfp_inst_code = p_instcode;

         IF TRIM (v_cracct_no) IS NULL AND TRIM (v_dracct_no) IS NULL
         THEN
            v_errmsg :=
                  'Both credit and debit account cannot be null for a Function code '
               || v_func_code;
            RAISE v_excep;
         END IF;
      EXCEPTION
         WHEN v_excep
         THEN
            RAISE;
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Function is not attached to card';
            RAISE v_excep;
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while selecting Gl details-'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE v_excep;
      END; */

      IF p_adj_type IN ('B', 'L')
      THEN
         v_txn_type := '1';

         IF p_trans_type = 'CR'
         THEN
            v_upd_amt := v_ledger_bal + v_txn_amount;
            v_upd_acct_bal := v_acct_bal + v_txn_amount;
         ELSIF p_trans_type = 'DR'
         THEN
            v_upd_amt := v_ledger_bal - v_txn_amount;
            v_upd_acct_bal := v_acct_bal - v_txn_amount;
         END IF;

         BEGIN
            v_timestamp := SYSTIMESTAMP;

            IF p_trans_type = 'CR'
            THEN
               IF TRIM (p_trans_narration) IS NOT NULL
               THEN
                  v_narration := p_trans_narration || '/';
               END IF;

               IF TRIM (v_auth_id) IS NOT NULL
               THEN
                  v_narration := v_narration || v_auth_id || '/';
               END IF;

               IF TRIM (v_acct_number) IS NOT NULL
               THEN
                  v_narration := v_narration || v_acct_number || '/';
               END IF;

               IF TRIM (v_business_date) IS NOT NULL
               THEN
                  v_narration := v_narration || v_business_date;
               END IF;

               BEGIN
                  IF p_adj_type = 'B'
                  THEN
                     BEGIN
                        UPDATE cms_acct_mast
                           SET cam_acct_bal = cam_acct_bal + v_txn_amount,
                               cam_ledger_bal = cam_ledger_bal + v_txn_amount
                         WHERE cam_inst_code = p_instcode
                           AND cam_acct_no = v_acct_number;

                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_errmsg :=
                                'No records updated in account master for CR';
                           RAISE v_excep;
                        END IF;
                     EXCEPTION
                        WHEN v_excep
                        THEN
                           RAISE v_excep;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                'No records updated in account master for CR';
                           RAISE v_excep;
                     END;
                  ELSIF p_adj_type = 'L'
                  THEN
                     BEGIN
                        UPDATE cms_acct_mast
                           SET -- cam_acct_bal = cam_acct_bal + v_txn_amount,
                              cam_ledger_bal = cam_ledger_bal + v_txn_amount
                         WHERE cam_inst_code = p_instcode
                           AND cam_acct_no = v_acct_number;

                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_errmsg :=
                              'No records updated in account master for CR(ledger)';
                           RAISE v_excep;
                        END IF;
                     EXCEPTION
                        WHEN v_excep
                        THEN
                           RAISE v_excep;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                              'No records updated in account master for CR(ledger)';
                           RAISE v_excep;
                     END;
                  -- END;
                  END IF;
               EXCEPTION
                  WHEN v_excep
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error occurred while updating acct mast for CR(ledger)-'
                        || SUBSTR (SQLERRM, 1, 100);
                     RAISE v_excep;
               END;
                /*
               BEGIN
                  sp_ins_eodupdate_acct_cmsauth (v_rrn,
                                                 NULL,
                                                 v_delivery_channel,
                                                 v_txn_code,
                                                 v_txn_mode,
                                                 TO_DATE (v_business_date,
                                                          'yyyymmdd'
                                                         ),
                                                 p_card_no,         --v_panno,
                                                 v_dracct_no,
                                                 v_txn_amount,
                                                 'D',
                                                 p_instcode,
                                                 v_errmsg
                                                );

                  IF v_errmsg <> 'OK'
                  THEN
                     RAISE v_excep;
                  END IF;
               EXCEPTION
                  WHEN v_excep
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error occurred while debiting gl for CR-'
                        || SUBSTR (SQLERRM, 1, 100);
                     RAISE v_excep;
               END;
                   */
               BEGIN
                  INSERT INTO cms_statements_log
                              (csl_pan_no, csl_opening_bal,
                               csl_trans_amount, csl_trans_type,
                               csl_trans_date,
                               csl_closing_balance, csl_trans_narrration,
                               csl_inst_code, csl_pan_no_encr, csl_rrn,
                               csl_business_date, csl_business_time,
                               csl_delivery_channel, csl_txn_code,
                               csl_auth_id, csl_ins_date, csl_ins_user,
                               csl_acct_no,
                               csl_panno_last4digit,
                               csl_to_acctno, csl_acct_type, csl_time_stamp,
                               csl_prod_code,csl_card_type
                              )
                       VALUES (v_hash_pan, v_ledger_bal,
                               v_txn_amount, p_trans_type,
                               TO_DATE (v_business_date, 'yyyymmdd'),
                               v_upd_amt, v_narration,
                               p_instcode, v_encr_pan, v_rrn,
                               v_business_date, v_business_time,
                               v_delivery_channel, v_txn_code,
                               v_auth_id, SYSDATE, 1,
                               v_acct_number,
                               (SUBSTR (p_card_no,
                                        LENGTH (p_card_no) - 3,
                                        LENGTH (p_card_no)
                                       )
                               ),
                               NULL, v_acct_type, v_timestamp,
                               v_prod_code,v_card_type
                              );

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_errmsg :=
                               'No records inserted in statements log for CR';
                     RAISE v_excep;
                  END IF;
               EXCEPTION
                  WHEN v_excep
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Problem while inserting into statement log for CR-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE v_excep;
               END;
            ELSIF p_trans_type = 'DR'
            THEN
               IF TRIM (p_trans_narration) IS NOT NULL
               THEN
                  v_narration := p_trans_narration || '/';
               END IF;

               IF TRIM (v_auth_id) IS NOT NULL
               THEN
                  v_narration := v_narration || v_auth_id || '/';
               END IF;

               /*IF TRIM (v_cracct_no) IS NOT NULL
               THEN
                  v_narration := v_narration || v_cracct_no || '/';
               END IF; */

               IF TRIM (v_business_date) IS NOT NULL
               THEN
                  v_narration := v_narration || v_business_date;
               END IF;

               BEGIN
                  IF p_adj_type = 'B'
                  THEN
                     BEGIN
                        UPDATE cms_acct_mast
                           SET cam_acct_bal = cam_acct_bal - v_txn_amount,
                               cam_ledger_bal = cam_ledger_bal - v_txn_amount
                         WHERE cam_inst_code = p_instcode
                           AND cam_acct_no = v_acct_number;

                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_errmsg :=
                                'No records updated in account master for DR';
                           RAISE v_excep;
                        END IF;
                     EXCEPTION
                        WHEN v_excep
                        THEN
                           RAISE v_excep;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                              'Error occured while  updating account master for DR';
                           RAISE v_excep;
                     END;
                  ELSIF p_adj_type = 'L'
                  THEN
                     BEGIN
                        UPDATE cms_acct_mast
                           SET   --cam_acct_bal = cam_acct_bal - v_txn_amount
                              cam_ledger_bal = cam_ledger_bal - v_txn_amount
                         WHERE cam_inst_code = p_instcode
                           AND cam_acct_no = v_acct_number;

                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_errmsg :=
                              'No records updated in account master for DR(Ledger) ';
                           RAISE v_excep;
                        END IF;
                     EXCEPTION
                        WHEN v_excep
                        THEN
                           RAISE v_excep;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                              'Error occured while  updating account master for DRDR(Ledger) ';
                           RAISE v_excep;
                     END;
                  END IF;
               EXCEPTION
                  WHEN v_excep
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error occurred while updating acct mast for DRDR(Ledger) -'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE v_excep;
               END;
                /*
               BEGIN
                  sp_ins_eodupdate_acct_cmsauth (v_rrn,
                                                 NULL,
                                                 v_delivery_channel,
                                                 v_txn_code,
                                                 v_txn_mode,
                                                 TO_DATE (v_business_date,
                                                          'yyyymmdd'
                                                         ),
                                                 p_card_no,         --v_panno,
                                                 v_cracct_no,
                                                 v_txn_amount,
                                                 'C',
                                                 p_instcode,
                                                 v_errmsg
                                                );

                  IF v_errmsg <> 'OK'
                  THEN
                     RAISE v_excep;
                  END IF;
               EXCEPTION
                  WHEN v_excep
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error occurred while crediting gl for DR-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE v_excep;
               END;
                */
               BEGIN
                  INSERT INTO cms_statements_log
                              (csl_pan_no, csl_opening_bal,
                               csl_trans_amount, csl_trans_type,
                               csl_trans_date,
                               csl_closing_balance, csl_trans_narrration,
                               csl_inst_code, csl_pan_no_encr, csl_rrn,
                               csl_business_date, csl_business_time,
                               csl_delivery_channel, csl_txn_code,
                               csl_auth_id, csl_ins_date, csl_ins_user,
                               csl_acct_no,
                               csl_panno_last4digit,
                               csl_to_acctno, csl_acct_type, csl_time_stamp,
                               csl_prod_code,csl_card_type
                              )
                       VALUES (v_hash_pan, v_ledger_bal,
                               v_txn_amount, p_trans_type,
                               TO_DATE (v_business_date, 'yyyymmdd'),
                               v_upd_amt, v_narration,
                               p_instcode, v_encr_pan, v_rrn,
                               v_business_date, v_business_time,
                               v_delivery_channel, v_txn_code,
                               v_auth_id, SYSDATE, 1,
                               v_acct_number,
                               (SUBSTR (p_card_no,
                                        LENGTH (p_card_no) - 3,
                                        LENGTH (p_card_no)
                                       )
                               ),
                               NULL, v_acct_type, v_timestamp,
                               v_prod_code,v_card_type
                              );

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_errmsg :=
                               'No records inserted in statements log for DR';
                     RAISE v_excep;
                  END IF;
               EXCEPTION
                  WHEN v_excep
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Problem while inserting into statement log for DR-'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE v_excep;
               END;
            ELSIF NVL (p_trans_type, '0') NOT IN ('DR', 'CR')
            THEN
               v_errmsg := 'invalid debit/credit flag ';
               RAISE v_excep;
            END IF;
         END;
      ELSIF p_adj_type = 'A'
      THEN
         v_txn_type := '0';

         IF p_trans_type = 'CR'
         THEN
            v_upd_amt := v_ledger_bal;                      --+ v_txn_amount;
            v_upd_acct_bal := v_acct_bal + v_txn_amount;
         ELSIF p_trans_type = 'DR'
         THEN
            v_upd_amt := v_ledger_bal;                     -- - v_txn_amount;
            v_upd_acct_bal := v_acct_bal - v_txn_amount;
         END IF;

         IF p_trans_type = 'CR'
         THEN
            BEGIN
               UPDATE cms_acct_mast
                  SET cam_acct_bal = cam_acct_bal + v_txn_amount           --,
                -- cam_ledger_bal = cam_ledger_bal + v_txn_amount
               WHERE  cam_inst_code = p_instcode
                  AND cam_acct_no = v_acct_number;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_errmsg :=
                     'No records updated in account master for CR(Only Account)';
                  RAISE v_excep;
               END IF;
            EXCEPTION
               WHEN v_excep
               THEN
                  RAISE v_excep;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                     'No records updated in account master for CR(Only Account)';
                  RAISE v_excep;
            END;
         ELSIF p_trans_type = 'DR'
         THEN
            BEGIN
               UPDATE cms_acct_mast
                  SET cam_acct_bal = cam_acct_bal - v_txn_amount
                --cam_ledger_bal = cam_ledger_bal + v_txn_amount
               WHERE  cam_inst_code = p_instcode
                  AND cam_acct_no = v_acct_number;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_errmsg :=
                     'No records updated in account master for DR(Only Account)';
                  RAISE v_excep;
               END IF;
            EXCEPTION
               WHEN v_excep
               THEN
                  RAISE v_excep;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                     'No records updated in account master for DR(Only Account)';
                  RAISE v_excep;
            END;
         END IF;
      END IF;
   EXCEPTION
      WHEN v_excep
      THEN
         RAISE v_excep;
      WHEN OTHERS
      THEN
         v_errmsg := 'Main Excp 1-' || SUBSTR (SQLERRM, 1, 200);
         RAISE v_excep;
   END;

   --END LOOP;
   BEGIN
      INSERT INTO transactionlog
                  (msgtype, rrn, delivery_channel, date_time, txn_code,
                   txn_type, txn_mode, txn_status, response_code,
                   business_date, business_time, customer_card_no, instcode,
                   customer_card_no_encr, customer_acct_no, error_msg,
                   cardstatus,
                   amount,
                   bank_code,
                   total_amount,
                   currencycode, auth_id, trans_desc, gl_upd_flag,
                   acct_balance,
                   ledger_balance, response_id,
                   add_ins_date, add_ins_user, productid, categoryid,
                   acct_type, time_stamp,
                   cr_dr_flag, reason
                  )
           VALUES (v_msg, v_rrn, v_delivery_channel, SYSDATE, v_txn_code,
                   v_txn_type, '0', 'C', '00',
                   v_business_date, v_business_time, v_hash_pan, p_instcode,
                   v_encr_pan, v_acct_number, v_errmsg,
                   v_cap_card_stat,
                   TRIM (TO_CHAR (v_txn_amount, '99999999999999990.99')),
                   p_instcode,
                   TRIM (TO_CHAR (v_txn_amount, '99999999999999990.99')),
                   '840', v_auth_id, SUBSTR (p_trans_narration, 1, 50), 'N',
                   TRIM (TO_CHAR (v_upd_acct_bal, '99999999999999990.99')),
                   --Modified by saravanakumar on 06-Mar-2014 for logging issue
                   TRIM (TO_CHAR (v_upd_amt, '99999999999999990.99')), '1',
                   SYSDATE, 1, v_prod_code, v_card_type,
                   v_acct_type, v_timestamp,
                   DECODE (p_adj_type, 'A', 'NA', p_trans_type), v_reasondesc
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Exception while inserting to transaction log-'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE v_excep;
   END;

   BEGIN
      INSERT INTO cms_transaction_log_dtl
                  (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                   ctd_txn_mode, ctd_business_date, ctd_business_time,
                   ctd_customer_card_no, ctd_txn_curr, ctd_fee_amount,
                   ctd_waiver_amount, ctd_servicetax_amount,
                   ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                   ctd_rrn, ctd_inst_code, ctd_ins_date,
                   ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                   ctd_cust_acct_number, ctd_addr_verify_response,
                   ctd_actual_amount, ctd_txn_amount
                  )
           VALUES (v_delivery_channel, v_txn_code, v_txn_type,
                   '0', v_business_date, v_business_time,
                   v_hash_pan, '840', NULL,
                   NULL, NULL,
                   NULL, 'Y', v_errmsg,
                   v_rrn, p_instcode, SYSDATE,
                   v_encr_pan, v_msg, '',
                   v_acct_number, '',
                   v_txn_amount, v_txn_amount
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE v_excep;
   END;

   p_errmsg := 'OK';
   p_auth_id := v_auth_id;
EXCEPTION
   WHEN v_excep
   THEN
      p_auth_id := v_auth_id;
      p_errmsg := v_errmsg;
   WHEN OTHERS
   THEN
      p_auth_id := v_auth_id;
      p_errmsg := ' Main Excp 2-' || SUBSTR (SQLERRM, 1, 200);
END;

/
show error