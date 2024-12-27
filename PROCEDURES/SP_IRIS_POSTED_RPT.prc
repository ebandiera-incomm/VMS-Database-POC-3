create or replace
PROCEDURE          "SP_IRIS_POSTED_RPT"(
                                    P_DATE       IN   DATE,
                                    P_DIRECTORY  IN   VARCHAR2,
                                    P_ERR        OUT  VARCHAR2 
                                    )
IS

V_FILE_HANDLE    UTL_FILE.FILE_TYPE;
V_WRT_BUFF       VARCHAR2(2000);
V_FILENAME       VARCHAR2(50);
V_CNT            NUMBER :=0;
V_EXCP           EXCEPTION;

BEGIN
    V_FILENAME := 'VMS_postedtransactions_IRIS_'||TO_CHAR(P_DATE,'YYYYMMDD')||'.txt';

    BEGIN
        IF  utl_file.is_open(V_FILE_HANDLE) THEN
            utl_file.fflush (V_FILE_HANDLE);
            utl_file.fclose (V_FILE_HANDLE);
        END IF;
        V_FILE_HANDLE := utl_file.fopen (P_DIRECTORY, V_FILENAME, 'W');
    EXCEPTION
        WHEN OTHERS THEN
            P_ERR := 'Error while opening file ' || SUBSTR (SQLERRM, 1, 200);
            RAISE V_EXCP;
    END;

    v_wrt_buff :='HHEADER'||RPAD('INCOMM',50)||RPAD('POSTED TRANSACTIONS',50)||RPAD(to_char(p_date+1,'MMDDYYYY'),8)||RPAD(to_char(p_date,'MMDDYYYY'),8);
    utl_file.put_line (V_FILE_HANDLE, V_WRT_BUFF);

    FOR cur_rep IN(SELECT  
                 (SELECT cpm_program_id
                    FROM cms_prod_mast
                   WHERE cpm_prod_code = cap_prod_code) unique_program_id,
                 cap_proxy_number proxy_no,
                 TO_CHAR (TO_DATE (csl_business_date, 'YYYYMMDD'), 'MMDDYYYY') txn_dt,
                    csl_txn_code
                 || csl_delivery_channel
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
                                         AND txn_code IN (11, 14, 16, 31)
                                         AND msgtype IN ('0100', '1200', '0200')
                                        )
                                    )) > 0
                          THEN '1'
                       ELSE '0'
                    END
                 || DECODE (txn_fee_flag, 'Y', 1, 0)
                 || (CASE
                        WHEN csl_delivery_channel IN ('03')
                        AND csl_txn_code IN
                               ('20', '13', '14', '19', '83', '74', '86', '85', '84',
                                '76', '12', '11', '75')
                           THEN LPAD ((SELECT TO_CHAR (csr_spprt_rsncode)
                                         FROM cms_spprt_reasons
                                        WHERE csr_reasondesc = a.reason
                                          AND csr_inst_code = a.instcode),
                                      3,
                                      '0'
                                     )
                        ELSE '000'
                     END
                    ) txn_cd_typ,
                 TO_CHAR (csl_trans_amount, 9999999990.99) txn_amt,
                 DECODE (csl_trans_type, 'CR', '+', '-') txn_amt_sign,
                 currencycode txn_curr_cd, csl_auth_id auth_code,
                 TO_CHAR (TO_DATE (csl_business_date, 'YYYYMMDD'),
                          'MMDDYYYY'
                         ) post_date,
                 network_id network_cd, merchant_id merc_no, merchant_name mer_name,
                 mccode mer_cat_cd, country_code mer_cntry_cd,
                 TO_CHAR (interchange_feeamt, 9999999990.99) interchnge_fee_amt,
                 csl_acct_no account_no, csl_rrn txn_ref_no,
                 csl_business_time txn_time, csl_business_time posted_time,
                 merchant_city merc_city, merchant_state merc_state,
                 merchant_zip merc_zip,
                 CASE
                    WHEN csl_delivery_channel IN ('01', '02')
                       THEN NVL (TO_CHAR (TO_DATE (network_settl_date, 'YYYYMMDD'),
                                          'MMDDYYYY'
                                         ),
                                 ''
                                )
                    ELSE NVL (TO_CHAR (csl_ins_date, 'MMDDYYYY'), '')
                 END settle_dt,
                 '' settle_time,
                 DECODE (csl_delivery_channel,
                         10, DECODE (csl_txn_code, '02', 'M', 'N'),
                         ' '
                        ) cvv_cvc,
                 DECODE (csl_delivery_channel,
                         10, DECODE (csl_txn_code, '02', 'M', 'N'),
                         ' '
                        ) cvv_cvc2,
                 ' ' x2x, ' ' post_indicator
            FROM transactionlog a, cms_appl_pan, cms_statements_log                 
           WHERE csl_inst_code = 1
	     AND CAP_PROD_CODE='VP73'
             AND csl_pan_no = cap_pan_code
	     AND CAP_ACCT_NO=CSL_ACCT_NO
             AND csl_ins_date BETWEEN TO_DATE (to_char(P_DATE,'YYYYMMDD') || '000000',
                                               'YYYYMMDDHH24MISS'
                                              )
                                  AND TO_DATE (TO_CHAR(P_DATE,'YYYYMMDD') || '235959',
                                               'YYYYMMDDHH24MISS'
                                              )
             AND csl_trans_amount <> 0
             AND csl_trans_amount IS NOT NULL
             AND csl_acct_no = customer_acct_no(+)
             AND csl_pan_no = customer_card_no(+)
             AND csl_rrn = rrn(+)
             AND csl_auth_id = auth_id(+)
        ORDER BY csl_pan_no, txn_dt, auth_code, txn_cd_typ DESC)
        
        
    LOOP
        BEGIN
            V_CNT := V_CNT+1;

            IF LENGTH(cur_rep.auth_code)>10 THEN
                cur_rep.auth_code:=SUBSTR(cur_rep.auth_code,LENGTH(cur_rep.auth_code)-6);
            END IF;
            
            

            V_WRT_BUFF:='D'||RPAD(NVL(TO_CHAR(TRIM(cur_rep.unique_program_id)),' '),15)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.proxy_no)),' '),30)||
            RPAD(NVL(TO_CHAR(TRIM(cur_rep.txn_dt)),' '),8)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.txn_cd_typ)),' '),15)||LPAD(NVL(TO_CHAR(TRIM(cur_rep.txn_amt)),' '),13)||
            RPAD(NVL(TO_CHAR(TRIM(cur_rep.txn_amt_sign)),' '),1)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.txn_curr_cd)),' '),3)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.auth_code)),' '),10)||
            RPAD(NVL(TO_CHAR(TRIM(cur_rep.post_date)),' '),8)|| RPAD(NVL(TO_CHAR(TRIM(cur_rep.network_cd)),' '),30)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.merc_no)),' '),30)||
            RPAD(NVL(TO_CHAR(TRIM(cur_rep.mer_name)),' '),50)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.mer_cat_cd)),' '),4)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.mer_cntry_cd)),' '),5)||
            RPAD(NVL(TO_CHAR(TRIM(cur_rep.interchnge_fee_amt)),' '),9)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.account_no)),' '),30)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.txn_ref_no)),' '),50)||
            RPAD(NVL(TO_CHAR(TRIM(cur_rep.txn_time)),' '),8)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.posted_time)),' '),8)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.merc_city)),' '),50)||
            RPAD(NVL(TO_CHAR(TRIM(cur_rep.merc_state)),' '),2)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.merc_zip)),' '),10)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.settle_dt)),' '),8)||
            RPAD(NVL(TO_CHAR(TRIM(cur_rep.settle_time)),' '),8)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.cvv_cvc)),' '),1)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.cvv_cvc2)),' '),1)||
            RPAD(NVL(TO_CHAR(TRIM(cur_rep.x2x)),' '),3)||RPAD(NVL(TO_CHAR(TRIM(cur_rep.post_indicator)),' '),3);

            utl_file.put_line (V_FILE_HANDLE, V_WRT_BUFF);
            
      
        EXCEPTION
            WHEN OTHERS THEN
                P_ERR:=SUBSTR(SQLERRM,1,200);
                RAISE V_EXCP;
        END;
    END LOOP;

    V_WRT_BUFF := 'TTRAILER'||LPAD(V_CNT,9,0);
    utl_file.put_line (v_file_handle, v_wrt_buff);

    utl_file.fflush (V_FILE_HANDLE);
    utl_file.fclose (V_FILE_HANDLE);
EXCEPTION
    WHEN V_EXCP THEN
        utl_file.fflush (V_FILE_HANDLE);
        utl_file.fclose (V_FILE_HANDLE);
    WHEN OTHERS THEN
        P_ERR := SUBSTR (SQLERRM, 1, 200);
        utl_file.fflush (V_FILE_HANDLE);
        utl_file.fclose (V_FILE_HANDLE);
END SP_IRIS_POSTED_RPT;