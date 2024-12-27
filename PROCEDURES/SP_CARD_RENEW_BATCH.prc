CREATE OR REPLACE PROCEDURE vmscms.sp_card_renew_batch (
   prm_instcode        IN       NUMBER,
   p_user              IN       NUMBER,
   p_total_processed   OUT      NUMBER,
   prm_errmsg          OUT      VARCHAR2
)
IS
   v_old_pan             NUMBER;
   v_hash_pan            cms_appl_pan.cap_pan_code%TYPE;
   v_newpan              cms_appl_pan.cap_pan_code%TYPE;
   v_old_expry_date      cms_appl_pan.cap_expry_date%TYPE;
   v_cardrenewal_check   NUMBER;
   exp_reject_record     EXCEPTION;
   v_encr_pan            cms_appl_pan.cap_pan_code_encr%TYPE;
   v_txn_desc            transactionlog.trans_desc%TYPE;
   v_rrn                 VARCHAR2 (20);
   v_card_stat           cms_appl_pan.cap_card_stat%TYPE;
   v_acct_no             cms_appl_pan.cap_acct_no%TYPE;
   v_cpm_catg_code       cms_prod_mast.cpm_catg_code%TYPE;
   v_prod_code           cms_appl_pan.cap_prod_code%TYPE;
   v_card_type           cms_appl_pan.cap_card_type%TYPE;
   v_old_product         cms_appl_pan.cap_prod_code%TYPE;
   v_old_cardtype        cms_appl_pan.cap_card_type%TYPE;
   v_acct_type           cms_acct_mast.cam_type_code%TYPE;
   v_acct_bal            cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal          cms_acct_mast.cam_ledger_bal%TYPE;
   v_savepoint           NUMBER                                DEFAULT 0;
   v_cnt                 NUMBER;
   v_repl_period         cms_prod_cattype.cpc_repl_period%TYPE;
    v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
/**************************************************************************
     * Created Date     : 06_Mar_2014
     * Created By       : Amudhan S
     * Purpose          : MVCSD-4121 and FWR-43 : Batch Card Renewal
     * Reviewer         : Dhiraj
     * Reviewed Date    : 06_Mar_2014
     * Build Number     : RI0027.2_B0002

    * Modified Date    : 25_Mar_2014
     * Modified By      : Amudhan
     * Purpose          : Review changes for MVCSD-4121 and FWR-47
     * Reviewer         : Pankaj S.
     * Reviewed Date    : 01-April-2014
     * Build Number     : RI0027.2_B0003

     * Modified Date    : 11_APR_2014
     * Modified By      : Amudhan
     * Purpose          : Review changes for cursor modified
     * Reviewer         : spankaj
     * Reviewed Date    : 15-April-2014
     * Build Number     : RI0027.2_B0005

     * Modified Date    : 24_SEPT_2015
     * Modified By      : Siva Kumar
     * Purpose          : In card Renewal, check for last 90 days transactions.
     * Reviewer         : Saravana Kumar
     * Reviewed Date    : 25-Sept-2015
     * Build Number     : VMSGPRHOSTCSD3.2_B0002
 /**************************************************************************/
   CURSOR cur_cardnewal
   IS
      /* Commented for review changes
        SELECT cap_pan_code, cap_expry_date, cap_pan_code_encr
       FROM cms_appl_pan,CMS_PROD_MAST,CMS_PROD_CATTYPE,cms_renewal_config
       WHERE CAP_INST_CODE=CPM_INST_CODE
        AND CPM_INST_CODE=CPC_INST_CODE
        and cap_inst_code=crc_inst_code
        AND CAP_PROD_CODE=CPM_PROD_CODE
        AND CAP_CARD_TYPE=CPC_CARD_TYPE
        AND CPM_PROD_CODE= cpc_prod_code
        and CAP_PROD_CODE= crc_prod_code
        and cap_card_type= crc_card_type
        and cap_card_stat = crc_card_stat
        and cap_expry_date is not null
        AND CPC_REPL_PERIOD IS NOT NULL AND CPC_REPL_PERIOD >0
        and (trunc( sysdate ) - trunc(cap_expry_date))<=CPC_REPL_PERIOD
        --and (trunc(cap_expry_date)-trunc(sysdate ))<0
        AND CAP_INST_CODE=PRM_INSTCODE
        ORDER BY trunc(sysdate )-trunc(cap_expry_date);
        */

      --added for review chanegs
      WITH mast AS
           (SELECT b.cpc_repl_period, c.cpm_prod_code, b.cpc_card_type,
                   a.crc_card_type, a.crc_card_stat, c.cpm_inst_code
              FROM cms_renewal_config a, cms_prod_cattype b, cms_prod_mast c
             WHERE c.cpm_prod_code = b.cpc_prod_code
               AND c.cpm_prod_code = a.crc_prod_code
               AND b.cpc_card_type = a.crc_card_type
               AND c.cpm_inst_code = b.cpc_inst_code
               AND c.cpm_inst_code = a.crc_inst_code
               AND b.cpc_repl_period > 0
               AND c.cpm_inst_code = 1)
      SELECT   a.cap_pan_code, a.cap_expry_date, a.cap_pan_code_encr,b.cpc_repl_period
          FROM cms_appl_pan a, mast b
         WHERE a.cap_inst_code = b.cpm_inst_code
           AND a.cap_prod_code = b.cpm_prod_code
           AND a.cap_card_type = b.crc_card_type
           AND a.cap_card_stat = b.crc_card_stat
           -- and  (trunc( a.cap_expry_date ) - trunc(sysdate))<=b.CPC_REPL_PERIOD
           AND TRUNC (a.cap_expry_date) BETWEEN TRUNC (SYSDATE)
                                            AND (TRUNC (  SYSDATE
                                                        + b.cpc_repl_period
                                                       )
                                                )
           AND a.cap_inst_code = prm_instcode
      ORDER BY TRUNC (a.cap_expry_date) - TRUNC (SYSDATE);
BEGIN
   -- MAIN BEGIN
   prm_errmsg := 'OK';
   p_total_processed := 0;

   OPEN cur_cardnewal;

   LOOP
      FETCH cur_cardnewal
       INTO v_hash_pan, v_old_expry_date, v_encr_pan,v_repl_period;

      EXIT WHEN cur_cardnewal%NOTFOUND;

      BEGIN
         SELECT COUNT (1)
           INTO v_cardrenewal_check
           FROM cms_cardrenewal_hist
          WHERE cch_pan_code = v_hash_pan
            --AND to_char(trunc(to_date(CCH_EXPRY_DATE)),'DD-MON-YYYY') = to_char(trunc(to_date(V_OLD_EXPRY_DATE)),'DD-MON-YYYY')
            AND TRUNC (cch_expry_date) = TRUNC (v_old_expry_date)
            AND cch_inst_code = prm_instcode;

         IF v_cardrenewal_check = 0
         THEN
            v_savepoint := v_savepoint + 1;
            SAVEPOINT v_savepoint;
                 BEGIN
				 --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(v_repl_period), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
                      SELECT count (1)
                            INTO v_cnt
                            FROM vmscms.transactionlog 
                            WHERE   customer_card_no = v_hash_pan
                            AND (  (delivery_channel = '11' AND txn_code IN ('22', '32'))
                                OR (delivery_channel = '08' AND txn_code IN ('22', '26'))
                                OR (delivery_channel = '01' AND txn_code IN ('10', '99','12'))
                                OR (delivery_channel = '02' AND txn_code IN ('12', '14', '16', '18', '20', '22', '25', '28','23','27','35','37','38','39','40','41','42','44','47','50','53','56')))
                            AND response_code = '00'
                            AND add_ins_date BETWEEN sysdate - v_repl_period AND sysdate;
ELSE
						SELECT count (1)
                            INTO v_cnt
                            FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
                            WHERE   customer_card_no = v_hash_pan
                            AND (  (delivery_channel = '11' AND txn_code IN ('22', '32'))
                                OR (delivery_channel = '08' AND txn_code IN ('22', '26'))
                                OR (delivery_channel = '01' AND txn_code IN ('10', '99','12'))
                                OR (delivery_channel = '02' AND txn_code IN ('12', '14', '16', '18', '20', '22', '25', '28','23','27','35','37','38','39','40','41','42','44','47','50','53','56')))
                            AND response_code = '00'
                            AND add_ins_date BETWEEN sysdate - v_repl_period AND sysdate;
END IF;							
                 EXCEPTION
                            WHEN others THEN
                                prm_errmsg :='Error while selecting transactionlog'|| substr (SQLERRM, 1, 200);
                            RAISE exp_reject_record;                  
                  END;
               IF v_cnt>=1 THEN

            --SN create encr pan
            BEGIN
               v_old_pan := fn_dmaps_main (v_encr_pan);
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while converting old card number to encrypted pan code '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

            sp_singlecard_renewal (prm_instcode,
                                   v_old_pan,
                                   '39',          --TXN_CODE     IN  VARCHAR2,
                                   1,              -- LUPDUSER     IN  NUMBER,
                                   v_newpan,
                                   prm_errmsg
                                  );

            IF prm_errmsg = 'OK'
            THEN
               p_total_processed := p_total_processed + 1;
            ELSE
               ROLLBACK TO v_savepoint;
               RAISE exp_reject_record;
            END IF;
         END IF;
        END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            --To find product catg
            BEGIN
               SELECT cap_prod_code, cap_card_type, cap_acct_no,
                      cap_card_stat
                 INTO v_prod_code, v_cpm_catg_code, v_acct_no,
                      v_card_stat
                 FROM cms_appl_pan
                WHERE cap_pan_code = v_hash_pan
                  AND cap_inst_code = prm_instcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_prod_code := NULL;
                  v_cpm_catg_code := NULL;
                  v_acct_no := NULL;
                  v_card_stat := NULL;
            END;

            --To find Account balance
            BEGIN
               SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
                 INTO v_acct_bal, v_ledger_bal, v_acct_type
                 FROM cms_acct_mast
                WHERE cam_acct_no = v_acct_no;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_acct_bal := 0;
                  v_ledger_bal := 0;
                  v_acct_type := NULL;
            END;

            BEGIN
               SELECT    TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISS')
                      || seq_passivestatupd_rrn.NEXTVAL
                 INTO v_rrn
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                       'Error while getting RRN ' || SUBSTR (SQLERRM, 1, 200);
            END;

            BEGIN                                                        --B23
               SELECT ctm_tran_desc
                 INTO v_txn_desc
                 FROM cms_transaction_mast
                WHERE ctm_inst_code = prm_instcode
                  AND ctm_tran_code = '39'                         -- TXN_CODE
                  AND ctm_delivery_channel = '05';
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_txn_desc := NULL;
            END;

            --Error Log
            BEGIN                                                        --B24
               INSERT INTO transactionlog
                           (msgtype, rrn, delivery_channel, txn_code,
                            trans_desc, customer_card_no,
                            customer_card_no_encr, business_date,
                            business_time, txn_status, response_code,
                            instcode, add_ins_date, response_id, date_time,
                            customer_acct_no, acct_balance, ledger_balance,
                            cardstatus, error_msg, acct_type,
                            productid, categoryid, cr_dr_flag, time_stamp
                           )
                    VALUES ('0200', v_rrn, '05', '39',
                            v_txn_desc, v_hash_pan,
                            v_encr_pan, TO_CHAR (SYSDATE, 'yyyymmdd'),
                            TO_CHAR (SYSDATE, 'hh24miss'), 'F', '89',
                            prm_instcode, SYSDATE, '89', SYSDATE,
                            v_acct_no, v_acct_bal, v_ledger_bal,
                            v_card_stat, prm_errmsg, v_acct_type,
                            v_prod_code, v_cpm_catg_code, 'NA', SYSTIMESTAMP
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while logging system initiated Single Card Renewal '
                     || SUBSTR (SQLERRM, 1, 200);
            END;

            BEGIN                                                        --B26
               INSERT INTO cms_transaction_log_dtl
                           (ctd_delivery_channel, ctd_txn_code,
                            ctd_txn_type, ctd_msg_type, ctd_txn_mode,
                            ctd_business_date,
                            ctd_business_time, ctd_customer_card_no,
                            ctd_process_flag, ctd_process_msg,
                            ctd_inst_code, ctd_customer_card_no_encr,
                            ctd_cust_acct_number
                           )
                    VALUES ('05', '39',
                            '0', '0200', 0,
                            TO_CHAR (SYSDATE, 'YYYYMMDD'),
                            TO_CHAR (SYSDATE, 'hh24miss'), v_hash_pan,
                            'E', prm_errmsg,
                            prm_instcode, v_encr_pan,
                            v_acct_no
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while inserting log details in transaction table'
                     || SUBSTR (SQLERRM, 1, 200);
            END;
         WHEN OTHERS
         THEN
            prm_errmsg := 'Main Exception' || SUBSTR (SQLERRM, 1, 100);

            --To find product catg
            BEGIN
               SELECT cap_prod_code, cap_card_type, cap_acct_no,
                      cap_card_stat
                 INTO v_prod_code, v_cpm_catg_code, v_acct_no,
                      v_card_stat
                 FROM cms_appl_pan
                WHERE cap_pan_code = v_hash_pan
                  AND cap_inst_code = prm_instcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_prod_code := NULL;
                  v_cpm_catg_code := NULL;
                  v_acct_no := NULL;
                  v_card_stat := NULL;
            END;

            --To find Account balance
            BEGIN
               SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
                 INTO v_acct_bal, v_ledger_bal, v_acct_type
                 FROM cms_acct_mast
                WHERE cam_acct_no = v_acct_no;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_acct_bal := 0;
                  v_ledger_bal := 0;
                  v_acct_type := NULL;
            END;

            BEGIN
               SELECT    TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISS')
                      || seq_passivestatupd_rrn.NEXTVAL
                 INTO v_rrn
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                       'Error while getting RRN ' || SUBSTR (SQLERRM, 1, 200);
            END;

            BEGIN                                                        --B23
               SELECT ctm_tran_desc
                 INTO v_txn_desc
                 FROM cms_transaction_mast
                WHERE ctm_inst_code = prm_instcode
                  AND ctm_tran_code = '39'                         -- TXN_CODE
                  AND ctm_delivery_channel = '05';
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_txn_desc := NULL;
            END;

            --Error Log
            BEGIN                                                        --B24
               INSERT INTO transactionlog
                           (msgtype, rrn, delivery_channel, txn_code,
                            trans_desc, customer_card_no,
                            customer_card_no_encr, business_date,
                            business_time, txn_status, response_code,
                            instcode, add_ins_date, response_id, date_time,
                            customer_acct_no, acct_balance, ledger_balance,
                            cardstatus, error_msg, acct_type,
                            productid, categoryid, cr_dr_flag, time_stamp
                           )
                    VALUES ('0200', v_rrn, '05', '39',
                            v_txn_desc, v_hash_pan,
                            v_encr_pan, TO_CHAR (SYSDATE, 'yyyymmdd'),
                            TO_CHAR (SYSDATE, 'hh24miss'), 'F', '89',
                            prm_instcode, SYSDATE, '89', SYSDATE,
                            v_acct_no, v_acct_bal, v_ledger_bal,
                            v_card_stat, prm_errmsg, v_acct_type,
                            v_prod_code, v_cpm_catg_code, 'NA', SYSTIMESTAMP
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while logging system initiated Single Card Renewal '
                     || SUBSTR (SQLERRM, 1, 200);
            END;

            BEGIN                                                        --B26
               INSERT INTO cms_transaction_log_dtl
                           (ctd_delivery_channel, ctd_txn_code,
                            ctd_txn_type, ctd_msg_type, ctd_txn_mode,
                            ctd_business_date,
                            ctd_business_time, ctd_customer_card_no,
                            ctd_process_flag, ctd_process_msg,
                            ctd_inst_code, ctd_customer_card_no_encr,
                            ctd_cust_acct_number
                           )
                    VALUES ('05', '39',
                            '0', '0200', 0,
                            TO_CHAR (SYSDATE, 'YYYYMMDD'),
                            TO_CHAR (SYSDATE, 'hh24miss'), v_hash_pan,
                            'E', prm_errmsg,
                            prm_instcode, v_encr_pan,
                            v_acct_no
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while inserting log details in transaction table'
                     || SUBSTR (SQLERRM, 1, 200);
            END;
      END;
   END LOOP;

   CLOSE cur_cardnewal;
EXCEPTION
   WHEN exp_reject_record
   THEN
      prm_errmsg := prm_errmsg;
   WHEN OTHERS
   THEN
      prm_errmsg := 'Main Exception' || SUBSTR (SQLERRM, 1, 100);
END;
/

SHOW ERROR;