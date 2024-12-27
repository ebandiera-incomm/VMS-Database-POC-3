CREATE OR REPLACE PACKAGE BODY VMSCMS.PKG_VMS_EXTRACTS
AS
--procedure to populate cmf cms_cmf_report table
   PROCEDURE p_cmf_report (
      p_cmf_id     IN       NUMBER,
      p_in_date    IN       DATE,
      p_resp_msg   OUT      VARCHAR2
   )
   AS
      CURSOR c (p_cmf_id NUMBER, acct_no VARCHAR2)
      IS
         SELECT a.*, a.ROWID row_id
           FROM cms_cmf a
          WHERE cmf_id = p_cmf_id AND account_no = acct_no;

      v_curr_bal                cms_cmf.curr_bal%TYPE;
      v_sign                    cms_cmf.curr_bal_sign%TYPE;
      v_exp                     EXCEPTION;
      v_cap_pan_code            cms_appl_pan.cap_pan_code%TYPE;
      v_cap_acct_no             cms_appl_pan.cap_acct_no%TYPE;
      v_avail_bal               cms_cmf.avail_bal_sign%TYPE;
      v_avail_balance           transactionlog.acct_balance%TYPE;
      --Sn Added on 08_Aug_2013
      v_cardstat_date           VARCHAR2 (8);
      v_neg_dt                  VARCHAR2 (8); --080813
      v_neg_dt1                 transactionlog.add_ins_date%TYPE;
      v_lst_txn_dt              VARCHAR2 (8);
      v_neg_amt                 cms_cmf.neg_bal_priniciple_amt%TYPE; --080813
      v_neg_fee_amt             cms_cmf.neg_bal_fee_amt%TYPE; --080813
      v_acct_crdt               VARCHAR2 (8);
      v_ledgerbal              cms_cmf.curr_bal%TYPE;  --080813
      v_availbal               cms_cmf.avail_bal%TYPE;  --080813
      v_acct_stat               VARCHAR2(22);
      v_legdrbal_sign           VARCHAR2 (2);
      v_availbal_sign           VARCHAR2 (2);
      v_card_transfer_no_from   cms_htlst_reisu.chr_pan_code_encr%TYPE;
      v_card_transfer_no_to     cms_htlst_reisu.chr_new_pan_encr%TYPE;
      v_last_reisued_dt         VARCHAR2 (8);
      v_first_load_dt           VARCHAR2 (8);
      v_pan_code                VARCHAR2(90);
      v_first_mail_dt           VARCHAR2 (8);
      v_last_mail_dt            VARCHAR2 (8); 
   --En Added on 08_Aug_2013
   BEGIN
      --EXECUTE IMMEDIATE 'TRUNCATE table vmscms.cms_cmf_rep';
      BEGIN
         INSERT INTO cms_cmf
            SELECT p_cmf_id, TRUNC (p_in_date), cc.*
              FROM (SELECT mm.esign_indi, mm.record_type, mm.acctcrtdt,
                           mm.email_one, mm.unique_program_id, mm.cardno,
                           mm.card_issued_dt, mm.account_expiration_dt,
                           mm.ssn, mm.card_holder_first_name,
                           mm.card_holder_last_name, mm.addr1, mm.addr2,
                           mm.city, mm.state, mm.zip, mm.card_mailing_addr1,
                           mm.card_mailing_addr2, mm.card_mailing_city,
                           mm.card_mailing_state, mm.card_mailing_zip,
                           mm.pri_phone, mm.sec_phone, mm.card_status,
                           mm.card_status_dt, mm.curr_bal, mm.curr_bal_sign,
                           mm.account_created_dt, mm.card_activation_date,
                           mm.card_transfer_no_from, mm.dt_of_neg_bal,
                           mm.neg_bal_priniciple_amt, mm.neg_bal_fee_amt,
                           mm.reload_indicator, mm.account_no,
                           mm.type_of_card, mm.authentication_typ,
                           mm.enroll_no, mm.account_stat, mm.account_stat_dt,
                           mm.account_transfer_no_from,
                           mm.account_transfer_to, mm.dob, mm.avail_bal,
                           mm.avail_bal_sign, mm.pri_card, mm.card_expiry_dt,
                           mm.card_transfer_no_to, mm.first_load_dt,
                           mm.last_txn_dt, mm.last_reisued_dt,
                           mm.crd_first_mailed_dt, mm.crd_last_mailed_dt,
                           mm.no_of_plastics, mm.alt_id_typ, mm.alt_id_val,
                           ROW_NUMBER () OVER (PARTITION BY mm.account_no ORDER BY card_issued_dt DESC)
                                                                        ranks,
                           mm.proxy_number, mm.fee_plan_id, mm.prod_code
                      --Added by Saravanakumar on 30-Jul-2013
                    FROM   (SELECT DISTINCT p_cmf_id, TRUNC (p_in_date),
                                            'N' esign_indi, 'D' record_type,

                                            --Sn Commented on 08_Aug_2013
                                            /*(SELECT TO_CHAR
                                                       (cam_ins_date,
                                                        'MMDDYYYY'
                                                       )
                                               FROM cms_acct_mast
                                              WHERE cam_acct_no = cap_acct_no)*/
                                            NULL acctcrtdt,

                                            --En Commented on 08_Aug_2013
                                            ccm_email_one email_one,
                                            (SELECT cpm_program_id
                                               FROM cms_prod_mast
                                              WHERE cpm_prod_code =
                                                                 cap_prod_code)
                                                            unique_program_id,
                                            cap_pan_code_encr cardno,

                                            --fn_dmaps_main (cap_pan_code_encr) cardno,
                                            TO_CHAR
                                               (cap_pangen_date,
                                                'mmddyyyy'
                                               ) card_issued_dt,
                                            ' ' account_expiration_dt,
                                            ccm_ssn ssn,
                                            ccm_first_name
                                                       card_holder_first_name,
                                            ccm_last_name
                                                        card_holder_last_name,
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

                                            --Sn Changed on 08_Aur_2013
                                            /*(SELECT TO_CHAR
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
                                                    )) */
                                            NULL card_status_dt,

                                            --En Changed on 08_Aur_2013
                                            --Sn Changed on 08_Aur_2013
                                            /*(SELECT TO_CHAR
                                                       (ABS ((cam_ledger_bal
                                                             )),
                                                        '9999999990.99'
                                                       )
                                               FROM cms_acct_mast
                                              WHERE cam_acct_no =
                                                       (SELECT cap_acct_no
                                                          FROM cms_appl_pan
                                                         WHERE cap_pan_code =
                                                                  a.cap_pan_code))*/
                                            NULL curr_bal,
                                                          /*CASE
                                                             WHEN (SELECT TO_CHAR
                                                                             (((cam_ledger_bal
                                                                               )
                                                                              ),
                                                                              '9999999990.99'
                                                                             )
                                                                     FROM cms_acct_mast
                                                                    WHERE cam_acct_no =
                                                                             (SELECT cap_acct_no
                                                                                FROM cms_appl_pan
                                                                               WHERE cap_pan_code =
                                                                                        a.cap_pan_code)) >
                                                                                           0
                                                                THEN '+'
                                                             ELSE '-'
                                                          END */
                                            NULL curr_bal_sign,

                                            --En Changed on 08_Aur_2013
                                            TO_CHAR
                                               (cap_pangen_date,
                                                'MMDDYYYY'
                                               ) account_created_dt,
                                            TO_CHAR
                                               (cap_active_date,
                                                'MMDDYYYY'
                                               ) card_activation_date,

                                             --Sn Commented on 08_Aug_2013
                                            /* (SELECT chr_pan_code_encr
                                                --fn_dmaps_main(chr_pan_code_encr)
                                              FROM   cms_htlst_reisu
                                               WHERE chr_new_pan = cap_pan_code)
                                             */
                                            NULL card_transfer_no_from,

                                             --Sn Commented on 08_Aug_2013
                                             --Sn Commented on 08_Aug_2013
                                            /*(SELECT MIN
                                                       (TO_CHAR (add_ins_date,
                                                                 'MMDDYYYY'
                                                                )
                                                       )
                                               FROM transactionlog x
                                              WHERE customer_card_no =
                                                                a.cap_pan_code
                                                AND acct_balance < 0
                                                AND fn_txndtchk
                                                               (business_date,
                                                                business_time
                                                               ) != 0)*/
                                            NULL dt_of_neg_bal,

                                             --En Commented on 08_Aug_2013
                                             --Sn Commented on 08_Aug_2013
                                            /*(SELECT MIN
                                                       (TO_CHAR
                                                              (amount,
                                                               '9999999990.99'
                                                              )
                                                       )
                                               FROM transactionlog x
                                              WHERE customer_card_no =
                                                                a.cap_pan_code
                                                AND acct_balance < 0
                                                AND add_ins_date =
                                                       (SELECT MIN
                                                                  (add_ins_date
                                                                  )
                                                          FROM transactionlog x
                                                         WHERE customer_card_no =
                                                                  a.cap_pan_code
                                                           AND acct_balance <
                                                                             0
                                                           AND fn_txndtchk
                                                                  (business_date,
                                                                   business_time
                                                                  ) != 0))*/
                                            NULL neg_bal_priniciple_amt,

                                             --En Commented on 08_Aug_2013
                                             --Sn Commented on 08_Aug_2013
                                            /*(SELECT MIN
                                                       (TO_CHAR
                                                              (tranfee_amt,
                                                               '9999999990.99'
                                                              )
                                                       )
                                               FROM transactionlog x
                                              WHERE customer_card_no =
                                                                a.cap_pan_code
                                                AND acct_balance < 0
                                                AND add_ins_date =
                                                       (SELECT MIN
                                                                  (add_ins_date
                                                                  )
                                                          FROM transactionlog x
                                                         WHERE customer_card_no =
                                                                  a.cap_pan_code
                                                           AND acct_balance <
                                                                             0
                                                           AND fn_txndtchk
                                                                  (business_date,
                                                                   business_time
                                                                  ) != 0))*/
                                            NULL neg_bal_fee_amt,

                                            --En Commented on 08_Aug_2013
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
                                                          --Sn Changed on 08_Aur_2013
                                                          /*(SELECT DECODE
                                                                     (cam_stat_code,
                                                                      2, 'Closed Account',
                                                                      3, 'Primary Open Account',
                                                                      8, 'Secondary Open Account'
                                                                     )
                                                             FROM cms_acct_mast
                                                            WHERE cam_acct_no = cap_acct_no)*/
                                            NULL account_stat,

                                            --En Changed on 08_Aur_2013
                                            ' ' account_stat_dt,
                                            ' ' account_transfer_no_from,
                                            ' ' account_transfer_to,
                                            TO_CHAR (ccm_birth_date,
                                                     'MMDDYYYY'
                                                    ) dob,

                                            --Sn Changed on 08_Aur_2013
                                            /*(SELECT TO_CHAR
                                                       (ABS (cam_acct_bal),
                                                        '9999999990.99'
                                                       )
                                               FROM cms_acct_mast
                                              WHERE cam_acct_no =
                                                       (SELECT cap_acct_no
                                                          FROM cms_appl_pan
                                                         WHERE cap_pan_code =
                                                                  a.cap_pan_code))*/
                                            NULL avail_bal,

                                            /*CASE
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
                                            END */
                                            NULL avail_bal_sign,

                                            --En Changed on 08_Aur_2013
                                            DECODE (cap_addon_stat,
                                                    'P', 'T',
                                                    'F'
                                                   ) pri_card,
                                            TO_CHAR
                                               (cap_expry_date,
                                                'mmddyyyy'
                                               ) card_expiry_dt,

                                            --Sn Commented on 08_Aug_2013
                                            /*
                                            (SELECT chr_new_pan_encr
                                               --fn_dmaps_main(chr_new_pan_encr)
                                             FROM   cms_htlst_reisu,
                                                    cms_appl_pan x
                                              WHERE chr_pan_code =
                                                                a.cap_pan_code
                                                AND x.cap_pan_code =
                                                                a.cap_pan_code
                                                AND a.ROWID = x.ROWID
                                                AND ROWNUM < 2)*/
                                            NULL card_transfer_no_to,

                                            --En Commented on 08_Aug_2013
                                            --Sn Commented on 08_Aug_2013
                                            /*TO_CHAR
                                               ((SELECT MIN (cps_ins_date)
                                                   FROM cms_pan_spprt
                                                  WHERE cps_spprt_key IN
                                                            ('INLOAD', 'TOP')
                                                    AND cps_pan_code =
                                                                a.cap_pan_code),
                                                'MMDDYYYY'
                                               ) */
                                            NULL first_load_dt,

                                             --En Commented on 08_Aug_2013
                                             --Sn Commented on 08_Aug_2013
                                            /*TO_CHAR
                                               ((SELECT MAX (add_ins_date)
                                                   FROM transactionlog
                                                  WHERE customer_card_no =
                                                                a.cap_pan_code
                                                    AND fn_txndtchk
                                                               (business_date,
                                                                business_time
                                                               ) != 0),
                                                'MMDDYYYY'
                                               )*/
                                            NULL last_txn_dt,

                                            --En Commented on 08_Aug_2013
                                            --Sn Commented on 08_Aug_2013
                                            /*TO_CHAR
                                               ((SELECT chr_ins_date
                                                   FROM cms_htlst_reisu,
                                                        cms_appl_pan x
                                                  WHERE chr_pan_code =
                                                                a.cap_pan_code
                                                    AND a.ROWID = x.ROWID
                                                    AND ROWNUM < 2),
                                                'MMDDYYYY'
                                               )*/
                                            NULL last_reisued_dt,
                                            --En Commented on 08_Aug_2013
                                            --Sn Commented on 08_Aug_2013
                                            /*TO_CHAR
                                               ((SELECT ccs_ins_date
                                                   FROM cms_cardissuance_status
                                                  WHERE ccs_card_status = 15
                                                    AND ccs_pan_code =
                                                                  cap_pan_code),
                                                'MMDDYYYY'
                                               )*/NULL crd_first_mailed_dt,
                                            --En Commented on 08_Aug_2013
                                            --Sn Commented on 08_Aug_2013
                                            /*TO_CHAR
                                               ((SELECT ccs_lupd_date
                                                   FROM cms_cardissuance_status
                                                  WHERE ccs_card_status = 15
                                                    AND ccs_pan_code =
                                                                  cap_pan_code),
                                                'MMDDYYYY'
                                               )*/NULL crd_last_mailed_dt,
                                            --En Commented on 08_Aug_2013
                                            1 no_of_plastics,
                                            cci_id_issuer alt_id_typ,
                                            cci_id_number alt_id_val,

                                            --Sn Added by Saravanakumar on 30-Jul-2013
                                            cap_proxy_number proxy_number,
                                            NVL
                                               ((SELECT cce_fee_plan
                                                   FROM cms_card_excpfee
                                                  WHERE cce_pan_code =
                                                                  cap_pan_code
                                                    AND cce_inst_code =
                                                                 cap_inst_code
                                                    AND (   (    cce_valid_to IS NOT NULL
                                                             AND TRUNC
                                                                    (p_in_date)
                                                                    BETWEEN cce_valid_from
                                                                        AND cce_valid_to
                                                            )
                                                         OR (    cce_valid_to IS NULL
                                                             AND TRUNC
                                                                    (p_in_date) >=
                                                                    cce_valid_from
                                                            )
                                                        )),
                                                NVL
                                                   ((SELECT cpf_fee_plan
                                                       FROM cms_prodcattype_fees
                                                      WHERE cap_prod_code =
                                                                 cpf_prod_code
                                                        AND cap_card_type =
                                                                 cpf_card_type
                                                        AND cap_inst_code =
                                                                 cpf_inst_code
                                                        AND (   (    cpf_valid_to IS NOT NULL
                                                                 AND TRUNC
                                                                        (p_in_date
                                                                        )
                                                                        BETWEEN TRUNC(cpf_valid_from)
                                                                            AND TRUNC(cpf_valid_to)
                                                                )
                                                             OR (    cpf_valid_to IS NULL
                                                                 AND TRUNC
                                                                        (p_in_date
                                                                        ) >=
                                                                        TRUNC(cpf_valid_from)
                                                                )
                                                            )),
                                                    (SELECT cpf_fee_plan
                                                       FROM cms_prod_fees
                                                      WHERE cap_prod_code =
                                                                 cpf_prod_code
                                                        AND cap_inst_code =
                                                                 cpf_inst_code
                                                        AND (   (    cpf_valid_to IS NOT NULL
                                                                 AND TRUNC
                                                                        (p_in_date
                                                                        )
                                                                        BETWEEN TRUNC(cpf_valid_from)
                                                                            AND TRUNC(cpf_valid_to)
                                                                )
                                                             OR (    cpf_valid_to IS NULL
                                                                 AND TRUNC
                                                                        (p_in_date
                                                                        ) >=
                                                                        TRUNC(cpf_valid_from)
                                                                )
                                                            ))
                                                   )
                                               ) fee_plan_id,
                                            cap_prod_code prod_code
                                       --En Added by Saravanakumar on 30-Jul-2013
                            FROM            cms_appl_pan a,
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
                                        --Modified by Saravanakumar on 07-Jun-3013
                                        AND 0 <
                                               (SELECT COUNT (1)
                                                  FROM cms_appl_pan
                                                 WHERE cap_firsttime_topup =
                                                                           'Y'
                                                   AND cap_acct_no =
                                                                 a.cap_acct_no)
                                        AND cap_pangen_date <=
                                               TO_DATE
                                                  (   TO_CHAR
                                                            (TRUNC (p_in_date),
                                                             'YYYYMMDD'
                                                            )
                                                   || '235959'
                                                  )
                                                   /*AND a.cap_pangen_date =  (select max(cap_pangen_date) from CMS_APPL_PAN
                                                                            where cap_acct_no =  a.cap_acct_no and
                                                                             cap_pangen_date <= TO_DATE (TO_CHAR (TRUNC (p_in_date), 'YYYYMMDD' )|| '235959' ))
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
                                                          END*/
                           ) mm) cc
             WHERE cc.ranks = 1;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                      'ERROR WHILE INSERTION IS ' || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

--Sn Added by Saravanakumar on 27-May-2013 for fetching record which is present in posted transaction and
--not present in CMF file.
      BEGIN
         INSERT INTO cms_cmf
            SELECT p_cmf_id, TRUNC (p_in_date), cc.*
              FROM (SELECT mm.esign_indi, mm.record_type, mm.acctcrtdt,
                           mm.email_one, mm.unique_program_id, mm.cardno,
                           mm.card_issued_dt, mm.account_expiration_dt,
                           mm.ssn, mm.card_holder_first_name,
                           mm.card_holder_last_name, mm.addr1, mm.addr2,
                           mm.city, mm.state, mm.zip, mm.card_mailing_addr1,
                           mm.card_mailing_addr2, mm.card_mailing_city,
                           mm.card_mailing_state, mm.card_mailing_zip,
                           mm.pri_phone, mm.sec_phone, mm.card_status,
                           mm.card_status_dt, mm.curr_bal, mm.curr_bal_sign,
                           mm.account_created_dt, mm.card_activation_date,
                           mm.card_transfer_no_from, mm.dt_of_neg_bal,
                           mm.neg_bal_priniciple_amt, mm.neg_bal_fee_amt,
                           mm.reload_indicator, mm.account_no,
                           mm.type_of_card, mm.authentication_typ,
                           mm.enroll_no, mm.account_stat, mm.account_stat_dt,
                           mm.account_transfer_no_from,
                           mm.account_transfer_to, mm.dob, mm.avail_bal,
                           mm.avail_bal_sign, mm.pri_card, mm.card_expiry_dt,
                           mm.card_transfer_no_to, mm.first_load_dt,
                           mm.last_txn_dt, mm.last_reisued_dt,
                           mm.crd_first_mailed_dt, mm.crd_last_mailed_dt,
                           mm.no_of_plastics, mm.alt_id_typ, mm.alt_id_val,
                           ROW_NUMBER () OVER (PARTITION BY mm.account_no ORDER BY card_issued_dt DESC)
                                                                        ranks,
                           mm.proxy_number, mm.fee_plan_id, mm.prod_code
                      --Added by Saravanakumar on 30-Jul-2013
                    FROM   (SELECT DISTINCT p_cmf_id, TRUNC (p_in_date),
                                            'N' esign_indi, 'D' record_type,

                                            --Sn Commented on 08_Aug_2013
                                            /*(SELECT TO_CHAR
                                                       (cam_ins_date,
                                                        'MMDDYYYY'
                                                       )
                                               FROM cms_acct_mast
                                              WHERE cam_acct_no = cap_acct_no)*/
                                            NULL acctcrtdt,

                                            --En Commented on 08_Aug_2013
                                            ccm_email_one email_one,
                                            (SELECT cpm_program_id
                                               FROM cms_prod_mast
                                              WHERE cpm_prod_code =
                                                                 cap_prod_code)
                                                            unique_program_id,
                                            cap_pan_code_encr cardno,

                                            --fn_dmaps_main (cap_pan_code_encr) cardno,
                                            TO_CHAR
                                               (cap_pangen_date,
                                                'mmddyyyy'
                                               ) card_issued_dt,
                                            ' ' account_expiration_dt,
                                            ccm_ssn ssn,
                                            ccm_first_name
                                                       card_holder_first_name,
                                            ccm_last_name
                                                        card_holder_last_name,
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

                                            --Sn Commented on 08_Aug_2013
                                            /*
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
                                                    )) */
                                            NULL card_status_dt,

                                            --En Commented on 08_Aug_2013
                                            --Sn Commented on 08_Aug_2013
                                             /*(SELECT TO_CHAR
                                                        (ABS ((cam_ledger_bal
                                                              )),
                                                         '9999999990.99'
                                                        )
                                                FROM cms_acct_mast
                                               WHERE cam_acct_no =
                                                        (SELECT cap_acct_no
                                                           FROM cms_appl_pan
                                                          WHERE cap_pan_code =
                                                                   a.cap_pan_code))*/
                                            NULL curr_bal,
                                                          /*CASE
                                                             WHEN (SELECT TO_CHAR
                                                                             (((cam_ledger_bal
                                                                               )
                                                                              ),
                                                                              '9999999990.99'
                                                                             )
                                                                     FROM cms_acct_mast
                                                                    WHERE cam_acct_no =
                                                                             (SELECT cap_acct_no
                                                                                FROM cms_appl_pan
                                                                               WHERE cap_pan_code =
                                                                                        a.cap_pan_code)) >
                                                                                           0
                                                                THEN '+'
                                                             ELSE '-'
                                                          END*/
                                            NULL curr_bal_sign,

                                            --En Commented on 08_Aug_2013
                                            TO_CHAR
                                               (cap_pangen_date,
                                                'MMDDYYYY'
                                               ) account_created_dt,
                                            TO_CHAR
                                               (cap_active_date,
                                                'MMDDYYYY'
                                               ) card_activation_date,

                                             --Sn Commented on 08_Aug_2013
                                            /*(SELECT chr_pan_code_encr
                                               --fn_dmaps_main(chr_pan_code_encr)
                                             FROM   cms_htlst_reisu
                                              WHERE chr_new_pan = cap_pan_code)*/
                                            NULL card_transfer_no_from,

                                            --En Commented on 08_Aug_2013
                                            --Sn Commented on 08_Aug_2013
                                            /*
                                            (SELECT MIN
                                                       (TO_CHAR (add_ins_date,
                                                                 'MMDDYYYY'
                                                                )
                                                       )
                                               FROM transactionlog x
                                              WHERE customer_card_no =
                                                                a.cap_pan_code
                                                AND acct_balance < 0
                                                AND fn_txndtchk
                                                               (business_date,
                                                                business_time
                                                               ) != 0)*/
                                            NULL dt_of_neg_bal,

                                            --En Commented on 08_Aug_2013
                                            --Sn Commented on 08_Aug_2013
                                            /*(SELECT MIN
                                                       (TO_CHAR
                                                              (amount,
                                                               '9999999990.99'
                                                              )
                                                       )
                                               FROM transactionlog x
                                              WHERE customer_card_no =
                                                                a.cap_pan_code
                                                AND acct_balance < 0
                                                AND add_ins_date =
                                                       (SELECT MIN
                                                                  (add_ins_date
                                                                  )
                                                          FROM transactionlog x
                                                         WHERE customer_card_no =
                                                                  a.cap_pan_code
                                                           AND acct_balance <
                                                                             0
                                                           AND fn_txndtchk
                                                                  (business_date,
                                                                   business_time
                                                                  ) != 0))*/
                                            NULL neg_bal_priniciple_amt,

                                            --En Commented on 08_Aug_2013
                                            --Sn Commented on 08_Aug_2013
                                            /*(SELECT MIN
                                                       (TO_CHAR
                                                              (tranfee_amt,
                                                               '9999999990.99'
                                                              )
                                                       )
                                               FROM transactionlog x
                                              WHERE customer_card_no =
                                                                a.cap_pan_code
                                                AND acct_balance < 0
                                                AND add_ins_date =
                                                       (SELECT MIN
                                                                  (add_ins_date
                                                                  )
                                                          FROM transactionlog x
                                                         WHERE customer_card_no =
                                                                  a.cap_pan_code
                                                           AND acct_balance <
                                                                             0
                                                           AND fn_txndtchk
                                                                  (business_date,
                                                                   business_time
                                                                  ) != 0))*/
                                            NULL neg_bal_fee_amt,

                                            --En Commented on 08_Aug_2013
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
                                                          --Sn Commented on 08_Aug_2013
                                                          /*(SELECT DECODE
                                                                     (cam_stat_code,
                                                                      2, 'Closed Account',
                                                                      3, 'Primary Open Account',
                                                                      8, 'Secondary Open Account'
                                                                     )
                                                             FROM cms_acct_mast
                                                            WHERE cam_acct_no = cap_acct_no)*/
                                            NULL account_stat,

                                            --Sn Commented on 08_Aug_2013
                                            ' ' account_stat_dt,
                                            ' ' account_transfer_no_from,
                                            ' ' account_transfer_to,
                                            TO_CHAR (ccm_birth_date,
                                                     'MMDDYYYY'
                                                    ) dob,

                                            --Sn Commented on 08_Aug_2013
                                            /*(SELECT TO_CHAR
                                                       (ABS (cam_acct_bal),
                                                        '9999999990.99'
                                                       )
                                               FROM cms_acct_mast
                                              WHERE cam_acct_no =
                                                       (SELECT cap_acct_no
                                                          FROM cms_appl_pan
                                                         WHERE cap_pan_code =
                                                                  a.cap_pan_code))*/
                                            NULL avail_bal,

                                            /*CASE
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
                                            END*/
                                            NULL avail_bal_sign,

                                            --En Commented on 08_Aug_2013
                                            DECODE (cap_addon_stat,
                                                    'P', 'T',
                                                    'F'
                                                   ) pri_card,
                                            TO_CHAR
                                               (cap_expry_date,
                                                'mmddyyyy'
                                               ) card_expiry_dt,

                                             --Sn Commented on 08_Aug_2013
                                            /*(SELECT chr_new_pan_encr
                                               --fn_dmaps_main(chr_new_pan_encr)
                                             FROM   cms_htlst_reisu,
                                                    cms_appl_pan x
                                              WHERE chr_pan_code =
                                                                a.cap_pan_code
                                                AND x.cap_pan_code =
                                                                a.cap_pan_code
                                                AND a.ROWID = x.ROWID
                                                AND ROWNUM < 2)*/
                                            NULL card_transfer_no_to,

                                            --En Commented on 08_Aug_2013
                                            --Sn Commented on 08_Aug_2013
                                            /*TO_CHAR
                                               ((SELECT MIN (cps_ins_date)
                                                   FROM cms_pan_spprt
                                                  WHERE cps_spprt_key IN
                                                            ('INLOAD', 'TOP')
                                                    AND cps_pan_code =
                                                                a.cap_pan_code),
                                                'MMDDYYYY'
                                               ) */
                                            NULL first_load_dt,

                                            --En Commented on 08_Aug_2013
                                            --Sn Commented on 08_Aug_2013
                                            /*TO_CHAR
                                               ((SELECT MAX (add_ins_date)
                                                   FROM transactionlog
                                                  WHERE customer_card_no =
                                                                a.cap_pan_code
                                                    AND fn_txndtchk
                                                               (business_date,
                                                                business_time
                                                               ) != 0),
                                                'MMDDYYYY'
                                               ) */
                                            NULL last_txn_dt,

                                            --En Commented on 08_Aug_2013
                                            --Sn Commented on 08_Aug_2013
                                            /*TO_CHAR
                                               ((SELECT chr_ins_date
                                                   FROM cms_htlst_reisu,
                                                        cms_appl_pan x
                                                  WHERE chr_pan_code =
                                                                a.cap_pan_code
                                                    AND a.ROWID = x.ROWID
                                                    AND ROWNUM < 2),
                                                'MMDDYYYY'
                                               )*/
                                            NULL last_reisued_dt,
                                            --En Commented on 08_Aug_2013
                                            --Sn Commented on 08_Aug_2013
                                            /*TO_CHAR
                                               ((SELECT ccs_ins_date
                                                   FROM cms_cardissuance_status
                                                  WHERE ccs_card_status = 15
                                                    AND ccs_pan_code =
                                                                  cap_pan_code),
                                                'MMDDYYYY'
                                               ) */NULL crd_first_mailed_dt,
                                            --En Commented on 08_Aug_2013
                                            --Sn Commented on 08_Aug_2013
                                            /*TO_CHAR
                                               ((SELECT ccs_lupd_date
                                                   FROM cms_cardissuance_status
                                                  WHERE ccs_card_status = 15
                                                    AND ccs_pan_code =
                                                                  cap_pan_code),
                                                'MMDDYYYY'
                                               )*/NULL crd_last_mailed_dt,
                                            1 no_of_plastics,
                                            cci_id_issuer alt_id_typ,
                                            cci_id_number alt_id_val,

                                            --Sn Added by Saravanakumar on 30-Jul-2013
                                            cap_proxy_number proxy_number,
                                            NVL
                                               ((SELECT cce_fee_plan
                                                   FROM cms_card_excpfee
                                                  WHERE cce_pan_code =
                                                                  cap_pan_code
                                                    AND cce_inst_code =
                                                                 cap_inst_code
                                                    AND (   (    cce_valid_to IS NOT NULL
                                                             AND TRUNC
                                                                    (p_in_date)
                                                                    BETWEEN TRUNC(cce_valid_from)
                                                                        AND TRUNC(cce_valid_to)
                                                            )
                                                         OR (    cce_valid_to IS NULL
                                                             AND TRUNC
                                                                    (p_in_date) >=
                                                                    TRUNC(cce_valid_from)
                                                            )
                                                        )),
                                                NVL
                                                   ((SELECT cpf_fee_plan
                                                       FROM cms_prodcattype_fees
                                                      WHERE cap_prod_code =
                                                                 cpf_prod_code
                                                        AND cap_card_type =
                                                                 cpf_card_type
                                                        AND cap_inst_code =
                                                                 cpf_inst_code
                                                        AND (   (    cpf_valid_to IS NOT NULL
                                                                 AND TRUNC
                                                                        (p_in_date
                                                                        )
                                                                        BETWEEN TRUNC(cpf_valid_from)
                                                                            AND TRUNC(cpf_valid_to)
                                                                )
                                                             OR (    cpf_valid_to IS NULL
                                                                 AND TRUNC
                                                                        (p_in_date
                                                                        ) >=
                                                                        TRUNC(cpf_valid_from)
                                                                )
                                                            ) ),
                                                    (SELECT cpf_fee_plan
                                                       FROM cms_prod_fees
                                                      WHERE cap_prod_code =
                                                                 cpf_prod_code
                                                        AND cap_inst_code =
                                                                 cpf_inst_code
                                                        AND (   (    cpf_valid_to IS NOT NULL
                                                                 AND TRUNC
                                                                        (p_in_date
                                                                        )
                                                                        BETWEEN TRUNC(cpf_valid_from)
                                                                            AND TRUNC(cpf_valid_to)
                                                                )
                                                             OR (    cpf_valid_to IS NULL
                                                                 AND TRUNC
                                                                        (p_in_date
                                                                        ) >=
                                                                        TRUNC(cpf_valid_from)
                                                                )
                                                            ))
                                                   )
                                               ) fee_plan_id,
                                            cap_prod_code prod_code
                                       --EN Added by Saravanakumar on 30-Jul-2013
                            FROM            cms_appl_pan a,
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
                                        AND cap_pangen_date <=
                                               TO_DATE
                                                  (   TO_CHAR
                                                            (TRUNC (p_in_date),
                                                             'YYYYMMDD'
                                                            )
                                                   || '235959'
                                                  )
                                        /*AND a.cap_pangen_date =  (select max(cap_pangen_date) from CMS_APPL_PAN
                                                                 where cap_acct_no =  a.cap_acct_no and
                                                                  cap_pangen_date <= TO_DATE (TO_CHAR (TRUNC (p_in_date), 'YYYYMMDD' )|| '235959' ))*/
                                        AND cap_acct_no IN (
                                               SELECT DISTINCT csl_acct_no
                                                          FROM cms_statements_log
                                                         WHERE csl_inst_code =
                                                                             1
                                                           /* SN: 20130618: COMMENTED TO CONSIDER POS PREAUTH
                                                           AND (( csl_delivery_channel IN ('02')
                                                           AND csl_txn_code NOT IN ('11'))
                                                           OR csl_delivery_channel != '02')
                                                           */ -- EN: 20130618: COMMENTED TO CONSIDER POS PREAUTH
                                                           AND csl_ins_date <=
                                                                  TO_DATE
                                                                     (   TO_CHAR
                                                                            (TRUNC
                                                                                (p_in_date
                                                                                ),
                                                                             'YYYYMMDD'
                                                                            )
                                                                      || '235959'
                                                                     )
                                                           AND csl_trans_amount <>
                                                                             0
                                                           AND csl_trans_amount IS NOT NULL
                                               MINUS
                                               SELECT account_no
                                                 FROM cms_cmf
                                                WHERE cmf_date
                                                         BETWEEN TO_DATE
                                                                   (   TO_CHAR
                                                                          (TRUNC
                                                                              (p_in_date
                                                                              ),
                                                                           'YYYYMMDD'
                                                                          )
                                                                    || '000000'
                                                                   )
                                                             AND TO_DATE
                                                                   (   TO_CHAR
                                                                          (TRUNC
                                                                              (p_in_date
                                                                              ),
                                                                           'YYYYMMDD'
                                                                          )
                                                                    || '235959'
                                                                   )
                                                  AND cmf_id = p_cmf_id)) mm) cc
             WHERE cc.ranks = 1;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                     'ERROR WHILE INSERTION IS 2' || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

--En Added by Saravanakumar on 27-May-2013 for fetching record which is present in posted transaction and
--not present in CMF file.

      ----------------------------------------------------------------------------
      --Sn Added on 08_Aug_2013
      ----------------------------------------------------------------------------
      FOR k IN (SELECT b.*, ROWID row_id
                  FROM cms_cmf b
                 WHERE cmf_id = p_cmf_id)
      LOOP

         v_pan_code:=gethash(fn_dmaps_main(k.cardno));

         BEGIN
            SELECT TO_CHAR (cam_ins_date, 'MMDDYYYY'),
                  cam_ledger_bal,cam_acct_bal,  --080813
                   DECODE (cam_stat_code,
                           2, 'Closed Account',
                           3, 'Primary Open Account',
                           8, 'Secondary Open Account'
                          )
              INTO v_acct_crdt,
                   v_ledgerbal,
                   v_availbal,
                   v_acct_stat
              FROM cms_acct_mast
             WHERE cam_inst_code = 1 AND cam_acct_no = k.account_no;

            IF v_ledgerbal > 0
            THEN
               v_legdrbal_sign := '+';
            ELSE
               v_legdrbal_sign := '-';
            END IF;

            IF v_availbal > 0
            THEN
               v_availbal_sign := '+';
            ELSE
               v_availbal_sign := '-';
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               NULL;
            WHEN OTHERS THEN
               p_resp_msg := 'ERROR WHILE SELECTING DETAILS FOR ACCOUNT-' || k.account_no || ' IS ' || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;

         BEGIN  --080813
            SELECT chr_new_pan_encr,
                   TO_CHAR (chr_ins_date, 'MMDDYYYY')
              INTO v_card_transfer_no_to,
                   v_last_reisued_dt
              FROM cms_htlst_reisu
             WHERE chr_inst_code = 1 AND chr_pan_code =v_pan_code
                   AND ROWNUM < 2;
          EXCEPTION  --080813
            WHEN NO_DATA_FOUND THEN
               NULL;
            WHEN OTHERS THEN
               p_resp_msg := 'ERROR WHILE SELECTING REISSUE DETAILS FOR ACCOUNT-' || k.account_no || ' IS ' || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;  --080813
         
         BEGIN  --080813
            SELECT chr_pan_code_encr
              INTO v_card_transfer_no_from
              FROM cms_htlst_reisu
             WHERE chr_inst_code = 1 AND chr_new_pan =v_pan_code;                 
         EXCEPTION  
            WHEN NO_DATA_FOUND THEN
               NULL;
            WHEN OTHERS THEN
               p_resp_msg := 'ERROR WHILE SELECTING REISSUE DETAILS FOR ACCOUNT-' || k.account_no || ' IS ' || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;--080813

         BEGIN
            SELECT TO_CHAR (MAX (add_ins_date), 'MMDDYYYY')
              INTO v_cardstat_date
              FROM transactionlog
             WHERE customer_card_no = v_pan_code
            AND ((delivery_channel = '04'AND txn_code IN ('68', '69', '75', '76', '77', '83'))
                 OR (delivery_channel = '06' AND txn_code IN ('01', '03'))
                 OR (delivery_channel = '07' AND txn_code IN ('05', '06'))
                 OR (delivery_channel = '10' AND txn_code IN ('05', '06', '11'))
                );

            SELECT MIN (to_char(add_ins_date,'MMDDYYYY')),MIN(add_ins_date) --080813
              INTO v_neg_dt,v_neg_dt1
              FROM transactionlog
             WHERE customer_card_no = v_pan_code
               AND acct_balance < 0
               AND fn_txndtchk (business_date, business_time) != 0;

            SELECT TO_CHAR (MAX (add_ins_date), 'MMDDYYYY')
              INTO v_lst_txn_dt
              FROM transactionlog
             WHERE customer_card_no = v_pan_code
               AND fn_txndtchk (business_date, business_time) != 0;

            SELECT MIN (TO_CHAR (amount, '9999999990.99')),
                   MIN (TO_CHAR (tranfee_amt, '9999999990.99'))
              INTO v_neg_amt,
                   v_neg_fee_amt
              FROM transactionlog x
             WHERE customer_card_no = v_pan_code
               AND acct_balance < 0
               AND add_ins_date = v_neg_dt1;
         EXCEPTION
            WHEN OTHERS THEN
               p_resp_msg := 'ERROR WHILE SELECTING TRANSACTION DETAILS FOR ACCOUNT-' || k.account_no || ' IS ' || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;

         BEGIN
            SELECT TO_CHAR (MIN (cps_ins_date), 'MMDDYYYY')
              INTO v_first_load_dt
              FROM cms_pan_spprt
             WHERE cps_spprt_key IN ('INLOAD', 'TOP')
               AND cps_pan_code = v_pan_code;
         EXCEPTION
            WHEN OTHERS THEN
               p_resp_msg := 'ERROR WHILE SELECTING FIRST LOAD DATE FOR ACCOUNT-' || k.account_no || ' IS ' || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;

        BEGIN
           SELECT TO_CHAR (ccs_ins_date, 'MMDDYYYY'),TO_CHAR (ccs_lupd_date, 'MMDDYYYY')
             INTO v_first_mail_dt,v_last_mail_dt
             FROM cms_cardissuance_status
            WHERE ccs_card_status = 15 AND ccs_pan_code = v_pan_code;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
              NULL;
           WHEN OTHERS THEN
              p_resp_msg := 'ERROR WHILE SELECTING ISSUENCE DETAILS FOR ACCOUNT-' || k.account_no || ' IS ' || SUBSTR (SQLERRM, 1, 200);
              RETURN;
        END;

         BEGIN
            UPDATE cms_cmf
               SET curr_bal = TO_CHAR (ABS (v_ledgerbal), '9999999990.99'),  --080813
                   curr_bal_sign = v_legdrbal_sign,
                   avail_bal =TO_CHAR (ABS (v_availbal), '9999999990.99'),   --080813
                   avail_bal_sign = v_availbal_sign,
                   acctcrtdt = v_acct_crdt,  --080813
                   account_stat = v_acct_stat,
                   card_status_dt = v_cardstat_date,
                   dt_of_neg_bal = v_neg_dt,  --080813
                   neg_bal_priniciple_amt = v_neg_amt,
                   neg_bal_fee_amt = v_neg_fee_amt,
                   last_txn_dt = v_lst_txn_dt,
                   card_transfer_no_from = v_card_transfer_no_from,
                   card_transfer_no_to = v_card_transfer_no_to,
                   first_load_dt = v_first_load_dt,
                   last_reisued_dt = v_last_reisued_dt,
                   crd_first_mailed_dt=v_first_mail_dt,
                   crd_last_mailed_dt=v_last_mail_dt
             WHERE ROWID = k.row_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'ERROR WHILE UPDATING CMF FOR ACCOUNT-'
                  || k.account_no
                  || ' IS '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;

        --Sn Added by Saravanakumar on 26-Dec-2013
        v_ledgerbal :=null;
        v_legdrbal_sign :=null;
        v_availbal  :=null;
        v_availbal_sign :=null;
        v_acct_crdt  :=null;
        v_acct_stat :=null;
        v_cardstat_date :=null;
        v_neg_dt :=null;
        v_neg_amt :=null;
        v_neg_fee_amt :=null;
        v_lst_txn_dt :=null;
        v_card_transfer_no_from :=null;
        v_card_transfer_no_to :=null;
        v_first_load_dt :=null;
        v_last_reisued_dt :=null;
        v_first_mail_dt :=null;
        v_last_mail_dt :=null;
        --En Added by Saravanakumar on 26-Dec-2013
      END LOOP;
      commit;
     ----------------------------------------------------------------------------
     --En Added on 08_Aug_2013
     ----------------------------------------------------------------------------

      FOR j IN (SELECT cam_acct_no
                  FROM cms_acct_mast
                 --the date should be for the date we are creating CMF file?
                WHERE  cam_lupd_date >
                          TO_DATE (   TO_CHAR (TRUNC (p_in_date), 'YYYYMMDD')
                                   || ' 23:59:59'
                                  ))
      --WHERE cam_lupd_date > TO_DATE ( p_in_date ||' 23:59:59', 'DD-MON-YYYY HH24:MI:SS'))
      LOOP
         BEGIN
            --DBMS_OUTPUT.PUT_LINE(j.cam_acct_no) ;
            FOR i IN c (p_cmf_id, j.cam_acct_no)
            LOOP
               BEGIN
                  --DBMS_OUTPUT.PUT_LINE('2222' || j.cam_acct_no) ;
                  SELECT   (SELECT cam_ledger_bal
                              FROM cms_acct_mast
                             WHERE cam_acct_no = j.cam_acct_no)
                         - mm.total_transaction
                    INTO v_curr_bal
                    FROM (SELECT TO_CHAR
                                    (NVL (SUM (DECODE (csl_trans_type,
                                                       'CR', csl_trans_amount,
                                                       'DR', -csl_trans_amount
                                                      )
                                              ),
                                          0
                                         ),
                                     '9999999990.99'
                                    ) total_transaction
                            FROM cms_statements_log
                           WHERE csl_acct_no = j.cam_acct_no
                                 -- SN: COMMENTED TO CONSIDER SPENDING ACCOUNT
                             -- SN: COMMENTED TO CONSIDER SPENDING ACCOUNT
                             /*csl_pan_no IN (
                                               SELECT cap_pan_code
                                                 FROM cms_appl_pan
                                                WHERE cap_acct_no =
                                                                   j.cam_acct_no)
                                                                   */ -- EN: COMMENTED TO CONSIDER SPENDING ACCOUNT
                             AND TO_DATE (TO_CHAR (csl_ins_date,
                                                   'YYYYMMDD HH24:MI:SS'
                                                  )
                                         ) >
                                    TO_DATE (   TO_CHAR (TRUNC (p_in_date),
                                                         'YYYYMMDD'
                                                        )
                                             || ' 23:59:59'
                                            )) mm;

                  /*
                     SELECT   i.curr_bal
                            - TO_CHAR (NVL (SUM (DECODE (csl_trans_type,
                                                         'CR', csl_trans_amount,
                                                         'DR', -csl_trans_amount
                                                        )
                                                ),
                                            0
                                           ),
                                       '9999999990.99'
                                      )
                       INTO v_curr_bal
                       FROM cms_statements_log
                       WHERE csl_pan_no IN (SELECT cap_pan_code
                                             FROM cms_appl_pan
                                            WHERE cap_acct_no = j.cam_acct_no)
                       --AND csl_ins_date >TO_DATE ( to_char(trunc(p_in_date)) ||' 23:59:59', 'DD-MON-YYYY HH24:MI:SS');
                       and to_date(to_char(csl_ins_date,'YYYYMMDD HH24:MI:SS')) > to_date(to_char(trunc(p_in_date),'YYYYMMDD')||' 23:59:59');

                        */
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
                                  AND add_ins_date <= p_in_date
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

                  UPDATE cms_cmf
                     SET                         --curr_bal = abs(v_curr_bal),
                        curr_bal = TO_CHAR (ABS (v_curr_bal), '9999999990.99'),
                        -- Formating Added by FSS on 10-APR-2013
                        curr_bal_sign = v_sign,
                        --avail_bal = abs(v_avail_balance),
                        avail_bal =
                              TO_CHAR (ABS (v_avail_balance), '9999999990.99'),
                        -- Formating Added by FSS on 10-APR-2013
                        avail_bal_sign = v_avail_bal
                   WHERE ROWID = i.row_id;
               --WHERE ACCOUNT_NO = j.cam_acct_no;
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

      p_resp_msg := 'TRUE';
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_msg := 'Error from main ' || SUBSTR (SQLERRM, 1, 200);
   END p_cmf_report;

--generate CMF
   PROCEDURE p_cmf (p_in_directory VARCHAR2, p_cmf_id NUMBER, p_in_date DATE)
   AS
      l_file            UTL_FILE.file_type;
      l_file_name       VARCHAR2 (1000);
      l_total_records   NUMBER             := 0;
      l_eod             DATE;

      CURSOR c
      IS
         SELECT RPAD (NVL (TO_CHAR (record_type), ' '), 1, ' ') record_type,
                RPAD (NVL (TO_CHAR (unique_program_id), ' '),
                      15,
                      ' '
                     ) unique_program_id,
                RPAD (NVL (TO_CHAR (fn_dmaps_main (cardno)), ' '),
                      30,
                      ' '
                     ) cardno,
                RPAD (NVL (TO_CHAR (card_issued_dt), ' '),
                      8,
                      ' '
                     ) card_issued_dt,
                RPAD
                   (NVL (TO_CHAR (account_expiration_dt), ' '),
                    8,
                    ' '
                   ) account_expiration_dt,
                RPAD (NVL (TO_CHAR (ssn), ' '), 9, ' ') ssn,
                RPAD
                   (NVL (TO_CHAR (card_holder_first_name), ' '),
                    50,
                    ' '
                   ) card_holder_first_name,
                RPAD
                   (NVL (TO_CHAR (card_holder_last_name), ' '),
                    50,
                    ' '
                   ) card_holder_last_name,
                RPAD (NVL (TO_CHAR (addr1), ' '), 100, ' ') addr1,
                RPAD (NVL (TO_CHAR (addr2), ' '), 100, ' ') addr2,
                RPAD (NVL (TO_CHAR (city), ' '), 50, ' ') city,
                RPAD (NVL (TO_CHAR (state), ' '), 2, ' ') state,
                RPAD (NVL (TO_CHAR (zip), ' '), 9, ' ') zip,
                RPAD (NVL (TO_CHAR (pri_phone), ' '), 10, ' ') pri_phone,
                RPAD (NVL (TO_CHAR (sec_phone), ' '), 10, ' ') sec_phone,
                RPAD (NVL (TO_CHAR (card_status), ' '), 50, ' ') card_status,
                RPAD (NVL (TO_CHAR (card_status_dt), ' '),
                      8,
                      ' '
                     ) card_status_dt,
                RPAD (NVL (TRIM (curr_bal), ' '), 13, ' ') curr_bal,
                RPAD (NVL (TO_CHAR (curr_bal_sign), ' '),
                      1,
                      ' '
                     ) curr_bal_sign,
                RPAD (NVL (TO_CHAR (account_created_dt), ' '),
                      8,
                      ' '
                     ) account_created_dt,
                RPAD
                   (NVL (TO_CHAR (card_activation_date), ' '),
                    8,
                    ' '
                   ) card_activation_date,
                RPAD
                   (NVL (TO_CHAR (fn_dmaps_main (card_transfer_no_from)), ' '),
                    30,
                    ' '
                   ) card_transfer_no_from,
                RPAD (NVL (TO_CHAR (dt_of_neg_bal), ' '),
                      8,
                      ' '
                     ) dt_of_neg_bal,
                RPAD
                   (NVL (TRIM (neg_bal_priniciple_amt), ' '),
                    13,
                    ' '
                   ) neg_bal_priniciple_amt,
                RPAD (NVL (TRIM (neg_bal_fee_amt), ' '),
                      13,
                      ' '
                     ) neg_bal_fee_amt,
                RPAD (NVL (TO_CHAR (reload_indicator), ' '),
                      1,
                      ' '
                     ) reload_indicator,
                RPAD (NVL (TO_CHAR (account_no), ' '), 30, ' ') account_no,
                RPAD (NVL (TO_CHAR (type_of_card), ' '), 25,
                      ' ') type_of_card,
                RPAD (NVL (TO_CHAR (authentication_typ), ' '),
                      3,
                      ' '
                     ) authentication_typ,
                RPAD (NVL (TO_CHAR (enroll_no), ' '), 16, ' ') enroll_no,
                RPAD (NVL (TO_CHAR (account_stat), ' '), 50,
                      ' ') account_stat,
                RPAD (NVL (TO_CHAR (account_stat_dt), ' '),
                      8,
                      ' '
                     ) account_stat_dt,
                RPAD
                   (NVL (TO_CHAR (account_transfer_no_from), ' '),
                    30,
                    ' '
                   ) account_transfer_no_from,
                RPAD (NVL (TO_CHAR (account_transfer_to), ' '),
                      30,
                      ' '
                     ) account_transfer_to,
                RPAD (NVL (TO_CHAR (dob), ' '), 8, ' ') dob,
                RPAD (NVL (TRIM (avail_bal), ' '), 13, ' ') avail_bal,
                RPAD (NVL (TO_CHAR (avail_bal_sign), ' '),
                      1,
                      ' '
                     ) avail_bal_sign,
                RPAD (NVL (TO_CHAR (pri_card), ' '), 1, ' ') pri_card,
                RPAD (NVL (TO_CHAR (card_expiry_dt), ' '),
                      8,
                      ' '
                     ) card_expiry_dt,
                RPAD
                   (NVL (TO_CHAR (fn_dmaps_main (card_transfer_no_to)), ' '),
                    30,
                    ' '
                   ) card_transfer_no_to,
                RPAD (NVL (TO_CHAR (first_load_dt), ' '),
                      8,
                      ' '
                     ) first_load_dt,
                RPAD (NVL (TO_CHAR (last_txn_dt), ' '), 8, ' ') last_txn_dt,
                RPAD (NVL (TO_CHAR (last_reisued_dt), ' '),
                      8,
                      ' '
                     ) last_reisued_dt,
                RPAD (NVL (TO_CHAR (crd_first_mailed_dt), ' '),
                      8,
                      ' '
                     ) crd_first_mailed_dt,
                RPAD (NVL (TO_CHAR (crd_last_mailed_dt), ' '),
                      8,
                      ' '
                     ) crd_last_mailed_dt,
                RPAD (NVL (TO_CHAR (no_of_plastics), ' '),
                      2,
                      ' '
                     ) no_of_plastics,
                RPAD (NVL (TO_CHAR (email_one), ' '), 20, ' ') email_one,
                RPAD (NVL (TO_CHAR (card_mailing_addr1), ' '),
                      100,
                      ' '
                     ) card_mailing_addr1,
                RPAD (NVL (TO_CHAR (card_mailing_addr2), ' '),
                      100,
                      ' '
                     ) card_mailing_addr2,
                RPAD (NVL (TO_CHAR (card_mailing_city), ' '),
                      50,
                      ' '
                     ) card_mailing_city,
                RPAD (NVL (TO_CHAR (card_mailing_state), ' '),
                      2,
                      ' '
                     ) card_mailing_state,
                RPAD (NVL (TO_CHAR (card_mailing_zip), ' '),
                      9,
                      ' '
                     ) card_mailing_zip,
                RPAD (NVL (TO_CHAR (esign_indi), ' '), 2, ' ') esign_indi,
                RPAD (NVL (TO_CHAR ('          '), ' '),
                      10,
                      ' '
                     ) esign_oin_oout_dt,
                CHR (13) || CHR (10) end_of_line
           FROM cms_cmf
          --Where TO_DATE(ACCTCRTDT, 'MMDDYYYY') <=TO_DATE (p_in_date , 'MMDDYYYY');
         WHERE  cmf_id = p_cmf_id 
            AND prod_code <> 'VP75';--Added by Saravanakumar on 20-Dec-2013
   BEGIN
      --if p_in_date is not null then
        --l_eod := p_in_date-1;
      --else
        --l_eod := sysdate-1;
      --end if;
      --set End of Date to today - 1 as this job is executed at 1 AM.
      --p_in_date should always be EOD+1
      l_eod := NVL (p_in_date, SYSDATE - 1);
      --generate file name
      l_file_name := TO_CHAR (l_eod, 'MMDDYYYY') || 'CustomerMaster.txt';
      --open file
      l_file :=
         UTL_FILE.fopen (LOCATION          => p_in_directory,
                         filename          => l_file_name,
                         open_mode         => 'W',
                         max_linesize      => 4000
                        );
      --write header information
      UTL_FILE.put (l_file, 'H');
      UTL_FILE.put (l_file, 'HEADER');
      UTL_FILE.put (l_file, RPAD ('INCOMM', 50, ' '));
      UTL_FILE.put (l_file, RPAD ('CUSTOMER', 50, ' '));
      UTL_FILE.put (l_file, TO_CHAR (NVL (p_in_date, SYSDATE), 'MMDDYYYY'));
      UTL_FILE.put (l_file, TO_CHAR (l_eod, 'MMDDYYYY'));
      UTL_FILE.put (l_file, CHR (13) || CHR (10));
      --flush file to disk
      UTL_FILE.fflush (l_file);

      --write records
      FOR cur_data IN c
      LOOP
         l_total_records := l_total_records + 1;
         --dbms_output.put_line('6');
         UTL_FILE.put (l_file, cur_data.record_type);
         UTL_FILE.put (l_file, cur_data.unique_program_id);
         UTL_FILE.put (l_file, cur_data.cardno);
         UTL_FILE.put (l_file, cur_data.card_issued_dt);
         UTL_FILE.put (l_file, cur_data.account_expiration_dt);
         UTL_FILE.put (l_file, cur_data.ssn);
         UTL_FILE.put (l_file, cur_data.card_holder_first_name);
         UTL_FILE.put (l_file, cur_data.card_holder_last_name);
         UTL_FILE.put (l_file, cur_data.addr1);
         UTL_FILE.put (l_file, cur_data.addr2);
         UTL_FILE.put (l_file, cur_data.city);
         UTL_FILE.put (l_file, cur_data.state);
         UTL_FILE.put (l_file, cur_data.zip);
         UTL_FILE.put (l_file, cur_data.pri_phone);
         UTL_FILE.put (l_file, cur_data.sec_phone);
         UTL_FILE.put (l_file, cur_data.card_status);
         UTL_FILE.put (l_file, cur_data.card_status_dt);
         UTL_FILE.put (l_file, cur_data.curr_bal);
         UTL_FILE.put (l_file, cur_data.curr_bal_sign);
         UTL_FILE.put (l_file, cur_data.account_created_dt);
         UTL_FILE.put (l_file, cur_data.card_activation_date);
         UTL_FILE.put (l_file, cur_data.card_transfer_no_from);
         UTL_FILE.put (l_file, cur_data.dt_of_neg_bal);
         UTL_FILE.put (l_file, cur_data.neg_bal_priniciple_amt);
         UTL_FILE.put (l_file, cur_data.neg_bal_fee_amt);
         UTL_FILE.put (l_file, cur_data.reload_indicator);
         UTL_FILE.put (l_file, cur_data.account_no);
         UTL_FILE.put (l_file, cur_data.type_of_card);
         UTL_FILE.put (l_file, cur_data.authentication_typ);
         UTL_FILE.put (l_file, cur_data.enroll_no);
         UTL_FILE.put (l_file, cur_data.account_stat);
         UTL_FILE.put (l_file, cur_data.account_stat_dt);
         UTL_FILE.put (l_file, cur_data.account_transfer_no_from);
         UTL_FILE.put (l_file, cur_data.account_transfer_to);
         UTL_FILE.put (l_file, cur_data.dob);
         UTL_FILE.put (l_file, cur_data.avail_bal);
         UTL_FILE.put (l_file, cur_data.avail_bal_sign);
         UTL_FILE.put (l_file, cur_data.pri_card);
         UTL_FILE.put (l_file, cur_data.card_expiry_dt);
         UTL_FILE.put (l_file, cur_data.card_transfer_no_to);
         UTL_FILE.put (l_file, cur_data.first_load_dt);
         UTL_FILE.put (l_file, cur_data.last_txn_dt);
         UTL_FILE.put (l_file, cur_data.last_reisued_dt);
         UTL_FILE.put (l_file, cur_data.crd_first_mailed_dt);
         UTL_FILE.put (l_file, cur_data.crd_last_mailed_dt);
         UTL_FILE.put (l_file, cur_data.no_of_plastics);
         UTL_FILE.put (l_file, cur_data.email_one);
         UTL_FILE.put (l_file, cur_data.card_mailing_addr1);
         UTL_FILE.put (l_file, cur_data.card_mailing_addr2);
         UTL_FILE.put (l_file, cur_data.card_mailing_city);
         UTL_FILE.put (l_file, cur_data.card_mailing_state);
         UTL_FILE.put (l_file, cur_data.card_mailing_zip);
         UTL_FILE.put (l_file, cur_data.esign_indi);
         UTL_FILE.put (l_file, cur_data.esign_oin_oout_dt);
         --end of record/carriage return and line feed
         UTL_FILE.put (l_file, CHR (13) || CHR (10));
         --flush so that buffer is emptied
         UTL_FILE.fflush (l_file);
      END LOOP;

      --write trailer record
      UTL_FILE.put (l_file, 'T');
      UTL_FILE.put (l_file, 'TRAILER');
      UTL_FILE.put (l_file, RPAD (NVL (TO_CHAR (l_total_records), ' '), 9));
      UTL_FILE.put (l_file, CHR (13) || CHR (10));
      --flush file to disk
      UTL_FILE.fflush (l_file);
      --close file
      UTL_FILE.fclose (l_file);
   --dbms_output.put_line(l_total_records);
   EXCEPTION
      WHEN OTHERS
      THEN
         IF UTL_FILE.is_open (l_file)
         THEN
            UTL_FILE.fclose (l_file);
         END IF;

         DBMS_OUTPUT.put_line (SQLERRM);
   END p_cmf;

--Sn Added by Saravanakumar on 30-Jul-2013
   PROCEDURE p_cmf_canada (
      p_in_directory   VARCHAR2,
      p_cmf_id         NUMBER,
      p_in_date        DATE
   )
   AS
      l_file            UTL_FILE.file_type;
      l_file_name       VARCHAR2 (1000);
      l_total_records   NUMBER             := 0;
      l_eod             DATE;

      CURSOR c
      IS
         SELECT RPAD (NVL (TO_CHAR (record_type), ' '), 1, ' ') record_type,
                RPAD (NVL (TO_CHAR (unique_program_id), ' '),
                      15,
                      ' '
                     ) unique_program_id,
                RPAD (NVL (TO_CHAR (proxy_number), ' '), 30,
                      ' ') proxy_number,
                RPAD (NVL (TO_CHAR (card_issued_dt), ' '),
                      8,
                      ' '
                     ) card_issued_dt,
                RPAD
                   (NVL (TO_CHAR (account_expiration_dt), ' '),
                    8,
                    ' '
                   ) account_expiration_dt,
                RPAD (NVL (TO_CHAR (ssn), ' '), 9, ' ') ssn,
                RPAD
                   (NVL (TO_CHAR (card_holder_first_name), ' '),
                    50,
                    ' '
                   ) card_holder_first_name,
                RPAD
                   (NVL (TO_CHAR (card_holder_last_name), ' '),
                    50,
                    ' '
                   ) card_holder_last_name,
                RPAD (NVL (TO_CHAR (addr1), ' '), 100, ' ') addr1,
                RPAD (NVL (TO_CHAR (addr2), ' '), 100, ' ') addr2,
                RPAD (NVL (TO_CHAR (city), ' '), 50, ' ') city,
                RPAD (NVL (TO_CHAR (state), ' '), 2, ' ') state,
                RPAD (NVL (TO_CHAR (zip), ' '), 9, ' ') zip,
                RPAD (NVL (TO_CHAR (pri_phone), ' '), 10, ' ') pri_phone,
                RPAD (NVL (TO_CHAR (sec_phone), ' '), 10, ' ') sec_phone,
                RPAD (NVL (TO_CHAR (card_status), ' '), 50, ' ') card_status,
                RPAD (NVL (TO_CHAR (card_status_dt), ' '),
                      8,
                      ' '
                     ) card_status_dt,
                RPAD (NVL (TRIM (curr_bal), ' '), 13, ' ') curr_bal,
                RPAD (NVL (TO_CHAR (curr_bal_sign), ' '),
                      1,
                      ' '
                     ) curr_bal_sign,
                RPAD (NVL (TO_CHAR (account_created_dt), ' '),
                      8,
                      ' '
                     ) account_created_dt,
                RPAD
                   (NVL (TO_CHAR (card_activation_date), ' '),
                    8,
                    ' '
                   ) card_activation_date,
                RPAD
                   (NVL (TO_CHAR (fn_dmaps_main (card_transfer_no_from)), ' '),
                    30,
                    ' '
                   ) card_transfer_no_from,
                RPAD (NVL (TO_CHAR (dt_of_neg_bal), ' '),
                      8,
                      ' '
                     ) dt_of_neg_bal,
                RPAD
                   (NVL (TRIM (neg_bal_priniciple_amt), ' '),
                    13,
                    ' '
                   ) neg_bal_priniciple_amt,
                RPAD (NVL (TRIM (neg_bal_fee_amt), ' '),
                      13,
                      ' '
                     ) neg_bal_fee_amt,
                RPAD (NVL (TO_CHAR (reload_indicator), ' '),
                      1,
                      ' '
                     ) reload_indicator,
                RPAD (NVL (TO_CHAR (account_no), ' '), 30, ' ') account_no,
                RPAD (NVL (TO_CHAR (type_of_card), ' '), 25,
                      ' ') type_of_card,
                RPAD (NVL (TO_CHAR (authentication_typ), ' '),
                      3,
                      ' '
                     ) authentication_typ,
                RPAD (NVL (TO_CHAR (enroll_no), ' '), 16, ' ') enroll_no,
                RPAD (NVL (TO_CHAR (account_stat), ' '), 50,
                      ' ') account_stat,
                RPAD (NVL (TO_CHAR (account_stat_dt), ' '),
                      8,
                      ' '
                     ) account_stat_dt,
                RPAD
                   (NVL (TO_CHAR (account_transfer_no_from), ' '),
                    30,
                    ' '
                   ) account_transfer_no_from,
                RPAD (NVL (TO_CHAR (account_transfer_to), ' '),
                      30,
                      ' '
                     ) account_transfer_to,
                RPAD (NVL (TO_CHAR (dob), ' '), 8, ' ') dob,
                RPAD (NVL (TRIM (avail_bal), ' '), 13, ' ') avail_bal,
                RPAD (NVL (TO_CHAR (avail_bal_sign), ' '),
                      1,
                      ' '
                     ) avail_bal_sign,
                RPAD (NVL (TO_CHAR (pri_card), ' '), 1, ' ') pri_card,
                RPAD (NVL (TO_CHAR (card_expiry_dt), ' '),
                      8,
                      ' '
                     ) card_expiry_dt,
                RPAD
                   (NVL (TO_CHAR (fn_dmaps_main (card_transfer_no_to)), ' '),
                    30,
                    ' '
                   ) card_transfer_no_to,
                RPAD (NVL (TO_CHAR (first_load_dt), ' '),
                      8,
                      ' '
                     ) first_load_dt,
                RPAD (NVL (TO_CHAR (last_txn_dt), ' '), 8, ' ') last_txn_dt,
                RPAD (NVL (TO_CHAR (last_reisued_dt), ' '),
                      8,
                      ' '
                     ) last_reisued_dt,
                RPAD (NVL (TO_CHAR (crd_first_mailed_dt), ' '),
                      8,
                      ' '
                     ) crd_first_mailed_dt,
                RPAD (NVL (TO_CHAR (crd_last_mailed_dt), ' '),
                      8,
                      ' '
                     ) crd_last_mailed_dt,
                RPAD (NVL (TO_CHAR (no_of_plastics), ' '),
                      2,
                      ' '
                     ) no_of_plastics,
                RPAD (NVL (TO_CHAR (email_one), ' '), 20, ' ') email_one,
                RPAD (NVL (TO_CHAR (card_mailing_addr1), ' '),
                      100,
                      ' '
                     ) card_mailing_addr1,
                RPAD (NVL (TO_CHAR (card_mailing_addr2), ' '),
                      100,
                      ' '
                     ) card_mailing_addr2,
                RPAD (NVL (TO_CHAR (card_mailing_city), ' '),
                      50,
                      ' '
                     ) card_mailing_city,
                RPAD (NVL (TO_CHAR (card_mailing_state), ' '),
                      2,
                      ' '
                     ) card_mailing_state,
                RPAD (NVL (TO_CHAR (card_mailing_zip), ' '),
                      9,
                      ' '
                     ) card_mailing_zip,
                RPAD (NVL (TO_CHAR (esign_indi), ' '), 2, ' ') esign_indi,
                RPAD (NVL (TO_CHAR (fee_plan_id), ' '), 10, ' ') fee_plan_id,
                CHR (13) || CHR (10) end_of_line
           FROM cms_cmf
          WHERE cmf_id = p_cmf_id AND prod_code = 'VP73';
   BEGIN
      l_eod := NVL (p_in_date, SYSDATE - 1);
      --generate file name
      l_file_name :=
            'VMS_customermasterfile_IRIS_'
         || TO_CHAR (l_eod, 'YYYYMMDD')
         || '.txt';
      --open file
      l_file :=
         UTL_FILE.fopen (LOCATION          => p_in_directory,
                         filename          => l_file_name,
                         open_mode         => 'W',
                         max_linesize      => 4000
                        );
      --write header information
      UTL_FILE.put (l_file, 'H');
      UTL_FILE.put (l_file, 'HEADER');
      UTL_FILE.put (l_file, RPAD ('INCOMM', 50, ' '));
      UTL_FILE.put (l_file, RPAD ('CUSTOMER', 50, ' '));
      UTL_FILE.put (l_file, TO_CHAR (NVL (p_in_date, SYSDATE), 'MMDDYYYY'));
      UTL_FILE.put (l_file, TO_CHAR (l_eod, 'MMDDYYYY'));
      UTL_FILE.put (l_file, CHR (13) || CHR (10));
      --flush file to disk
      UTL_FILE.fflush (l_file);

      --write records
      FOR cur_data IN c
      LOOP
         l_total_records := l_total_records + 1;
         UTL_FILE.put (l_file, cur_data.record_type);
         UTL_FILE.put (l_file, cur_data.unique_program_id);
         UTL_FILE.put (l_file, cur_data.proxy_number);
         UTL_FILE.put (l_file, cur_data.card_issued_dt);
         UTL_FILE.put (l_file, cur_data.account_expiration_dt);
         UTL_FILE.put (l_file, cur_data.ssn);
         UTL_FILE.put (l_file, cur_data.card_holder_first_name);
         UTL_FILE.put (l_file, cur_data.card_holder_last_name);
         UTL_FILE.put (l_file, cur_data.addr1);
         UTL_FILE.put (l_file, cur_data.addr2);
         UTL_FILE.put (l_file, cur_data.city);
         UTL_FILE.put (l_file, cur_data.state);
         UTL_FILE.put (l_file, cur_data.zip);
         UTL_FILE.put (l_file, cur_data.pri_phone);
         UTL_FILE.put (l_file, cur_data.sec_phone);
         UTL_FILE.put (l_file, cur_data.card_status);
         UTL_FILE.put (l_file, cur_data.card_status_dt);
         UTL_FILE.put (l_file, cur_data.curr_bal);
         UTL_FILE.put (l_file, cur_data.curr_bal_sign);
         UTL_FILE.put (l_file, cur_data.account_created_dt);
         UTL_FILE.put (l_file, cur_data.card_activation_date);
         UTL_FILE.put (l_file, cur_data.card_transfer_no_from);
         UTL_FILE.put (l_file, cur_data.dt_of_neg_bal);
         UTL_FILE.put (l_file, cur_data.neg_bal_priniciple_amt);
         UTL_FILE.put (l_file, cur_data.neg_bal_fee_amt);
         UTL_FILE.put (l_file, cur_data.reload_indicator);
         UTL_FILE.put (l_file, cur_data.account_no);
         UTL_FILE.put (l_file, cur_data.type_of_card);
         UTL_FILE.put (l_file, cur_data.authentication_typ);
         UTL_FILE.put (l_file, cur_data.enroll_no);
         UTL_FILE.put (l_file, cur_data.account_stat);
         UTL_FILE.put (l_file, cur_data.account_stat_dt);
         UTL_FILE.put (l_file, cur_data.account_transfer_no_from);
         UTL_FILE.put (l_file, cur_data.account_transfer_to);
         UTL_FILE.put (l_file, cur_data.dob);
         UTL_FILE.put (l_file, cur_data.avail_bal);
         UTL_FILE.put (l_file, cur_data.avail_bal_sign);
         UTL_FILE.put (l_file, cur_data.pri_card);
         UTL_FILE.put (l_file, cur_data.card_expiry_dt);
         UTL_FILE.put (l_file, cur_data.card_transfer_no_to);
         UTL_FILE.put (l_file, cur_data.first_load_dt);
         UTL_FILE.put (l_file, cur_data.last_txn_dt);
         UTL_FILE.put (l_file, cur_data.last_reisued_dt);
         UTL_FILE.put (l_file, cur_data.crd_first_mailed_dt);
         UTL_FILE.put (l_file, cur_data.crd_last_mailed_dt);
         UTL_FILE.put (l_file, cur_data.no_of_plastics);
         UTL_FILE.put (l_file, cur_data.email_one);
         UTL_FILE.put (l_file, cur_data.card_mailing_addr1);
         UTL_FILE.put (l_file, cur_data.card_mailing_addr2);
         UTL_FILE.put (l_file, cur_data.card_mailing_city);
         UTL_FILE.put (l_file, cur_data.card_mailing_state);
         UTL_FILE.put (l_file, cur_data.card_mailing_zip);
         UTL_FILE.put (l_file, cur_data.esign_indi);
         UTL_FILE.put (l_file, cur_data.fee_plan_id);
         --end of record/carriage return and line feed
         UTL_FILE.put (l_file, CHR (13) || CHR (10));
         --flush so that buffer is emptied
         UTL_FILE.fflush (l_file);
      END LOOP;

      --write trailer record
      UTL_FILE.put (l_file, 'T');
      UTL_FILE.put (l_file, 'TRAILER');
      UTL_FILE.put (l_file, RPAD (NVL (TO_CHAR (l_total_records), ' '), 9));
      UTL_FILE.put (l_file, CHR (13) || CHR (10));
      --flush file to disk
      UTL_FILE.fflush (l_file);
      --close file
      UTL_FILE.fclose (l_file);
   EXCEPTION
      WHEN OTHERS
      THEN
         IF UTL_FILE.is_open (l_file)
         THEN
            UTL_FILE.fclose (l_file);
         END IF;

         DBMS_OUTPUT.put_line (SQLERRM);
   END p_cmf_canada;

--En Added by Saravanakumar on 30-Jul-2013

   --generate bancorp posted transaction file
   PROCEDURE p_posted_trans (
      p_in_directory   VARCHAR2,
      p_in_date        DATE DEFAULT SYSDATE,
      p_in_inst_code   NUMBER
   )
   AS
      l_file            UTL_FILE.file_type;
      l_file_name       VARCHAR2 (1000);
      l_total_records   NUMBER             := 0;
      l_eod             DATE;

      CURSOR c
      IS
         SELECT RPAD (NVL (TO_CHAR (record_type), ' '), 1, ' ') record_type,
                RPAD (NVL (TO_CHAR (unique_program_id), ' '),
                      15,
                      ' '
                     ) unique_program_id,
                RPAD (NVL (TO_CHAR (card_number), ' '), 30, ' ') card_number,
                RPAD (NVL (TO_CHAR (transaction_date), ' '),
                      8,
                      ' '
                     ) transaction_date,
                RPAD
                   (NVL (TO_CHAR (transaction_code_type), ' '),
                    15,
                    ' '
                   ) transaction_code_type,
                RPAD (NVL (TO_CHAR (transaction_amount), ' '),
                      13,
                      ' '
                     ) transaction_amount,
                RPAD
                   (NVL (TO_CHAR (transaction_amount_sign), ' '),
                    1,
                    ' '
                   ) transaction_amount_sign,
                RPAD
                   (NVL (TO_CHAR (transaction_currency_code), ' '),
                    3,
                    ' '
                   ) transaction_currency_code,
                RPAD (NVL (TO_CHAR (authorization_code), ' '),
                      10,
                      ' '
                     ) authorization_code,
                RPAD (NVL (TO_CHAR (post_date), ' '), 8, ' ') post_date,
                RPAD (NVL (TO_CHAR (network_code), ' '), 30,
                      ' ') network_code,
                RPAD (NVL (TO_CHAR (merchant_number), ' '),
                      30,
                      ' '
                     ) merchant_number,
                RPAD (NVL (TO_CHAR (merchant_name), ' '),
                      50,
                      ' '
                     ) merchant_name,
                RPAD
                   (NVL (TO_CHAR (merchant_category_code), ' '),
                    4,
                    ' '
                   ) merchant_category_code,
                RPAD
                   (NVL (TO_CHAR (merchant_country_code), ' '),
                    5,
                    ' '
                   ) merchant_country_code,
                RPAD
                   (NVL (TO_CHAR (interchange_fee_amount), ' '),
                    9,
                    ' '
                   ) interchange_fee_amount,
                RPAD (NVL (TO_CHAR (account_number), ' '),
                      30,
                      ' '
                     ) account_number,
                RPAD
                   (NVL (TO_CHAR (transaction_ref_number), ' '),
                    50,
                    ' '
                   ) transaction_ref_number,
                RPAD (NVL (TO_CHAR (transaction_time), ' '),
                      8,
                      ' '
                     ) transaction_time,
                RPAD (NVL (TO_CHAR (posted_time), ' '), 8, ' ') posted_time,
                RPAD (NVL (TO_CHAR (merchant_city), ' '),
                      50,
                      ' '
                     ) merchant_city,
                RPAD (NVL (TO_CHAR (merchant_state), ' '),
                      2,
                      ' '
                     ) merchant_state,
                RPAD (NVL (TO_CHAR (merchant_zip), ' '), 10,
                      ' ') merchant_zip,
                RPAD (NVL (TO_CHAR (settled_date), ' '), 8, ' ')
                                                                settled_date,
                RPAD (NVL (TO_CHAR (settled_time), ' '), 8, ' ')
                                                                settled_time,
                RPAD (NVL (TO_CHAR (cvv_cvc), ' '), 1, ' ') cvv_cvc,
                RPAD (NVL (TO_CHAR (cvv_cvc2), ' '), 1, ' ') cvv_cvc2,
                RPAD (NVL (TO_CHAR (blank_reserved), ' '),
                      3,
                      ' '
                     ) blank_reserved,
                RPAD (NVL (TO_CHAR (pos_entry_mode), ' '),
                      3,
                      ' '
                     ) pos_entry_mode,
                CHR (13) || CHR (10) end_of_line
           FROM (SELECT   'D' record_type,
                          (SELECT cpm_program_id
                             FROM cms_prod_mast
                            WHERE cpm_prod_code =
                                              cap_prod_code)
                                                            unique_program_id,
                          fn_dmaps_main (csl_pan_no_encr) card_number,
                          TO_CHAR (TO_DATE (business_date, 'yyyymmdd'),
                                   'MMDDYYYY'
                                  ) transaction_date,
                             csl_txn_code
                          || csl_delivery_channel
                          || NVL (TRIM (internation_ind_response), 0)
                          || CASE
                                WHEN (SELECT COUNT (*)
                                        FROM transactionlog
                                       WHERE ROWID = a.ROWID
                                         AND (   (    delivery_channel = '01'
                                                  AND txn_code IN (10, 30)
                                                  AND msgtype = '0200'
                                                 )
                                              OR (    delivery_channel = '02'
                                                  AND txn_code IN
                                                             (11, 14, 16, 31)
                                                  AND msgtype IN
                                                         ('0100', '1200',
                                                          '0200')
                                                 )
                                             )) > 0
                                   THEN '1'
                                ELSE '0'
                             END
                          || DECODE (txn_fee_flag, 'Y', 1, 0)
                          --Modified for FSS-1203 by Saravanakumar on 16-May-2013
                          || (CASE
                                 WHEN csl_delivery_channel IN ('03')
                                 AND csl_txn_code IN
                                        ('20', '13', '14', '19', '83', '74',
                                         '86', '85', '84', '76', '12', '11',
                                         '75')
                                    THEN LPAD
                                           (NVL
                                               ((SELECT TO_CHAR
                                                            (csr_spprt_rsncode)
                                                   FROM cms_spprt_reasons
                                                  WHERE csr_reasondesc =
                                                                      a.reason
                                                    AND csr_inst_code =
                                                                    a.instcode),
                                                0
                                               ),
                                            3,
                                            '0'
                                           )
                                 ELSE '000'
                              END
                             ) transaction_code_type,
                          TO_CHAR (csl_trans_amount,
                                   999999990.99
                                  ) transaction_amount,
                          DECODE (csl_trans_type,
                                  'CR', '+',
                                  '-'
                                 ) transaction_amount_sign,
                          currencycode transaction_currency_code,
                          csl_auth_id authorization_code,
                          TO_CHAR (TO_DATE (business_date, 'yyyymmdd'),
                                   'MMDDYYYY'
                                  ) post_date,
                          network_id network_code,
                          merchant_id merchant_number,
                          merchant_name merchant_name,
                          mccode merchant_category_code,
                          country_code merchant_country_code,
                          TO_CHAR (interchange_feeamt,
                                   9999999990.99
                                  ) interchange_fee_amount,
                          csl_acct_no account_number,
                          csl_rrn transaction_ref_number,
                          csl_business_time transaction_time,
                          csl_business_time posted_time,
                          merchant_city merchant_city,
                          merchant_state merchant_state,
                          merchant_zip merchant_zip,
                          CASE
                             WHEN csl_delivery_channel IN
                                                   ('01', '02')
                                THEN NVL
                                       (TO_CHAR (TO_DATE (network_settl_date,
                                                          'yyyymmdd'
                                                         ),
                                                 'MMDDYYYY'
                                                ),
                                        ''
                                       )
                             ELSE NVL (TO_CHAR (csl_ins_date, 'MMDDYYYY'), '')
                          END settled_date,
                          '' settled_time,
                          DECODE (csl_delivery_channel,
                                  10, DECODE (csl_txn_code, '02', 'M', 'N'),
                                  ' '
                                 ) cvv_cvc,
                          DECODE (csl_delivery_channel,
                                  10, DECODE (csl_txn_code, '02', 'M', 'N'),
                                  ' '
                                 ) cvv_cvc2,
                          '' blank_reserved, '' pos_entry_mode,
                          '' post_indicator,
                          fn_dmaps_main (topup_card_no_encr) tocardnumber
                     FROM transactionlog a, cms_appl_pan, cms_statements_log
                    WHERE csl_inst_code = p_in_inst_code
                      AND csl_pan_no = cap_pan_code
                      AND csl_acct_no=cap_acct_no--Added for JIRA DFCHOST350 by saravanakumar on 04-Oct-2013
                      /* SN: 20130618: COMMENTED TO CONSIDER POS PREAUTH
                      AND (   (    csl_delivery_channel IN ('02')
                               AND csl_txn_code NOT IN ('11')
                              )
                           OR csl_delivery_channel != '02'
                          )
                             */ -- EN: 20130618: COMMENTED TO CONSIDER POS PREAUTH
                      AND csl_ins_date
                             BETWEEN TO_DATE (   TO_CHAR (TRUNC (p_in_date),
                                                          'YYYYMMDD'
                                                         )
                                              || '000000'
                                             )
                                 AND TO_DATE (   TO_CHAR (TRUNC (p_in_date),
                                                          'YYYYMMDD'
                                                         )
                                              || '235959'
                                             )
                      AND csl_trans_amount <> 0
                      AND csl_trans_amount IS NOT NULL
                      AND csl_acct_no = customer_acct_no(+)
                      AND csl_pan_no = customer_card_no(+)
                      AND csl_rrn = rrn(+)
                      AND csl_auth_id = auth_id(+)
                      AND cap_prod_code <> 'VP75'--Added by Saravanakumar on 20-Dec-2013
                 --and csl_pan_no =  gethash('4420620301721600')
                 ORDER BY csl_pan_no,
                          transaction_date,
                          authorization_code,
                          transaction_code_type DESC);
   BEGIN
      --if p_in_date is not null then
        --l_eod := p_in_date-1;
      --else
        --l_eod := sysdate-1;
      --end if;
      --set End of Date to today - 1 as this job is executed at 1 AM.
      --p_in_date should always be EOD+1
      l_eod := NVL (p_in_date, SYSDATE - 1);
      --generate file name
      --VMS_postedtransactions_20130305.txt
      l_file_name :=
            'VMS_postedtransactions_' || TO_CHAR (l_eod, 'YYYYMMDD')
            || '.txt';
      --open file
      l_file :=
         UTL_FILE.fopen (LOCATION          => p_in_directory,
                         filename          => l_file_name,
                         open_mode         => 'W',
                         max_linesize      => 4000
                        );
      --write header information
      UTL_FILE.put (l_file, 'H');
      UTL_FILE.put (l_file, 'HEADER');
      UTL_FILE.put (l_file, RPAD ('INCOMM', 50, ' '));
      UTL_FILE.put (l_file, RPAD ('CUSTOMER', 50, ' '));
      UTL_FILE.put (l_file, TO_CHAR (NVL (p_in_date, SYSDATE), 'MMDDYYYY'));
      UTL_FILE.put (l_file, TO_CHAR (l_eod, 'MMDDYYYY'));
      UTL_FILE.put (l_file, CHR (13) || CHR (10));
      --flush file to disk
      UTL_FILE.fflush (l_file);

      --dbms_output.put_line('=========');
      --dbms_output.put_line(to_char(trunc(p_in_date-1),'YYYYMMDD')||'000000');
      --dbms_output.put_line(to_char(trunc(p_in_date-2),'YYYYMMDD')||'000000');
      --write records
      FOR cur_data IN c
      LOOP
         l_total_records := l_total_records + 1;
         UTL_FILE.put (l_file, cur_data.record_type);
         UTL_FILE.put (l_file, cur_data.unique_program_id);
         UTL_FILE.put (l_file, cur_data.card_number);
         UTL_FILE.put (l_file, cur_data.transaction_date);
         UTL_FILE.put (l_file, cur_data.transaction_code_type);
         UTL_FILE.put (l_file, cur_data.transaction_amount);
         UTL_FILE.put (l_file, cur_data.transaction_amount_sign);
         UTL_FILE.put (l_file, cur_data.transaction_currency_code);
         UTL_FILE.put (l_file, cur_data.authorization_code);
         UTL_FILE.put (l_file, cur_data.post_date);
         UTL_FILE.put (l_file, cur_data.network_code);
         UTL_FILE.put (l_file, cur_data.merchant_number);
         UTL_FILE.put (l_file, cur_data.merchant_name);
         UTL_FILE.put (l_file, cur_data.merchant_category_code);
         UTL_FILE.put (l_file, cur_data.merchant_country_code);
         UTL_FILE.put (l_file, cur_data.interchange_fee_amount);
         UTL_FILE.put (l_file, cur_data.account_number);
         UTL_FILE.put (l_file, cur_data.transaction_ref_number);
         UTL_FILE.put (l_file, cur_data.transaction_time);
         UTL_FILE.put (l_file, cur_data.posted_time);
         UTL_FILE.put (l_file, cur_data.merchant_city);
         UTL_FILE.put (l_file, cur_data.merchant_state);
         UTL_FILE.put (l_file, cur_data.merchant_zip);
         UTL_FILE.put (l_file, cur_data.settled_date);
         UTL_FILE.put (l_file, cur_data.settled_time);
         UTL_FILE.put (l_file, cur_data.cvv_cvc);
         UTL_FILE.put (l_file, cur_data.cvv_cvc2);
         UTL_FILE.put (l_file, cur_data.blank_reserved);
         UTL_FILE.put (l_file, cur_data.pos_entry_mode);
         --end of record/carriage return and line feed
         UTL_FILE.put (l_file, CHR (13) || CHR (10));
         --flush so that buffer is emptied
         UTL_FILE.fflush (l_file);
      END LOOP;

      --write trailer record
      UTL_FILE.put (l_file, 'T');
      UTL_FILE.put (l_file, 'TRAILER');
      UTL_FILE.put (l_file, RPAD (NVL (TO_CHAR (l_total_records), ' '), 9));
      UTL_FILE.put (l_file, CHR (13) || CHR (10));
      --flush file to disk
      UTL_FILE.fflush (l_file);
      --close file
      UTL_FILE.fclose (l_file);
   --dbms_output.put_line(l_total_records);
   EXCEPTION
      WHEN OTHERS
      THEN
         IF UTL_FILE.is_open (l_file)
         THEN
            UTL_FILE.fclose (l_file);
         END IF;

         DBMS_OUTPUT.put_line (SQLERRM);
   END p_posted_trans;

--========================================================================================================

   --========================================================================================================

   --SN: TO GENERATE LOOPUP REPORT
   PROCEDURE p_lookup_rep (p_in_directory VARCHAR2)
   AS
      /*******************************************************************************
       * DATE OF CREATION      : 16/MAy/2013
       * CREATED BY            : Sagar
       * Reveiwed BY            : Sachin Nikam
       * PURPOSE               : To generate lookup file
       **********************************************************************************/
      file_handle   UTL_FILE.file_type;
      wrt_buff      VARCHAR2 (1000);
      fname         VARCHAR2 (100);
      v_errmsg      VARCHAR2 (500);
      exp_main      EXCEPTION;
      v_header      VARCHAR2 (500);
      v_trailer     VARCHAR2 (500);
      v_cnt         NUMBER             := 0;
   BEGIN
      v_errmsg := 'OK';

      --
      --
      BEGIN
         fname := 'VMS_lookup_' || TO_CHAR (SYSDATE, 'yyyymmdd') || '.txt';
         file_handle := UTL_FILE.fopen (p_in_directory, fname, 'w');
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg := 'ERROR OPENING FILE' || SQLERRM;
            RAISE exp_main;
      END;

   --
--   BEGIN
--*****************************************************HEADING SECTION*****************************************
      BEGIN
         --V_HEADER := LPAD ('H', 1, ' ')||LPAD ('HEADER', 6, ' ')||LPAD (' ', 49, ' ')||LPAD ('LOOKUP', 49, ' ')||LPAD (TO_CHAR(SYSDATE,'MMDDYYYY'), 7, ' ')||LPAD (TO_CHAR(SYSDATE,'MMDDYYYY'), 7, ' ')||LPAD ('0D0A', 1, ' ');
         v_header :=
               'H'
            || 'HEADER'
            || RPAD (' ', 50, ' ')
            || RPAD ('LOOKUP', 50, ' ')
            || TO_CHAR (SYSDATE, 'MMDDYYYY')
            || TO_CHAR (SYSDATE, 'MMDDYYYY');
         wrt_buff := v_header;
         UTL_FILE.put_line (file_handle, wrt_buff);

         FOR i IN (SELECT   'D' record_type, a.clf_file_id fileid,
                            a.clf_field_name fieldname,
                            b.car_response_id code,
                            b.car_resp_desc description
                       FROM (SELECT clf_file_id, clf_field_name
                               FROM cms_lookup_file
                              WHERE clf_column_name = 'CAR_RESPONSE_ID') a,
                            (SELECT car_response_id, car_resp_desc
                               FROM cms_addressveri_resp
                              WHERE car_inst_code = 1) b
                   UNION ALL
                   SELECT   'D' record_type, a.clf_file_id fileid,
                            a.clf_field_name fieldname,
                            TO_CHAR (   LPAD (b.cms_delivery_channel, 2, '0')
                                     || b.cms_response_id
                                    ) code,
                            b.cms_resp_desc description
                       FROM (SELECT clf_file_id, clf_field_name
                               FROM cms_lookup_file
                              WHERE clf_column_name = 'CMS_RESPONSE_ID') a,
                            (SELECT DISTINCT cms_delivery_channel,
                                             cms_response_id, cms_resp_desc
                                        FROM cms_response_mast
                                       WHERE cms_inst_code = 1) b
                   UNION ALL
                   SELECT   'D' record_type, a.clf_file_id fileid,
                            a.clf_field_name fieldname, b.cpm_prod_code code,
                            b.cpm_prod_desc description
                       FROM (SELECT clf_file_id, clf_field_name
                               FROM cms_lookup_file
                              WHERE clf_column_name = 'CPM_PROD_CODE') a,
                            (SELECT cpm_prod_code, cpm_prod_desc
                               FROM cms_prod_mast
                              WHERE cpm_inst_code = 1) b
                   UNION ALL
                   SELECT   'D' record_type, a.clf_file_id fileid,
                            a.clf_field_name fieldname, b.ccs_stat_code code,
                            b.ccs_stat_desc description
                       FROM (SELECT clf_file_id, clf_field_name
                               FROM cms_lookup_file
                              WHERE clf_column_name = 'CCS_STAT_CODE') a,
                            (SELECT ccs_stat_code, ccs_stat_desc
                               FROM cms_card_stat
                              WHERE ccs_inst_code = 1) b
                   UNION ALL
                   SELECT   'D' record_type, a.clf_file_id fileid,
                            a.clf_field_name fieldname, b.cpm_program_id code,
                            b.cpm_prod_desc description
                       FROM (SELECT clf_file_id, clf_field_name
                               FROM cms_lookup_file
                              WHERE clf_column_name = 'CPM_PROGRAM_ID') a,
                            (SELECT cpm_program_id, cpm_prod_desc
                               FROM cms_prod_mast
                              WHERE cpm_inst_code = 1) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '000000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'Signature '
                                           || ctm_tran_desc
                                           || ' (Domestic)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '010000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'PIN '
                                           || ctm_tran_desc
                                           || ' (Domestic)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '100000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'Signature '
                                           || ctm_tran_desc
                                           || ' (International)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '110000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'PIN '
                                           || ctm_tran_desc
                                           || ' (International)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '001000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'Signature '
                                           || ctm_tran_desc
                                           || '-FEE'
                                           || ' (Domestic)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '011000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'PIN '
                                           || ctm_tran_desc
                                           || '-FEE'
                                           || ' (Domestic)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '101000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'Signature '
                                           || ctm_tran_desc
                                           || '-FEE'
                                           || ' (International)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '111000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'PIN '
                                           || ctm_tran_desc
                                           || '-FEE'
                                           || ' (International)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '000000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || ctm_tran_desc trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel NOT IN
                                                           ('01', '02', '03')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '001000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || ctm_tran_desc
                                           || '-FEE' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel NOT IN
                                                           ('01', '02', '03')) b
                   UNION ALL
--Sn Added on 11-Jul-2013 by saravanakumar
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    a.ctm_tran_code
                                           || a.ctm_delivery_channel
                                           || '000'
                                           || LPAD (csr_spprt_rsncode, 3, '0')
                                                                      transcd,
                                              'CSR-'
                                           || DECODE (a.ctm_tran_code,
                                                      '14', 'Admin Credit',
                                                      '13', 'Admin Debit-Reversal',
                                                      a.ctm_tran_desc
                                                     )
                                           || '-'
                                           || csr_reasondesc trndesc
                                      FROM cms_transaction_mast a,
                                           cms_spprt_reasons
                                     WHERE a.ctm_inst_code = 1
                                       AND a.ctm_delivery_channel = '03') b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    a.ctm_tran_code
                                           || a.ctm_delivery_channel
                                           || '000000' transcd,
                                              'CSR-'
                                           || DECODE (a.ctm_tran_code,
                                                      '14', 'Admin Credit',
                                                      '13', 'Admin Debit-Reversal',
                                                      a.ctm_tran_desc
                                                     ) trndesc
                                      FROM cms_transaction_mast a
                                     WHERE a.ctm_inst_code = 1
                                       AND a.ctm_delivery_channel = '03') b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    a.ctm_tran_code
                                           || a.ctm_delivery_channel
                                           || '001'
                                           || LPAD (csr_spprt_rsncode, 3, '0')
                                                                      transcd,
                                              'CSR-'
                                           || DECODE (a.ctm_tran_code,
                                                      '14', 'Admin Credit',
                                                      '13', 'Admin Debit-Reversal',
                                                      a.ctm_tran_desc
                                                     )
                                           || '-'
                                           || csr_reasondesc
                                           || '-FEE' trndesc
                                      FROM cms_transaction_mast a,
                                           cms_spprt_reasons
                                     WHERE a.ctm_inst_code = 1
                                       AND a.ctm_delivery_channel = '03') b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    a.ctm_tran_code
                                           || a.ctm_delivery_channel
                                           || '001000' transcd,
                                              'CSR-'
                                           || DECODE (a.ctm_tran_code,
                                                      '14', 'Admin Credit',
                                                      '13', 'Admin Debit-Reversal',
                                                      a.ctm_tran_desc
                                                     )
                                           || '-FEE' trndesc
                                      FROM cms_transaction_mast a
                                     WHERE a.ctm_inst_code = 1
                                       AND a.ctm_delivery_channel = '03') b
--En Added on 11-Jul-2013 by saravanakumar
/*select distinct 'D' record_type, a.clf_file_id fileid,
                                a.clf_field_name fieldname, b.transcd code,
                                b.trndesc description
                           from (select clf_file_id, clf_field_name
                                   from cms_lookup_file
                                  where clf_column_name = 'CTM_TRAN_CODE') a,
(select a.ctm_tran_code||a.ctm_delivery_channel||'000'||
case when  a.ctm_tran_code ='11' then '069'
     when  a.ctm_tran_code in ('13','14') then '080'
     when  a.ctm_tran_code ='20' then '082'
     when  a.ctm_tran_code ='19' then '013'
     when  a.ctm_tran_code ='12' then '067'
     when  a.ctm_tran_code ='37' then '101'
     when  a.ctm_tran_code ='86' then '012'
     when  a.ctm_tran_code ='75' then '002'
     when  a.ctm_tran_code ='74' then '055'
     when  a.ctm_tran_code ='76' then '062'
     when  a.ctm_tran_code ='84' then '005'
     when  a.ctm_tran_code ='85' then '006'
     when  a.ctm_tran_code ='83' then '009'
     when  a.ctm_tran_code ='78' then '003'
     when  a.ctm_tran_code ='87' then '004'
     else '000' end transcd,
case when  a.ctm_tran_code ='11' then 'CSR-PREAUTH HOLD RELEASE-Duplicate Auth'
     when  a.ctm_tran_code in ('13','14') then
     decode (a.ctm_tran_code,'14', 'CSR-Admin Credit','CSR-Admin Debit-Reversal')
     when  a.ctm_tran_code ='20' then 'CSR-ADHOC FEES DR-Live Agent Customer Support Fee'
     when  a.ctm_tran_code ='19' then 'CSR-CSR ACHTXN PROCESS-DD Exception'
     when  a.ctm_tran_code ='12' then 'CSR-FEE REV-Incorrect Fee'
     when  a.ctm_tran_code ='37' then 'CSR-Update Profile With DOB And Last Name-Divorced'
     when  a.ctm_tran_code ='86' then 'CSR-RETURNED MAIL-FRAUD TEAM RETURNED MAIL'
     when  a.ctm_tran_code ='75' then 'CSR-CARD LOST-STOLEN-Card Lost'
     when  a.ctm_tran_code ='74' then 'CSR-CARD ACTIVATION-ACTIVATE CARD'
     when  a.ctm_tran_code ='76' then 'CSR-CARD BLOCK-Fraud Investigation'
     when  a.ctm_tran_code ='84' then 'CSR-MONITORED CARD-FRAUD TEAM MONITORED'
     when  a.ctm_tran_code ='85' then 'CSR-HOT CARDED-FRAUD TEAM HOT CARDED'
     when  a.ctm_tran_code ='83' then 'CSR-CARD STATUS UPDATE_CLOSE-Card Close'
     when  a.ctm_tran_code ='78' then 'CSR-CARD DAMAGE-Card Stolen'
     when  a.ctm_tran_code ='87' then 'CSR-RESTRICTED CARD-CARD RESTRICT'
     else 'CSR-'||a.ctm_tran_desc end trndesc
    from cms_transaction_mast a
    where a.ctm_inst_code=1 and a.ctm_delivery_channel='03')b
union all
select distinct 'D' record_type, a.clf_file_id fileid,
                                a.clf_field_name fieldname, b.transcd code,
                                b.trndesc description
                           from (select clf_file_id, clf_field_name
                                   from cms_lookup_file
                                  where clf_column_name = 'CTM_TRAN_CODE') a,
(select a.ctm_tran_code||a.ctm_delivery_channel||'000'||
case when  a.ctm_tran_code ='11' then '070'
     when  a.ctm_tran_code ='12' then '068'
     when  a.ctm_tran_code ='37' then '102'
     end transcd,
case when  a.ctm_tran_code ='11' then 'CSR-PREAUTH HOLD RELEASE-Void not Processed'
     when  a.ctm_tran_code ='12' then 'CSR-FEE REV-Courtesy Reversal'
     when  a.ctm_tran_code ='37' then 'CSR-Update Profile With DOB And Last Name-Wrong Date Of Birth'
     end trndesc
    from cms_transaction_mast a
    where  a.ctm_inst_code=1 and a.ctm_delivery_channel='03' and a.ctm_tran_code in ('11','12','37'))b
union all
select distinct 'D' record_type, a.clf_file_id fileid,
                                a.clf_field_name fieldname, b.transcd code,
                                b.trndesc description
                           from (select clf_file_id, clf_field_name
                                   from cms_lookup_file
                                  where clf_column_name = 'CTM_TRAN_CODE') a,
(select a.ctm_tran_code||a.ctm_delivery_channel||'000'||
case when  a.ctm_tran_code ='11' then '071'
     when  a.ctm_tran_code ='37' then '103'
     end transcd,
case when  a.ctm_tran_code ='11' then 'CSR-PREAUTH HOLD RELEASE-Merchant Error'
     when  a.ctm_tran_code ='37' then 'CSR-Update Profile With DOB And Last Name-Marriage'
     end trndesc
    from cms_transaction_mast a
    where  a.ctm_inst_code=1 and a.ctm_delivery_channel='03' and a.ctm_tran_code in ('11','37'))b
union all
select distinct 'D' record_type, a.clf_file_id fileid,
                                a.clf_field_name fieldname, b.transcd code,
                                b.trndesc description
                           from (select clf_file_id, clf_field_name
                                   from cms_lookup_file
                                  where clf_column_name = 'CTM_TRAN_CODE') a,
(select a.ctm_tran_code||a.ctm_delivery_channel||'000000' transcd,'CSR-'||a.ctm_tran_desc trndesc
    from cms_transaction_mast a
    where  a.ctm_inst_code=1 and a.ctm_delivery_channel='03' and
    a.ctm_tran_code in ('11','13','14','20','19','12','37','86','75','74','76','84','85','83','78','87'))b
union all
select distinct 'D' record_type, a.clf_file_id fileid,
                                a.clf_field_name fieldname, b.transcd code,
                                b.trndesc description
                           from (select clf_file_id, clf_field_name
                                   from cms_lookup_file
                                  where clf_column_name = 'CTM_TRAN_CODE') a,
(select a.ctm_tran_code||a.ctm_delivery_channel||'001'||
case when  a.ctm_tran_code ='11' then '069'
     when  a.ctm_tran_code in ('13','14') then '080'
     when  a.ctm_tran_code ='20' then '082'
     when  a.ctm_tran_code ='19' then '013'
     when  a.ctm_tran_code ='12' then '067'
     when  a.ctm_tran_code ='37' then '101'
     when  a.ctm_tran_code ='86' then '012'
     when  a.ctm_tran_code ='75' then '002'
     when  a.ctm_tran_code ='74' then '055'
     when  a.ctm_tran_code ='76' then '062'
     when  a.ctm_tran_code ='84' then '005'
     when  a.ctm_tran_code ='85' then '006'
     when  a.ctm_tran_code ='83' then '009'
     when  a.ctm_tran_code ='78' then '003'
     when  a.ctm_tran_code ='87' then '004'
     else '000' end transcd,
case when  a.ctm_tran_code ='11' then 'CSR-PREAUTH HOLD RELEASE-Duplicate Auth-FEE'
     when  a.ctm_tran_code in ('13','14') then
     decode (a.ctm_tran_code,'14', 'CSR-Admin Credit-FEE','CSR-Admin Debit-Reversal-FEE')
     when  a.ctm_tran_code ='20' then 'CSR-ADHOC FEES DR-Live Agent Customer Support Fee-FEE'
     when  a.ctm_tran_code ='19' then 'CSR-CSR ACHTXN PROCESS-DD Exception-FEE'
     when  a.ctm_tran_code ='12' then 'CSR-FEE REV-Incorrect Fee-FEE'
     when  a.ctm_tran_code ='37' then 'CSR-Update Profile With DOB And Last Name-Divorced-FEE'
     when  a.ctm_tran_code ='86' then 'CSR-RETURNED MAIL-FRAUD TEAM RETURNED MAIL-FEE'
     when  a.ctm_tran_code ='75' then 'CSR-CARD LOST-STOLEN-Card Lost-FEE'
     when  a.ctm_tran_code ='74' then 'CSR-CARD ACTIVATION-ACTIVATE CARD-FEE'
     when  a.ctm_tran_code ='76' then 'CSR-CARD BLOCK-Fraud Investigation-FEE'
     when  a.ctm_tran_code ='84' then 'CSR-MONITORED CARD-FRAUD TEAM MONITORED-FEE'
     when  a.ctm_tran_code ='85' then 'CSR-HOT CARDED-FRAUD TEAM HOT CARDED-FEE'
     when  a.ctm_tran_code ='83' then 'CSR-CARD STATUS UPDATE_CLOSE-Card Close-FEE'
     when  a.ctm_tran_code ='78' then 'CSR-CARD DAMAGE-Card Stolen-FEE'
     when  a.ctm_tran_code ='87' then 'CSR-RESTRICTED CARD-CARD RESTRICT-FEE'
     else 'CSR-'||a.ctm_tran_desc||'-FEE' end trndesc
    from cms_transaction_mast a
    where a.ctm_inst_code=1 and a.ctm_delivery_channel='03')b
union all
select distinct 'D' record_type, a.clf_file_id fileid,
                                a.clf_field_name fieldname, b.transcd code,
                                b.trndesc description
                           from (select clf_file_id, clf_field_name
                                   from cms_lookup_file
                                  where clf_column_name = 'CTM_TRAN_CODE') a,
(select a.ctm_tran_code||a.ctm_delivery_channel||'001'||
case when  a.ctm_tran_code ='11' then '070'
     when  a.ctm_tran_code ='12' then '068'
     when  a.ctm_tran_code ='37' then '102'
     end transcd,
case when  a.ctm_tran_code ='11' then 'CSR-PREAUTH HOLD RELEASE-Void not Processed-FEE'
     when  a.ctm_tran_code ='12' then 'CSR-FEE REV-Courtesy Reversal-FEE'
     when  a.ctm_tran_code ='37' then 'CSR-Update Profile With DOB And Last Name-Wrong Date Of Birth-FEE'
     end trndesc
    from cms_transaction_mast a
    where  a.ctm_inst_code=1 and a.ctm_delivery_channel='03' and a.ctm_tran_code in ('11','12','37'))b
union all
select distinct 'D' record_type, a.clf_file_id fileid,
                                a.clf_field_name fieldname, b.transcd code,
                                b.trndesc description
                           from (select clf_file_id, clf_field_name
                                   from cms_lookup_file
                                  where clf_column_name = 'CTM_TRAN_CODE') a,
(select a.ctm_tran_code||a.ctm_delivery_channel||'001'||
case when  a.ctm_tran_code ='11' then '071'
     when  a.ctm_tran_code ='37' then '103'
     end transcd,
case when  a.ctm_tran_code ='11' then 'CSR-PREAUTH HOLD RELEASE-Merchant Error-FEE'
     when  a.ctm_tran_code ='37' then 'CSR-Update Profile With DOB And Last Name-Marriage-FEE'
     end trndesc
    from cms_transaction_mast a
    where  a.ctm_inst_code=1 and a.ctm_delivery_channel='03' and a.ctm_tran_code in ('11','37'))b
union all
select distinct 'D' record_type, a.clf_file_id fileid,
                                a.clf_field_name fieldname, b.transcd code,
                                b.trndesc description
                           from (select clf_file_id, clf_field_name
                                   from cms_lookup_file
                                  where clf_column_name = 'CTM_TRAN_CODE') a,
(select a.ctm_tran_code||a.ctm_delivery_channel||'001000' transcd,'CSR-'||a.ctm_tran_desc ||'-FEE' trndesc
    from cms_transaction_mast a
    where  a.ctm_inst_code=1 and a.ctm_delivery_channel='03' and
    a.ctm_tran_code in ('11','13','14','20','19','12','37','86','75','74','76','84','85','83','78','87'))b*/
                /*SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                a.clf_field_name fieldname, b.transcd code,
                                b.trndesc description
                           FROM (SELECT clf_file_id, clf_field_name
                                   FROM cms_lookup_file
                                  WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                (SELECT    txn_code
                                        || delivery_channel
                                        || NVL (internation_ind_response, 0)
                                        || CASE
                                              WHEN (SELECT COUNT (*)
                                                      FROM transactionlog
                                                     WHERE ROWID = a.ROWID
                                                       AND (   (    delivery_channel = '01'
                                                                AND txn_code IN (10, 30)
                                                                AND msgtype = '0200'
                                                               )
                                                            OR (    delivery_channel = '02'
                                                                AND txn_code IN
                                                                             (11, 14, 16, 31)
                                                                AND msgtype IN
                                                                       ('0100', '1200',
                                                                        '0200')
                                                               )
                                                           )) > 0
                                                 THEN '1'
                                              ELSE '0'
                                           END
                                        || 1
                                        || (CASE
                                               WHEN delivery_channel IN ('03')
                                               AND txn_code IN
                                                      ('20', '13', '14', '19', '83', '74',
                                                       '86', '85', '84', '76', '12', '11',
                                                       '75')
                                                  THEN LPAD
                                                         (NVL
                                                             ((SELECT TO_CHAR
                                                                            (csr_spprt_rsncode)
                                                                 FROM cms_spprt_reasons
                                                                WHERE csr_reasondesc =
                                                                                      a.reason
                                                                  AND csr_inst_code =
                                                                                    a.instcode),
                                                              '0'
                                                             ),
                                                          3,
                                                          '0'
                                                         )
                                               ELSE '000'
                                            END
                                           ) transcd,
                                           CASE
                                              WHEN delivery_channel IN ('03')
                                              AND txn_code IN ('13', '14')
                                                 THEN (SELECT    DECODE (txn_code,
                                                                         '14', 'Admin Credit-',
                                                                         'Admin Debit-'
                                                                        )
                                                              || csr_reasondesc
                                                              || DECODE (txn_code,
                                                                         '13', ' Reversal'
                                                                        )
                                                         FROM cms_spprt_reasons
                                                        WHERE csr_reasondesc = a.reason
                                                          AND csr_inst_code = a.instcode)
                                              ELSE (   (SELECT cdm_channel_desc
                                                          FROM cms_delchannel_mast
                                                         WHERE cdm_channel_code =
                                                                          ctm_delivery_channel)
                                                    || '-'
                                                    || CASE
                                                          WHEN (SELECT COUNT (*)
                                                                  FROM transactionlog
                                                                 WHERE ROWID = a.ROWID
                                                                   AND delivery_channel = '02'
                                                                   AND txn_code IN
                                                                             (11, 14, 16, 31)
                                                                   AND msgtype IN
                                                                          ('0100', '1200',
                                                                           '0200')) > 0
                                                             THEN 'PIN '
                                                          WHEN (SELECT COUNT (*)
                                                                  FROM transactionlog
                                                                 WHERE ROWID = a.ROWID
                                                                   AND delivery_channel = '02'
                                                                   AND txn_code IN
                                                                             (11, 14, 16, 31)
                                                                   AND msgtype IN
                                                                          ('0100', '1200',
                                                                           '0200')) = 0
                                                          AND delivery_channel = '02'
                                                             THEN 'Signature '
                                                       END
                                                    || ctm_tran_desc
                                                    || ' FEE'
                                                   )
                                           END
                                        || CASE
                                              WHEN delivery_channel IN ('01', '02')
                                              AND NVL (internation_ind_response, 0) = '0'
                                                 THEN ' (Domestic)'
                                              WHEN delivery_channel IN ('01', '02')
                                              AND NVL (internation_ind_response, 0) = '1'
                                                 THEN ' (International)'
                                           END trndesc
                                   FROM cms_transaction_mast, transactionlog a
                                  WHERE ctm_inst_code = 1
                                    AND ctm_delivery_channel = delivery_channel
                                    AND ctm_tran_code = txn_code
                                    AND instcode = 1) b
                UNION ALL
                SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                a.clf_field_name fieldname, b.transcd code,
                                b.trndesc description
                           FROM (SELECT clf_file_id, clf_field_name
                                   FROM cms_lookup_file
                                  WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                (SELECT    txn_code
                                        || delivery_channel
                                        || NVL (internation_ind_response, 0)
                                        || CASE
                                              WHEN (SELECT COUNT (*)
                                                      FROM transactionlog
                                                     WHERE ROWID = a.ROWID
                                                       AND (   (    delivery_channel = '01'
                                                                AND txn_code IN (10, 30)
                                                                AND msgtype = '0200'
                                                               )
                                                            OR (    delivery_channel = '02'
                                                                AND txn_code IN
                                                                             (11, 14, 16, 31)
                                                                AND msgtype IN
                                                                       ('0100', '1200',
                                                                        '0200')
                                                               )
                                                           )) > 0
                                                 THEN '1'
                                              ELSE '0'
                                           END
                                        || 0
                                        || (CASE
                                               WHEN delivery_channel IN ('03')
                                               AND txn_code IN
                                                      ('20', '13', '14', '19', '83', '74',
                                                       '86', '85', '84', '76', '12', '11',
                                                       '75')
                                                  THEN LPAD
                                                         (NVL
                                                             ((SELECT TO_CHAR
                                                                            (csr_spprt_rsncode)
                                                                 FROM cms_spprt_reasons
                                                                WHERE csr_reasondesc =
                                                                                      a.reason
                                                                  AND csr_inst_code =
                                                                                    a.instcode),
                                                              '0'
                                                             ),
                                                          3,
                                                          '0'
                                                         )
                                               ELSE '000'
                                            END
                                           ) transcd,
                                           CASE
                                              WHEN delivery_channel IN ('03')
                                              AND txn_code IN ('13', '14')
                                                 THEN (SELECT    DECODE (txn_code,
                                                                         '14', 'Admin Credit-',
                                                                         'Admin Debit-'
                                                                        )
                                                              || csr_reasondesc
                                                              || DECODE (txn_code,
                                                                         '13', ' Reversal'
                                                                        )
                                                         FROM cms_spprt_reasons
                                                        WHERE csr_reasondesc = a.reason
                                                          AND csr_inst_code = a.instcode)
                                              ELSE (   (SELECT cdm_channel_desc
                                                          FROM cms_delchannel_mast
                                                         WHERE cdm_channel_code =
                                                                          ctm_delivery_channel)
                                                    || '-'
                                                    || CASE
                                                          WHEN (SELECT COUNT (*)
                                                                  FROM transactionlog
                                                                 WHERE ROWID = a.ROWID
                                                                   AND delivery_channel = '02'
                                                                   AND txn_code IN
                                                                             (11, 14, 16, 31)
                                                                   AND msgtype IN
                                                                          ('0100', '1200',
                                                                           '0200')) > 0
                                                             THEN 'PIN '
                                                          WHEN (SELECT COUNT (*)
                                                                  FROM transactionlog
                                                                 WHERE ROWID = a.ROWID
                                                                   AND delivery_channel = '02'
                                                                   AND txn_code IN
                                                                             (11, 14, 16, 31)
                                                                   AND msgtype IN
                                                                          ('0100', '1200',
                                                                           '0200')) = 0
                                                          AND delivery_channel = '02'
                                                             THEN 'Signature '
                                                       END
                                                    || ctm_tran_desc
                                                   )
                                           END
                                        || CASE
                                              WHEN delivery_channel IN ('01', '02')
                                              AND NVL (internation_ind_response, 0) = '0'
                                                 THEN ' (Domestic)'
                                              WHEN delivery_channel IN ('01', '02')
                                              AND NVL (internation_ind_response, 0) = '1'
                                                 THEN ' (International)'
                                           END trndesc
                                   FROM cms_transaction_mast, transactionlog a
                                  WHERE ctm_inst_code = 1
                                    AND ctm_delivery_channel = delivery_channel
                                    AND ctm_tran_code = txn_code
                                    AND instcode = 1) b*/
                   UNION ALL
                   SELECT   'D' record_type, a.clf_file_id fileid,
                            a.clf_field_name fieldname,
                            TO_CHAR (b.cas_stat_code) code,
                            b.cas_stat_desc description
                       FROM (SELECT clf_file_id, clf_field_name
                               FROM cms_lookup_file
                              WHERE clf_column_name = 'CAS_STAT_CODE') a,
                            (SELECT cas_stat_code, cas_stat_desc
                               FROM cms_acct_stat
                              WHERE cas_inst_code = 1) b
                   ORDER BY 2, 3)
         LOOP
            v_cnt := v_cnt + 1;
            wrt_buff :=
                  RPAD (i.record_type, 1, ' ')
               || RPAD (i.fileid, 1, ' ')
               || RPAD (i.fieldname, 30, ' ')
               || RPAD (i.code, 10, ' ')
               || RPAD (i.description, 50, ' ');                   --||'0D0A';
            UTL_FILE.put_line (file_handle, wrt_buff);
         END LOOP;

         v_trailer := 'T' || 'TRAILER' || LPAD (v_cnt, 8, '0');
         wrt_buff := v_trailer;
         UTL_FILE.put_line (file_handle, wrt_buff);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg := 'From header section ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main;
      END;

--*****************************************************FIELD HEADING*******************************************

      -- --*******************************************************DATA SEGMENT*************************************************
      UTL_FILE.fclose (file_handle);
   EXCEPTION
      WHEN exp_main
      THEN
         UTL_FILE.fclose (file_handle);
      WHEN OTHERS
      THEN
         IF UTL_FILE.is_open (file_handle)
         THEN
            UTL_FILE.fclose (file_handle);
         END IF;

         DBMS_OUTPUT.put_line (SQLERRM);
   END p_lookup_rep;

--EN: TO GENERATE LOOPUP REPORT

   --Sn Added by Saravanakumar on 30-Jul-2013
   PROCEDURE p_lookup_rep_canada (p_in_directory VARCHAR2)
   AS
      file_handle   UTL_FILE.file_type;
      wrt_buff      VARCHAR2 (1000);
      fname         VARCHAR2 (100);
      v_errmsg      VARCHAR2 (500);
      exp_main      EXCEPTION;
      v_header      VARCHAR2 (500);
      v_trailer     VARCHAR2 (500);
      v_cnt         NUMBER             := 0;
   BEGIN
      v_errmsg := 'OK';

      --
      --
      BEGIN
         fname :=
                 'VMS_lookup_IRIS_' || TO_CHAR (SYSDATE, 'yyyymmdd')
                 || '.txt';
         file_handle := UTL_FILE.fopen (p_in_directory, fname, 'w');
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg := 'ERROR OPENING FILE' || SQLERRM;
            RAISE exp_main;
      END;

--*****************************************************HEADING SECTION*****************************************
      BEGIN
         v_header :=
               'H'
            || 'HEADER'
            || RPAD (' ', 50, ' ')
            || RPAD ('LOOKUP', 50, ' ')
            || TO_CHAR (SYSDATE, 'MMDDYYYY')
            || TO_CHAR (SYSDATE, 'MMDDYYYY');
         wrt_buff := v_header;
         UTL_FILE.put_line (file_handle, wrt_buff);

         FOR i IN (SELECT   'D' record_type, a.clf_file_id fileid,
                            a.clf_field_name fieldname,
                            b.car_response_id code,
                            b.car_resp_desc description
                       FROM (SELECT clf_file_id, clf_field_name
                               FROM cms_lookup_file
                              WHERE clf_column_name = 'CAR_RESPONSE_ID') a,
                            (SELECT car_response_id, car_resp_desc
                               FROM cms_addressveri_resp
                              WHERE car_inst_code = 1) b
                   UNION ALL
                   SELECT   'D' record_type, a.clf_file_id fileid,
                            a.clf_field_name fieldname,
                            TO_CHAR (   LPAD (b.cms_delivery_channel, 2, '0')
                                     || b.cms_response_id
                                    ) code,
                            b.cms_resp_desc description
                       FROM (SELECT clf_file_id, clf_field_name
                               FROM cms_lookup_file
                              WHERE clf_column_name = 'CMS_RESPONSE_ID') a,
                            (SELECT DISTINCT cms_delivery_channel,
                                             cms_response_id, cms_resp_desc
                                        FROM cms_response_mast
                                       WHERE cms_inst_code = 1) b
                   UNION ALL
                   SELECT   'D' record_type, a.clf_file_id fileid,
                            a.clf_field_name fieldname, b.cpm_prod_code code,
                            b.cpm_prod_desc description
                       FROM (SELECT clf_file_id, clf_field_name
                               FROM cms_lookup_file
                              WHERE clf_column_name = 'CPM_PROD_CODE') a,
                            (SELECT cpm_prod_code, cpm_prod_desc
                               FROM cms_prod_mast
                              WHERE cpm_inst_code = 1) b
                   UNION ALL
                   SELECT   'D' record_type, a.clf_file_id fileid,
                            a.clf_field_name fieldname, b.ccs_stat_code code,
                            b.ccs_stat_desc description
                       FROM (SELECT clf_file_id, clf_field_name
                               FROM cms_lookup_file
                              WHERE clf_column_name = 'CCS_STAT_CODE') a,
                            (SELECT ccs_stat_code, ccs_stat_desc
                               FROM cms_card_stat
                              WHERE ccs_inst_code = 1) b
                   UNION ALL
                   SELECT   'D' record_type, a.clf_file_id fileid,
                            a.clf_field_name fieldname, b.cpm_program_id code,
                            b.cpm_prod_desc description
                       FROM (SELECT clf_file_id, clf_field_name
                               FROM cms_lookup_file
                              WHERE clf_column_name = 'CPM_PROGRAM_ID') a,
                            (SELECT cpm_program_id, cpm_prod_desc
                               FROM cms_prod_mast
                              WHERE cpm_inst_code = 1) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '000000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'Signature '
                                           || ctm_tran_desc
                                           || ' (Domestic)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '010000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'PIN '
                                           || ctm_tran_desc
                                           || ' (Domestic)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '100000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'Signature '
                                           || ctm_tran_desc
                                           || ' (International)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '110000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'PIN '
                                           || ctm_tran_desc
                                           || ' (International)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '001000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'Signature '
                                           || ctm_tran_desc
                                           || '-FEE'
                                           || ' (Domestic)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '011000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'PIN '
                                           || ctm_tran_desc
                                           || '-FEE'
                                           || ' (Domestic)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '101000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'Signature '
                                           || ctm_tran_desc
                                           || '-FEE'
                                           || ' (International)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '111000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || 'PIN '
                                           || ctm_tran_desc
                                           || '-FEE'
                                           || ' (International)' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel IN
                                                                 ('01', '02')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '000000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || ctm_tran_desc trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel NOT IN
                                                           ('01', '02', '03')) b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    ctm_tran_code
                                           || ctm_delivery_channel
                                           || '001000' transcd,
                                              (SELECT    cdm_channel_desc
                                                      || '-'
                                                 FROM cms_delchannel_mast
                                                WHERE cdm_channel_code =
                                                          ctm_delivery_channel)
                                           || ctm_tran_desc
                                           || '-FEE' trndesc
                                      FROM cms_transaction_mast
                                     WHERE ctm_inst_code = 1
                                       AND ctm_delivery_channel NOT IN
                                                           ('01', '02', '03')) b
                   UNION ALL
--Sn Added on 11-Jul-2013 by saravanakumar
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    a.ctm_tran_code
                                           || a.ctm_delivery_channel
                                           || '000'
                                           || LPAD (csr_spprt_rsncode, 3, '0')
                                                                      transcd,
                                              'CSR-'
                                           || DECODE (a.ctm_tran_code,
                                                      '14', 'Admin Credit',
                                                      '13', 'Admin Debit-Reversal',
                                                      a.ctm_tran_desc
                                                     )
                                           || '-'
                                           || csr_reasondesc trndesc
                                      FROM cms_transaction_mast a,
                                           cms_spprt_reasons
                                     WHERE a.ctm_inst_code = 1
                                       AND a.ctm_delivery_channel = '03') b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    a.ctm_tran_code
                                           || a.ctm_delivery_channel
                                           || '000000' transcd,
                                              'CSR-'
                                           || DECODE (a.ctm_tran_code,
                                                      '14', 'Admin Credit',
                                                      '13', 'Admin Debit-Reversal',
                                                      a.ctm_tran_desc
                                                     ) trndesc
                                      FROM cms_transaction_mast a
                                     WHERE a.ctm_inst_code = 1
                                       AND a.ctm_delivery_channel = '03') b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    a.ctm_tran_code
                                           || a.ctm_delivery_channel
                                           || '001'
                                           || LPAD (csr_spprt_rsncode, 3, '0')
                                                                      transcd,
                                              'CSR-'
                                           || DECODE (a.ctm_tran_code,
                                                      '14', 'Admin Credit',
                                                      '13', 'Admin Debit-Reversal',
                                                      a.ctm_tran_desc
                                                     )
                                           || '-'
                                           || csr_reasondesc
                                           || '-FEE' trndesc
                                      FROM cms_transaction_mast a,
                                           cms_spprt_reasons
                                     WHERE a.ctm_inst_code = 1
                                       AND a.ctm_delivery_channel = '03') b
                   UNION ALL
                   SELECT DISTINCT 'D' record_type, a.clf_file_id fileid,
                                   a.clf_field_name fieldname, b.transcd code,
                                   b.trndesc description
                              FROM (SELECT clf_file_id, clf_field_name
                                      FROM cms_lookup_file
                                     WHERE clf_column_name = 'CTM_TRAN_CODE') a,
                                   (SELECT    a.ctm_tran_code
                                           || a.ctm_delivery_channel
                                           || '001000' transcd,
                                              'CSR-'
                                           || DECODE (a.ctm_tran_code,
                                                      '14', 'Admin Credit',
                                                      '13', 'Admin Debit-Reversal',
                                                      a.ctm_tran_desc
                                                     )
                                           || '-FEE' trndesc
                                      FROM cms_transaction_mast a
                                     WHERE a.ctm_inst_code = 1
                                       AND a.ctm_delivery_channel = '03') b
--En Added on 11-Jul-2013 by saravanakumar
                   UNION ALL
                   SELECT   'D' record_type, a.clf_file_id fileid,
                            a.clf_field_name fieldname,
                            TO_CHAR (b.cas_stat_code) code,
                            b.cas_stat_desc description
                       FROM (SELECT clf_file_id, clf_field_name
                               FROM cms_lookup_file
                              WHERE clf_column_name = 'CAS_STAT_CODE') a,
                            (SELECT cas_stat_code, cas_stat_desc
                               FROM cms_acct_stat
                              WHERE cas_inst_code = 1) b
                   ORDER BY 2, 3)
         LOOP
            v_cnt := v_cnt + 1;
            wrt_buff :=
                  RPAD (i.record_type, 1, ' ')
               || RPAD (i.fileid, 1, ' ')
               || RPAD (i.fieldname, 30, ' ')
               || RPAD (i.code, 10, ' ')
               || RPAD (i.description, 50, ' ');
            UTL_FILE.put_line (file_handle, wrt_buff);
         END LOOP;

         v_trailer := 'T' || 'TRAILER' || LPAD (v_cnt, 8, '0');
         wrt_buff := v_trailer;
         UTL_FILE.put_line (file_handle, wrt_buff);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg := 'From header section ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main;
      END;

--*****************************************************FIELD HEADING*******************************************

      -- --*******************************************************DATA SEGMENT*************************************************
      UTL_FILE.fclose (file_handle);
   EXCEPTION
      WHEN exp_main
      THEN
         UTL_FILE.fclose (file_handle);
      WHEN OTHERS
      THEN
         IF UTL_FILE.is_open (file_handle)
         THEN
            UTL_FILE.fclose (file_handle);
         END IF;

         DBMS_OUTPUT.put_line (SQLERRM);
   END p_lookup_rep_canada;

--En Added by Saravanakumar on 30-Jul-2013
--========================================================================================================

   --generate settlement transactions extract
   PROCEDURE p_generate_settle_trans (
      p_in_directory   VARCHAR2,
      p_in_date        VARCHAR2
   )
   AS
      l_file            UTL_FILE.file_type;
      l_file_name       VARCHAR2 (1000);
      l_total_records   NUMBER             := 0;

      CURSOR c
      IS
         (SELECT SUBSTR
                      (fn_dmaps_main (customer_card_no_encr),
                       1,
                       16
                      ) customer_card_no,
                 (SELECT cdm_channel_desc
                    FROM vmscms.cms_delchannel_mast
                   WHERE cdm_channel_code = delivery_channel) txn_type,
                 msgtype, trans_desc transcodedesc,
                 (SELECT cms_resp_desc
                    FROM vmscms.cms_response_mast
                   WHERE TO_CHAR (cms_response_id) =
                                                    response_id
                     AND cms_delivery_channel = delivery_channel)
                                                               response_code,
                 rrn seq_no,
                 NVL (TO_CHAR (amount, '999999999999999999.99'),
                      0
                     ) tran_amount,
                 NVL (TO_CHAR (acct_balance, '999999999999999999.99'),
                      0
                     ) acct_balance,
                 NVL (TO_CHAR (tranfee_amt, '9999999999999999999999999999.99'),
                      0
                     ) tranfee_amt,
                 (CASE
                     WHEN delivery_channel = '03'
                        THEN (SELECT ctm_credit_debit_flag
                                FROM vmscms.cms_transaction_mast b
                               WHERE b.ctm_delivery_channel =
                                                            a.delivery_channel
                                 AND b.ctm_tran_code = a.txn_code)
                     ELSE DECODE (a.cr_dr_flag, 'DR', 'DR', 'CR', 'CR', 'NA')
                  END
                 ) cr_dr_flag,
                 (CASE
                     WHEN delivery_channel = '01'
                        THEN 'PIN'
                     WHEN delivery_channel = '02' AND pos_verification = 'P'
                        THEN 'PIN'
                     WHEN delivery_channel = '02'
                     AND NVL (pos_verification, ' ') <> 'P'
                        THEN 'SIG'
                     ELSE 'NA'
                  END
                 ) "PIN/SIG",
                 ' ' "TERM LOGICAL N/W", ' ' "TERM FIID", terminal_id,
                 TO_CHAR (TO_DATE (business_date, 'yymmdd'),
                          'yymmdd'
                         ) settle_date,
                 TO_CHAR (TO_DATE (business_date, 'yyyymmdd'),
                          'mm/dd/yy'
                         ) tran_date,
                 TO_CHAR (TO_DATE (business_time, 'hh24miss'),
                          'hh24:mi:ss'
                         ) tran_time,
                 merchant_state term_name, merchant_name term_owner,
                 merchant_city term_city, mccode,
                 (SELECT cam_state_switch
                    FROM vmscms.cms_appl_pan,
                         vmscms.cms_addr_mast
                   WHERE cap_bill_addr = cam_addr_code
                     AND cap_pan_code = a.customer_card_no) cam_state_switch,
                 (SELECT cap_acct_no
                    FROM vmscms.cms_appl_pan
                   WHERE cap_pan_code = a.customer_card_no) cap_acct_no
            FROM vmscms.transactionlog a
           WHERE instcode = 1
             AND delivery_channel IN ('01', '02')
             AND network_settl_date = p_in_date
             AND txn_code NOT IN ('30', '31', '11')
             AND a.response_code = '00');
   BEGIN
      --execute immediate 'alter session set nls_date_format=''YYYY-MM-DDDD HH24:MI:SS''';
      --generate file name
      l_file_name := p_in_date || 'SettlementTransactions.csv';
      --open file
      l_file :=
         UTL_FILE.fopen (LOCATION          => p_in_directory,
                         filename          => l_file_name,
                         open_mode         => 'W',
                         max_linesize      => 4000
                        );
      --write header information
      UTL_FILE.put (l_file, 'CUSTOMERCARD NUMBER,');
      UTL_FILE.put (l_file, 'TRANSACTION_TYPE,');
      UTL_FILE.put (l_file, 'MSGTYPE,');
      UTL_FILE.put (l_file, 'TRAN CODE DESC,');
      UTL_FILE.put (l_file, 'RESPONSE CODE,');
      UTL_FILE.put (l_file, 'TRAN AMOUNT,');
      UTL_FILE.put (l_file, 'TERMINAL ID,');
      UTL_FILE.put (l_file, 'SETTLED DATE,');
      UTL_FILE.put (l_file, 'TRAN DATE,');
      UTL_FILE.put (l_file, 'TRAN TIME,');
      UTL_FILE.put (l_file, 'TERM OWNER,');
      UTL_FILE.put (l_file, 'TERM CITY,');
      UTL_FILE.put (l_file, 'MCC,');
      UTL_FILE.put (l_file, 'CAM,');
      UTL_FILE.put (l_file, 'CAP ACCT NO,');
      UTL_FILE.put (l_file, CHR (13) || CHR (10));
      --flush file to disk
      UTL_FILE.fflush (l_file);

      --write records
      FOR cur_data IN c
      LOOP
         l_total_records := l_total_records + 1;
         UTL_FILE.put (l_file, cur_data.customer_card_no || ',');
         UTL_FILE.put (l_file, cur_data.txn_type || ',');
         UTL_FILE.put (l_file, cur_data.msgtype || ',');
         UTL_FILE.put (l_file, cur_data.transcodedesc || ',');
         UTL_FILE.put (l_file, cur_data.response_code || ',');
         UTL_FILE.put (l_file, cur_data.tran_amount || ',');
         UTL_FILE.put (l_file, cur_data.terminal_id || ',');
         UTL_FILE.put (l_file, cur_data.settle_date || ',');
         UTL_FILE.put (l_file, cur_data.tran_date || ',');
         UTL_FILE.put (l_file, cur_data.tran_time || ',');
         UTL_FILE.put (l_file, cur_data.term_owner || ',');
         UTL_FILE.put (l_file, cur_data.term_city || ',');
         UTL_FILE.put (l_file, cur_data.mccode || ',');
         UTL_FILE.put (l_file, cur_data.cam_state_switch || ',');
         UTL_FILE.put (l_file, cur_data.cap_acct_no || ',');
         --end of record/carriage return and line feed
         UTL_FILE.put (l_file, CHR (13) || CHR (10));
         --flush so that buffer is emptied
         UTL_FILE.fflush (l_file);
      END LOOP;

      --flush file to disk
      UTL_FILE.fflush (l_file);
      --close file
      UTL_FILE.fclose (l_file);
   --dbms_output.put_line(l_total_records);
   EXCEPTION
      WHEN OTHERS
      THEN
         IF UTL_FILE.is_open (l_file)
         THEN
            UTL_FILE.fclose (l_file);
         END IF;

         DBMS_OUTPUT.put_line (SQLERRM);
   END p_generate_settle_trans;

   PROCEDURE p_merch_return_reversal (
      p_in_directory   VARCHAR2,
      p_from_date      DATE,
      p_to_date        DATE
   )
   AS
      l_file            UTL_FILE.file_type;
      l_file_name       VARCHAR2 (1000);
      l_file_created    VARCHAR2 (10)      := 'FALSE';
      l_total_records   NUMBER             := 0;
      l_to_date         DATE;

      CURSOR c
      IS
         SELECT customer_acct_no account_number,
                SUBSTR
                   (vmscms.fn_dmaps_main (customer_card_no_encr),
                    13,
                    16
                   ) last4digits_cardbnumber,
                TO_CHAR (add_ins_date,
                         'MM-DD-YYYY HH24:MI:SS'
                        ) transaction_date_time
           FROM transactionlog
          WHERE delivery_channel = '02'
            AND txn_code = '25'
            AND response_code = '12'
            AND msgtype = '9220'
            AND add_ins_date BETWEEN p_from_date AND p_to_date;
   BEGIN
      FOR cur_data IN c
      LOOP
         IF l_file_created = 'FALSE'
         THEN
            --create file
            l_file_name :=
                  TO_CHAR (p_from_date, 'YYYYMMDDHH24MISS')
               || '_'
               || TO_CHAR (p_to_date, 'YYYYMMDDHH24MISS')
               || '_MerchRetRev.csv';
            --open file
            l_file :=
               UTL_FILE.fopen (LOCATION          => p_in_directory,
                               filename          => l_file_name,
                               open_mode         => 'W',
                               max_linesize      => 4000
                              );
            UTL_FILE.put (l_file, 'Account_number,');
            UTL_FILE.put (l_file, 'Last 4 Digits,');
            UTL_FILE.put (l_file, 'Transaction Date Time');
            --end of record/carriage return and line feed
            UTL_FILE.put (l_file, CHR (13) || CHR (10));
            l_file_created := 'TRUE';
         END IF;

         l_total_records := l_total_records + 1;
         UTL_FILE.put (l_file, cur_data.account_number || ',');
         UTL_FILE.put (l_file, cur_data.last4digits_cardbnumber || ',');
         UTL_FILE.put (l_file, cur_data.transaction_date_time);
         --end of record/carriage return and line feed
         UTL_FILE.put (l_file, CHR (13) || CHR (10));
         --flush so that buffer is emptied
         UTL_FILE.fflush (l_file);
      END LOOP;

      --flush file to disk
      UTL_FILE.fflush (l_file);
      --close file
      UTL_FILE.fclose (l_file);

      INSERT INTO vmscms.merch_return_reversal
                  (from_date, TO_DATE, tot_transactions
                  )
           VALUES (p_from_date, p_to_date, l_total_records
                  );

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF UTL_FILE.is_open (l_file)
         THEN
            UTL_FILE.fclose (l_file);
         END IF;
   END p_merch_return_reversal;

   PROCEDURE p_person (
      p_in_directory   VARCHAR2,
      p_from_date      DATE,
      p_to_date        DATE
   )
   AS
      l_file        UTL_FILE.file_type;
      l_file_name   VARCHAR2 (1000);
      l_rec_cnt     NUMBER             := 0;

      CURSOR c
      IS
         --This will fetch Customer Information
         -- Above query is used to fetch all records.
         --To retrieve data for perticular date range then uncomment the last two lines of query and replace ? with date .
         SELECT DISTINCT 'D' record_type, cap_acct_no person_identifier,
                         cap_acct_no person_reference_number,
                         '' hierarchy_identifier, 'CUSTOMER' person_type,
                         'CUSTOMER' person_role, ccm_first_name first_name,
                         ccm_last_name last_name,
                         NVL (TO_CHAR (ccm_birth_date, 'MMDDYYYY'),
                              ''
                             ) birth_date,
                         cam_add_one address_line_1,
                         cam_add_two address_line_2, cam_city_name city,
                         (SELECT gsm_state_name
                            FROM gen_state_mast
                           WHERE gsm_inst_code = cam_inst_code
                             AND gsm_cntry_code = cam_cntry_code
                             AND gsm_state_code = cam_state_code) state,
                         cam_pin_code zip_code,
                         cam_cntry_code prim_phone_no_cntry_code,
                         '' prim_phone_no_area_code,
                         SUBSTR
                            (fn_spclchar_chekdmg (cam_phone_one),
                             -7,
                             7
                            ) primary_phone_number,
                         cam_cntry_code sec_phone_no_cntry_code,
                         '' sec_phone_no_area_code,
                         SUBSTR
                            (fn_spclchar_chekdmg (cam_phone_two),
                             0,
                             10
                            ) secondary_phone_number,  -- added 26 April 2013
                         '' identification_value,
                         '' identification_value_type,
                         '' identification_value2,
                         '' identification_value_type2
                    FROM cms_appl_pan,
                         cms_cust_mast,
                         cms_addr_mast,
                         cms_iris_prodcatgmast d
                   WHERE ccm_inst_code = cap_inst_code
                     AND ccm_cust_code = cap_cust_code
                     AND cap_inst_code = cam_inst_code
                     AND cap_bill_addr = cam_addr_code
                     AND d.cpm_inst_code = cap_inst_code
                     AND d.cpm_prod_code = cap_prod_code
                     AND d.cpm_catg_code = cap_card_type
                     AND d.cpm_iris_flag = 'Y'
                     AND DECODE (cap_startercard_flag,
                                 'Y', cap_firsttime_topup,
                                 cap_firsttime_topup
                                ) =
                            DECODE (cap_startercard_flag,
                                    'Y', 'Y',
                                    cap_firsttime_topup
                                   )
                     --in QA it is set to
                     --AND cap_prod_code='MP49'
                     --in PROD
                     AND cap_prod_code <> 'VP73'
                                               --   AND (trunc(cap_lupd_date)  between trunc(p_from_date) and trunc(p_to_date)
                                               --   OR    trunc(cap_ins_date)   between trunc(p_from_date) and trunc(p_to_date) )
                                               --AND (trunc(cap_lupd_date)   = trunc(?)
                                               --OR trunc(cap_ins_date)      = trunc(?) )
      ;
   BEGIN
      --generate file name
      l_file_name :=
                'PERSN01101' || TO_CHAR (p_from_date, 'MMDDYYYY')
                --TO_CHAR (SYSDATE, 'MMDDYYYY') Modified on 11-Jul-2013 by saravanankumar
                || '001.csv';
      --open file
      l_file :=
         UTL_FILE.fopen (LOCATION          => p_in_directory,
                         filename          => l_file_name,
                         open_mode         => 'W',
                         max_linesize      => 4000
                        );
      UTL_FILE.put (l_file, 'Record_Type');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Person_Identifier');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Personal_Reference_Number');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Hierarchy_Identifier');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Person_Type  ');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Person_Role');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'First_Name');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Last_Name');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Birth_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Address_Line_1');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Address_Line_2');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'City');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'State');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Zip_Code');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Primary_Phone_Number_Country_Code');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Primary_Phone_Number_Area_Code');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Primary_Phone_Number');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Secondary_Phone_Number_Country_Code  ');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Secondary_Phone_Number_Area_Code');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Secondary_Phone_Number');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Identification_Value');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Identification_Value_Type');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Identification_Value2');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Identification_Value_Type2');
      UTL_FILE.put (l_file, CHR (13) || CHR (10));

      --write data
      FOR c_person IN c
      LOOP
         l_rec_cnt := l_rec_cnt + 1;
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.record_type);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.person_identifier);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.person_reference_number);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.hierarchy_identifier);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.person_type);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.person_role);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.first_name);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.last_name);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.birth_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.address_line_1);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.address_line_2);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.city);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.state);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.zip_code);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.prim_phone_no_cntry_code);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.prim_phone_no_area_code);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.primary_phone_number);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.sec_phone_no_cntry_code);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.sec_phone_no_area_code);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.secondary_phone_number);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.identification_value);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.identification_value_type);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.identification_value2);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.identification_value_type2);
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, CHR (13) || CHR (10));
         --flush file
         UTL_FILE.fflush (l_file);
      END LOOP;

      --add trailer record
      UTL_FILE.put (l_file, '"');
      UTL_FILE.put (l_file, 'Z');
      UTL_FILE.put (l_file, '",');
      UTL_FILE.put (l_file, '"');
      UTL_FILE.put (l_file, l_rec_cnt);
      UTL_FILE.put (l_file, '"');
      UTL_FILE.put (l_file, CHR (13) || CHR (10));
      --flush file
      UTL_FILE.fflush (l_file);
      --close file
      UTL_FILE.fclose (l_file);
   EXCEPTION
      WHEN OTHERS
      THEN
         IF UTL_FILE.is_open (l_file)
         THEN
            UTL_FILE.fclose (l_file);
         END IF;

         DBMS_OUTPUT.put_line (SQLERRM);
   END p_person;

   PROCEDURE p_card (p_in_directory VARCHAR2, p_from_date DATE, p_to_date DATE)
   AS
      l_file        UTL_FILE.file_type;
      l_file_name   VARCHAR2 (1000);
      l_rec_cnt     NUMBER             := 0;

      CURSOR c
      IS
            --This will fetch Card Information
         -- Above query is used to fetch all records.
         --To retrieve data for perticular date range then uncomment the last two lines of query and replace ? with date .
         SELECT *
           FROM (SELECT record_type, account_number, card_id, customer_prn,
                        program_id, product_id, GROUP_ID, card_type,
                        card_status,
                        NVL2 (card_status_date,
                              card_status_date || ':000',
                              card_status_date
                             ) card_status_date,
                        primary_card_indicator, authentication_type,
                        number_of_plastics, card_activation_date,
                        CASE
                           WHEN cap_startercard_flag = 'Y'
                              THEN card_issued_date1
                           ELSE card_first_mailed_date
                        END card_issued_date,
                        last_reissued_date, card_expiration_date,
                        card_first_mailed_date, card_last_mailed_date, opt_in,
                        card_transfer_number_from, card_transfer_number_to,
                        ROW_NUMBER () OVER (PARTITION BY account_number ORDER BY pan_gen_date DESC)
                                                                        ranks
                   -- Added by Besky on 21/06/13
                 FROM   (SELECT 'D' record_type, cap_acct_no account_number,
                                cap_startercard_flag,
                                cap_proxy_number card_id,

                                -- added 26 April 2013
                                cap_acct_no customer_prn, m.cpm_program_id program_id,
                                m.cpb_inst_bin
                                || m.cpc_prod_prefix product_id,
                                '' GROUP_ID,
                                m.cpb_inst_bin || m.cpc_prod_prefix card_type,
                                CASE
                                   WHEN LENGTH (cap_card_stat) =
                                                                1
                                      THEN '0' || cap_card_stat
                                   ELSE cap_card_stat
                                END card_status,
                                TO_CHAR
                                   ((SELECT cps_ins_date
                                       FROM cms_pan_spprt
                                      WHERE cps_spprt_key = 'chngestat'
                                        AND cps_pan_code = cap_pan_code),
                                    'MMDDYYYY HH:MI:SS'
                                   ) card_status_date,
                                '1' primary_card_indicator,
                                '' authentication_type, '' number_of_plastics,
                                NVL
                                   (TO_CHAR (cap_active_date, 'MMDDYYYY'),
                                    'NA'
                                   ) card_activation_date,

                                --TO_CHAR (cap_pangen_date, 'MMDDYYYY') card_issued_date,
                                (SELECT TO_CHAR
                                           (MAX (add_ins_date),
                                            'MMDDYYYY'
                                           )
                                   FROM transactionlog
                                  WHERE customer_card_no = cap_pan_code
                                    AND delivery_channel IN ('08', '04')
                                    AND txn_code IN ('68', '26')
                                    AND response_code = '00')
                                                            card_issued_date1,
                                '' last_reissued_date,
                                TO_CHAR (cap_expry_date,
                                         'MMDDYYYY'
                                        ) card_expiration_date,
                                TO_CHAR
                                   ((SELECT ccs_lupd_date
                                       FROM cms_cardissuance_status
                                      WHERE ccs_card_status = 15
                                        AND ccs_pan_code = cap_pan_code),
                                    'MMDDYYYY'
                                   ) card_first_mailed_date,
                                '' card_last_mailed_date,
                                '' card_transfer_number_from,
                                '' card_transfer_number_to, '0' opt_in,
                                a.cap_pangen_date pan_gen_date
                           -- Added by Besky on 21/06/13
                         FROM   (SELECT p.cpm_prod_desc, p.cpc_inst_code,
                                        p.cpm_prod_code, p.cpc_card_type,
                                        p.cpc_cardtype_desc,
                                        p.cpc_prod_prefix, g.cpb_inst_bin,p.cpm_program_id
                                   FROM (SELECT b.cpm_prod_desc,
                                                c.cpc_inst_code,
                                                b.cpm_prod_code,
                                                b.cpm_inst_code,
                                                c.cpc_card_type,
                                                c.cpc_cardtype_desc,
                                                cpc_prod_prefix,
                                                b.cpm_program_id
                                           FROM cms_prod_mast b,
                                                cms_iris_prodcatgmast e,
                                                cms_prod_cattype c
                                          WHERE b.cpm_inst_code =
                                                                 cpc_inst_code
                                            AND b.cpm_prod_code =
                                                                 cpc_prod_code
                                            AND cpc_inst_code =
                                                               e.cpm_inst_code
                                            AND cpc_prod_code =
                                                               e.cpm_prod_code
                                            AND cpc_card_type =
                                                               e.cpm_catg_code
                                            AND e.cpm_iris_flag = 'Y') p,
                                        cms_prod_bin g
                                  WHERE p.cpm_inst_code = g.cpb_inst_code
                                    AND p.cpm_prod_code = g.cpb_prod_code) m,
                                cms_appl_pan a,
                                cms_cust_mast cm
                          WHERE m.cpc_inst_code = a.cap_inst_code
                            AND m.cpm_prod_code = a.cap_prod_code
                            AND m.cpc_card_type = a.cap_card_type
                            --in QA it is set to
                            --AND cap_prod_code='MP49'
                            --in PROD
                            AND cap_prod_code <> 'VP73'
                            AND ccm_cust_code = a.cap_cust_code
                                                               --AND a.cap_pangen_date in (select max(cap_pangen_date) from cms_appl_pan where cap_acct_no=a.cap_acct_no) -- Commented by Besky on 21/06/13
                                                                                                  --   AND (trunc(a.cap_lupd_date)  between trunc(p_from_date) and trunc(p_to_date)
                                                                                                    --  OR    trunc(a.cap_ins_date)   between trunc(p_from_date) and trunc(p_to_date) )
                        ) nn)
          WHERE ranks = 1;                       -- Added by Besky on 21/06/13
       --This will fetch Card Information
       -- Above query is used to fetch all records.
       --To retrieve data for perticular date range then uncomment the last two lines of query and replace ? with date .
      /* SELECT record_type, account_number, card_id, customer_prn, program_id,
          product_id, GROUP_ID, card_type, card_status,
          NVL2 (card_status_date, card_status_date || ':000', card_status_date) card_status_date,
          primary_card_indicator, authentication_type, number_of_plastics,
          card_activation_date, card_issued_date, last_reissued_date,
          card_expiration_date, card_first_mailed_date, card_last_mailed_date,opt_in,
          card_transfer_number_from, card_transfer_number_to
       FROM (SELECT 'D' record_type, cap_acct_no account_number,
                  ccm_cust_code card_id, cap_proxy_number customer_prn,
                  --IRIS cannot consume description
                  --hard coding it to 1234 which is in the lookup file
                  --m.cpm_prod_desc program_id,
                  '1234' program_id,
                  m.cpb_inst_bin || m.cpc_prod_prefix product_id, '' GROUP_ID,
                  m.cpb_inst_bin || m.cpc_prod_prefix card_type,
                  cap_card_stat card_status,
                  TO_CHAR ((SELECT cps_ins_date
                              FROM cms_pan_spprt
                             WHERE cps_spprt_key = 'chngestat'
                               AND cps_pan_code = cap_pan_code),
                           'MMDDYYYY HH:MI:SS'
                          ) card_status_date,
                  '1' primary_card_indicator, '' authentication_type,
                  '' number_of_plastics,
                  NVL (TO_CHAR (cap_active_date, 'MMDDYYYY'),
                       'NA'
                      ) card_activation_date,
                  TO_CHAR (cap_pangen_date, 'MMDDYYYY') card_issued_date,
                  '' last_reissued_date,
                  TO_CHAR (cap_expry_date, 'MMDDYYYY') card_expiration_date,
                  TO_CHAR
                         ((SELECT ccs_ins_date
                             FROM cms_cardissuance_status
                            WHERE ccs_card_status = 15
                              AND ccs_pan_code = cap_pan_code),
                          'MMDDYYYY'
                         ) card_first_mailed_date,'' card_last_mailed_date,
                   '' card_transfer_number_from,'' card_transfer_number_to,'0' opt_in
               FROM     (SELECT p.cpm_prod_desc, p.cpc_inst_code, p.cpm_prod_code,
                          p.cpc_card_type, p.cpc_cardtype_desc,
                          p.cpc_prod_prefix, g.cpb_inst_bin
                     FROM (SELECT b.cpm_prod_desc, c.cpc_inst_code,
                                  b.cpm_prod_code, b.cpm_inst_code,
                                  c.cpc_card_type, c.cpc_cardtype_desc,
                                  cpc_prod_prefix
                             FROM cms_prod_mast b,
                                 cms_iris_prodcatgmast e, cms_prod_cattype c
                            WHERE b.cpm_inst_code = cpc_inst_code
                              AND b.cpm_prod_code = cpc_prod_code
                              AND cpc_inst_code = e.cpm_inst_code
                              AND cpc_prod_code = e.cpm_prod_code
                              AND cpc_card_type = e.cpm_catg_code
                              AND e.cpm_iris_flag = 'Y') p,  cms_prod_bin g
                    WHERE p.cpm_inst_code = g.cpb_inst_code
                      AND p.cpm_prod_code = g.cpb_prod_code) m,cms_appl_pan a,cms_cust_mast cm
            WHERE m.cpc_inst_code = a.cap_inst_code
              AND m.cpm_prod_code = a.cap_prod_code
              AND m.cpc_card_type = a.cap_card_type
              --in QA it is set to
              --AND cap_prod_code='MP49'
              --in PROD
              AND cap_prod_code='VP72'
              and ccm_cust_code=a.cap_cust_code
              --     AND (trunc(a.cap_lupd_date)   = trunc(?)
             --      OR    trunc(a.cap_ins_date)     = trunc(?) )
         ) nn
       ;
   */
   BEGIN
      --generate file name
      l_file_name :=
                'CARDD01103' || TO_CHAR (p_from_date, 'MMDDYYYY')
                --TO_CHAR (SYSDATE, 'MMDDYYYY')Modified on 11-Jul-2013 by saravanankumar
                || '001.csv';
      --open file
      l_file :=
         UTL_FILE.fopen (LOCATION          => p_in_directory,
                         filename          => l_file_name,
                         open_mode         => 'W',
                         max_linesize      => 4000
                        );
      UTL_FILE.put (l_file, 'Record_Type');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Account_Number');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Card_ID');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Customer_PRN');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Program_ID');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Product_ID');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Group_ID');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Card_Type');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Card_Status');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Card_Status_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Primary_Card_Indicator');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Authentication_Type');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Number_of_Plastics');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Card_Activation_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Card_Issued_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Last_Reissued_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Card_Expiration_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Card_First_Mailed_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Card_Last_Mailed_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Card_Transfer_Number_From');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Card_Transfer_Number_To');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'OPTIN');
      UTL_FILE.put (l_file, CHR (13) || CHR (10));

      --write data
      FOR c_person IN c
      LOOP
         l_rec_cnt := l_rec_cnt + 1;
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.record_type);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.account_number);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.card_id);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.customer_prn);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.program_id);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.product_id);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.GROUP_ID);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.card_type);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.card_status);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.card_status_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.primary_card_indicator);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.authentication_type);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.number_of_plastics);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.card_activation_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.card_issued_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.last_reissued_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.card_expiration_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.card_first_mailed_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.card_last_mailed_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.card_transfer_number_from);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.card_transfer_number_to);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.opt_in);
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, CHR (13) || CHR (10));
         --flush file
         UTL_FILE.fflush (l_file);
      END LOOP;

      --add trailer record
      UTL_FILE.put (l_file, '"');
      UTL_FILE.put (l_file, 'Z');
      UTL_FILE.put (l_file, '",');
      UTL_FILE.put (l_file, '"');
      UTL_FILE.put (l_file, l_rec_cnt);
      UTL_FILE.put (l_file, '"');
      UTL_FILE.put (l_file, CHR (13) || CHR (10));
      --flush file
      UTL_FILE.fflush (l_file);
      --close file
      UTL_FILE.fclose (l_file);
   EXCEPTION
      WHEN OTHERS
      THEN
         IF UTL_FILE.is_open (l_file)
         THEN
            UTL_FILE.fclose (l_file);
         END IF;

         DBMS_OUTPUT.put_line (SQLERRM);
   END p_card;

   PROCEDURE p_account (
      p_in_directory   VARCHAR2,
      p_from_date      DATE,
      p_to_date        DATE
   )
   AS
      l_file                    UTL_FILE.file_type;
      l_file_name               VARCHAR2 (1000);
      l_rec_cnt                 NUMBER                                   := 0;
      v_rept_id                 NUMBER (15);
      v_err_msg                 VARCHAR2 (300);
      excp_raise                EXCEPTION;
      v_curr_bal                cms_acct_report.current_balance%TYPE;
      v_sign                    cms_acct_report.current_balance_sign%TYPE;
      v_avail_bal_sign          cms_acct_report.available_balance_sign%TYPE;
      v_avail_balance           cms_acct_report.available_balance%TYPE;
      v_last_transaction_date   cms_acct_report.last_transaction_date%TYPE;

      CURSOR c1 (c_rept_id NUMBER, c_acct_no VARCHAR2)
      IS
         SELECT a.*, a.ROWID row_id
           FROM cms_acct_report a
          WHERE rept_id = c_rept_id AND account_number = c_acct_no;

      CURSOR c (c_rept_id NUMBER)
      IS
         --This will fetch Account Information
         -- Above query is use to fetch all records .
         --If wants to retrieve data for perticular date range then uncomment the last two lines of query
         SELECT *
           FROM cms_acct_report
          WHERE rept_id = c_rept_id;            -- Added by Besky on 21/06/13
   BEGIN
      BEGIN
         SELECT seq_acct_rept_id.NEXTVAL
           INTO v_rept_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Error while selecting rept id for account report as '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_raise;
      END;

      BEGIN
         INSERT INTO cms_acct_report
                     (rept_id, acct_rept_date, record_type, account_number,
                      program_id, location_id, agent_user_id, product_id,
                      GROUP_ID, account_type, account_status,
                      account_status_date, account_created_date,
                      account_expiration_date, reloadable_indicator,
                      credit_line, available_credit, secured_amount,
                      current_balance, current_balance_sign,
                      current_payment_due_date, available_balance,
                      available_balance_sign, negative_balance_fee_amount,
                      negative_bal_principle_amount,
                      cash_advance_outstanding, negative_balance_date,
                      delinquent_amount, delinquent_days, bill_cycle_day,
                      account_transfer_number_to,
                      account_transfer_number_from, enrollment_number,
                      external_account_number, first_load_date,
                      last_reage_date, last_statement_date,
                      last_transaction_date, account_currency_code)
            SELECT v_rept_id, TRUNC (p_to_date), record_type, account_number,
                   program_id, location_id, agent_user_id, product_id,
                   GROUP_ID, account_type, account_status,
                   account_status_date, account_created_date,
                   account_expiration_date, reloadable_indicator,
                   credit_line, available_credit, secured_amount,
                   current_balance, current_balance_sign,
                   current_payment_due_date, available_balance,
                   available_balance_sign, negative_balance_fee_amount,
                   negative_bal_principle_amount, cash_advance_outstanding,
                   negative_balance_date, delinquent_amount, delinquent_days,
                   bill_cycle_day, account_transfer_number_to,
                   account_transfer_number_from, enrollment_number,
                   external_account_number, first_load_date, last_reage_date,
                   last_statement_date, last_transaction_date,
                   account_currency_code
              FROM (SELECT record_type, account_number, program_id,
                           location_id, agent_user_id, product_id, GROUP_ID,
                           account_type, account_status, account_status_date,
                           account_created_date, account_expiration_date,
                           reloadable_indicator, credit_line,
                           available_credit, secured_amount, current_balance,
                           current_balance_sign, current_payment_due_date,
                           available_balance, available_balance_sign,
                           negative_balance_fee_amount,
                           negative_bal_principle_amount,
                           cash_advance_outstanding, negative_balance_date,
                           delinquent_amount, delinquent_days, bill_cycle_day,
                           account_transfer_number_to,
                           account_transfer_number_from, enrollment_number,
                           external_account_number,
                           NVL2 (first_load_date,
                                 first_load_date || '.000',
                                 first_load_date
                                ) first_load_date,
                           last_reage_date, last_statement_date,
                           NVL2
                              (last_transaction_date,
                               last_transaction_date || '.000',
                               last_transaction_date
                              ) last_transaction_date,
                           account_currency_code,
                           ROW_NUMBER () OVER (PARTITION BY account_number ORDER BY pan_gen_date DESC)
                                                                        ranks
                      -- Added by Besky on 21/06/13
                    FROM   (SELECT 'D' record_type,
                                   cam_acct_no account_number,
                                   
                                   --IRIS cannot consume description
                                   --hard coding it to 1234 which is in the lookup file
                                   --m.cpm_prod_desc program_id,
                                   c.cpm_program_id program_id,
                                   RPAD
                                      (NVL ((SELECT cci_store_id
                                               FROM cms_caf_info_entry
                                              WHERE cci_appl_code =
                                                               b.cap_appl_code
                                                AND cci_inst_code =
                                                               b.cap_inst_code
                                                AND cci_pan_code =
                                                                b.cap_pan_code),
                                            '0'
                                           ),
                                       20
                                      ) location_id,
                                   '' agent_user_id,
                                      g.cpb_inst_bin
                                   || h.cpc_prod_prefix product_id,
                                   '' GROUP_ID, cam_type_code account_type,
                                   '1' account_status,
                                   TO_CHAR (cam_ins_date,
                                            'MMDDYYYY'
                                           ) account_status_date,
                                   TO_CHAR
                                          (cam_ins_date,
                                           'MMDDYYYY'
                                          ) account_created_date,
                                   '' account_expiration_date,
                                   '1' reloadable_indicator, '' credit_line,
                                   '' available_credit, '' secured_amount,
                                   TO_CHAR
                                        (ABS (cam_ledger_bal),
                                         '9999999990.99'
                                        ) current_balance,
                                   DECODE
                                      (cam_ledger_bal,
                                       NULL, '',
                                       DECODE
                                          (SIGN (cam_ledger_bal),
                                           '0', 1,
                                           '1', 1,
                                           '-1', -1
                                          )             -- Added 26 April 2013
                                      ) current_balance_sign,
                                   '' current_payment_due_date,
                                   TO_CHAR
                                        (ABS (cam_acct_bal),
                                         '9999999990.99'
                                        ) available_balance,
                                   DECODE
                                      (cam_acct_bal,
                                       NULL, '',
                                       DECODE
                                          (SIGN (cam_acct_bal),
                                           '0', 1,
                                           '1', 1,
                                           '-1', -1
                                          )             -- Added 26 April 2013
                                      ) available_balance_sign,
                                   '' negative_balance_fee_amount,
                                   '' negative_bal_principle_amount,
                                   '' cash_advance_outstanding,
                                   '' negative_balance_date,
                                   '' delinquent_amount, '' delinquent_days,
                                   '' bill_cycle_day,
                                   '' account_transfer_number_to,
                                   '' account_transfer_number_from,
                                   '' enrollment_number,
                                   '' external_account_number,
                                   TO_CHAR
                                      ((SELECT MIN (cps_ins_date)
                                          FROM cms_pan_spprt
                                         WHERE cps_spprt_key IN
                                                            ('INLOAD', 'TOP')
                                           AND cps_inst_code = b.cap_inst_code
                                           AND cps_pan_code = b.cap_pan_code),
                                       'MMDDYYYY HH24:MI:SS'
                                      ) first_load_date,
                                   '' last_reage_date, '' last_statement_date,
                                   
                                   /*TO_CHAR
                                      ((SELECT MAX
                                                  (fn_check_date
                                                             (   business_date
                                                              || business_time
                                                             )
                                                  )
                                          FROM transactionlog
                                         WHERE customer_card_no =
                                                                b.cap_pan_code
                                           AND TRUNC (add_ins_date) <=
                                                             TRUNC (p_to_date)),
                                       'MMDDYYYY HH24:MI:SS'
                                      ) last_transaction_date,*/-- Changed on 16-AUG-2013 for last transaction date of fin txns
                                   TO_CHAR
                                      ((SELECT MAX (csl_ins_date)
                                          FROM cms_statements_log
                                         WHERE csl_acct_no = a.cam_acct_no
                                           -- Changed by Ganesh on 16-AUG-2013
                                           --WHERE csl_pan_no = b.cap_pan_code
                                           AND TRUNC (csl_ins_date) <=
                                                             TRUNC (p_to_date)),
                                       'MMDDYYYY HH24:MI:SS'
                                      ) last_transaction_date,
                                   
                                   -- Changed on 16-AUG-2013 for last transaction date of fin txns
                                   (SELECT gcm_curr_name
                                      FROM cms_bin_param,
                                           gen_curr_mast
                                     WHERE cbp_profile_code =
                                                            c.cpm_profile_code
                                       AND cbp_inst_code = c.cpm_inst_code
                                       AND cbp_param_name = 'Currency'
                                       AND gcm_curr_code = cbp_param_value
                                       AND gcm_inst_code = cbp_inst_code)
                                                        account_currency_code,
                                b.cap_pangen_date pan_gen_date
                           -- Added by Besky on 21/06/13
                         FROM   cms_acct_mast a,
                                cms_appl_pan b,
                                cms_prod_mast c,
                                cms_iris_prodcatgmast d,
                                cms_prod_bin g,
                                cms_prod_cattype h
                          WHERE b.cap_inst_code = a.cam_inst_code
                            AND b.cap_acct_id = a.cam_acct_id
                            AND c.cpm_inst_code = cap_inst_code
                            AND c.cpm_prod_code = cap_prod_code
                            AND d.cpm_inst_code = cap_inst_code
                            AND d.cpm_prod_code = cap_prod_code
                            AND d.cpm_catg_code = cap_card_type
                            AND c.cpm_inst_code = g.cpb_inst_code
                            AND c.cpm_prod_code = g.cpb_prod_code
                            AND h.cpc_inst_code = c.cpm_inst_code
                            AND h.cpc_prod_code = c.cpm_prod_code
                            AND b.cap_card_type = h.cpc_card_type
                            AND d.cpm_iris_flag = 'Y'
                            AND cap_prod_code <> 'VP73'
                                                      --    AND (trunc(cap_lupd_date)  between trunc(p_from_date) and trunc(p_to_date)
                                                      --       OR    trunc(cap_ins_date)    between trunc(p_from_date) and trunc(p_to_date) )

                        -- AND (trunc(cap_lupd_date)   = trunc(sysdate-1)
                                                                                                                  --  OR trunc(cap_ins_date)       = trunc(sysdate-1))
                        ))
          WHERE ranks = 1; 
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Error while inserting account details in cms_acct_report as '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_raise;
      END;

      FOR j IN (SELECT cam_acct_no
                  FROM cms_acct_mast
                 WHERE cam_lupd_date >
                          TO_DATE (   TO_CHAR (TRUNC (p_to_date), 'YYYYMMDD')
                                   || ' 23:59:59',
                                   'YYYYMMDD HH24:MI:SS'
                                  ))
      LOOP
         BEGIN
            FOR i IN c1 (v_rept_id, j.cam_acct_no)
            LOOP
               BEGIN
                  SELECT   (SELECT cam_ledger_bal
                              FROM cms_acct_mast
                             WHERE cam_acct_no = j.cam_acct_no)
                         - mm.total_transaction
                    INTO v_curr_bal
                    FROM (SELECT TO_CHAR
                                    (NVL (SUM (DECODE (csl_trans_type,
                                                       'CR', csl_trans_amount,
                                                       'DR', -csl_trans_amount
                                                      )
                                              ),
                                          0
                                         ),
                                     '9999999990.99'
                                    ) total_transaction
                            FROM cms_statements_log
                           WHERE csl_acct_no = j.cam_acct_no
                             AND TO_DATE (TO_CHAR (csl_ins_date,
                                                   'YYYYMMDD HH24:MI:SS'
                                                  ),
                                          'YYYYMMDD HH24:MI:SS'
                                         ) >
                                    TO_DATE (   TO_CHAR (TRUNC (p_to_date),
                                                         'YYYYMMDD'
                                                        )
                                             || ' 23:59:59',
                                             'YYYYMMDD HH24:MI:SS'
                                            )) mm;

                  IF v_curr_bal >= 0
                  THEN
                     v_sign := '1';
                  ELSE
                     v_sign := '-1';
                  END IF;

                  -- SN : Changed below query on 16-AUG-2013 Removed last transaction date from query
                  BEGIN
                     SELECT acct_balance
                       INTO v_avail_balance
                       FROM (SELECT   acct_balance, add_ins_date
                                 FROM transactionlog a
                                WHERE customer_card_no IN (
                                             SELECT cap_pan_code
                                               FROM cms_appl_pan
                                              WHERE cap_acct_no =
                                                                 j.cam_acct_no)
                                  AND TRUNC (add_ins_date) <=
                                                             TRUNC (p_to_date)
                                  AND acct_balance IS NOT NULL
                             ORDER BY add_ins_date DESC, a.ROWID DESC)
                      WHERE ROWNUM < 2;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_avail_balance := NULL;
                     WHEN OTHERS
                     THEN
                        v_err_msg :=
                              'ERROR WHILE SELECTING AVAILABLE BALANCE FOR ACCT FILE IS '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE excp_raise;
                  END;

                  -- SN : Changed below query on 16-AUG-2013 Removed last transaction date from query
                  IF v_avail_balance >= 0
                  THEN
                     v_avail_bal_sign := '1';
                  ELSE
                     v_avail_bal_sign := '-1';
                  END IF;

                  UPDATE cms_acct_report
                     SET current_balance =
                                   TO_CHAR (ABS (v_curr_bal), '9999999990.99'),
                         current_balance_sign = v_sign,
                         available_balance =
                              TO_CHAR (ABS (v_avail_balance), '9999999990.99'),
                         available_balance_sign = v_avail_bal_sign
                   WHERE ROWID = i.row_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_err_msg :=
                           'ERROR FROM INNER LOOP WHILE UPDATING CMS_ACCT_REPORT IS '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE excp_raise;
               END;
            END LOOP;
         END;

         COMMIT;
      END LOOP;

      --generate file name
      l_file_name :=
                 'ACCNT01102' || TO_CHAR (p_from_date, 'MMDDYYYY')
                 || '001.csv';
                          -- Changed on 16-MAY-2013 for closeloop as per mail
                    --'ACCNT01102' || TO_CHAR (SYSDATE, 'MMDDYYYY')|| '001.csv';
      --open file
      l_file :=
         UTL_FILE.fopen (LOCATION          => p_in_directory,
                         filename          => l_file_name,
                         open_mode         => 'W',
                         max_linesize      => 4000
                        );
      UTL_FILE.put (l_file, 'Record_Type');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Account_Number');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Program_ID');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Location_ID');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Agent_User_ID');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Product_ID');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Group_ID');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Account_Type');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Account_Status');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Account_Status_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Account_Created_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Account_Expiration_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Reloadable_Indicator');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Credit_Line');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Available_Credit');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Secured_Amount');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Current_Balance');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Current_Balance_Sign');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Current_Payment_Due_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Available_Balance');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Available_Balance_Sign');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Negative_Balance_Fee_Amount');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Negative_Balance_Principle_Amount');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Cash_Advance_Outstanding');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Negative_Balance_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Delinquent_Amount');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Delinquent_Days');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Bill_Cycle_Day');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Account_Transfer_Number_To');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Account_Transfer_Number_From');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Enrollment_Number');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'External_Account_Number');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'First_Load_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Last_Reage_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Last_Statement_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Last_Transaction_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Account_Currency_Code');
      UTL_FILE.put (l_file, CHR (13) || CHR (10));

      --write data
      FOR c_person IN c (v_rept_id)
      LOOP
         l_rec_cnt := l_rec_cnt + 1;
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.record_type);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.account_number);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.program_id);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.location_id);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.agent_user_id);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.product_id);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.GROUP_ID);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.account_type);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.account_status);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.account_status_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.account_created_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.account_expiration_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.reloadable_indicator);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.credit_line);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.available_credit);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.secured_amount);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.current_balance);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.current_balance_sign);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.current_payment_due_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.available_balance);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.available_balance_sign);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.negative_balance_fee_amount);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.negative_bal_principle_amount);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.cash_advance_outstanding);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.negative_balance_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.delinquent_amount);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.delinquent_days);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.bill_cycle_day);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.account_transfer_number_to);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.account_transfer_number_from);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.enrollment_number);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.external_account_number);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.first_load_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.last_reage_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.last_statement_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.last_transaction_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.account_currency_code);
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, CHR (13) || CHR (10));
         --flush file
         UTL_FILE.fflush (l_file);
      END LOOP;

      --add trailer record
      UTL_FILE.put (l_file, '"');
      UTL_FILE.put (l_file, 'Z');
      UTL_FILE.put (l_file, '",');
      UTL_FILE.put (l_file, '"');
      UTL_FILE.put (l_file, l_rec_cnt);
      UTL_FILE.put (l_file, '"');
      UTL_FILE.put (l_file, CHR (13) || CHR (10));
      --flush file
      UTL_FILE.fflush (l_file);
      --close file
      UTL_FILE.fclose (l_file);
   EXCEPTION
      WHEN excp_raise
      THEN
         IF UTL_FILE.is_open (l_file)
         THEN
            UTL_FILE.fclose (l_file);
         END IF;

  --       DBMS_OUTPUT.put_line (v_err_msg);
      WHEN OTHERS
      THEN
         IF UTL_FILE.is_open (l_file)
         THEN
            UTL_FILE.fclose (l_file);
         END IF;

         DBMS_OUTPUT.put_line (SQLERRM);
   END p_account;

   PROCEDURE p_gpr_tran (
      p_in_directory   VARCHAR2,
      p_from_date      DATE,
      p_to_date        DATE
   )
   AS
      l_file        UTL_FILE.file_type;
      l_file_name   VARCHAR2 (1000);
      l_rec_cnt     NUMBER             := 0;

      CURSOR c
      IS
         --This will fetch GPR Transaction Information
          -- below query is used to fetch all records.
          --To retrieve data for perticular date range then uncomment the last two lines of query and replace ? with date .
         SELECT record_type, source_code, gpr_type, account_number,
                program_id, card_id, agent_user_id, customer_prn,
                network_code, transaction_reference_number,
                authorization_code,
                DECODE (gpr_type,
                        'AUTHORIZATION', transaction_code,
                        ''
                       ) transaction_code,
                authorization_response, address_verification_response,
                transaction_amount, transaction_amount_sign,
                transaction_currency_code, processor_commission_amt,
                store_commission_amt, direct_deposit_indicator,
                interchange_fee_amount, pos_indicator,
                NVL2 (transaction_date,
                      transaction_date || '.000',
                      transaction_date
                     ) transaction_date,
                DECODE (gpr_type,
                        'POSTED', NVL2 (post_date,
                                        post_date || '.000',
                                        post_date
                                       ),
                        ''
                       ) post_date,
                transaction_code_type, cvv_cvc, cvv_cvc2, store_number,
                merchant_number, merchant_name, merchant_category_code,
                merchant_city, merchant_state, merchant_zip,
                merchant_country_code, processor_commission_amt_sign,
                store_commission_amt_sign, corporate_commission_amt,
                corporate_commission_amt_sign, fee_amt, fee_amt_sign,
                product_id, orig_reference_number,
                requested_amount     --Added on 11-Jul-2013 by saravanankumar
           FROM (SELECT 'D' record_type, '14' source_code,
                        DECODE (cim_tran_type,
                                'F', 'POSTED',
                                'N', DECODE (NVL (TRIM (tranfee_amt), 0),
                                             0, 'AUTHORIZATION',
                                             'POSTED'
                                            )
                               ) gpr_type,       -- Added by Besky on 04/06/13
                        cap_acct_no account_number, mm.cpm_program_id program_id,
                        cap_proxy_number card_id, '' agent_user_id,
                        cap_acct_no customer_prn, '' network_code,
                        csl.csl_rrn transaction_reference_number,
                        (CASE
                            WHEN LENGTH (csl_auth_id) > 10
                               THEN SUBSTR (csl_auth_id, -6)
                            ELSE csl_auth_id
                         END
                        ) authorization_code,
                        '' transaction_code,
                        CASE
                           WHEN (   (    csl_delivery_channel IN ('10', '07')
                                     AND csl_txn_code = '07'
                                    )
                                 OR (    csl_delivery_channel = '03'
                                     AND csl_txn_code = '39'
                                    )
                                 OR (    csl_delivery_channel = '07'
                                     AND csl_txn_code = '10'
                                    )
                                )
                              THEN 'APPROVED'
                           ELSE (SELECT cms_resp_desc
                                   FROM cms_response_mast
                                  WHERE a.instcode = cms_inst_code
                                    AND a.response_code = cms_iso_respcde
                                    AND TO_NUMBER (a.delivery_channel) =
                                                          cms_delivery_channel
                                    AND ROWNUM < 2)
                        END authorization_response,
                        addr_verify_response address_verification_response,
                         --Commented by Arunprasath on 30/10/2013
						/*TO_CHAR (csl_trans_amount,
                                 9999999990.99
                                ) transaction_amount,*/
						--Added by Arunprasath on 30/10/2013		
                                TO_CHAR(DECODE (TXN_FEE_FLAG,'N',csl_trans_amount,0),9999999990.99) transaction_amount,
                        --Commented by Arunprasath on 30/10/2013
						/*DECODE (csl_trans_type,
                                'CR', '1',
                                'DR', '-1',
                                '0'
                               ) transaction_amount_sign,*/
						--Added by Arunprasath on 30/10/2013	   
                               (CASE WHEN DECODE (TXN_FEE_FLAG,'N',csl_trans_amount,0) <> 0
                                THEN DECODE (csl_trans_type,'CR', '1','DR', '-1','0')
                                ELSE
                                '0'
                                END)transaction_amount_sign,

                        NVL
                           ((SELECT gcm_curr_name
                               FROM gen_curr_mast
                              WHERE gcm_curr_code = tran_curr
                                AND gcm_inst_code = a.instcode),
                            'USD'
                           ) transaction_currency_code,
                        '0' processor_commission_amt,
                        '0' store_commission_amt,
                        DECODE (delivery_channel,
                                '11', '1',
                                '0'
                               ) direct_deposit_indicator,
                        NVL (interchange_feeamt, 0) interchange_fee_amount,
                        '' pos_indicator,
                        TO_CHAR
                           (csl_ins_date,               -- added 26 April 2013
                            'MMDDYYYY HH24:MI:SS'
                           ) transaction_date,
                        TO_CHAR (csl_ins_date,

                                 -- added 26 April 2013
                                 'MMDDYYYY HH24:MI:SS'
                                ) post_date,
                           csl_delivery_channel
                        || csl_txn_code transaction_code_type,
                        '' cvv_cvc, '' cvv_cvc2,
                        NVL (terminal_id, '') store_number,
                        merchant_id merchant_number,
                        merchant_name merchant_name,
                        NVL (mccode, 'NA') merchant_category_code,
                        merchant_city merchant_city, '' merchant_state,
                        merchant_zip merchant_zip,
                        country_code merchant_country_code,
                        '0' processor_commission_amt_sign,
                        '0' store_commission_amt_sign,
                        '0' corporate_commission_amt,
                        '0' corporate_commission_amt_sign,
                                         --NVL (tranfee_amt, 0) fee_amt,--Commented by Arunprasath on 30/10/2013
                         --Added by Arunprasath on 30/10/2013
						 (select nvl(sum(decode(a.csl_trans_type,'DR',a.csl_trans_amount,'CR',-a.csl_trans_amount)),0)
                         from cms_statements_log a 
                          where a.csl_rrn = csl.csl_rrn 
                            and a.csl_acct_no=csl.csl_acct_no  
                          and a.csl_pan_no=csl.csl_pan_no 
                           and a.csl_auth_id=csl.csl_auth_id 
                          and a.csl_inst_code=csl.csl_inst_code 
                            and a.csl_business_date=csl.csl_business_date
                          and a.txn_fee_flag='Y')fee_amt,
						  --Commented by Arunprasath on 30/10/2013
                        /*DECODE (NVL (TRIM (tranfee_amt), 0),
                                0, 1,
                                DECODE (csl_trans_type,
                                        'CR', '1',
                                        'DR', '-1'
                                       )
                               ) fee_amt_sign,   -- Added by Besky on 04/06/13*/   
                        --Added by Arunprasath on 30/10/2013							   
                         case when (select nvl(sum(decode(a.csl_trans_type,'DR',a.csl_trans_amount,'CR',-a.csl_trans_amount)),0)
                         from cms_statements_log a 
                          where a.csl_rrn = csl.csl_rrn 
                            and a.csl_acct_no=csl.csl_acct_no  
                          and a.csl_pan_no=csl.csl_pan_no 
                           and a.csl_auth_id=csl.csl_auth_id 
                          and a.csl_inst_code=csl.csl_inst_code 
                            and a.csl_business_date=csl.csl_business_date
                          and a.txn_fee_flag='Y')<>0 then
                         -1 
                         else 0 end fee_amt_sign,                       
                        mm.cpb_inst_bin || mm.cpc_prod_prefix product_id,
                        DECODE
                             (csl.csl_delivery_channel,
                              '08', csl.csl_rrn,
                              NULL
                             ) orig_reference_number,

                        --SN Added on 11-Jul-2013 by saravanankumar
                        (SELECT ctd_txn_amount
                           FROM cms_transaction_log_dtl
                          WHERE ctd_delivery_channel =
                                            delivery_channel
                            AND ctd_rrn = rrn
                            AND ctd_txn_code = txn_code
                            AND ctd_delivery_channel = '02'
                            AND ctd_txn_code = '11'
                            AND ctd_process_flag = 'Y'
                            AND response_code = '00'
                            AND ctd_customer_card_no = customer_card_no
                            AND ctd_business_date = business_date
                            AND ctd_business_time = business_time)
                                                             requested_amount
                   --EN Added on 11-Jul-2013 by saravanankumar
                 FROM   transactionlog a,
                        (SELECT b.cpm_prod_desc, c.cpc_inst_code,
                                b.cpm_prod_code, c.cpc_card_type,
                                c.cpc_cardtype_desc, c.cpc_prod_prefix,
                                g.cpb_inst_bin,b.cpm_program_id
                           FROM cms_prod_mast b,
                                cms_prod_cattype c,
                                cms_iris_prodcatgmast e,
                                cms_prod_bin g
                          WHERE b.cpm_inst_code = cpc_inst_code
                            AND b.cpm_prod_code = cpc_prod_code
                            AND cpc_inst_code = e.cpm_inst_code
                            AND cpc_prod_code = e.cpm_prod_code
                            AND cpc_card_type = e.cpm_catg_code
                            AND b.cpm_inst_code = g.cpb_inst_code
                            AND b.cpm_prod_code = g.cpb_prod_code
                            AND e.cpm_iris_flag = 'Y') mm,
                        cms_iristransaction_mast d,
                        (SELECT *
                           FROM (SELECT a.*,
                                        ROW_NUMBER () OVER (PARTITION BY    csl_rrn
                                                                         || csl_delivery_channel
                                                                         || csl_ins_date ORDER BY txn_fee_flag)
                                                                        ranks
                                   FROM cms_statements_log a) mm
                          WHERE (   (ranks = 1 AND txn_fee_flag = 'Y')
                                 OR txn_fee_flag = 'N'
                                )) csl,
                        cms_appl_pan cap,
                        cms_cust_mast cm
                  WHERE ccm_cust_code = cap.cap_cust_code
                    AND cap.cap_inst_code = mm.cpc_inst_code
                    AND cap.cap_prod_code = mm.cpm_prod_code
                    AND cap_card_type = mm.cpc_card_type
                    AND cim_inst_code = csl.csl_inst_code
                    AND cim_tran_code = csl.csl_txn_code
                    AND cim_delivery_channel = csl.csl_delivery_channel
                    AND csl.csl_rrn = a.rrn(+)
                    AND csl.csl_pan_no = a.customer_card_no(+)
                    AND csl.csl_acct_no = a.customer_acct_no(+)
                    AND csl.csl_delivery_channel = a.delivery_channel(+)
                    AND csl.csl_txn_code = a.txn_code(+)
                    AND csl.csl_business_date = business_date(+)
                    AND csl.csl_business_time = business_time(+)
                    AND a.response_code(+) = '00'
                    AND csl.csl_delivery_channel NOT IN ('08')
                    AND cim_iris_flag = 'Y'
                    AND cap.cap_prod_code = mm.cpm_prod_code
                    AND cap.cap_pan_code = csl.csl_pan_no
                    AND cap.cap_prod_code <> 'VP73'
                    AND (   TRUNC (csl_lupd_date) BETWEEN TRUNC (p_from_date)
                                                      AND TRUNC (p_to_date)
                         OR TRUNC (csl_ins_date) BETWEEN TRUNC (p_from_date)
                                                     AND TRUNC (p_to_date)
                        )) nn
         UNION
         SELECT record_type, source_code, gpr_type, account_number,
                program_id, card_id, agent_user_id, customer_prn,
                network_code, transaction_reference_number,
                authorization_code,
                DECODE (gpr_type,
                        'AUTHORIZATION', transaction_code,
                        ''
                       ) transaction_code,
                authorization_response, address_verification_response,
                transaction_amount, transaction_amount_sign,
                transaction_currency_code, processor_commission_amt,
                store_commission_amt, direct_deposit_indicator,
                interchange_fee_amount, pos_indicator,
                NVL2 (transaction_date,
                      transaction_date || '.000',
                      transaction_date
                     ) transaction_date,
                DECODE (gpr_type,
                        'POSTED', NVL2 (post_date,
                                        post_date || '.000',
                                        post_date
                                       ),
                        ''
                       ) post_date,
                transaction_code_type, cvv_cvc, cvv_cvc2, store_number,
                merchant_number, merchant_name, merchant_category_code,
                merchant_city, merchant_state, merchant_zip,
                merchant_country_code, processor_commission_amt_sign,
                store_commission_amt_sign, corporate_commission_amt,
                corporate_commission_amt_sign, fee_amt, fee_amt_sign,
                product_id, orig_reference_number,
                requested_amount      --Added on 11-Jul-2013 by saravanankumar
           FROM (SELECT 'D' record_type, '14' source_code,
                        DECODE (cim_tran_type,
                                'F', 'POSTED',
                                'N', DECODE (NVL (TRIM (tranfee_amt), 0),
                                             0, 'AUTHORIZATION',
                                             'POSTED'
                                            )
                               ) gpr_type,       -- Added by Besky on 04/06/13
                        cap_acct_no account_number, mm.cpm_program_id program_id,
                        cap_proxy_number card_id, '' agent_user_id,
                        cap_acct_no customer_prn, '' network_code,
                        a.rrn transaction_reference_number,
                        (CASE
                            WHEN LENGTH (auth_id) > 10
                               THEN SUBSTR (auth_id, -6)
                            ELSE auth_id
                         END
                        ) authorization_code,
                        '' transaction_code,
                        (SELECT cms_resp_desc
                           FROM cms_response_mast
                          WHERE a.instcode =
                                         cms_inst_code
                            AND a.response_code = cms_iso_respcde
                            AND TO_NUMBER (a.delivery_channel) =
                                                          cms_delivery_channel
                            AND ROWNUM < 2) authorization_response,
                        addr_verify_response address_verification_response,
                        TO_CHAR (amount, 9999999990.99) transaction_amount,
                        
                                      /*(DECODE (msgtype,
                         '0200', '1',
                         '0400', '-1'
                        ) */
                        (CASE
                            WHEN csl_trans_type = 'CR' AND msgtype = '0200'
                               THEN '1'
                            WHEN csl_trans_type = 'DR' AND msgtype = '0200'
                               THEN '-1'
                            WHEN csl_trans_type = 'CR' AND msgtype = '0400'
                               THEN '-1'
                            WHEN csl_trans_type = 'DR' AND msgtype = '0400'
                               THEN '1'
                         END
                        ) transaction_amount_sign,
                        
                        -- Added by Besky on 01/08/13
                        NVL
                           ((SELECT gcm_curr_name
                               FROM gen_curr_mast
                              WHERE gcm_curr_code = tran_curr
                                AND gcm_inst_code = a.instcode),
                            'USD'
                           ) transaction_currency_code,
                        '0' processor_commission_amt,
                        '0' store_commission_amt,
                        DECODE (delivery_channel,
                                '11', '1',
                                '0'
                               ) direct_deposit_indicator,
                        NVL (interchange_feeamt, 0) interchange_fee_amount,
                        '' pos_indicator,
                        TO_CHAR
                           (add_ins_date,               -- added 26 April 2013
                            'MMDDYYYY HH24:MI:SS'
                           ) transaction_date,
                        TO_CHAR (add_ins_date,

                                 -- added 26 April 2013
                                 'MMDDYYYY HH24:MI:SS'
                                ) post_date,
                        a.delivery_channel
                        || a.txn_code transaction_code_type,
                        '' cvv_cvc, '' cvv_cvc2,
                        NVL (terminal_id, '') store_number,
                        merchant_id merchant_number,
                        merchant_name merchant_name,
                        NVL (mccode, 'NA') merchant_category_code,
                        merchant_city merchant_city, '' merchant_state,
                        merchant_zip merchant_zip,
                        country_code merchant_country_code,
                        '0' processor_commission_amt_sign,
                        '0' store_commission_amt_sign,
                        '0' corporate_commission_amt,
                        '0' corporate_commission_amt_sign,
                        NVL (tranfee_amt, 0) fee_amt,
                        
                                       /*DECODE (NVL (TRIM (tranfee_amt), 0),
                         0, 1,
                         DECODE (msgtype, '0200', '-1', '0400', '1') -- Added by Besky on 04/06/13
                        )*/
                        (CASE
                            WHEN csl_trans_type = 'CR' AND msgtype = '0200'
                               THEN 1
                            WHEN csl_trans_type = 'DR' AND msgtype = '0200'
                               THEN -1
                            WHEN csl_trans_type = 'CR' AND msgtype = '0400'
                               THEN -1
                            WHEN csl_trans_type = 'DR' AND msgtype = '0400'
                               THEN 1
                         END
                        ) fee_amt_sign,          -- Added by Besky on 01/08/13
                        mm.cpb_inst_bin || mm.cpc_prod_prefix product_id,
                        DECODE (a.delivery_channel,
                                '08', a.rrn,
                                NULL
                               ) orig_reference_number,

                        --SN Added on 11-Jul-2013 by saravanankumar
                        (SELECT ctd_txn_amount
                           FROM cms_transaction_log_dtl
                          WHERE ctd_delivery_channel =
                                            delivery_channel
                            AND ctd_rrn = rrn
                            AND ctd_txn_code = txn_code
                            AND ctd_delivery_channel = '02'
                            AND ctd_txn_code = '11'
                            AND ctd_process_flag = 'Y'
                            AND response_code = '00'
                            AND ctd_customer_card_no = customer_card_no
                            AND ctd_business_date = business_date
                            AND ctd_business_time = business_time)
                                                             requested_amount
                   --EN Added on 11-Jul-2013 by saravanankumar
                 FROM   transactionlog a,
                        (SELECT b.cpm_prod_desc, c.cpc_inst_code,
                                b.cpm_prod_code, c.cpc_card_type,
                                c.cpc_cardtype_desc, c.cpc_prod_prefix,
                                g.cpb_inst_bin,b.cpm_program_id
                           FROM cms_prod_mast b,
                                cms_prod_cattype c,
                                cms_iris_prodcatgmast e,
                                cms_prod_bin g
                          WHERE b.cpm_inst_code = cpc_inst_code
                            AND b.cpm_prod_code = cpc_prod_code
                            AND cpc_inst_code = e.cpm_inst_code
                            AND cpc_prod_code = e.cpm_prod_code
                            AND cpc_card_type = e.cpm_catg_code
                            AND b.cpm_inst_code = g.cpb_inst_code
                            AND b.cpm_prod_code = g.cpb_prod_code
                            AND e.cpm_iris_flag = 'Y') mm,
                        cms_iristransaction_mast d,
                        cms_appl_pan cap,
                        cms_cust_mast cm,
                        cms_statements_log csl
                  WHERE ccm_cust_code = cap.cap_cust_code
                    AND cap.cap_inst_code = mm.cpc_inst_code
                    AND cap.cap_prod_code = mm.cpm_prod_code
                    AND cap_card_type = mm.cpc_card_type
                    AND cim_inst_code = a.instcode
                    AND cim_tran_code = a.txn_code
                    AND cim_delivery_channel = a.delivery_channel
                    AND a.response_code = '00'
                    AND a.delivery_channel = '08'
                    AND cim_iris_flag = 'Y'
                    AND cap.cap_prod_code = mm.cpm_prod_code
                    AND cap.cap_pan_code = a.customer_card_no
                    AND csl.csl_pan_no = cap.cap_pan_code
                    AND csl.csl_acct_no = cap.cap_acct_no
                    -- Added by Ganesh S on 16-AUG-2013
                    AND cap.cap_inst_code = csl.csl_inst_code
                    AND a.rrn = csl.csl_rrn
                    AND a.business_date = csl_business_date
                    AND a.business_time = csl_business_time
                    AND a.delivery_channel = csl_delivery_channel
                    AND a.txn_code = csl_txn_code
                                                 -- Added by Besky on 01/08/13
                    AND cap.cap_prod_code <> 'VP73'
                    AND (   TRUNC (add_lupd_date) BETWEEN TRUNC (p_from_date)
                                                      AND TRUNC (p_to_date)
                         OR TRUNC (add_ins_date) BETWEEN TRUNC (p_from_date)
                                                     AND TRUNC (p_to_date)
                        )) nn;
   /*  SELECT record_type, source_code, gpr_type, account_number, program_id,
        card_id, agent_user_id, customer_prn, network_code,
        transaction_reference_number, authorization_code,
        DECODE (gpr_type,
                'AUTHORIZATION', transaction_code,
                ''
               ) transaction_code,
        authorization_response, address_verification_response,
        transaction_amount, transaction_amount_sign, transaction_currency_code,
        processor_commission_amt, store_commission_amt,
        direct_deposit_indicator, interchange_fee_amount, pos_indicator,





        NVL2 (transaction_date,
              transaction_date || '.000',
              transaction_date
             ) transaction_date,
        DECODE (gpr_type,
                'POSTED', NVL2 (post_date, post_date || '.000', post_date),
                ''
               ) post_date,
        transaction_code_type, cvv_cvc, cvv_cvc2, store_number,
        merchant_number, merchant_name, merchant_category_code, merchant_city,
        merchant_state, merchant_zip, merchant_country_code,
        processor_commission_amt_sign, store_commission_amt_sign,
        corporate_commission_amt, corporate_commission_amt_sign, fee_amt,
        fee_amt_sign, product_id, orig_reference_number
   FROM (SELECT 'D' record_type, '14' source_code,
                DECODE (cim_tran_type,
                        'N', 'AUTHORIZATION',
                        'F', 'POSTED'
                       ) gpr_type,
                cap_acct_no account_number, '1234' program_id,
                ccm_cust_code card_id, '' agent_user_id,
                cap_acct_no customer_prn, '' network_code,
                csl.csl_rrn transaction_reference_number,
                (CASE
                    WHEN LENGTH (csl_auth_id) > 10
                       THEN SUBSTR (csl_auth_id, -6)
                    ELSE csl_auth_id
                 END
                ) authorization_code,
                '' transaction_code,
                CASE
                   WHEN (   (    csl_delivery_channel IN ('10', '07')
                             AND csl_txn_code = '07'
                            )
                         OR (csl_delivery_channel = '03'
                             AND csl_txn_code = '39'
                            )
                        )
                      THEN 'APPROVED'
                   ELSE (SELECT cms_resp_desc
                           FROM cms_response_mast
                          WHERE a.instcode = cms_inst_code
                            AND a.response_code = cms_iso_respcde
                            AND TO_NUMBER (a.delivery_channel) =
                                                           cms_delivery_channel
                            AND ROWNUM < 2)
                END authorization_response,
                addr_verify_response address_verification_response,
                TO_CHAR (csl_trans_amount, 9999999990.99) transaction_amount,
                DECODE (csl_trans_type,
                        'CR', '1','DR','-1',
                        '0'
                       ) transaction_amount_sign,
                NVL ((SELECT gcm_curr_name
                        FROM gen_curr_mast
                       WHERE gcm_curr_code = tran_curr
                         AND gcm_inst_code = a.instcode),
                     'USD'
                    ) transaction_currency_code,
                '0' processor_commission_amt, '0' store_commission_amt,
                DECODE (delivery_channel,
                        '11', '1',
                        '0'
                       ) direct_deposit_indicator,
                NVL (interchange_feeamt, 0) interchange_fee_amount,
                '' pos_indicator,
                TO_CHAR (TO_DATE (csl_business_date || csl_business_time,
                                  'YYYYMMDDhh24miss'
                                 ),
                         'MMDDYYYY HH24:MI:SS'
                        ) transaction_date,
                TO_CHAR (TO_DATE (csl_business_date || csl_business_time,
                                  'YYYYMMDDhh24miss'
                                 ),
                         'MMDDYYYY HH24:MI:SS'
                        ) post_date,
                csl_delivery_channel || csl_txn_code transaction_code_type,
                '' cvv_cvc, '' cvv_cvc2, NVL (terminal_id, '') store_number,
                merchant_id merchant_number, merchant_name merchant_name,
                NVL (mccode, 'NA') merchant_category_code,
                merchant_city merchant_city, '' merchant_state,
                merchant_zip merchant_zip, country_code merchant_country_code,
                '0' processor_commission_amt_sign,
                '0' store_commission_amt_sign, '0' corporate_commission_amt,
                '0' corporate_commission_amt_sign, NVL (tranfee_amt,
                                                        0) fee_amt,
                SIGN (NVL (tranfee_amt, 0)) fee_amt_sign,
                mm.cpb_inst_bin || mm.cpc_prod_prefix product_id,
                DECODE (csl.csl_delivery_channel,
                        '08', csl.csl_rrn,
                        NULL
                       ) orig_reference_number
           FROM transactionlog a,
                (SELECT b.cpm_prod_desc, c.cpc_inst_code, b.cpm_prod_code,
                        c.cpc_card_type, c.cpc_cardtype_desc,
                        c.cpc_prod_prefix, g.cpb_inst_bin
                   FROM cms_prod_mast b,
                        cms_prod_cattype c,
                        cms_iris_prodcatgmast e,
                        cms_prod_bin g
                  WHERE b.cpm_inst_code = cpc_inst_code
                    AND b.cpm_prod_code = cpc_prod_code
                    AND cpc_inst_code = e.cpm_inst_code
                    AND cpc_prod_code = e.cpm_prod_code
                    AND cpc_card_type = e.cpm_catg_code
                    AND b.cpm_inst_code = g.cpb_inst_code
                    AND b.cpm_prod_code = g.cpb_prod_code
                    AND e.cpm_iris_flag = 'Y') mm,
                cms_iristransaction_mast d,
               -- cms_statements_log csl,
    (    SELECT *
                      FROM (SELECT  a.*,
                                   ROW_NUMBER () OVER (PARTITION BY csl_rrn||CSL_DELIVERY_CHANNEL|| csl_ins_date  ORDER BY txn_fee_flag)
                                                                         ranks
                              FROM cms_statements_log a) mm
                     WHERE (   (ranks = 1 AND txn_fee_flag = 'Y')
                            OR txn_fee_flag = 'N'
                           ))csl,
                cms_appl_pan cap,
                cms_cust_mast cm
          WHERE ccm_cust_code = cap.cap_cust_code
            AND cap.cap_inst_code = mm.cpc_inst_code
            AND cap.cap_prod_code = mm.cpm_prod_code
            AND cap_card_type = mm.cpc_card_type
            AND cim_inst_code = csl.csl_inst_code
            AND cim_tran_code = csl.csl_txn_code
            AND cim_delivery_channel = csl.csl_delivery_channel
            AND csl.csl_rrn = a.rrn(+)
            AND csl.csl_pan_no = a.customer_card_no(+)
            AND csl.csl_acct_no = a.customer_acct_no(+)
            AND csl.csl_delivery_channel = a.delivery_channel(+)
            AND csl.csl_txn_code = a.txn_code(+)
            and csl.CSL_BUSINESS_DATE = BUSINESS_DATE (+)
            and csl.CSL_BUSINESS_TIME=BUSINESS_TIME(+)
            AND a.response_code(+) = '00'
            AND cim_iris_flag = 'Y'
            AND cap.cap_prod_code = mm.cpm_prod_code
            AND cap.cap_pan_code = csl.csl_pan_no
            AND cap.cap_prod_code = 'SP02'
            AND (trunc(csl_lupd_date)  between trunc(p_from_date) and trunc(p_to_date)
                OR    trunc(csl_ins_date)    between trunc(p_from_date) and trunc(p_to_date) )
                ) nn; */
   BEGIN
      --generate file name
      l_file_name :=
                'GPRZZ01102' || TO_CHAR (p_from_date, 'MMDDYYYY')
                -- TO_CHAR (SYSDATE, 'MMDDYYYY')Modified on 11-Jul-2013 by saravanankumar
                || '001.csv';
      --open file
      l_file :=
         UTL_FILE.fopen (LOCATION          => p_in_directory,
                         filename          => l_file_name,
                         open_mode         => 'W',
                         max_linesize      => 4000
                        );
      UTL_FILE.put (l_file, 'Rec_Type');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Source_Code');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'GPR_Type');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Account_Number');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Program_ID');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Card_ID');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Agent_User_ID');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Customer_PRN');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Network_Code');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Transaction_Reference_Number');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Authorization_Code');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Transaction_Code');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Authorization_Response');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Address_Verification_Response');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Transaction_Amount');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Transaction_Amount_Sign');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Transaction_Currency_Code');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Processor_Commission_Amt');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Store_Commission_Amt');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Direct_Deposit_Indicator');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Interchange_Fee_Amount');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'POS_Indicator');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Transaction_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Post_Date');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Transaction_Code_Type');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'CVV_CVC');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'CVV_CVC2');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Store_Number');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Merchant_Number');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Merchant_Name');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Merchant_Category_Code');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Merchant_City');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Merchant_State');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Merchant_Zip');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Merchant_Country_Code');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Processor_Commission_Amt_Sign');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Store_Commission_Amt_Sign');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Corporate_Commission_Amt');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Corporate Commission_Amt_Sign');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Fee_Amt');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Fee_Amt_Sign');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Product_ID');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Orig_Reference_Number');
      UTL_FILE.put (l_file, ',');
      UTL_FILE.put (l_file, 'Requested amount');
      UTL_FILE.put (l_file, CHR (13) || CHR (10));

      --write data
      FOR c_person IN c
      LOOP
         l_rec_cnt := l_rec_cnt + 1;
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.record_type);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.source_code);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.gpr_type);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.account_number);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.program_id);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.card_id);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.agent_user_id);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.customer_prn);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.network_code);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.transaction_reference_number);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.authorization_code);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.transaction_code);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.authorization_response);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.address_verification_response);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.transaction_amount);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.transaction_amount_sign);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.transaction_currency_code);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.processor_commission_amt);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.store_commission_amt);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.direct_deposit_indicator);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.interchange_fee_amount);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.pos_indicator);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.transaction_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.post_date);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.transaction_code_type);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.cvv_cvc);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.cvv_cvc2);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.store_number);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.merchant_number);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.merchant_name);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.merchant_category_code);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.merchant_city);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.merchant_state);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.merchant_zip);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.merchant_country_code);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.processor_commission_amt_sign);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.store_commission_amt_sign);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.corporate_commission_amt);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.corporate_commission_amt_sign);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.fee_amt);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.fee_amt_sign);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.product_id);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.orig_reference_number);
         UTL_FILE.put (l_file, '",');
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, c_person.requested_amount);
         UTL_FILE.put (l_file, '"');
         UTL_FILE.put (l_file, CHR (13) || CHR (10));
         --flush file
         UTL_FILE.fflush (l_file);
      END LOOP;

      --add trailer record
      UTL_FILE.put (l_file, '"');
      UTL_FILE.put (l_file, 'Z');
      UTL_FILE.put (l_file, '",');
      UTL_FILE.put (l_file, '"');
      UTL_FILE.put (l_file, l_rec_cnt);
      UTL_FILE.put (l_file, '"');
      UTL_FILE.put (l_file, CHR (13) || CHR (10));
      --flush file
      UTL_FILE.fflush (l_file);
      --close file
      UTL_FILE.fclose (l_file);
   EXCEPTION
      WHEN OTHERS
      THEN
         IF UTL_FILE.is_open (l_file)
         THEN
            UTL_FILE.fclose (l_file);
         END IF;

         DBMS_OUTPUT.put_line (SQLERRM);
   END p_gpr_tran;

   PROCEDURE p_iris (p_in_directory VARCHAR2, p_from_date DATE, p_to_date DATE)
   AS
   BEGIN
      p_person (p_in_directory, p_from_date, p_to_date);
      p_card (p_in_directory, p_from_date, p_to_date);
      p_account (p_in_directory, p_from_date, p_to_date);
      p_gpr_tran (p_in_directory, p_from_date, p_to_date);
   END p_iris;

   --international ATM for Skeet/Fraud team
   PROCEDURE p_international_atm (
      p_in_directory   VARCHAR2,
      p_from_date      DATE,
      p_to_date        DATE
   )
   AS
      l_file            UTL_FILE.file_type;
      l_file_name       VARCHAR2 (1000);
      l_file_created    VARCHAR2 (10)      := 'FALSE';
      l_total_records   NUMBER             := 0;
      l_to_date         DATE;

      CURSOR c
      IS
         SELECT   add_ins_date,
                     SUBSTR
                        (vmscms.fn_dmaps_main (customer_card_no_encr),
                         1,
                         4
                        )
                  || '********'
                  || SUBSTR (vmscms.fn_dmaps_main (customer_card_no_encr),
                             13,
                             4
                            ) masked_pan,
                  customer_acct_no,
                                   --VMSCMS.fn_dmaps_main(customer_card_no_encr),
                                   amount, total_amount, terminal_id,
                  atm_name_location, mccode, merchant_name, merchant_city,
                  merchant_state, country_code,
                  DECODE (response_code,
                          '00', 'Accepted',
                          '10', 'Declined',
                          response_code
                         ) response_code,
                  error_msg
             FROM transactionlog
            WHERE mccode IN ('6010', '6011')
              AND internation_ind_response = '1'
              AND add_ins_date BETWEEN p_from_date AND p_to_date
         ORDER BY 1;
   BEGIN
      FOR cur_data IN c
      LOOP
         IF l_file_created = 'FALSE'
         THEN
            --create file
            l_file_name :=
                  TO_CHAR (p_from_date, 'YYYYMMDDHH24MISS')
               || '_'
               || TO_CHAR (p_to_date, 'YYYYMMDDHH24MISS')
               || '_InternationalATM.csv';
            --open file
            l_file :=
               UTL_FILE.fopen (LOCATION          => p_in_directory,
                               filename          => l_file_name,
                               open_mode         => 'W',
                               max_linesize      => 4000
                              );
            UTL_FILE.put (l_file, 'Transaction Date,');
            UTL_FILE.put (l_file, 'Masked PAN,');
            UTL_FILE.put (l_file, 'Account No,');
            UTL_FILE.put (l_file, 'Amount,');
            UTL_FILE.put (l_file, 'Total Amount,');
            UTL_FILE.put (l_file, 'Terminal ID,');
            UTL_FILE.put (l_file, 'ATM Location,');
            UTL_FILE.put (l_file, 'Merchant Name,');
            UTL_FILE.put (l_file, 'Merchant City,');
            UTL_FILE.put (l_file, 'Merchant State,');
            UTL_FILE.put (l_file, 'Country Code,');
            UTL_FILE.put (l_file, 'Response,');
            UTL_FILE.put (l_file, 'Decline Reason,');
            UTL_FILE.put (l_file, 'MCC');
            --end of record/carriage return and line feed
            UTL_FILE.put (l_file, CHR (13) || CHR (10));
            l_file_created := 'TRUE';
         END IF;

         l_total_records := l_total_records + 1;
         UTL_FILE.put (l_file, cur_data.add_ins_date || ',');
         UTL_FILE.put (l_file, cur_data.masked_pan || ',');
         UTL_FILE.put (l_file, cur_data.customer_acct_no || ',');
         UTL_FILE.put (l_file, cur_data.amount || ',');
         UTL_FILE.put (l_file, cur_data.total_amount || ',');
         UTL_FILE.put (l_file, cur_data.terminal_id || ',');
         UTL_FILE.put (l_file, cur_data.atm_name_location || ',');
         UTL_FILE.put (l_file, cur_data.merchant_name || ',');
         UTL_FILE.put (l_file, cur_data.merchant_city || ',');
         UTL_FILE.put (l_file, cur_data.merchant_state || ',');
         UTL_FILE.put (l_file, cur_data.country_code || ',');
         UTL_FILE.put (l_file, cur_data.response_code || ',');
         UTL_FILE.put (l_file, cur_data.error_msg || ',');
         UTL_FILE.put (l_file, cur_data.mccode);
         --end of record/carriage return and line feed
         UTL_FILE.put (l_file, CHR (13) || CHR (10));
         --flush so that buffer is emptied
         UTL_FILE.fflush (l_file);
      END LOOP;

      IF l_file_created = 'TRUE'
      THEN
         --flush file to disk
         UTL_FILE.fflush (l_file);
         --close file
         UTL_FILE.fclose (l_file);
      END IF;

      --insert into tabel
      INSERT INTO vmscms.international_atm
                  (from_date, TO_DATE, tot_transactions
                  )
           VALUES (p_from_date, p_to_date, l_total_records
                  );

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF UTL_FILE.is_open (l_file)
         THEN
            UTL_FILE.fclose (l_file);
         END IF;
   END p_international_atm;

   --generate bancorp extracts
   PROCEDURE p_bancorp (
      p_in_directory   VARCHAR2,
      p_in_date        DATE DEFAULT SYSDATE,
      p_in_inst_code   NUMBER
   )
   AS
      v_date       VARCHAR2 (50);
      v_resp_msg   VARCHAR2 (4000) := NULL;
      v_cmf_id     NUMBER;
   BEGIN
      SELECT vmscms.cmf_id.NEXTVAL
        INTO v_cmf_id
        FROM DUAL;

      DBMS_OUTPUT.put_line ('1');
      p_cmf_report (v_cmf_id, p_in_date, v_resp_msg);
      DBMS_OUTPUT.put_line ('2');

      IF v_resp_msg = 'TRUE'
      THEN
         DBMS_OUTPUT.put_line ('3');
         p_cmf (p_in_directory, v_cmf_id, p_in_date);
         p_cmf_canada (p_in_directory, v_cmf_id, p_in_date);
         --Added by Saravanakumar on 30-Jul-2013
         COMMIT;
         DBMS_OUTPUT.put_line ('4');
      ELSE
         ROLLBACK;
         DBMS_OUTPUT.put_line (v_resp_msg);
      END IF;

      DBMS_OUTPUT.put_line ('5');
      p_posted_trans (p_in_directory, p_in_date, p_in_inst_code);
      DBMS_OUTPUT.put_line ('6');
      -- To Generate Lookup file
      p_lookup_rep (p_in_directory);
      p_lookup_rep_canada (p_in_directory);
      --Added by Saravanakumar on 30-Jul-2013
      DBMS_OUTPUT.put_line ('7');
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line (SQLERRM);
   END p_bancorp;

   --NextCALA
   PROCEDURE p_nextcala (
      p_in_directory   VARCHAR2,
      p_in_date        DATE DEFAULT SYSDATE
   )
   AS
      l_eod         DATE;
      l_file        UTL_FILE.file_type;
      l_file_name   VARCHAR2 (1000);

      CURSOR c_rewards
      IS
         SELECT TO_CHAR (csl_ins_date, 'MMDDYYYY') fee_date,

--Changed CSL_INS_DATE instead of sysdate and date formate on 18-Jul-2013 by Saravanakumar
                SUBSTR (fn_dmaps_main (cap_pan_code_encr), -4, 4)
                                                                 card_number,
                NVL (ccm_mobl_one, cam_mobl_one) mobile_number,

                --Modified by Saravanakumar on 30-Jul-2013
                NVL (ccm_email_one, cam_email) email_address,

                --Modified by Saravanakumar on 30-Jul-2013
                DECODE (csl_delivery_channel, '05', 1, 0) fee_type,
                '$' || csl_trans_amount fee_amount,

                --Removed space after $ on 18-Jul-2013 by Saravanakumar

                --Sn added by saravanakumar on 11-Jul-2013
                ccm_first_name first_name, ccm_last_name last_name,
                cam_add_one address_one, cam_add_two address_two,
                cam_city_name city,
                (SELECT gsm_state_name
                   FROM gen_state_mast
                  WHERE gsm_inst_code = cam_inst_code
                    AND gsm_cntry_code = cam_cntry_code
                    AND gsm_state_code = cam_state_code) state,
                cam_pin_code zip
           --En added by saravanakumar on 11-Jul-2013
         FROM   cms_statements_log,
                cms_cust_mast,
                cms_appl_pan,
                cms_addr_mast          --added by saravanakumar on 11-Jul-2013
          WHERE csl_inst_code = 1
            AND txn_fee_flag = 'Y'
            AND TRUNC (csl_ins_date) = TRUNC (p_in_date)
            AND cap_pan_code = csl_pan_no
            --for QA
            --AND cap_prod_code = 'VP88'
            --for PROD
            AND     CAP_PROD_CODE        =    'VP74'
            AND cap_cust_code = ccm_cust_code
            AND ccm_inst_code = cap_inst_code
            AND csl_inst_code = cap_inst_code
            --Sn added by saravanakumar on 11-Jul-2013
            AND cam_inst_code = cap_inst_code
            AND cam_cust_code = cap_cust_code
            AND cam_addr_flag = 'P'
            --En added by saravanakumar on 11-Jul-2013
            AND (csl_delivery_channel, csl_txn_code) IN
                   (('04', '68'),
                    ('07', '02'),
                    ('07', '09'),
                    ('10', '02'),
                    ('03', '74'),
                    ('05', '16')
                   );

      CURSOR c_billing
      IS
         SELECT TO_CHAR (ckl_kycreq_date, 'MMDDYY') tran_date,
                TO_CHAR (ckl_kycreq_date, 'hh24:mi:ss') tran_time,
                cci_prod_code product,
                   ckl_kycres_refno
                || TO_CHAR (ckl_kycreq_date, 'yyyymmddhh24miss') unique_id,
                CASE
                   WHEN ckl_kyc_flag IN ('P', 'Y')
                      THEN 'PASS'
                   WHEN ckl_kyc_flag IN ('F', 'E')
                      THEN 'FAIL'
                END pass_fail_indicator
           FROM cms_caf_info_entry, cms_kyctxn_log
          WHERE ckl_inst_code = 1
            AND ckl_row_id = cci_row_id
            --for QA
            --AND cci_prod_code = 'VP88'
            --for PROD
            AND     cci_prod_code        =    'VP74'
            AND TRUNC (cci_ins_date) = TRUNC (p_in_date);
   BEGIN
      l_eod := NVL (p_in_date, SYSDATE - 1);
      --generate file name for NextCala rewards file
      DBMS_OUTPUT.put_line ('1');
      l_file_name :=
                  'nextcala_rewards_' || TO_CHAR (l_eod, 'MMDDYYYY')
                  || '.txt';
      --open file
      l_file :=
         UTL_FILE.fopen (LOCATION          => p_in_directory,
                         filename          => l_file_name,
                         open_mode         => 'W',
                         max_linesize      => 4000
                        );

      --write header information
      --Commended header information on 18-Jul-2013 by Saravanakumar
      /*UTL_FILE.put (l_file, 'Date,');
      UTL_FILE.put (l_file, 'Card Number,');
      UTL_FILE.put (l_file, 'Mobile Number,');
      UTL_FILE.put (l_file, 'Email Address,');
      UTL_FILE.put (l_file, 'Fee Type,');
      UTL_FILE.put (l_file, 'Fee Amount,');
      --Sn added by saravanakumar on 11-Jul-2013
      UTL_FILE.put (l_file, 'First Name,');
      UTL_FILE.put (l_file, 'Last Name,');
      UTL_FILE.put (l_file, 'Address one,');
      UTL_FILE.put (l_file, 'Address two,');
      UTL_FILE.put (l_file, 'City,');
      UTL_FILE.put (l_file, 'State,');
      UTL_FILE.put (l_file, 'Zip');
      --En added by saravanakumar on 11-Jul-2013
      --end of record/carriage return and line feed
      UTL_FILE.put (l_file, CHR (13) || CHR (10));
      --flush file to disk
      UTL_FILE.fflush (l_file);*/
      FOR cur_data IN c_rewards
      LOOP
         UTL_FILE.put (l_file, cur_data.fee_date || ',');
         UTL_FILE.put (l_file, cur_data.card_number || ',');
         UTL_FILE.put (l_file, cur_data.mobile_number || ',');
         UTL_FILE.put (l_file, cur_data.email_address || ',');
         UTL_FILE.put (l_file, cur_data.fee_type || ',');
         UTL_FILE.put (l_file, cur_data.fee_amount || ',');
         --Sn added by saravanakumar on 11-Jul-2013
         UTL_FILE.put (l_file, cur_data.first_name || ',');
         UTL_FILE.put (l_file, cur_data.last_name || ',');
         UTL_FILE.put (l_file, cur_data.address_one || ',');
         UTL_FILE.put (l_file, cur_data.address_two || ',');
         UTL_FILE.put (l_file, cur_data.city || ',');
         UTL_FILE.put (l_file, cur_data.state || ',');
         UTL_FILE.put (l_file, cur_data.zip);
         --En added by saravanakumar on 11-Jul-2013
         --end of record/carriage return and line feed
         UTL_FILE.put (l_file, CHR (13) || CHR (10));
         --flush so that buffer is emptied
         UTL_FILE.fflush (l_file);
      END LOOP;

      --close file
      UTL_FILE.fclose (l_file);
      --generate file name for incomm billing file
      l_file_name :=
               'vms_nextcala_billing_' || TO_CHAR (l_eod, 'MMDDYYYY')
               || '.txt';
      --open file
      l_file :=
         UTL_FILE.fopen (LOCATION          => p_in_directory,
                         filename          => l_file_name,
                         open_mode         => 'W',
                         max_linesize      => 4000
                        );
      --write header information
      UTL_FILE.put (l_file, 'Date,');
      UTL_FILE.put (l_file, 'Time,');
      UTL_FILE.put (l_file, 'Product,');
      UTL_FILE.put (l_file, 'Unique ID,');
      UTL_FILE.put (l_file, 'Pass / Fail Indicator');
      --end of record/carriage return and line feed
      UTL_FILE.put (l_file, CHR (13) || CHR (10));
      --flush file to disk
      UTL_FILE.fflush (l_file);

      FOR cur_data IN c_billing
      LOOP
         UTL_FILE.put (l_file, cur_data.tran_date || ',');
         UTL_FILE.put (l_file, cur_data.tran_time || ',');
         UTL_FILE.put (l_file, cur_data.product || ',');
         UTL_FILE.put (l_file, cur_data.unique_id || ',');
         UTL_FILE.put (l_file, cur_data.pass_fail_indicator);
         --end of record/carriage return and line feed
         UTL_FILE.put (l_file, CHR (13) || CHR (10));
         --flush so that buffer is emptied
         UTL_FILE.fflush (l_file);
      END LOOP;

      --close file
      UTL_FILE.fclose (l_file);
   EXCEPTION
      WHEN OTHERS
      THEN
         IF UTL_FILE.is_open (l_file)
         THEN
            UTL_FILE.fclose (l_file);
         END IF;

         DBMS_OUTPUT.put_line (SQLERRM);
   END;

--Recon report
   PROCEDURE p_rec_rpt (
      prm_directory    VARCHAR2,
      prm_from_month   VARCHAR2,
      prm_to_month     VARCHAR2
   )
   IS
      from_month_dt           DATE;
      to_month_dt             DATE;
      v_cnt                   NUMBER;
      v_preauth_cnt           NUMBER;
      v_preauth_amt           transactionlog.amount%TYPE;
      v_preauth_fee_cnt       NUMBER;
      v_preauth_fee_amt       transactionlog.tranfee_amt%TYPE;
      v_purchase_cnt          NUMBER;
      v_purchase_amt          transactionlog.amount%TYPE;
      v_purchase_fee_cnt      NUMBER;
      v_purchase_fee_amt      transactionlog.tranfee_amt%TYPE;
      v_merchreturn_cnt       NUMBER;
      v_merchreturn_amt       transactionlog.amount%TYPE;
      v_merchreturn_fee_cnt   NUMBER;
      v_merchreturn_fee_amt   transactionlog.tranfee_amt%TYPE;
      v_cashback_cnt          NUMBER;
      v_cashback_amt          transactionlog.amount%TYPE;
      v_cashback_fee_cnt      NUMBER;
      v_cashback_fee_amt      transactionlog.tranfee_amt%TYPE;
      v_withdrawal_cnt        NUMBER;
      v_withdrawal_amt        transactionlog.amount%TYPE;
      v_withdrawal_fee_cnt    NUMBER;
      v_withdrawal_fee_amt    transactionlog.tranfee_amt%TYPE;
      v_err                   VARCHAR2 (500);
      v_file_handle           UTL_FILE.file_type;
      v_filename              VARCHAR2 (50);
      v_wrt_buff              VARCHAR2 (2000);
      v_excp                  EXCEPTION;
   BEGIN
      v_filename :=
               'Eves_Recon_Report_' || TO_CHAR (SYSDATE, 'YYYYMMDD')
               || '.csv';

      BEGIN
         IF UTL_FILE.is_open (v_file_handle)
         THEN
            UTL_FILE.fflush (v_file_handle);
            UTL_FILE.fclose (v_file_handle);
         END IF;

         v_file_handle := UTL_FILE.fopen (prm_directory, v_filename, 'w');
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err := 'ERROR OPENING FILE (W) ' || SUBSTR (SQLERRM, 1, 200);
            RAISE v_excp;
      END;

      from_month_dt := TO_DATE (prm_from_month, 'mon-yyyy');
      to_month_dt := TO_DATE (prm_to_month, 'mon-yyyy');
      v_cnt := MONTHS_BETWEEN (to_month_dt, from_month_dt);
      v_wrt_buff :=
            'Month*'
         || ','
         || 'Pre-Auth Completion'
         || ','
         || ','
         || ','
         || ','
         || 'POS Purchase'
         || ','
         || ','
         || ','
         || ','
         || 'Merchandise Return'
         || ','
         || ','
         || ','
         || ','
         || 'Purchase Cashback'
         || ','
         || ','
         || ','
         || ','
         || 'ATM Cash Withdrawal';
      UTL_FILE.put_line (v_file_handle, v_wrt_buff);
      v_wrt_buff :=
            ','
         || 'Transaction Count'
         || ','
         || 'Transaction Amount'
         || ','
         || 'Fee Count'
         || ','
         || 'Fee Amount'
         || ','
         || 'Transaction Count'
         || ','
         || 'Transaction Amount'
         || ','
         || 'Fee Count'
         || ','
         || 'Fee Amount'
         || ','
         || 'Transaction Count'
         || ','
         || 'Transaction Amount'
         || ','
         || 'Fee Count'
         || ','
         || 'Fee Amount'
         || ','
         || 'Transaction Count'
         || ','
         || 'Transaction Amount'
         || ','
         || 'Fee Count'
         || ','
         || 'Fee Amount'
         || ','
         || 'Transaction Count'
         || ','
         || 'Transaction Amount'
         || ','
         || 'Fee Count'
         || ','
         || 'Fee Amount';
      UTL_FILE.put_line (v_file_handle, v_wrt_buff);

      FOR i IN 0 .. v_cnt
      LOOP
         BEGIN
            SELECT SUM (CASE
                           WHEN response_code = '00'
                           AND NVL (reversal_code, 00) = '00'
                           AND txn_fee_flag = 'N'
                              THEN 1
                        END
                       ),
                   SUM
                      (CASE
                          WHEN response_code = '00' AND txn_fee_flag = 'N'
                             THEN DECODE (NVL (reversal_code, 00),
                                          00, amount,
                                          -amount
                                         )
                       END
                      ),
                   SUM
                      (CASE
                          WHEN NVL (reversal_code, 00) = '00'
                          AND txn_fee_flag = 'Y'
                             THEN DECODE (NVL (tranfee_amt, 0), 0, 0, 1)
                       END
                      ),
                   SUM (DECODE (txn_fee_flag,
                                'Y', DECODE (csl_trans_type,
                                             'DR', csl_trans_amount,
                                             'CR', -csl_trans_amount
                                            ),
                                0
                               )
                       )
              INTO v_preauth_cnt,
                   v_preauth_amt,
                   v_preauth_fee_cnt,
                   v_preauth_fee_amt
              FROM transactionlog, cms_statements_log
             WHERE instcode = 1
               AND delivery_channel = '02'
               AND txn_code = '12'
               AND csl_delivery_channel = delivery_channel
               AND csl_txn_code = txn_code
               AND csl_pan_no = customer_card_no
               AND csl_rrn = rrn
               AND TO_DATE (network_settl_date, 'YYYYMMDD')
                      BETWEEN ADD_MONTHS (from_month_dt, i)
                          AND LAST_DAY (ADD_MONTHS (from_month_dt, i));

            SELECT SUM (CASE
                           WHEN response_code = '00'
                           AND NVL (reversal_code, 00) = '00'
                           AND txn_fee_flag = 'N'
                              THEN 1
                        END
                       ),
                   SUM
                      (CASE
                          WHEN response_code = '00' AND txn_fee_flag = 'N'
                             THEN DECODE (NVL (reversal_code, 00),
                                          00, amount,
                                          -amount
                                         )
                       END
                      ),
                   SUM
                      (CASE
                          WHEN NVL (reversal_code, 00) = '00'
                          AND txn_fee_flag = 'Y'
                             THEN DECODE (NVL (tranfee_amt, 0), 0, 0, 1)
                       END
                      ),
                   SUM (DECODE (txn_fee_flag,
                                'Y', DECODE (csl_trans_type,
                                             'DR', csl_trans_amount,
                                             'CR', -csl_trans_amount
                                            ),
                                0
                               )
                       )
              INTO v_purchase_cnt,
                   v_purchase_amt,
                   v_purchase_fee_cnt,
                   v_purchase_fee_amt
              FROM transactionlog, cms_statements_log
             WHERE instcode = 1
               AND delivery_channel = '02'
               AND txn_code = '14'
               AND csl_delivery_channel = delivery_channel
               AND csl_txn_code = txn_code
               AND csl_pan_no = customer_card_no
               AND csl_rrn = rrn
               AND TO_DATE (network_settl_date, 'YYYYMMDD')
                      BETWEEN ADD_MONTHS (from_month_dt, i)
                          AND LAST_DAY (ADD_MONTHS (from_month_dt, i));

            SELECT SUM (CASE
                           WHEN response_code = '00'
                           AND NVL (reversal_code, 00) = '00'
                           AND txn_fee_flag = 'N'
                              THEN 1
                        END
                       ),
                   SUM
                      (CASE
                          WHEN response_code = '00' AND txn_fee_flag = 'N'
                             THEN DECODE (NVL (reversal_code, 00),
                                          00, amount,
                                          -amount
                                         )
                       END
                      ),
                   SUM
                      (CASE
                          WHEN NVL (reversal_code, 00) = '00'
                          AND txn_fee_flag = 'Y'
                             THEN DECODE (NVL (tranfee_amt, 0), 0, 0, 1)
                       END
                      ),
                   SUM (DECODE (txn_fee_flag,
                                'Y', DECODE (csl_trans_type,
                                             'DR', csl_trans_amount,
                                             'CR', -csl_trans_amount
                                            ),
                                0
                               )
                       )
              INTO v_merchreturn_cnt,
                   v_merchreturn_amt,
                   v_merchreturn_fee_cnt,
                   v_merchreturn_fee_amt
              FROM transactionlog, cms_statements_log
             WHERE instcode = 1
               AND delivery_channel = '02'
               AND txn_code = '25'
               AND csl_delivery_channel = delivery_channel
               AND csl_txn_code = txn_code
               AND csl_pan_no = customer_card_no
               AND csl_rrn = rrn
               AND TO_DATE (network_settl_date, 'YYYYMMDD')
                      BETWEEN ADD_MONTHS (from_month_dt, i)
                          AND LAST_DAY (ADD_MONTHS (from_month_dt, i));

            SELECT SUM (CASE
                           WHEN response_code = '00'
                           AND NVL (reversal_code, 00) = '00'
                           AND txn_fee_flag = 'N'
                              THEN 1
                        END
                       ),
                   SUM
                      (CASE
                          WHEN response_code = '00' AND txn_fee_flag = 'N'
                             THEN DECODE (NVL (reversal_code, 00),
                                          00, amount,
                                          -amount
                                         )
                       END
                      ),
                   SUM
                      (CASE
                          WHEN NVL (reversal_code, 00) = '00'
                          AND txn_fee_flag = 'Y'
                             THEN DECODE (NVL (tranfee_amt, 0), 0, 0, 1)
                       END
                      ),
                   SUM (DECODE (txn_fee_flag,
                                'Y', DECODE (csl_trans_type,
                                             'DR', csl_trans_amount,
                                             'CR', -csl_trans_amount
                                            ),
                                0
                               )
                       )
              INTO v_cashback_cnt,
                   v_cashback_amt,
                   v_cashback_fee_cnt,
                   v_cashback_fee_amt
              FROM transactionlog, cms_statements_log
             WHERE instcode = 1
               AND delivery_channel = '02'
               AND txn_code = '16'
               AND csl_delivery_channel = delivery_channel
               AND csl_txn_code = txn_code
               AND csl_pan_no = customer_card_no
               AND csl_rrn = rrn
               AND TO_DATE (network_settl_date, 'YYYYMMDD')
                      BETWEEN ADD_MONTHS (from_month_dt, i)
                          AND LAST_DAY (ADD_MONTHS (from_month_dt, i));

            SELECT SUM (CASE
                           WHEN response_code = '00'
                           AND NVL (reversal_code, 00) = '00'
                           AND txn_fee_flag = 'N'
                              THEN 1
                        END
                       ),
                   SUM
                      (CASE
                          WHEN response_code = '00' AND txn_fee_flag = 'N'
                             THEN DECODE (NVL (reversal_code, 00),
                                          00, amount,
                                          -amount
                                         )
                       END
                      ),
                   SUM
                      (CASE
                          WHEN NVL (reversal_code, 00) = '00'
                          AND txn_fee_flag = 'Y'
                             THEN DECODE (NVL (tranfee_amt, 0), 0, 0, 1)
                       END
                      ),
                   SUM (DECODE (txn_fee_flag,
                                'Y', DECODE (csl_trans_type,
                                             'DR', csl_trans_amount,
                                             'CR', -csl_trans_amount
                                            ),
                                0
                               )
                       )
              INTO v_withdrawal_cnt,
                   v_withdrawal_amt,
                   v_withdrawal_fee_cnt,
                   v_withdrawal_fee_amt
              FROM transactionlog, cms_statements_log
             WHERE instcode = 1
               AND delivery_channel = '01'
               AND txn_code = '10'
               AND csl_delivery_channel = delivery_channel
               AND csl_txn_code = txn_code
               AND csl_pan_no = customer_card_no
               AND csl_rrn = rrn
               AND TO_DATE (network_settl_date, 'YYYYMMDD')
                      BETWEEN ADD_MONTHS (from_month_dt, i)
                          AND LAST_DAY (ADD_MONTHS (from_month_dt, i));

            BEGIN
               INSERT INTO cms_recon_report
                           (crr_month_year,
                            crr_preauth_cnt, crr_preauth_amt,
                            crr_preauth_fee_cnt,
                            crr_preauth_fee_amt,
                            crr_purchase_cnt,
                            crr_purchase_amt,
                            crr_purchase_fee_cnt,
                            crr_purchase_fee_amt,
                            crr_merchreturn_cnt,
                            crr_merchreturn_amt,
                            crr_merchreturn_fee_cnt,
                            crr_merchreturn_fee_amt,
                            crr_cashback_cnt,
                            crr_cashback_amt,
                            crr_cashback_fee_cnt,
                            crr_cashback_fee_amt,
                            crr_withdrawal_cnt,
                            crr_withdrawal_amt,
                            crr_withdrawal_fee_cnt,
                            crr_withdrawal_fee_amt, crr_ins_user,
                            crr_ins_date
                           )
                    VALUES (TO_CHAR (ADD_MONTHS (from_month_dt, i),
                                     'MON-YYYY'),
                            NVL (v_preauth_cnt, 0), NVL (v_preauth_amt, 0),
                            NVL (v_preauth_fee_cnt, 0),
                            NVL (v_preauth_fee_amt, 0),
                            NVL (v_purchase_cnt, 0),
                            NVL (v_purchase_amt, 0),
                            NVL (v_purchase_fee_cnt, 0),
                            NVL (v_purchase_fee_amt, 0),
                            NVL (v_merchreturn_cnt, 0),
                            NVL (v_merchreturn_amt, 0),
                            NVL (v_merchreturn_fee_cnt, 0),
                            NVL (v_merchreturn_fee_amt, 0),
                            NVL (v_cashback_cnt, 0),
                            NVL (v_cashback_amt, 0),
                            NVL (v_cashback_fee_cnt, 0),
                            NVL (v_cashback_fee_amt, 0),
                            NVL (v_withdrawal_cnt, 0),
                            NVL (v_withdrawal_amt, 0),
                            NVL (v_withdrawal_fee_cnt, 0),
                            NVL (v_withdrawal_fee_amt, 0), 1,
                            SYSDATE
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_err :=
                        'Error while inserting in to CMS_RECON_REPORT table'
                     || SUBSTR (SQLERRM, 1, 100);
                  RAISE v_excp;
            END;

            v_wrt_buff :=
                  TO_CHAR (ADD_MONTHS (from_month_dt, i), 'MON-YYYY')
               || ','
               || NVL (v_preauth_cnt, 0)
               || ','
               || NVL (v_preauth_amt, 0)
               || ','
               || NVL (v_preauth_fee_cnt, 0)
               || ','
               || NVL (v_preauth_fee_amt, 0)
               || ','
               || NVL (v_purchase_cnt, 0)
               || ','
               || NVL (v_purchase_amt, 0)
               || ','
               || NVL (v_purchase_fee_cnt, 0)
               || ','
               || NVL (v_purchase_fee_amt, 0)
               || ','
               || NVL (v_merchreturn_cnt, 0)
               || ','
               || NVL (v_merchreturn_amt, 0)
               || ','
               || NVL (v_merchreturn_fee_cnt, 0)
               || ','
               || NVL (v_merchreturn_fee_amt, 0)
               || ','
               || NVL (v_cashback_cnt, 0)
               || ','
               || NVL (v_cashback_amt, 0)
               || ','
               || NVL (v_cashback_fee_cnt, 0)
               || ','
               || NVL (v_cashback_fee_amt, 0)
               || ','
               || NVL (v_withdrawal_cnt, 0)
               || ','
               || NVL (v_withdrawal_amt, 0)
               || ','
               || NVL (v_withdrawal_fee_cnt, 0)
               || ','
               || NVL (v_withdrawal_fee_amt, 0);
            UTL_FILE.put_line (v_file_handle, v_wrt_buff);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err := SUBSTR (SQLERRM, 1, 100);
               DBMS_OUTPUT.put_line (v_err);
               UTL_FILE.fflush (v_file_handle);
               UTL_FILE.fclose (v_file_handle);
         END;
      END LOOP;

      UTL_FILE.fflush (v_file_handle);
      UTL_FILE.fclose (v_file_handle);
   EXCEPTION
      WHEN v_excp
      THEN
         DBMS_OUTPUT.put_line (v_err);
         UTL_FILE.fflush (v_file_handle);
         UTL_FILE.fclose (v_file_handle);
      WHEN OTHERS
      THEN
         v_err := SUBSTR (SQLERRM, 1, 100);
         DBMS_OUTPUT.put_line (v_err);
         UTL_FILE.fflush (v_file_handle);
         UTL_FILE.fclose (v_file_handle);
   END p_rec_rpt;
END pkg_vms_extracts;
/
show error