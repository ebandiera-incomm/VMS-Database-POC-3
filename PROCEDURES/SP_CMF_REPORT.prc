CREATE OR REPLACE PROCEDURE VMSCMS.SP_CMF_REPORT (
   prm_date     IN       DATE,
   p_resp_msg   OUT      VARCHAR2
)
AS
   CURSOR c (acct_no VARCHAR2)
   IS
      SELECT a.*, a.ROWID row_id
        FROM cms_cmf_rep a
       WHERE account_no = acct_no;

   v_curr_bal        cms_cmf_rep.curr_bal%TYPE;
   v_sign            cms_cmf_rep.curr_bal_sign%TYPE;
   v_exp             EXCEPTION;
   v_cap_pan_code    cms_appl_pan.cap_pan_code%TYPE;
   v_cap_acct_no     cms_appl_pan.cap_acct_no%TYPE;
   v_avail_bal       cms_cmf_rep.avail_bal_sign%TYPE;
   v_avail_balance   transactionlog.acct_balance%TYPE;
BEGIN

   truncate_tab_ebr ('CMS_CMF_REP');
   
   BEGIN
      INSERT INTO cms_cmf_rep
         SELECT cc.*
           FROM (SELECT mm.esign_indi, mm.record_type, mm.acctcrtdt,
                        mm.email_one, mm.unique_program_id, mm.cardno,
                        mm.card_issued_dt, mm.account_expiration_dt, mm.ssn,
                        mm.card_holder_first_name, mm.card_holder_last_name,
                        mm.addr1, mm.addr2, mm.city, mm.state, mm.zip,
                        mm.card_mailing_addr1, mm.card_mailing_addr2,
                        mm.card_mailing_city, mm.card_mailing_state,
                        mm.card_mailing_zip, mm.pri_phone, mm.sec_phone,
                        mm.card_status, mm.card_status_dt, mm.curr_bal,
                        mm.curr_bal_sign, mm.account_created_dt,
                        mm.card_activation_date, mm.card_transfer_no_from,
                        mm.dt_of_neg_bal, mm.neg_bal_priniciple_amt,
                        mm.neg_bal_fee_amt, mm.reload_indicator,
                        mm.account_no, mm.type_of_card, mm.authentication_typ,
                        mm.enroll_no, mm.account_stat, mm.account_stat_dt,
                        mm.account_transfer_no_from, mm.account_transfer_to,
                        mm.dob, mm.avail_bal, mm.avail_bal_sign, mm.pri_card,
                        mm.card_expiry_dt, mm.card_transfer_no_to,
                        mm.first_load_dt, mm.last_txn_dt, mm.last_reisued_dt,
                        mm.crd_first_mailed_dt, mm.crd_last_mailed_dt,
                        mm.no_of_plastics, mm.alt_id_typ, mm.alt_id_val,
                        ROW_NUMBER () OVER (PARTITION BY mm.account_no ORDER BY card_issued_dt DESC)
                                                                        ranks
                   FROM (SELECT DISTINCT 'Y' esign_indi, 'D' record_type,
                                         (SELECT TO_CHAR
                                                     (cam_ins_date,
                                                      'MMDDYYYY'
                                                     )
                                            FROM cms_acct_mast
                                           WHERE cam_acct_no = cap_acct_no)
                                                                    acctcrtdt,
                                         ccm_email_one email_one,
                                         (SELECT cpm_program_id
                                            FROM cms_prod_mast
                                           WHERE cpm_prod_code = cap_prod_code)
                                                            unique_program_id,
                                         cap_pan_code_encr cardno,
                                         TO_CHAR
                                             (cap_pangen_date,
                                              'mmddyyyy'
                                             ) card_issued_dt,
                                         ' ' account_expiration_dt,
                                         ccm_ssn ssn,
                                         ccm_first_name
                                                       card_holder_first_name,
                                         ccm_last_name card_holder_last_name,
                                         c.cam_add_one addr1,
                                         c.cam_add_two addr2,
                                         c.cam_city_name city,
                                         (SELECT gsm_switch_state_code
                                            FROM gen_state_mast
                                           WHERE gsm_state_code =
                                                       c.cam_state_code
                                             AND gsm_inst_code = 1
                                             AND gsm_cntry_code = 1) state,
                                         c.cam_pin_code zip,
                                         f.cam_add_one card_mailing_addr1,
                                         f.cam_add_two card_mailing_addr2,
                                         f.cam_city_name card_mailing_city,
                                         (SELECT gsm_switch_state_code
                                            FROM gen_state_mast
                                           WHERE gsm_state_code =
                                                              f.cam_state_code
                                             AND gsm_inst_code = 1
                                             AND gsm_cntry_code = 1)
                                                           card_mailing_state,
                                         f.cam_pin_code card_mailing_zip,
                                         c.cam_phone_one pri_phone,
                                         c.cam_phone_two sec_phone,
                                         cap_card_stat card_status,
                                         (SELECT TO_CHAR
                                                    (MAX (add_ins_date),
                                                     'MMDDYYYY'
                                                    )
                                            FROM transactionlog aa
                                           WHERE aa.customer_card_no =
                                                                a.cap_pan_code
                                             AND (   (    delivery_channel =
                                                                          '04'
                                                      AND txn_code IN
                                                             ('68', '69',
                                                              '75', '76',
                                                              '77', '83')
                                                     )
                                                  OR (    delivery_channel =
                                                                          '06'
                                                      AND txn_code IN
                                                                 ('01', '03')
                                                     )
                                                  OR (    delivery_channel =
                                                                          '07'
                                                      AND txn_code IN
                                                                 ('05', '06')
                                                     )
                                                  OR (    delivery_channel =
                                                                          '10'
                                                      AND txn_code IN
                                                             ('05', '06',
                                                              '11')
                                                     )
                                                 )) card_status_dt,
                                         (SELECT ABS (cam_ledger_bal)
                                            FROM cms_acct_mast
                                           WHERE cam_acct_no =
                                                    (SELECT cap_acct_no
                                                       FROM cms_appl_pan
                                                      WHERE cap_pan_code =
                                                                a.cap_pan_code))
                                                                     curr_bal,
                                         CASE
                                            WHEN (SELECT cam_ledger_bal
                                                    FROM cms_acct_mast
                                                   WHERE cam_acct_no =
                                                            (SELECT cap_acct_no
                                                               FROM cms_appl_pan
                                                              WHERE cap_pan_code =
                                                                       a.cap_pan_code)) >
                                                                             0
                                               THEN '+'
                                            ELSE '-'
                                         END curr_bal_sign,
                                         TO_CHAR
                                            (cap_pangen_date,
                                             'MMDDYYYY'
                                            ) account_created_dt,
                                         TO_CHAR
                                            (cap_active_date,
                                             'MMDDYYYY'
                                            ) card_activation_date,
                                         (SELECT fn_dmaps_main
                                                    (chr_pan_code_encr
                                                    )
                                            FROM cms_htlst_reisu
                                           WHERE chr_new_pan = cap_pan_code)
                                                        card_transfer_no_from,
                                         (SELECT MIN
                                                    (TO_CHAR (add_ins_date,
                                                              'MMDDYYYY'
                                                             )
                                                    )
                                            FROM transactionlog x
                                           WHERE customer_card_no =
                                                                a.cap_pan_code
                                             AND acct_balance < 0
                                             AND fn_txndtchk (business_date,
                                                              business_time
                                                             ) != 0)
                                                                dt_of_neg_bal,
                                         (SELECT MIN
                                                    (TO_CHAR (amount,
                                                              '9999999990.99'
                                                             )
                                                    )
                                            FROM transactionlog x
                                           WHERE customer_card_no =
                                                                a.cap_pan_code
                                             AND acct_balance < 0
                                             AND add_ins_date =
                                                    (SELECT MIN (add_ins_date)
                                                       FROM transactionlog x
                                                      WHERE customer_card_no =
                                                                a.cap_pan_code
                                                        AND acct_balance < 0
                                                        AND fn_txndtchk
                                                               (business_date,
                                                                business_time
                                                               ) != 0))
                                                       neg_bal_priniciple_amt,
                                         (SELECT MIN
                                                    (TO_CHAR (tranfee_amt,
                                                              '9999999990.99'
                                                             )
                                                    )
                                            FROM transactionlog x
                                           WHERE customer_card_no =
                                                                a.cap_pan_code
                                             AND acct_balance < 0
                                             AND add_ins_date =
                                                    (SELECT MIN (add_ins_date)
                                                       FROM transactionlog x
                                                      WHERE customer_card_no =
                                                                a.cap_pan_code
                                                        AND acct_balance < 0
                                                        AND fn_txndtchk
                                                               (business_date,
                                                                business_time
                                                               ) != 0))
                                                              neg_bal_fee_amt,
                                         1 reload_indicator,
                                         cap_acct_no account_no,
                                         (SELECT cpc_cardtype_desc
                                            FROM cms_prod_cattype
                                           WHERE cpc_card_type =
                                                               a.cap_card_type
                                             AND cpc_prod_code =
                                                               a.cap_prod_code)
                                                                 type_of_card,
                                         'PIN' authentication_typ,
                                         ' ' enroll_no,
                                         (SELECT DECODE
                                                    (cam_stat_code,
                                                     2, 'Closed Account',
                                                     3, 'Primary Open Account',
                                                     8, 'Secondary Open Account'
                                                    )
                                            FROM cms_acct_mast
                                           WHERE cam_acct_no = cap_acct_no)
                                                                 account_stat,
                                         ' ' account_stat_dt,
                                         ' ' account_transfer_no_from,
                                         ' ' account_transfer_to,
                                         TO_CHAR (ccm_birth_date,
                                                  'MMDDYYYY'
                                                 ) dob,
                                         (SELECT ABS (cam_acct_bal)
                                            FROM cms_acct_mast
                                           WHERE cam_acct_no =
                                                    (SELECT cap_acct_no
                                                       FROM cms_appl_pan
                                                      WHERE cap_pan_code =
                                                                a.cap_pan_code))
                                                                    avail_bal,
                                         CASE
                                            WHEN (SELECT cam_acct_bal
                                                    FROM cms_acct_mast
                                                   WHERE cam_acct_no =
                                                            (SELECT cap_acct_no
                                                               FROM cms_appl_pan
                                                              WHERE cap_pan_code =
                                                                       a.cap_pan_code)) >
                                                                             0
                                               THEN '+'
                                            ELSE '-'
                                         END avail_bal_sign,
                                         DECODE (cap_addon_stat,
                                                 'P', 'T',
                                                 'F'
                                                ) pri_card,
                                         TO_CHAR
                                              (cap_expry_date,
                                               'mmddyyyy'
                                              ) card_expiry_dt,
                                         (SELECT fn_dmaps_main
                                                    (chr_new_pan_encr
                                                    )
                                            FROM cms_htlst_reisu,
                                                 cms_appl_pan x
                                           WHERE chr_pan_code = a.cap_pan_code
                                             AND x.cap_pan_code =
                                                                a.cap_pan_code
                                             AND a.ROWID = x.ROWID
                                             AND ROWNUM < 2)
                                                          card_transfer_no_to,
                                         TO_CHAR
                                            ((SELECT MIN (cps_ins_date)
                                                FROM cms_pan_spprt
                                               WHERE cps_spprt_key IN
                                                            ('INLOAD', 'TOP')
                                                 AND cps_pan_code =
                                                                a.cap_pan_code),
                                             'MMDDYYYY'
                                            ) first_load_dt,
                                         TO_CHAR
                                            ((SELECT MAX (add_ins_date)
                                                FROM transactionlog
                                               WHERE customer_card_no =
                                                                a.cap_pan_code
                                                 AND fn_txndtchk
                                                               (business_date,
                                                                business_time
                                                               ) != 0),
                                             'MMDDYYYY'
                                            ) last_txn_dt,
                                         TO_CHAR
                                            ((SELECT chr_ins_date
                                                FROM cms_htlst_reisu,
                                                     cms_appl_pan x
                                               WHERE chr_pan_code =
                                                                a.cap_pan_code
                                                 AND a.ROWID = x.ROWID
                                                 AND ROWNUM < 2),
                                             'MMDDYYYY'
                                            ) last_reisued_dt,
                                         TO_CHAR
                                            ((SELECT ccs_ins_date
                                                FROM cms_cardissuance_status
                                               WHERE ccs_card_status = 15
                                                 AND ccs_pan_code =
                                                                  cap_pan_code),
                                             'MMDDYYYY'
                                            ) crd_first_mailed_dt,
                                         TO_CHAR
                                            ((SELECT ccs_lupd_date
                                                FROM cms_cardissuance_status
                                               WHERE ccs_card_status = 15
                                                 AND ccs_pan_code =
                                                                  cap_pan_code),
                                             'MMDDYYYY'
                                            ) crd_last_mailed_dt,
                                         1 no_of_plastics,
                                         cci_id_issuer alt_id_typ,
                                         cci_id_number alt_id_val
                                    FROM cms_appl_pan a,
                                         cms_cust_mast b,
                                         (SELECT *
                                            FROM cms_addr_mast
                                           WHERE cam_addr_flag = 'P') c,
                                         (SELECT *
                                            FROM cms_addr_mast
                                           WHERE cam_addr_flag = 'O') f,
                                         cms_caf_info_entry,
                                         cms_appl_mast
                                   WHERE cap_cust_code = ccm_cust_code
                                     AND cap_cust_code = c.cam_cust_code
                                     AND c.cam_cust_code = f.cam_cust_code(+)
                                     AND cam_appl_code = cap_appl_code
                                     AND cci_appl_no(+) = cam_appl_no
                                     AND a.cap_pan_code NOT IN (
                                                          SELECT chr_pan_code
                                                            FROM cms_htlst_reisu)
                                     AND cap_firsttime_topup = 'Y'
                                     AND cap_startercard_flag =
                                            CASE
                                               WHEN (SELECT COUNT (*)
                                                       FROM cms_appl_pan
                                                      WHERE cap_startercard_flag =
                                                                           'N'
                                                        AND cap_firsttime_topup =
                                                                           'Y'
                                                        AND a.cap_acct_no =
                                                                   cap_acct_no) >
                                                                             0
                                                  THEN 'N'
                                               ELSE 'Y'
                                            END) mm) cc
          WHERE cc.ranks = 1;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_msg :=
                      'ERROR WHILE INSERTION IS ' || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   FOR j IN (SELECT cam_acct_no
               FROM cms_acct_mast
              WHERE cam_lupd_date > prm_date)
   LOOP
      BEGIN
         FOR i IN c (j.cam_acct_no)
         LOOP
            BEGIN
               SELECT  i.curr_bal
                      - NVL (SUM (DECODE (csl_trans_type,
                                                      'CR', csl_trans_amount,
                                                      'DR', -csl_trans_amount
                                                     )
                                             ),
                                         0
                                        )
                 INTO v_curr_bal
                 FROM cms_statements_log
                WHERE csl_pan_no IN (SELECT cap_pan_code
                                       FROM cms_appl_pan
                                      WHERE cap_acct_no = j.cam_acct_no)
                  AND csl_ins_date > prm_date;

               IF v_curr_bal > 0
               THEN
                  v_sign := '+';
               ELSE
                  v_sign := '-';
               END IF;

               BEGIN
                  SELECT acct_balance
                    INTO v_avail_balance
                    FROM (SELECT   acct_balance, add_ins_date
                              FROM transactionlog
                             WHERE customer_card_no IN (
                                             SELECT cap_pan_code
                                               FROM cms_appl_pan
                                              WHERE cap_acct_no =
                                                                 j.cam_acct_no)
                               AND add_ins_date <= prm_date
                               AND acct_balance IS NOT NULL
                          ORDER BY add_ins_date DESC)
                   WHERE ROWNUM < 2;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     NULL;
                  WHEN OTHERS
                  THEN
                     p_resp_msg :=
                           'ERROR WHILE SELECTING AVAILABLE BALANCE IS '
                        || SUBSTR (SQLERRM, 1, 200);
                     RETURN;
               END;

               IF v_avail_balance > 0
               THEN
                  v_avail_bal := '+';
               ELSE
                  v_avail_bal := '-';
               END IF;

               UPDATE cms_cmf_rep
                  SET curr_bal = v_curr_bal,
                      curr_bal_sign = v_sign,
                      avail_bal = v_avail_balance,
                      avail_bal_sign = v_avail_bal
                WHERE ROWID = i.row_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_msg :=
                        'ERROR FROM INNER LOOP WHILE UPDATE IS '
                     || SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;
         END LOOP;
      END;
   END LOOP;
EXCEPTION
   WHEN OTHERS
   THEN
      p_resp_msg := 'Error from main ' || SUBSTR (SQLERRM, 1, 200);
END; 
/

SHOW ERRORS;