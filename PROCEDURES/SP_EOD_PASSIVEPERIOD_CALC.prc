create or replace PROCEDURE        VMSCMS.sp_eod_passiveperiod_calc (
   p_inst_code   IN       NUMBER,
   p_resp_msg    OUT      VARCHAR2
)
IS
   v_limit_check             VARCHAR2 (1);
   v_atmpos_flag             VARCHAR2 (1);
   v_limit_type              VARCHAR2 (1);
   v_dailytran_cnt           NUMBER (2);
   v_dailytran_limit         NUMBER (6);
   v_weeklytran_cnt          NUMBER (2);
   v_weeklytran_limit        NUMBER (6);
   v_txn_code                cms_func_mast.cfm_txn_code%TYPE;
   v_last_trandate           NUMBER (14);
   v_passive_time_prodcatg   cms_prod_cattype.cpc_passive_time%TYPE;
   v_passive_days            cms_prod_cattype.cpc_passive_time%TYPE;
   v_passive_period          cms_prod_cattype.cpc_passive_time%TYPE;
   v_prod_code               cms_appl_pan.cap_prod_code%TYPE;
   v_prod_catg               cms_appl_pan.cap_card_type%TYPE;
   v_resp_code               cms_passiveperiod_fail_dtl.cpd_resp_code%TYPE
                                                                    DEFAULT 1;
   exp_reject_passive        EXCEPTION;
   v_resp_msg                cms_passiveperiod_fail_dtl.cpd_process_msg%TYPE;
   v_last_tran_date          transactionlog.business_date%TYPE;
   v_last_tran_time          transactionlog.business_time%TYPE;
   v_err_msg                 VARCHAR2 (300);
   v_rrn                     transactionlog.rrn%TYPE;
   v_tran_code               transactionlog.txn_code%TYPE        DEFAULT '04';
   v_del_channel             transactionlog.delivery_channel%TYPE
                                                                 DEFAULT '05';
   v_tran_desc               cms_transaction_mast.ctm_tran_desc%TYPE;
   v_acct_bal                cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal              cms_acct_mast.cam_ledger_bal%TYPE;
   v_acct_no                 cms_acct_mast.cam_acct_no%TYPE;
   v_passivestatupd_rrn      NUMBER (20);

   CURSOR c1
   IS
      SELECT DISTINCT cap_pan_code, cap_pan_code_encr, cap_active_date,
                      cap_prod_code, cap_card_type
                 FROM cms_appl_pan, cms_prod_cattype
                WHERE cap_card_stat IN ('1')
                  AND cap_inst_code = p_inst_code
                  AND cap_prod_code = cpc_prod_code
                  AND cap_card_type = cpc_card_type
                  AND (cpc_passive_time IS NOT NULL
                       AND cpc_passive_time != '0'
                      )
                  AND cpc_inst_code = p_inst_code
                  AND cap_expry_date > SYSDATE;
BEGIN
   p_resp_msg := 'OK';

   FOR i1 IN c1
   LOOP
      BEGIN
         SELECT MAX (business_date || business_time)
           INTO v_last_trandate
           FROM transactionlog
          WHERE customer_card_no = i1.cap_pan_code
            AND instcode = p_inst_code
            AND delivery_channel IN (
                   SELECT cdm_channel_code
                     FROM cms_delchannel_mast
                    WHERE cdm_passiveperiod_flag = 'Y'
                      AND cdm_inst_code = p_inst_code);

         IF v_last_trandate IS NULL
         THEN
            v_last_trandate :=
                             TO_CHAR (i1.cap_active_date, 'YYYYMMDDHH24MISS');
         END IF;

         BEGIN
            SELECT TRUNC (  SYSDATE
                          - TO_DATE (v_last_trandate, 'yyyymmdd hh24:mi:ss')
                         )
              INTO v_passive_days
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_code := '89';
               v_err_msg :=
                     'Problem in calculating passive days'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_passive;
         END;

         v_last_tran_date := SUBSTR (v_last_trandate, 1, 8);
         v_last_tran_time := SUBSTR (v_last_trandate, 9);

         BEGIN
            SELECT cpc_passive_time
              INTO v_passive_time_prodcatg
              FROM cms_prod_cattype
             WHERE cpc_prod_code = i1.cap_prod_code
               AND cpc_card_type = i1.cap_card_type
               AND cpc_inst_code = p_inst_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_resp_code := '89';
               v_err_msg :=
                     'Problem while selecting Passive period of Product Catg'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_passive;
         END;

         IF v_passive_days > v_passive_time_prodcatg
         THEN
            BEGIN
               INSERT INTO cms_passivecard_details
                           (cpd_inst_code, cpd_pan_code,
                            cpd_pan_code_encr, cpd_last_trandate,
                            cpd_last_trantime, cpd_currtran_date,
                            cpd_currtran_time, cpd_passive_period,
                            cpd_process_flag
                           )
                    VALUES (p_inst_code, i1.cap_pan_code,
                            i1.cap_pan_code_encr, v_last_tran_date,
                            v_last_tran_time, TO_CHAR (SYSDATE, 'YYYYMMDD'),
                            TO_CHAR (SYSDATE, 'hh24miss'), v_passive_days,
                            'N'
                           );

               IF SQL%ROWCOUNT = 0
               THEN
                  v_resp_code := '89';
                  v_err_msg := 'Problem in inserting the passive details';
                  RAISE exp_reject_passive;
               END IF;

               UPDATE cms_appl_pan
                  SET cap_card_stat = '8'
                WHERE cap_pan_code = i1.cap_pan_code
                  AND cap_inst_code = p_inst_code;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_resp_code := '89';
                  v_err_msg :=
                             'Problem in updating the card status to passive';
                  RAISE exp_reject_passive;
               END IF;

               SELECT seq_passivestatupd_rrn.NEXTVAL
                 INTO v_passivestatupd_rrn
                 FROM DUAL;

               v_rrn :=
                  'PSU' || TO_CHAR (SYSDATE, 'YYYYMMDD')
                  || v_passivestatupd_rrn;

               BEGIN
                  SELECT ctm_tran_desc
                    INTO v_tran_desc
                    FROM cms_transaction_mast
                   WHERE ctm_delivery_channel = v_del_channel
                     AND ctm_tran_code = v_tran_code
                     AND ctm_inst_code = p_inst_code;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_err_msg := 'Transaction Details Not Found';
                     v_resp_code := '89';
                     RAISE exp_reject_passive;
                  WHEN OTHERS
                  THEN
                     v_err_msg :=
                           'While getting Transaction Description'
                        || SUBSTR (SQLERRM, 1, 200);
                     v_resp_code := '89';
                     RAISE exp_reject_passive;
               END;

               BEGIN
                  SELECT cam_acct_bal, cam_ledger_bal, cam_acct_no
                    INTO v_acct_bal, v_ledger_bal, v_acct_no
                    FROM cms_acct_mast
                   WHERE cam_acct_no =
                            (SELECT cap_acct_no
                               FROM cms_appl_pan
                              WHERE cap_pan_code = i1.cap_pan_code
                                AND cap_inst_code = p_inst_code)
                     AND cam_inst_code = p_inst_code;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_err_msg := 'Account Details Not Found';
                     v_resp_code := '89';
                     RAISE exp_reject_passive;
                  WHEN OTHERS
                  THEN
                     v_err_msg :=
                           'While getting account details'
                        || SUBSTR (SQLERRM, 1, 200);
                     v_resp_code := '89';
                     RAISE exp_reject_passive;
               END;

               BEGIN
                  INSERT INTO transactionlog
                              (msgtype, rrn, delivery_channel, date_time,
                               txn_code, txn_type, txn_status,
                               response_code, business_date,
                               business_time,
                               customer_card_no, bank_code,
                               auth_id,
                               trans_desc, instcode,
                               customer_card_no_encr, customer_acct_no,
                               acct_balance, ledger_balance, response_id,
                               txn_mode, cardstatus
                              )
                       VALUES ('0200', v_rrn, v_del_channel, SYSDATE,
                               v_tran_code, '0', 'C',
                               '00', TO_CHAR (SYSDATE, 'YYYYMMDD'),
                               TO_CHAR (SYSDATE, 'hh24miss'),
                               i1.cap_pan_code, p_inst_code,
                               LPAD (seq_auth_id.NEXTVAL, 6, '0'),
                               v_tran_desc, p_inst_code,
                               i1.cap_pan_code_encr, v_acct_no,
                               v_acct_bal, v_ledger_bal, 1,
                               0, '8'
                              );

                  IF SQL%ROWCOUNT <> 1
                  THEN
                     v_err_msg :=
                           'Error while inserting details in transactionlog'
                        || SUBSTR (SQLERRM, 1, 200);
                     v_resp_code := '89';
                     RAISE exp_reject_passive;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_err_msg :=
                           'Error in inserting transactionlog'
                        || SUBSTR (SQLERRM, 1, 200);
                     v_resp_code := '89';
                     RAISE exp_reject_passive;
               END;

               BEGIN
                  INSERT INTO cms_transaction_log_dtl
                              (ctd_delivery_channel, ctd_txn_code,
                               ctd_txn_type, ctd_msg_type, ctd_txn_mode,
                               ctd_business_date,
                               ctd_business_time,
                               ctd_customer_card_no, ctd_process_flag,
                               ctd_process_msg, ctd_rrn, ctd_inst_code,
                               ctd_customer_card_no_encr,
                               ctd_cust_acct_number
                              )
                       VALUES (v_del_channel, v_tran_code,
                               '0', '0200', 0,
                               TO_CHAR (SYSDATE, 'YYYYMMDD'),
                               TO_CHAR (SYSDATE, 'hh24miss'),
                               i1.cap_pan_code, 'Y',
                               'Successful', v_rrn, p_inst_code,
                               i1.cap_pan_code_encr,
                               v_acct_no
                              );

                  IF SQL%ROWCOUNT <> 1
                  THEN
                     v_err_msg :=
                           'Error while inserting details in cms_transaction_log_dtl'
                        || SUBSTR (SQLERRM, 1, 200);
                     v_resp_code := '89';
                     RAISE exp_reject_passive;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_err_msg :=
                           'Error in inserting cms_transaction_log_dtl'
                        || SUBSTR (SQLERRM, 1, 200);
                     v_resp_code := '89';
                     RAISE exp_reject_passive;
               END;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_resp_code := '89';
                  v_err_msg :=
                        'Problem while inserting data passive card details'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_passive;
            END;
         END IF;
      EXCEPTION
         WHEN exp_reject_passive
         THEN
            BEGIN
               INSERT INTO cms_passiveperiod_fail_dtl
                           (cpd_inst_code, cpd_pan_code,
                            cpd_pan_code_encr,
                            cpd_currtran_date,
                            cpd_currtran_time, cpd_lasttran_date,
                            cpd_lasttrantime, cpd_ins_user, cpd_ins_date,
                            cpd_lupd_user, cpd_lupd_date, cpd_resp_code,
                            cpd_process_msg
                           )
                    VALUES (p_inst_code, i1.cap_pan_code,
                            i1.cap_pan_code_encr,
                            TO_CHAR (SYSDATE, 'YYYYMMDD'),
                            TO_CHAR (SYSDATE, 'hh24miss'), v_last_tran_date,
                            v_last_tran_time, '1', SYSDATE,
                            '1', SYSDATE, v_resp_code,
                            'EOD' || v_err_msg
                           );

               IF SQL%ROWCOUNT = 0
               THEN
                  v_resp_code := '89';
                  v_err_msg :=
                     'Problem in inserting the FAILURE DETAILS OF PASSIVE PERIOD CALCULATION';
               END IF;
            END;
         WHEN OTHERS
         THEN
            v_resp_code := '89';
            v_err_msg := 'Error in main' || SUBSTR (SQLERRM, 1, 200);
      END;
   END LOOP;
EXCEPTION
   WHEN OTHERS
   THEN
      p_resp_msg :=
                 'Error in GPR Card Status Check' || SUBSTR (SQLERRM, 1, 200);
END;
/
SHOW ERROR;