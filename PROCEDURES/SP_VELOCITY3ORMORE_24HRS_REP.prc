CREATE OR REPLACE PROCEDURE vmscms.sp_velocity3ormore_24hrs_rep (
   frmdt        IN       VARCHAR2,
   todt         IN       VARCHAR2,
   prm_errmsg   OUT      VARCHAR2
)
IS
   cnt    NUMBER;
   cnt1   NUMBER;

   CURSOR LOAD
   IS
      SELECT DISTINCT ROWID, customer_card_no,
                      business_date || business_time trndt
                 FROM transactionlog
                WHERE instcode = 1
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
                       OR (delivery_channel = '07' AND txn_code IN ('08'))
                       OR (delivery_channel = '08'
                           AND txn_code IN ('21', '22')
                          )
                       OR (delivery_channel = '10' AND txn_code IN ('08'))
                      )
             ORDER BY customer_card_no, trndt;

   CURSOR loadtmp
   IS
      SELECT chr_row_id, chr_primary_card_number, chr_txn_date
        FROM cms_velocityload_txn24hrs;

   CURSOR loadtmp1 (pan VARCHAR2, txndt VARCHAR2)
   IS
      SELECT chr_row_id, chr_primary_card_number, chr_txn_date
        FROM cms_velocityload_txn24hrs
       WHERE chr_primary_card_number = pan
         AND TO_DATE (chr_txn_date, 'yyyymmddhh24miss')
                BETWEEN TO_DATE (txndt, 'yyyymmddhh24miss')
                    AND TO_DATE (txndt, 'yyyymmddhh24miss') + 1;

   CURSOR loadtmp2
   IS
      SELECT DISTINCT chr_row_id
                 FROM cms_velocityall_txn24hrs;

   CURSOR rep (row_id VARCHAR2)
   IS
      SELECT   x.cardno primary_card_number,
               TO_CHAR (x.cap_expry_date, 'MMYY') expiry_date,
               x.cap_disp_name card_holder_name, x.address,
               x.cam_phone_one phone_number,
               TO_CHAR (txndt, 'MM/DD/YYYY HH:MI:SS AM') txn_date,
               TO_CHAR (ledger_balance, '$9,999,999,990.99') balance,
               TO_CHAR (amount, '$999,999,999,999,999,990.99') load_amount,
               amount, response_code response_code, terminal_id term_id,
               merchant_name term_owner,
               DECODE (merchant_state,
                       NULL, merchant_city,
                       DECODE (merchant_city,
                               NULL, merchant_state,
                               merchant_city || ',' || merchant_state
                              )
                      ) term_city_state_country
          FROM (SELECT fn_dmaps_main (cap_pan_code_encr) cardno, cap_pan_code,
                       cap_expry_date, cap_disp_name,
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
                  FROM cms_appl_pan a, cms_addr_mast b
                 WHERE a.cap_bill_addr = b.cam_addr_code) x,
               (SELECT a.customer_card_no, terminal_id, merchant_name,
                       merchant_city, merchant_state,
                       (SELECT DISTINCT cms_resp_desc
                                   FROM cms_response_mast
                                  WHERE cms_iso_respcde =
                                                  response_code
                                    AND LPAD (cms_delivery_channel, 2, 0) =
                                                              delivery_channel
                                    AND cms_inst_code = instcode
                                    AND ROWNUM < 2) response_code,
                       ledger_balance, amount,
                       TO_DATE (a.business_date || a.business_time,
                                'yyyymmddhh24miss'
                               ) txndt
                  FROM transactionlog a,
                       (SELECT   COUNT (*), customer_card_no
                            FROM transactionlog
                           WHERE instcode = 1
                             AND TO_DATE
                                        (DECODE (fn_txndtchk (business_date,
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
                        GROUP BY customer_card_no
                          HAVING COUNT (*) >= 3) b
                 WHERE instcode = 1
                   AND b.customer_card_no = a.customer_card_no
                   AND (   (    delivery_channel = '04'
                            AND txn_code IN
                                         ('68', '69', '80', '82', '85', '88')
                           )
                        OR (delivery_channel = '07' AND txn_code IN ('08'))
                        OR (    delivery_channel = '08'
                            AND txn_code IN ('21', '22')
                           )
                        OR (delivery_channel = '10' AND txn_code IN ('08'))
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
                                                 )
                   AND a.ROWID = row_id) y
         WHERE x.cap_pan_code = y.customer_card_no
      ORDER BY x.cardno, txndt;
BEGIN
   prm_errmsg := 'OK';

    truncate_tab_ebr ('CMS_VELOCITY_TXN24HRS');
    truncate_tab_ebr ('CMS_VELOCITYLOAD_TXN24HRS');
    truncate_tab_ebr ('CMS_VELOCITYALL_TXN24HRS');

   BEGIN
      FOR i IN LOAD
      LOOP
         INSERT INTO cms_velocityload_txn24hrs
              VALUES (i.ROWID, i.customer_card_no, i.trndt);
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
           FROM cms_velocityload_txn24hrs
          WHERE chr_row_id = j.chr_row_id
            AND chr_primary_card_number = j.chr_primary_card_number
            AND TO_DATE (chr_txn_date, 'yyyymmddhh24miss')
                   BETWEEN TO_DATE (j.chr_txn_date, 'yyyymmddhh24miss')
                       AND TO_DATE (j.chr_txn_date, 'yyyymmddhh24miss') + 1;

         IF cnt > 0
         THEN
            SELECT COUNT (*)
              INTO cnt1
              FROM cms_velocityload_txn24hrs
             WHERE chr_primary_card_number = j.chr_primary_card_number
               AND TO_DATE (chr_txn_date, 'yyyymmddhh24miss')
                      BETWEEN TO_DATE (j.chr_txn_date, 'yyyymmddhh24miss')
                          AND TO_DATE (j.chr_txn_date, 'yyyymmddhh24miss') + 1;

            IF cnt1 > 1
            THEN
               FOR k IN loadtmp1 (j.chr_primary_card_number, j.chr_txn_date)
               LOOP
                  INSERT INTO cms_velocityall_txn24hrs
                       VALUES (j.chr_row_id, j.chr_primary_card_number,
                               j.chr_txn_date);

                  INSERT INTO cms_velocityall_txn24hrs
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

   BEGIN
      FOR l IN loadtmp2
      LOOP
         FOR j IN rep (l.chr_row_id)
         LOOP
            INSERT INTO cms_velocity_txn24hrs
                        (chr_primary_card_number, chr_expiry_date,
                         chr_card_holder_name, chr_address,
                         chr_phone_number, chr_txn_date, chr_balance,
                         chr_load_amount, chr_response_code, chr_term_id,
                         chr_term_owner, chr_term_city_state_country,
                         chr_ins_date
                        )
                 VALUES (j.primary_card_number, j.expiry_date,
                         j.card_holder_name, j.address,
                         j.phone_number, j.txn_date, j.balance,
                         j.load_amount, j.response_code, j.term_id,
                         j.term_owner, j.term_city_state_country,
                         SYSDATE
                        );
         END LOOP;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg := 'EXCP - 3 ' || SQLERRM;
   END;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'MAIN EXCP - ' || SQLERRM;
END;
/

SHOW ERROR