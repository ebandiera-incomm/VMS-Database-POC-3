CREATE OR REPLACE PROCEDURE vmscms.sp_velocityload1000_24hrs_rep (
   frmdt        IN       VARCHAR2,
   todt         IN       VARCHAR2,
   prm_errmsg   OUT      VARCHAR2
)
IS
   cnt    NUMBER;
   cnt1   NUMBER;

   CURSOR LOAD
   IS
      SELECT DISTINCT a.ROWID, a.customer_card_no, a.txndt
                 FROM (SELECT ROWID,
                              fn_dmaps_main
                                      (customer_card_no_encr)
                                                             customer_card_no,
                              business_date || business_time txndt
                         FROM transactionlog
                        WHERE instcode = 1
                          AND reversal_code = 0
                          AND response_code = '00'
                          AND TO_DATE (DECODE (fn_txndtchk (business_date,
                                                            business_time
                                                           ),
                                               0, NULL,
                                               business_date || business_time
                                              ),
                                       'yyyymmddhh24miss'
                                      ) BETWEEN TO_DATE (frmdt || '000000',
                                                         'yyyymmddhh24miss'
                                                        )
                                            AND TO_DATE (todt || '235959',
                                                         'yyyymmddhh24miss'
                                                        )
                          AND (   (    delivery_channel = '04'
                                   AND txn_code IN
                                          ('68', '69', '80', '82', '85', '88')
                                  )
                               OR (    delivery_channel = '07'
                                   AND txn_code IN ('08')
                                  )
                               OR (    delivery_channel = '08'
                                   AND txn_code IN ('21', '22')
                                  )
                               OR (    delivery_channel = '10'
                                   AND txn_code IN ('08')
                                  )
                              )) a,
                      (SELECT   COUNT (*) cnt, SUM (amount) amt,
                                fn_dmaps_main
                                      (customer_card_no_encr)
                                                             customer_card_no,
                                TO_DATE (business_date, 'yyyymmdd') txndt
                           FROM transactionlog
                          WHERE instcode = 1
                            AND reversal_code = 0
                            AND response_code = '00'
                            AND TO_DATE (DECODE (fn_txndtchk (business_date,
                                                              business_time
                                                             ),
                                                 0, NULL,
                                                 business_date
                                                 || business_time
                                                ),
                                         'yyyymmddhh24miss'
                                        ) BETWEEN TO_DATE (frmdt || '000000',
                                                           'yyyymmddhh24miss'
                                                          )
                                              AND TO_DATE (todt || '235959',
                                                           'yyyymmddhh24miss'
                                                          )
                            AND (   (    delivery_channel = '04'
                                     AND txn_code IN
                                            ('68', '69', '80', '82', '85',
                                             '88')
                                    )
                                 OR (    delivery_channel = '07'
                                     AND txn_code IN ('08')
                                    )
                                 OR (    delivery_channel = '08'
                                     AND txn_code IN ('21', '22')
                                    )
                                 OR (    delivery_channel = '10'
                                     AND txn_code IN ('08')
                                    )
                                )
                       GROUP BY fn_dmaps_main (customer_card_no_encr),
                                TO_DATE (business_date, 'yyyymmdd')
                         HAVING SUM (amount) >= 1000
                       ORDER BY txndt) b
                WHERE a.customer_card_no = b.customer_card_no;

   CURSOR loadtmp
   IS
      SELECT   chr_row_id, chr_primary_card_number, chr_txn_date
          FROM cms_velocityload1000_txn24hrs
      ORDER BY chr_txn_date;

   CURSOR loadtmp1 (pan VARCHAR2, txndt VARCHAR2)
   IS
      SELECT chr_row_id, chr_primary_card_number, chr_txn_date
        FROM cms_velocityload1000_txn24hrs
       WHERE chr_primary_card_number = pan
         AND TO_DATE (chr_txn_date, 'yyyymmddhh24miss')
                BETWEEN TO_DATE (txndt, 'yyyymmddhh24miss')
                    AND TO_DATE (txndt, 'yyyymmddhh24miss') + 1;

   CURSOR loadtmp2
   IS
      SELECT DISTINCT chr_row_id
                 FROM cms_vlctyld1000_temp_txn24hrs;

   CURSOR rep (row_id VARCHAR2)
   IS
      SELECT   acctno, x.crdno, x.cardno primary_card_number,
               x.cap_expry_date, x.custname card_holder_name,
               x.address address, x.cam_phone_one phone_number,
               TO_CHAR (txndt, 'MM/DD/YYYY HH:MI:SS AM') txn_date,
               TO_CHAR (ledger_balance, '999999999999999990.99') balance,
               TO_CHAR (amount, '999999999999999990.99') load_amount,
               response_code response_code, terminal_id term_id,
               merchant_name term_owner,
               DECODE (merchant_state,
                       NULL, merchant_city,
                       DECODE (merchant_city,
                               NULL, merchant_state,
                               merchant_city || ',' || merchant_state
                              )
                      ) term_city_state_country
          FROM (SELECT fn_dmaps_main (cap_pan_code_encr) cardno,
                       cap_pan_code crdno,
                       TO_CHAR (cap_expry_date, 'MMYY') cap_expry_date,
                       ccm_first_name || ccm_last_name custname,
                          cam_add_one
                       || ' '
                       || cam_add_two
                       || ' '
                       || cam_add_three
                       || ' '
                       || cam_pin_code
                       || ' '
                       || cam_city_name address,
                          SUBSTR (cam_phone_one, 1, 3)
                       || '-'
                       || SUBSTR (cam_phone_one, 4, 3)
                       || '-'
                       || SUBSTR (cam_phone_one, 7, 4) cam_phone_one
                  FROM cms_appl_pan a, cms_addr_mast b, cms_cust_mast c
                 WHERE a.cap_bill_addr = b.cam_addr_code
                   AND a.cap_cust_code = c.ccm_cust_code) x,
               (SELECT a.customer_acct_no acctno, a.customer_card_no,
                       terminal_id, merchant_name, merchant_city,
                       merchant_state,
                       (SELECT cms_resp_desc
                          FROM cms_response_mast
                         WHERE cms_response_id = response_id
                           AND LPAD (cms_delivery_channel, 2, 0) =
                                                              delivery_channel
                           AND cms_inst_code = instcode) response_code,
                       ledger_balance, a.amount - NVL (b.amount, 0) amount,
                       TO_DATE (a.business_date || a.business_time,
                                'yyyymmddhh24miss'
                               ) txndt
                  FROM transactionlog a,
                       (SELECT customer_card_no, amount, orgnl_rrn,
                               orgnl_business_date, orgnl_business_time
                          FROM transactionlog
                         WHERE instcode = 1
                           AND reversal_code <> 0
                           AND response_code = '00'
                           AND (   (    delivery_channel = '04'
                                    AND txn_code IN
                                           ('68', '69', '80', '82', '85',
                                            '88')
                                   )
                                OR (    delivery_channel = '07'
                                    AND txn_code IN ('07', '08')
                                   )
                               )
                           AND TO_DATE (DECODE (fn_txndtchk (business_date,
                                                             business_time
                                                            ),
                                                0, NULL,
                                                business_date || business_time
                                               ),
                                        'yyyymmddhh24miss'
                                       ) BETWEEN TO_DATE (frmdt || '000000',
                                                          'yyyymmddhh24miss'
                                                         )
                                             AND TO_DATE (todt || '235959',
                                                          'yyyymmddhh24miss'
                                                         )) b
                 WHERE instcode = 1
                   AND a.customer_card_no = b.customer_card_no(+)
                   AND reversal_code = 0
                   AND response_code = '00'
                   AND (   (    delivery_channel = '04'
                            AND txn_code IN
                                         ('68', '69', '80', '82', '85', '88')
                           )
                        OR (    delivery_channel = '07'
                            AND txn_code IN ('07', '08')
                           )
                        OR (    delivery_channel = '08'
                            AND txn_code IN ('21', '22')
                           )
                        OR (    delivery_channel = '10'
                            AND txn_code IN ('07', '08')
                           )
                       )
                   AND a.rrn = b.orgnl_rrn(+)
                   AND a.business_date = b.orgnl_business_date(+)
                   AND a.business_time = b.orgnl_business_time(+)
                   AND TO_DATE (DECODE (fn_txndtchk (business_date,
                                                     business_time
                                                    ),
                                        0, NULL,
                                        business_date || business_time
                                       ),
                                'yyyymmddhh24miss'
                               ) BETWEEN TO_DATE (frmdt || '000000',
                                                  'yyyymmddhh24miss'
                                                 )
                                     AND TO_DATE (todt || '235959',
                                                  'yyyymmddhh24miss'
                                                 )
                   AND a.ROWID = row_id) y
         WHERE x.crdno = y.customer_card_no
      ORDER BY x.cardno;
BEGIN
   prm_errmsg := 'OK';

  truncate_tab_ebr ('CMS_VELOCITYLOAD1000_TXN24HRS');
   truncate_tab_ebr ('CMS_VLCTYLD1000_TEMP_TXN24HRS');
   truncate_tab_ebr ('CMS_VLCTYLD1000_TEMP1_TXN24HRS');
   truncate_tab_ebr ('CMS_VELOCITY1000_TXN24HRS');

   BEGIN
      FOR i IN LOAD
      LOOP
         INSERT INTO cms_velocityload1000_txn24hrs
                     (chr_row_id, chr_primary_card_number, chr_txn_date
                     )
              VALUES (i.ROWID, i.customer_card_no, i.txndt
                     );
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg := 'EXCP - 1 ' || SQLERRM;
   END;

   BEGIN
      FOR j IN loadtmp
      LOOP
         SELECT COUNT (*)
           INTO cnt
           FROM cms_velocityload1000_txn24hrs
          WHERE chr_row_id = j.chr_row_id
            AND chr_primary_card_number = j.chr_primary_card_number
            AND TO_DATE (chr_txn_date, 'yyyymmddhh24miss')
                   BETWEEN TO_DATE (j.chr_txn_date, 'yyyymmddhh24miss')
                       AND TO_DATE (j.chr_txn_date, 'yyyymmddhh24miss') + 1;

         IF cnt > 0
         THEN
            SELECT COUNT (*)
              INTO cnt1
              FROM cms_velocityload1000_txn24hrs
             WHERE chr_primary_card_number = j.chr_primary_card_number
               AND TO_DATE (chr_txn_date, 'yyyymmddhh24miss')
                      BETWEEN TO_DATE (j.chr_txn_date, 'yyyymmddhh24miss')
                          AND TO_DATE (j.chr_txn_date, 'yyyymmddhh24miss') + 1;

            IF cnt1 > 1
            THEN
               FOR k IN loadtmp1 (j.chr_primary_card_number, j.chr_txn_date)
               LOOP
                  INSERT INTO cms_vlctyld1000_temp_txn24hrs
                       VALUES (j.chr_row_id, j.chr_primary_card_number,
                               j.chr_txn_date);

                  INSERT INTO cms_vlctyld1000_temp_txn24hrs
                       VALUES (k.chr_row_id, k.chr_primary_card_number,
                               k.chr_txn_date);
               END LOOP;
            END IF;
         END IF;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg := 'EXCP - 2 ' || SQLERRM;
   END;

   COMMIT;

   BEGIN
      FOR l IN loadtmp2
      LOOP
         FOR j IN rep (l.chr_row_id)
         LOOP
            INSERT INTO cms_vlctyld1000_temp1_txn24hrs
                        (chr_account_no, chr_primary_card_number,
                         chr_expiry_date, chr_card_holder_name, chr_address,
                         chr_phone_number, chr_txn_date, chr_balance,
                         chr_load_amount, chr_response_code, chr_term_id,
                         chr_term_owner, chr_term_city_state_country
                        )
                 VALUES (j.acctno, j.primary_card_number,
                         j.cap_expry_date, j.card_holder_name, j.address,
                         j.phone_number, j.txn_date, j.balance,
                         j.load_amount, j.response_code, j.term_id,
                         j.term_owner, j.term_city_state_country
                        );
         END LOOP;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg := 'EXCP - 3 ' || SQLERRM;
   END;

   BEGIN
      INSERT INTO cms_velocity1000_txn24hrs
         SELECT   a.*
             FROM cms_vlctyld1000_temp1_txn24hrs a,
                  (SELECT   SUM (chr_load_amount), chr_primary_card_number
                       FROM cms_vlctyld1000_temp1_txn24hrs
                   GROUP BY chr_primary_card_number
                     HAVING SUM (chr_load_amount) >= 1000) b
            WHERE a.chr_primary_card_number = b.chr_primary_card_number
         ORDER BY chr_txn_date;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg := 'EXCP - 4 ' || SQLERRM;
   END;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'MAIN EXCP - ' || SQLERRM;
END;
/

SHOW ERROR