create or replace PACKAGE BODY                      VMSCMS.VMSAUTOJOBS
IS
   -- Private type declarations

   -- Private constant declarations

   -- Private variable declarations

   -- Functions and procedures implementations
   -- PROCEDURE to automatic closure of account with balance write-off
   PROCEDURE card_auto_closure
   IS
      l_days             vms_autoclosure_prod.vap_prod_code%TYPE;
      l_acct_type        cms_acct_mast.cam_type_code%TYPE := 2;
      l_txn_code         transactionlog.txn_code%TYPE :='98';
      l_delivery_chnl    transactionlog.delivery_channel%TYPE:='05';
      l_msgtype          transactionlog.msgtype%TYPE:='0200';
      l_txnmode          transactionlog.txn_mode%TYPE:='0';
      l_rrn              transactionlog.rrn%TYPE;
      l_drcr_flag        cms_transaction_mast.ctm_credit_debit_flag%TYPE;
      l_txn_type         transactionlog.txn_type%TYPE;
      l_trans_desc       cms_transaction_mast.ctm_tran_desc%TYPE;
      l_rrn_cnt          NUMBER := 0;
      l_business_date    transactionlog.business_date%TYPE;
      l_business_time    transactionlog.business_time%TYPE;
      l_savngledgr_bal   cms_acct_mast.cam_ledger_bal%TYPE;
      l_authid           transactionlog.auth_id%TYPE;
      l_last_txndt      DATE;
      l_errmsg           VARCHAR2 (1000);
      excp_rej_rec       EXCEPTION;

/***************************************************************************************
	 * Modified By        : Ubaidur Rahman.H
         * Modified Date      : 06-May-2019
         * Modified Reason    : Write-Off Change - VMS-885
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 07-May-2019
         * Build Number       : VMS_R15_B5
***************************************************************************************/ 

   BEGIN
      BEGIN
         SELECT ctm_credit_debit_flag,
                DECODE (ctm_tran_type,  'N', '0',  'F', '1'),
                ctm_tran_desc
           INTO l_drcr_flag, l_txn_type, l_trans_desc
           FROM cms_transaction_mast
          WHERE     ctm_tran_code =l_txn_code
                AND ctm_delivery_channel =l_delivery_chnl
                AND ctm_inst_code = 1;
      EXCEPTION
         WHEN OTHERS THEN
            l_drcr_flag := 'NA';
            l_txn_type := '0';
            l_trans_desc := 'Automatic closure of card';
      END;

      FOR l_idx
         IN (SELECT a.cap_inst_code instcode, a.cap_acct_no acctno,
                    a.cap_pan_code cardno, a.cap_pan_code_encr cardno_encr,
                    a.cap_cust_code custcode, a.cap_prod_code prodcode,
                    a.cap_card_type cardtype, a.cap_card_stat cardstat,b.cam_acct_bal acctbal,
                    b.cam_ledger_bal ledgbal, cap_mbr_numb mbrnumb,
                    a.cap_proxy_number proxy, b.cam_lupd_date, c.vap_period,
                    c.vap_reason_code, c.vap_narration, c.vap_remarks,
                     row_number() over (partition by a.cap_acct_no order by a.cap_active_date)rnum
               FROM cms_appl_pan a, cms_acct_mast b,vms_autoclosure_prod c
              WHERE   ---  a.cap_card_stat <> '9' AND				--- Commented for VMS-885
                     (b.cam_acct_bal < 0  AND b.cam_ledger_bal < 0)
                    AND a.cap_inst_code = b.cam_inst_code
                    AND a.cap_acct_no = b.cam_acct_no
                    AND a.cap_prod_code=c.vap_prod_code
             ORDER BY a.cap_acct_no, a.cap_active_date)
      LOOP
         BEGIN
            l_errmsg := 'OK';

            IF  l_idx.ledgbal<> l_idx.acctbal THEN
                  l_errmsg := 'Available and Ledger Balance is Not Same';
                  RAISE excp_rej_rec;
            END IF;

            BEGIN
               SELECT cam_ledger_bal
                 INTO l_savngledgr_bal
                 FROM cms_cust_acct a, cms_acct_mast b
                WHERE     b.cam_type_code = l_acct_type
                      AND a.cca_cust_code = l_idx.custcode
                      AND a.cca_inst_code = cam_inst_code
                      AND a.cca_acct_id = cam_acct_id;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  l_savngledgr_bal := 0;
               WHEN OTHERS THEN
                  l_errmsg := 'Error while selecting saving acct dtls-' || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_rej_rec;
            END;

         IF l_savngledgr_bal = 0 THEN

/*                IF l_idx.cap_last_txndate IS NULL AND l_idx.cardstat <>'0' THEN
                   BEGIN
                       SELECT nvl(max(add_ins_date),sysdate-180)
                        into l_idx.cap_last_txndate
                        FROM transactionlog
                        WHERE instcode = l_idx.instcode
                        AND customer_card_no =l_idx.cardno
                        AND NOT (delivery_channel='05' AND txn_code IN ('04','13','16','17','18','97'))
                        AND add_ins_date >= TRUNC (SYSDATE) - 180 ;
                   EXCEPTION
                      WHEN OTHERS THEN
                         l_idx.cap_last_txndate:=sysdate-180;
                   END;
                END IF;

                IF l_idx.rnum=1 THEN
                    l_last_txndt:=l_idx.cap_last_txndate;
                ELSE
                    l_idx.cap_last_txndate:= l_last_txndt;
                END IF;
*/                
             IF l_idx.cam_lupd_date < SYSDATE - l_idx.vap_period THEN
                  l_rrn_cnt := l_rrn_cnt + 1;

                  BEGIN
                     SELECT TO_CHAR (SYSDATE, 'yyyymmdd'),
                            TO_CHAR (SYSDATE, 'hh24miss'),
                            TO_CHAR (SYSDATE, 'ddhh24miss')
                            || LPAD (l_rrn_cnt, 5, 0)
                       INTO l_business_date, l_business_time, l_rrn
                       FROM DUAL;
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_errmsg :='Error while selecting txn dtls-'|| SUBSTR (SQLERRM, 1, 200);
                        RAISE excp_rej_rec;
                  END;

                  BEGIN
                     vmsautojobs.acct_bal_adjustment (
                        l_idx.instcode,
                        l_rrn,
                        l_idx.cardno,
                        l_idx.cardno_encr,
                        l_idx.acctno,
                        l_idx.prodcode,
                        l_idx.cardtype,
                        l_idx.cardstat,
                        ABS(ROUND (l_idx.ledgbal, 2)),
                        'CR',
                        l_idx.vap_reason_code,
                        l_idx.vap_narration,--'Card Auto Closure',
                        l_idx.vap_remarks,--'Automatic closure of account with balance write-off ',
                        l_errmsg);

                     IF l_errmsg <> 'OK' THEN
                        RAISE excp_rej_rec;
                     END IF;
                  EXCEPTION
                     WHEN excp_rej_rec THEN
                        RAISE;
                     WHEN OTHERS THEN
                        l_errmsg :='Error while calling ACCT_BAL_ADJUSTMENT-'|| SUBSTR (SQLERRM, 1, 200);
                        RAISE excp_rej_rec;
                  END;

          IF l_idx.cardstat <> '9'
          THEN
               BEGIN
                  UPDATE cms_appl_pan
                     SET cap_card_stat = '9'
                   WHERE     cap_inst_code = l_idx.instcode
                         AND cap_pan_code = l_idx.cardno
                         AND cap_mbr_numb = l_idx.mbrnumb;
               EXCEPTION
                  WHEN OTHERS THEN
                     l_errmsg :='Error while updating cardstat-'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE excp_rej_rec;
               END;


                BEGIN
                   SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0') INTO l_authid FROM DUAL;
                EXCEPTION
                   WHEN OTHERS THEN
                      l_errmsg := 'Error while generating authid-' || SUBSTR (SQLERRM, 1, 200);
                      RAISE excp_rej_rec;
                END;

               BEGIN
                  sp_log_txnlog (l_idx.instcode,
                                 l_msgtype,
                                 l_rrn,
                                 l_delivery_chnl,
                                 l_txn_code,
                                 l_txn_type,
                                 l_txnmode,
                                 l_business_date,
                                 l_business_time,
                                 '00',
                                 l_idx.cardno,
                                 l_idx.cardno_encr,
                                 l_errmsg,
                                 NULL,
                                 '9',
                                 l_trans_desc,
                                 NULL,
                                 NULL,
                                 SYSTIMESTAMP,
                                 l_idx.acctno,
                                 l_idx.prodcode,
                                 l_idx.cardtype,
                                 l_drcr_flag,
                                 0,
                                 0,
                                 1,
                                 l_idx.proxy,
                                 l_authid,
                                 '0',
                                 '0',
                                 NULL,
                                 0,
                                 NULL,
                                 NULL,
                                 '1',
                                 '00',
                                 NULL,
                                 l_errmsg);

                  IF l_errmsg <> 'OK' THEN
                     l_errmsg := 'Error from sp_log_txnlog-' || l_errmsg;
                     RAISE excp_rej_rec;
                  END IF;
               EXCEPTION
                  WHEN excp_rej_rec THEN
                     RAISE;
                  WHEN OTHERS THEN
                     l_errmsg :='Error while inserting into txnlog-'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE excp_rej_rec;
               END;

                BEGIN
                   sp_log_txnlogdetl (l_idx.instcode,
                                      l_msgtype,
                                      l_rrn,
                                      l_delivery_chnl,
                                      l_txn_code,
                                      l_txn_type,
                                      l_txnmode,
                                      l_business_date,
                                      l_business_time,
                                      l_idx.cardno,
                                      l_idx.cardno_encr,
                                      l_errmsg,
                                      l_idx.acctno,
                                      l_authid,
                                      '0',
                                      NULL,
                                      NULL,
                                      NULL,   --l_hashkey_id
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      '00',
                                      NULL,
                                      NULL,
                                      NULL,
                                      l_errmsg);

                   IF l_errmsg <> 'OK' THEN
                      l_errmsg := 'Error from sp_log_txnlogdetl-' || l_errmsg;
                      RAISE excp_rej_rec;
                   END IF;
                EXCEPTION
                   WHEN excp_rej_rec THEN
                      RAISE;
                   WHEN OTHERS THEN
                      l_errmsg :='Error while inserting into sp_log_txnlogdetl-' || SUBSTR (SQLERRM, 1, 200);
                      RAISE excp_rej_rec;
                END;
             END IF;

         	END IF;
            END IF;
         EXCEPTION
            WHEN excp_rej_rec THEN
               ROLLBACK;
               l_last_txndt:=NULL;
               INSERT INTO vms_autoclosr_fail_dtl
                    VALUES (l_idx.cardno, l_idx.acctno, l_errmsg, SYSDATE);
            WHEN OTHERS THEN
               ROLLBACK;
               l_errmsg :='Error while processing-' || SUBSTR (SQLERRM, 1, 200);
               l_last_txndt:=NULL;
               INSERT INTO vms_autoclosr_fail_dtl
                    VALUES (l_idx.cardno, l_idx.acctno, l_errmsg, SYSDATE);
         END;
         COMMIT;
      END LOOP;
   END card_auto_closure;

   --PROCEDURE  use for SWEEP job
PROCEDURE sweep_acct_job
IS
   l_rrn           transactionlog.rrn%TYPE;
   l_txn_code      transactionlog.txn_code%TYPE;
   l_rrn_cnt       NUMBER := 0;
   l_errmsg        VARCHAR2 (1000);
   l_rsncode       NUMBER;
   l_cardstat      cms_appl_pan.cap_card_stat%TYPE := '9';
   l_instcode      cms_appl_pan.cap_inst_code%TYPE := 1;
   l_pan_code      cms_appl_pan.cap_pan_code%TYPE;
   l_pan_encr      cms_appl_pan.cap_pan_code_encr%TYPE;
   l_card_stat     cms_appl_pan.cap_card_stat%TYPE;
   l_prod_code     cms_appl_pan.cap_prod_code%TYPE;
   l_card_type     cms_appl_pan.cap_card_type%TYPE;
   l_sweep_flag    cms_prod_cattype.cpc_sweep_flag%TYPE;
   l_active_flag   NUMBER;
   l_remark        VARCHAR2 (300);
   excp_rej_rec    EXCEPTION;
/***************************************************************************************
	     * Modified By          : Ubaid
         * Modified Date      : 14-Feb-2019
         * Modified Reason    : Commented infinitive loop
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 14-Feb-2019
         * Build Number       : VMS_RSI0189

         * Modified By        : Ubaid
         * Modified Date      : 09-Sep-2019
         * Modified Reason    : VMS-1081 (Enhance Sweep Job for Amex products)
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 09-Sep-2019
         * Build Number       : R20_B0002

		 * Modified By      : Saravanakumar A.
		 * Modified Date    : 29-09-2021
		 * Purpose          : VMS-:3371 Health Care Sweep .
		 * Reviewer         : Anil
		 * Build Number     : R52 - BUILD 2
***************************************************************************************/ 
BEGIN
   --LOOP--Commented infinitive loop
      FOR l_idx
         IN (SELECT DISTINCT 
                a.cap_acct_no acctno,
                b.cam_acct_bal acctbal,
                b.cam_ledger_bal ledgbal
              FROM cms_appl_pan a,
                cms_acct_mast b,
                cms_prod_cattype c
              WHERE a.cap_inst_code   = c.cpc_inst_code
              AND a.cap_prod_code     = c.cpc_prod_code
              AND a.cap_card_type     = c.cpc_card_type
              AND c.cpc_sweep_flag    = 'Y'
              AND a.cap_card_stat     <> l_cardstat
              AND b.cam_inst_code     = a.cap_inst_code
              AND b.cam_acct_no       = a.cap_acct_no
              AND b.cam_acct_bal     > 0
              AND b.cam_acct_bal      = b.cam_ledger_bal
              AND TRUNC(a.cap_expry_date)   <= TRUNC(SYSDATE) --NVL (c.cpc_addl_sweep_period, 0) --VMS:8532 changes for Usecase-2 & 3
			  AND NVL(C.CPC_YEAREND_SWEEP,'N') = 'N'
              AND NOT EXISTS (SELECT vli_pan_code                                         -- VMS-1081 (Enhance Sweep Job for Amex products)
                               FROM vms_line_item_dtl d,
                                vms_order_details e,
                                vms_sweep_state_exclusion f
                               WHERE d.vli_pan_code        = a.cap_pan_code
                               AND d.vli_order_id          = e.vod_order_id
                               AND d.vli_partner_id        = e.vod_partner_id
                               AND f.vss_bank_id           = c.cpc_issubank_id
                               AND f.vss_state_switch_code = fn_dmaps_main(e.vod_state)
                               AND f.vss_switch_cntry_code = fn_dmaps_main(e.vod_country)
                               AND e.vod_order_type        = 'IND'
                               ))
      LOOP
         BEGIN
            l_errmsg := 'OK';

            BEGIN
               SELECT *
                 INTO l_pan_code, l_pan_encr, l_card_stat,
                      l_prod_code, l_card_type, l_sweep_flag, l_active_flag
                 FROM (  SELECT a.cap_pan_code cardno, a.cap_pan_code_encr cardno_encr, a.cap_card_stat cardstat,
                                a.cap_prod_code prodcode, a.cap_card_type cardtype, NVL (b.cpc_sweep_flag, 'N') sweepflag,
                                SUM (CASE WHEN a.cap_active_date IS NULL THEN 0 ELSE 1 END)
                                OVER (PARTITION BY a.cap_acct_no) active_flag
                           FROM cms_appl_pan a, cms_prod_cattype b
                          WHERE     a.cap_inst_code = l_instcode
                                AND a.cap_acct_no = l_idx.acctno
                                AND b.cpc_inst_code = a.cap_inst_code
                                AND b.cpc_prod_code = a.cap_prod_code
                                AND b.cpc_card_type = a.cap_card_type
                       ORDER BY a.cap_pangen_date DESC)
                WHERE ROWNUM = 1;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'Error while selecting activation dtls-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_rej_rec;
            END;

            IF l_sweep_flag = 'N'
            THEN
               CONTINUE;
            END IF;

            l_rrn_cnt := l_rrn_cnt + 1;

            BEGIN
               SELECT TO_CHAR (SYSDATE, 'ddmmhh24miss')
                      || LPAD (l_rrn_cnt, 5, 0)
                 INTO l_rrn
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'Error while selecting txn dtls-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_rej_rec;
            END;

            IF l_active_flag = 0
            THEN
               l_rsncode := 222;
               l_remark := 'No Act/Fund Sweeps Account - Debit/Incomm';
               l_txn_code := '60';
            ELSE
               l_rsncode := 223;
               l_remark := 'Expired Fund - Debit/Incomm';
               l_txn_code := '61';
            END IF;

            BEGIN
               vmsautojobs.acct_bal_adjustment (l_instcode,
                                                l_rrn,
                                                l_pan_code,
                                                l_pan_encr,
                                                l_idx.acctno,
                                                l_prod_code,
                                                l_card_type,
                                                l_card_stat,
                                                ROUND (l_idx.ledgbal, 2),
                                                'DR',
                                                l_rsncode,
                                                l_remark,
                                                l_remark,
                                                l_errmsg,
                                                'B',
                                                NULL,
                                                l_txn_code);

               IF l_errmsg <> 'OK'
               THEN
                  RAISE excp_rej_rec;
               END IF;
            EXCEPTION
               WHEN excp_rej_rec
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'Error while calling ACCT_BAL_ADJUSTMENT-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_rej_rec;
            END;
         EXCEPTION
            WHEN excp_rej_rec
            THEN
               ROLLBACK;

               INSERT INTO vms_sweepjob_fail_dtl
                    VALUES (l_pan_code,
                            l_idx.acctno,
                            l_errmsg,
                            SYSDATE);
            WHEN OTHERS
            THEN
               ROLLBACK;
               l_errmsg :=
                  'Error while processing-' || SUBSTR (SQLERRM, 1, 200);

               INSERT INTO vms_sweepjob_fail_dtl
                    VALUES (l_pan_code,
                            l_idx.acctno,
                            l_errmsg,
                            SYSDATE);
         END;

         COMMIT;
      END LOOP;
  -- END LOOP;--Commented infinitive loop
END sweep_acct_job;

   --PROCEDURE  use for Card replacement  job
PROCEDURE card_replacement_job
(p_rec_count       OUT NUMBER)

IS
   l_rrn            transactionlog.rrn%TYPE;
   l_auth_id        transactionlog.auth_id%TYPE;
   l_resp_code      transactionlog.response_id%TYPE;
   l_txn_code       transactionlog.txn_code%TYPE := '11';
   l_delv_channel   transactionlog.delivery_channel%TYPE := '10';
   l_cardstat       cms_appl_pan.cap_card_stat%TYPE := '9';
   l_instcode       cms_appl_pan.cap_inst_code%TYPE := 1;
   l_errmsg         VARCHAR2 (1000);
   l_dup_check  NUMBER;
   l_txn_cnt        NUMBER;
   l_capture_date   DATE;
   excp_rej_rec     EXCEPTION;
   l_rec_count NUMBER := 0;
BEGIN
p_rec_count :=0;
   FOR l_idx
      IN (SELECT a.ROWID rd,
                 a.cap_pan_code pan_code,
                 a.cap_expry_date expry_date,
                 a.cap_pan_code_encr pan_code_encr,
                 a.cap_expry_date - b.vap_repl_period expry_dt
            FROM cms_appl_pan a, vms_autoreplacement_prod b
           WHERE     a.cap_inst_code = l_instcode
                 AND a.cap_startercard_flag = 'N'
                 AND a.cap_card_stat != l_cardstat
                 AND a.cap_replace_exprydt IS NULL
                 AND a.cap_prod_code = b.vap_prod_code
                 AND TO_CHAR (a.cap_expry_date, 'MMYYYY') = TO_CHAR(sysdate,'MMYYYY'))
   LOOP
      BEGIN
         l_errmsg := 'OK';

        BEGIN
           SELECT COUNT (1)
             INTO l_dup_check
             FROM cms_htlst_reisu
            WHERE     chr_inst_code = l_instcode
                  AND chr_pan_code =  l_idx.pan_code
                  AND chr_reisu_cause = 'R'
                  AND chr_new_pan IS NOT NULL;

           IF l_dup_check > 0
           THEN
             CONTINUE;
           END IF;
        END;

         BEGIN
            SELECT COUNT (1)
              INTO l_txn_cnt
              FROM transactionlog a
             WHERE a.customer_card_no = l_idx.pan_code
                   AND ( (a.delivery_channel = '11'
                          AND a.txn_code IN ('22', '32'))
                        OR (a.delivery_channel = '08'
                            AND a.txn_code IN ('22', '26'))
                        OR (a.delivery_channel = '01'
                            AND a.txn_code IN ('10', '99', '12'))
                        OR (a.delivery_channel = '02'
                            AND a.txn_code IN ('12', '14', '16', '18', '20', '22', '23',  '25', '27', '28', '35', '37', '38', '39','40', '41', '42', '44', '47', '50', '53', '56')))
                   AND a.response_code = '00'
                   AND a.add_ins_date BETWEEN l_idx.expry_dt
                                          AND l_idx.expry_date;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_errmsg :=
                  'Error while selecting txn count-'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_rej_rec;
         END;

         IF l_txn_cnt > 0
         THEN
            BEGIN
               UPDATE cms_appl_pan
                  SET cap_card_stat = '3'
                WHERE ROWID = l_idx.rd;

               IF SQL%ROWCOUNT = 0
               THEN
                  l_errmsg := 'Record is not updated in cms_appl_pan';
                  RAISE excp_rej_rec;
               END IF;
            EXCEPTION
               WHEN excp_rej_rec
               THEN
                  RAISE excp_rej_rec;
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'Error while updating card status to damage in appl_pan-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_rej_rec;
            END;

            BEGIN
               SELECT    'MI'
                      || TO_CHAR (SYSDATE, 'ddmmyy')
                      || LPAD (mio_rrn.NEXTVAL, 7, 0)
                 INTO l_rrn
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'Error while generating rrn-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_rej_rec;
            END;

            BEGIN
               sp_chw_order_replace_r305 (
                  l_instcode,
                  '0200',
                  l_rrn,
                  l_delv_channel ,
                  '0',
                  l_txn_code ,
                  '0',
                  TO_CHAR (SYSDATE, 'yyyymmdd'),
                  TO_CHAR (SYSDATE, 'hh24miss'),
                  fn_dmaps_main (l_idx.pan_code_encr),
                  l_instcode,                                      --Bank code
                  NULL,
                  NULL,
                  '840',
                  NULL,
                  NULL,
                  NULL,
                  '000',
                  0,
                  '12.34.56.78',
                  l_auth_id,
                  l_resp_code,
                  l_errmsg,
                  l_capture_date,
                  l_rec_count,
                  'N');

               IF l_resp_code <> '00'
               THEN
                  RAISE excp_rej_rec;
               END IF;
            EXCEPTION
               WHEN excp_rej_rec
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'Error while calling sp_chw_order_replace_r305-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_rej_rec;
            END;
         END IF;
      EXCEPTION
         WHEN excp_rej_rec
         THEN
            ROLLBACK;

            INSERT INTO vms_autoreplacement_fail_dtl
                 VALUES (l_idx.pan_code, l_errmsg, SYSDATE);
         WHEN OTHERS
         THEN
            ROLLBACK;
            l_errmsg := 'Error while processing-' || SUBSTR (SQLERRM, 1, 200);

            INSERT INTO vms_autoreplacement_fail_dtl
                 VALUES (l_idx.pan_code, l_errmsg, SYSDATE);
      END;
      p_rec_count := p_rec_count+l_rec_count;
      COMMIT;
   END LOOP;
END card_replacement_job;

   -- PROCEDURE to automatic credits of reward points
    PROCEDURE rewards_auto_credit (p_src_dir_in    IN VARCHAR2,
                                   p_dest_dir_in   IN VARCHAR2, p_rej_dir_in   IN VARCHAR2)
    IS
       l_instcode      NUMBER := 1;
       l_dup_check  NUMBER;
       l_batch_id      VARCHAR2 (100);
       l_panno         VARCHAR2 (30);
       l_dir_path      all_directories.directory_path%TYPE;
       l_hash_pan      cms_appl_pan.cap_pan_code%TYPE;
       l_encr_pan      cms_appl_pan.cap_pan_code_encr%TYPE;
       l_card_stat     cms_appl_pan.cap_card_stat%TYPE;
       l_prod_code     cms_appl_pan.cap_prod_code%TYPE;
       l_card_type     cms_appl_pan.cap_card_type%TYPE;
       l_acct_number   cms_appl_pan.cap_acct_no%TYPE;
       l_rrn           transactionlog.rrn%TYPE;
       l_rrn_cnt       NUMBER DEFAULT 0;
       l_proc_stat    VARCHAR2(1);
       l_file_stat    VARCHAR2(1);
       l_err_cnt       NUMBER DEFAULT 0;
       l_succ_cnt     NUMBER DEFAULT 0;
       l_errmsg        VARCHAR2 (1000);
       excp_rej_rec    EXCEPTION;
       excp_rej_file   EXCEPTION;
    BEGIN
       BEGIN
          SELECT TRIM (directory_path)
            INTO l_dir_path
            FROM all_directories
           WHERE directory_name = UPPER (p_src_dir_in);

          IF l_dir_path IS NULL THEN
             l_errmsg := 'Oracle directory Not Found-';
             RETURN;
          END IF;
       EXCEPTION
          WHEN OTHERS THEN
             l_errmsg :='Error while getting the Oracle directory path-'|| SUBSTR (SQLERRM, 1, 200);
             RETURN;
       END;

       BEGIN
          get_AutoReward_filelist (l_dir_path);
       EXCEPTION
          WHEN OTHERS THEN
             l_errmsg :='Error while getting file lists-' || SUBSTR (SQLERRM, 1, 200);
             RETURN;
       END;

       FOR l_idx IN (SELECT ROWID rd, vrd_file_name FROM vms_rewardfile_dtls where vrd_upd_stat='N')
       LOOP
          BEGIN
             l_errmsg := 'OK';
             l_err_cnt :=0;
             l_succ_cnt :=0;
             l_file_stat:='S';

            /* IF SUBSTR (l_idx.vrd_file_name,1,15) <>'Credit_Rewards_' THEN
                  l_errmsg :='Invalid file(name mismatch) for auto credit reward processing';
                  RAISE excp_rej_file;
             END IF;*/

             BEGIN
                SELECT COUNT (1)
                  INTO l_dup_check
                  FROM vms_rewardfile_dtls
                 WHERE vrd_upd_stat IN ('E', 'S') AND vrd_file_name = l_idx.vrd_file_name;

                IF l_dup_check > 0 THEN
                   l_errmsg := 'File already processed.';
                   RAISE excp_rej_file;
                END IF;
             EXCEPTION
               WHEN excp_rej_file THEN
                   RAISE excp_rej_file;
                WHEN OTHERS THEN
                   l_errmsg := 'Error while dup file check-' || SUBSTR (SQLERRM, 1, 200);
                   RAISE excp_rej_file;
             END;

             BEGIN
                SELECT 'AutoRewards_Batch'|| LPAD (seq_batchupload_id.NEXTVAL, 6, '0')
                  INTO l_batch_id
                  FROM DUAL;
             EXCEPTION
                WHEN OTHERS THEN
                   l_errmsg :='Error while generating Batch id-'|| SUBSTR (SQLERRM, 1, 200);
                   RAISE excp_rej_file;
             END;

             load_reward_file (p_src_dir_in, l_idx.vrd_file_name, l_batch_id, l_errmsg);

             IF l_errmsg <> 'OK' THEN
                RAISE excp_rej_file;
             END IF;

             FOR l_indx IN (SELECT a.ROWID rid, a.* FROM cms_acct_batch_adjustment a
                             WHERE cab_batch_id = l_batch_id AND cab_process_status='N')
             LOOP
                    BEGIN
                       l_rrn_cnt := l_rrn_cnt + 1;
                       l_proc_stat:='Y';
                       l_errmsg := 'OK';

                       BEGIN
                          SELECT *
                            INTO l_card_stat, l_prod_code, l_card_type,
                             l_encr_pan, l_hash_pan
                            FROM (  SELECT cap_card_stat, cap_prod_code, cap_card_type,
                                           cap_pan_code_encr, cap_pan_code
                                      FROM cms_appl_pan
                                     WHERE     cap_acct_no = l_indx.cab_acct_no
                                           AND cap_inst_code = l_instcode
                                           AND cap_card_stat NOT IN ('9', '11')
                                  ORDER BY cap_ins_date)
                           WHERE ROWNUM = 1;
                       EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                             BEGIN
                                SELECT *
                                  INTO l_card_stat, l_prod_code, l_card_type,
                                       l_encr_pan, l_hash_pan
                                  FROM (  SELECT cap_card_stat, cap_prod_code, cap_card_type,
                                                 cap_pan_code_encr, cap_pan_code
                                            FROM cms_appl_pan
                                           WHERE cap_acct_no = l_indx.cab_acct_no
                                                 AND cap_inst_code = l_instcode
                                        ORDER BY cap_ins_date)
                                 WHERE ROWNUM = 1;
                             EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                   l_errmsg := 'Card Not Found In CMS';
                                   RAISE excp_rej_rec;
                                WHEN OTHERS THEN
                                   l_errmsg :='Error while selecting card number-'|| SUBSTR (SQLERRM, 1, 200);
                                   RAISE excp_rej_rec;
                             END;
                          WHEN OTHERS THEN
                             l_errmsg :='Error while selecting card number-'|| SUBSTR (SQLERRM, 1, 200);
                             RAISE excp_rej_rec;
                       END;

                       l_rrn :=TO_CHAR (SYSDATE, 'ddhh24miss') || LPAD (l_rrn_cnt, 5, 0);

                       BEGIN
                          vmsautojobs.acct_bal_adjustment (
                             l_instcode,
                             l_rrn,
                             l_hash_pan,
                             l_encr_pan,
                             l_indx.cab_acct_no,
                             l_prod_code,
                             l_card_type,
                             l_card_stat,
                             ROUND (l_indx.cab_trans_amount, 2),
                             l_indx.cab_trans_type,
                             l_indx.cab_reason_code,
                             l_indx.cab_trans_narration,
                             l_indx.cab_remark,
                             l_errmsg,
                             nvl(l_indx.cab_balimpact_flag,'B'),
                             l_batch_id);

                          IF l_errmsg <> 'OK' THEN
                             RAISE excp_rej_rec;
                          END IF;
                       EXCEPTION
                          WHEN excp_rej_rec THEN
                             RAISE;
                          WHEN OTHERS THEN
                             l_errmsg :='Error while calling ACCT_BAL_ADJUSTMENT-'|| SUBSTR (SQLERRM, 1, 200);
                             RAISE excp_rej_rec;
                       END;

                       l_succ_cnt:=l_succ_cnt+1;
                    EXCEPTION
                       WHEN excp_rej_rec THEN
                            l_proc_stat:='E';
                            l_err_cnt:=l_err_cnt+1;
                            ROLLBACK;
                        WHEN OTHERS THEN
                           l_errmsg :='Error while processing records-'|| SUBSTR (SQLERRM, 1, 200);
                           ROLLBACK;
                           l_err_cnt:=l_err_cnt+1;
                           l_proc_stat:='E';
                    END;
                  UPDATE cms_acct_batch_adjustment
                     SET cab_process_status = l_proc_stat,
                         cab_process_description = l_errmsg,
                         cab_process_date = SYSDATE
                   WHERE ROWID = l_indx.rid;
                       COMMIT;
             END LOOP;

          EXCEPTION
             WHEN excp_rej_file THEN
                l_file_stat:='R';
             WHEN OTHERS THEN
                l_file_stat:='R';
                l_errmsg :='Error while processing file-'|| SUBSTR (SQLERRM, 1, 200);
          END;

            UPDATE vms_rewardfile_dtls
               SET vrd_batch_id = l_batch_id,
                   vrd_tot_rows = l_err_cnt + l_succ_cnt,
                   vrd_succ_rows = l_succ_cnt,
                   vrd_err_rows = l_err_cnt,
                   vrd_process_msg = l_errmsg,
                   vrd_process_date = SYSDATE,
                   vrd_upd_stat = l_file_stat
             WHERE ROWID = l_idx.rd;

            BEGIN
               UTL_FILE.frename ( p_src_dir_in, l_idx.vrd_file_name,
                  CASE WHEN l_file_stat = 'S' THEN p_dest_dir_in ELSE p_rej_dir_in END, l_idx.vrd_file_name, TRUE);
            EXCEPTION
               WHEN OTHERS THEN
                  l_errmsg := 'Error while moving file-' || SUBSTR (SQLERRM, 1, 200);
                  UPDATE vms_rewardfile_dtls
                     SET vrd_process_msg = l_errmsg, vrd_upd_stat = 'E'
                   WHERE ROWID = l_idx.rd;
            END;
         COMMIT;
       END LOOP;
    END rewards_auto_credit;

   --PROCEDURE to Post the adjustment to the account based on the account number, amount, credit/debit indicator.
   PROCEDURE acct_bal_adjustment (p_instcode_in            NUMBER,
                                  p_rrn_in                 VARCHAR2,
                                  p_cardno_in              VARCHAR2,
                                  p_cardno_encr_in         VARCHAR2,
                                  p_acctno_in              VARCHAR2,
                                  p_prodcode_in            VARCHAR2,
                                  p_cardtype_in            NUMBER,
                                  p_cardstat_in            VARCHAR2,
                                  p_txnamt_in              NUMBER,
                                  p_txntype_in             VARCHAR2,
                                  p_rsn_code_in          NUMBER,
                                  p_txnnarration_in        VARCHAR2,
                                  p_remark_in              VARCHAR2,
                                  p_resp_msg_out       OUT VARCHAR2,
                                  p_bal_impctflag_in      VARCHAR2 DEFAULT 'B',
                                  p_batchid_in             VARCHAR2 DEFAULT NULL,
                                  p_txncode_in              VARCHAR2 DEFAULT NULL)
   AS
      l_delivery_channel   transactionlog.delivery_channel%TYPE;
      l_txn_type           transactionlog.txn_type%TYPE;
      l_txn_code           transactionlog.txn_code%TYPE;
      l_reasondesc         cms_spprt_reasons.csr_reasondesc%TYPE;
      l_upd_amt            NUMBER;
      l_upd_acct_bal       NUMBER;
      l_acct_type          cms_acct_type.cat_type_code%TYPE;
      l_acct_bal           cms_acct_mast.cam_acct_bal%TYPE;
      l_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
      l_auth_id            transactionlog.auth_id%TYPE;
      l_narration          cms_statements_log.csl_trans_narrration%TYPE;
      l_business_date    transactionlog.business_date%TYPE;
      l_business_time    transactionlog.business_time%TYPE;
      l_timestamp          TIMESTAMP;
      exp_reject_record    EXCEPTION;
   BEGIN
      p_resp_msg_out := 'OK';
      l_business_date:=TO_CHAR (SYSDATE, 'yyyymmdd');
      l_business_time:=TO_CHAR (SYSDATE, 'hh24miss');

      IF p_bal_impctflag_in NOT IN ('B', 'L', 'A')
      THEN
         p_resp_msg_out := 'Transaction rejected for Invalid adjustment type';
         RETURN;
      END IF;

      IF p_txnamt_in = 0 THEN
         p_resp_msg_out := 'Transaction rejected for txn amount is zero';
         RETURN;
      ELSE
         l_delivery_channel := '05';
        IF p_bal_impctflag_in='A' THEN
             l_txn_type := '0';
        ELSE
             l_txn_type := '1';
        END IF;
      END IF;

      BEGIN
        SELECT csr_reasondesc
          INTO l_reasondesc
          FROM cms_spprt_reasons
         WHERE csr_inst_code = p_instcode_in
               AND csr_spprt_key = 'MANADJDRCR'
              AND csr_spprt_rsncode = p_rsn_code_in;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            p_resp_msg_out := 'Inavlid Reason code ';
            RETURN;
         WHEN OTHERS THEN
            p_resp_msg_out :='Error while selecting reason code '|| SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO l_acct_bal, l_ledger_bal, l_acct_type
           FROM cms_acct_mast
          WHERE cam_inst_code = p_instcode_in AND cam_acct_no = p_acctno_in
         FOR UPDATE;
      EXCEPTION
         WHEN OTHERS THEN
            p_resp_msg_out := 'Error while selecting acct dtls-' || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      IF l_acct_bal=0 OR l_ledger_bal=0 THEN
          RETURN;
      END IF;

      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0') INTO l_auth_id FROM DUAL;
      EXCEPTION
         WHEN OTHERS THEN
            p_resp_msg_out :='Error while generating authid-' || SUBSTR (SQLERRM, 1, 100);
            RETURN;
      END;

      l_timestamp := SYSTIMESTAMP;

      IF TRIM (p_txnnarration_in) IS NOT NULL THEN
         l_narration := p_txnnarration_in || '/';
      END IF;

      IF TRIM (l_auth_id) IS NOT NULL THEN
         l_narration :=
               l_narration
            || l_auth_id
            || '/'
            || p_acctno_in
            || '/'
            || l_business_date;
      END IF;

      IF p_txntype_in = 'CR' THEN
         l_txn_code := '20';
         l_upd_amt := l_ledger_bal + case when p_bal_impctflag_in='A' THEN 0 else p_txnamt_in end;
         l_upd_acct_bal := l_acct_bal + case when p_bal_impctflag_in='L' THEN 0 else p_txnamt_in end;

         BEGIN
            UPDATE cms_acct_mast
               SET cam_acct_bal = cam_acct_bal + decode(p_bal_impctflag_in,'L',0, p_txnamt_in),
                   cam_ledger_bal = cam_ledger_bal + decode(p_bal_impctflag_in,'A',0, p_txnamt_in)
             WHERE cam_inst_code = p_instcode_in
                   AND cam_acct_no = p_acctno_in;
         EXCEPTION
            WHEN OTHERS THEN
               p_resp_msg_out :='Error occurred while updating acct mast for CR-'|| SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;
      ELSIF p_txntype_in = 'DR' THEN
         l_txn_code := '19';
         l_upd_amt := l_ledger_bal - case when p_bal_impctflag_in='A' THEN 0 else p_txnamt_in end;
         l_upd_acct_bal := l_acct_bal - case when p_bal_impctflag_in='L' THEN 0 else p_txnamt_in end;

         BEGIN
            UPDATE cms_acct_mast
               SET cam_acct_bal = cam_acct_bal - decode(p_bal_impctflag_in,'L',0, p_txnamt_in),
                   cam_ledger_bal = cam_ledger_bal - decode(p_bal_impctflag_in,'A',0, p_txnamt_in)
             WHERE cam_inst_code = p_instcode_in
                   AND cam_acct_no = p_acctno_in;
         EXCEPTION
            WHEN OTHERS THEN
               p_resp_msg_out :='Error occurred while updating acct mast for DR-'|| SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      ELSIF NVL (p_txntype_in, 'NA') NOT IN ('DR', 'CR') THEN
         p_resp_msg_out := 'invalid debit/credit flag ';
         RETURN;
      END IF;

     IF p_bal_impctflag_in<>'A' THEN
      BEGIN
         INSERT INTO cms_statements_log (csl_pan_no,
                                         csl_opening_bal,
                                         csl_trans_amount,
                                         csl_trans_type,
                                         csl_trans_date,
                                         csl_closing_balance,
                                         csl_trans_narrration,
                                         csl_inst_code,
                                         csl_pan_no_encr,
                                         csl_rrn,
                                         csl_business_date,
                                         csl_business_time,
                                         csl_delivery_channel,
                                         csl_txn_code,
                                         csl_auth_id,
                                         csl_ins_date,
                                         csl_ins_user,
                                         csl_acct_no,
                                         csl_panno_last4digit,
                                         csl_acct_type,
                                         csl_time_stamp,
                                         csl_prod_code,
                                         csl_card_type)
              VALUES (p_cardno_in,
                      l_ledger_bal,
                      p_txnamt_in,
                      p_txntype_in,
                      TO_DATE (l_business_date, 'yyyymmdd'),
                      l_upd_amt,
                      l_narration,
                      p_instcode_in,
                      p_cardno_encr_in,
                      p_rrn_in,
                      l_business_date,
                      l_business_time,
                      l_delivery_channel,
                      NVL(p_txncode_in,l_txn_code),
                      l_auth_id,
                      SYSDATE,
                      1,
                      p_acctno_in,
                      SUBSTR (fn_dmaps_main (p_cardno_encr_in), -4),
                      l_acct_type,
                      l_timestamp,
                      p_prodcode_in,
                      p_cardtype_in);
      EXCEPTION
         WHEN OTHERS THEN
            p_resp_msg_out :='Error while inserting into statement log for DR-'|| SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;
     END IF;

      BEGIN
         INSERT INTO transactionlog (msgtype,
                                     rrn,
                                     delivery_channel,
                                     date_time,
                                     txn_code,
                                     txn_type,
                                     txn_mode,
                                     txn_status,
                                     response_code,
                                     business_date,
                                     business_time,
                                     customer_card_no,
                                     instcode,
                                     customer_card_no_encr,
                                     customer_acct_no,
                                     error_msg,
                                     cardstatus,
                                     amount,
                                     bank_code,
                                     total_amount,
                                     currencycode,
                                     auth_id,
                                     trans_desc,
                                     gl_upd_flag,
                                     acct_balance,
                                     ledger_balance,
                                     response_id,
                                     add_ins_date,
                                     add_ins_user,
                                     productid,
                                     categoryid,
                                     acct_type,
                                     time_stamp,
                                     cr_dr_flag,
                                     reason_code,
                                     reason,
                                     remark)
              VALUES (
                        '0200',
                        p_rrn_in,
                        l_delivery_channel,
                        SYSDATE,
                        NVL(p_txncode_in,l_txn_code),
                        l_txn_type,
                        '0',
                        'C',
                        '00',
                        l_business_date,
                        l_business_time,
                        p_cardno_in,
                        p_instcode_in,
                        p_cardno_encr_in,
                        p_acctno_in,
                        p_resp_msg_out,
                        p_cardstat_in,
                        TRIM (TO_CHAR (p_txnamt_in, '99999999999999990.99')),
                        p_instcode_in,
                        TRIM (TO_CHAR (p_txnamt_in, '99999999999999990.99')),
                        '840',
                        l_auth_id,
                        SUBSTR (l_narration, 1, 50),
                        'N',
                        TRIM (
                           TO_CHAR (l_upd_acct_bal, '99999999999999990.99')),
                        TRIM (TO_CHAR (l_upd_amt, '99999999999999990.99')),
                        '1',
                        SYSDATE,
                        1,
                        p_prodcode_in,
                        p_cardtype_in,
                        l_acct_type,
                        l_timestamp,
                        DECODE (p_bal_impctflag_in, 'A', 'NA', p_txntype_in),
                        p_rsn_code_in,
                        l_reasondesc,
                        p_remark_in);
      EXCEPTION
         WHEN OTHERS THEN
            p_resp_msg_out :='Exception while inserting to transaction log-'|| SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                              ctd_txn_code,
                                              ctd_txn_type,
                                              ctd_txn_mode,
                                              ctd_business_date,
                                              ctd_business_time,
                                              ctd_customer_card_no,
                                              ctd_txn_curr,
                                              ctd_process_flag,
                                              ctd_process_msg,
                                              ctd_rrn,
                                              ctd_inst_code,
                                              ctd_ins_date,
                                              ctd_customer_card_no_encr,
                                              ctd_msg_type,
                                              ctd_cust_acct_number,
                                              ctd_actual_amount,
                                              ctd_txn_amount)
              VALUES (l_delivery_channel,
                      NVL(p_txncode_in,l_txn_code),
                      l_txn_type,
                      '0',
                      l_business_date,
                      l_business_time,
                      p_cardno_in,
                      '840',
                      'Y',
                      p_resp_msg_out,
                      p_rrn_in,
                      p_instcode_in,
                      SYSDATE,
                      p_cardno_encr_in,
                      '0200',
                      p_acctno_in,
                      p_txnamt_in,
                      p_txnamt_in);
      EXCEPTION
         WHEN OTHERS THEN
            p_resp_msg_out :='Error while inserting data into transaction log  dtl'|| SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      IF p_batchid_in IS NOT NULL THEN
        BEGIN
           INSERT INTO cms_bal_adj_batch (cbb_batch_id, cbb_pan_code, cbb_pan_code_encr, cbb_txn_amt,
                                          cbb_forse_post, cbb_reason_code, cbb_txn_desc, cbb_before_ledg_bal,
                                          cbb_after_ledg_bal, cbb_process_flag, cbb_process_msg, cbb_ins_user, cbb_ins_date)
                VALUES (p_batchid_in, p_cardno_in, p_cardno_encr_in, p_txnamt_in,
                        'Yes', p_rsn_code_in, l_narration, l_ledger_bal, l_upd_amt,
                        'S', 'Success', 1, SYSDATE);
        EXCEPTION
           WHEN OTHERS THEN
              p_resp_msg_out :='Error while inserting bal adj batch process Detail '|| SUBSTR (SQLERRM, 1, 200);
              RETURN;
        END;
       END IF;
   EXCEPTION
      WHEN OTHERS THEN
         p_resp_msg_out := 'Main Error  - ' || SUBSTR (SQLERRM, 1, 250);
   END acct_bal_adjustment;

  PROCEDURE get_AutoReward_filelist (p_directory_in IN VARCHAR2)
  AS
      LANGUAGE JAVA
      NAME 'AutoRewardFileList.getList( java.lang.String )';

    PROCEDURE load_reward_file (p_directory_in   IN     VARCHAR2,
                                p_filename_in    IN     VARCHAR2,
                                p_batch_id_in    IN     VARCHAR2,
                                p_resp_msg_out      OUT VARCHAR2)
    AS
       l_file_handle     UTL_FILE.file_type;
       l_filebuffer      VARCHAR2 (32767);
       l_indicator        VARCHAR2(1);
       l_recno            NUMBER default 0;
       l_errmsg          VARCHAR2(500);
       exp_rej_rec      EXCEPTION;
       l_acct_no         cms_acct_batch_adjustment.cab_acct_no%TYPE;
       l_txn_type        cms_acct_batch_adjustment.cab_trans_type%TYPE;
       l_txn_amt         cms_acct_batch_adjustment.cab_trans_amount%TYPE;
       l_txn_narration   cms_acct_batch_adjustment.cab_trans_narration%TYPE;
       l_reason_code     cms_acct_batch_adjustment.cab_reason_code%TYPE;
       l_txn_remark      cms_acct_batch_adjustment.cab_remark%TYPE;
    BEGIN
       p_resp_msg_out := 'OK';

       IF UTL_FILE.is_open (l_file_handle) THEN
          UTL_FILE.fclose (l_file_handle);
       END IF;

       BEGIN
          l_file_handle :=UTL_FILE.fopen (p_directory_in, p_filename_in, 'R', 32767);
       EXCEPTION
          WHEN OTHERS THEN
             p_resp_msg_out :='Error occured during file open-' || SUBSTR (SQLERRM, 1, 200);
             RETURN;
       END;

       LOOP
          l_errmsg:='OK';
          l_recno:=l_recno+1;
          BEGIN
             UTL_FILE.get_line (l_file_handle, l_filebuffer);
             l_acct_no :=TRIM (SUBSTR (l_filebuffer,1, INSTR (l_filebuffer, ',', 1, 1) - 1));

             l_txn_type :=TRIM (SUBSTR (l_filebuffer, INSTR (l_filebuffer, ',', 1) + 1, (INSTR (l_filebuffer,',',1,2)- 1)- INSTR (l_filebuffer, ',', 1)));

             l_txn_amt :=TRIM (SUBSTR (l_filebuffer, INSTR (l_filebuffer,',', 1, 2) + 1, (INSTR (l_filebuffer, ',', 1, 3) - 1) - INSTR (l_filebuffer, ',', 1, 2)));

             l_txn_narration :=TRIM (SUBSTR (l_filebuffer, INSTR (l_filebuffer, ',', 1, 3) + 1, (INSTR (l_filebuffer, ',', 1, 4) - 1) - INSTR (l_filebuffer, ',', 1, 3)));

             l_reason_code :=TRIM (SUBSTR (l_filebuffer, INSTR (l_filebuffer, ',', 1, 4) + 1, (INSTR (l_filebuffer, ',', 1, 5) - 1) - INSTR (l_filebuffer, ',', 1, 4)));

             l_indicator :=TRIM (SUBSTR (l_filebuffer, INSTR (l_filebuffer, ',', 1,5) + 1, (INSTR (l_filebuffer, ',', 1, 6) - 1) - INSTR (l_filebuffer, ',', 1, 5)));

             IF l_indicator is not null and l_indicator NOT IN ('A','L','B') THEN
                 l_errmsg:='invalid balance impact flag';
                 RAISE exp_rej_rec;
             END IF;

             l_txn_remark := REPLACE (TRIM (SUBSTR (l_filebuffer, INSTR (l_filebuffer, ',', 1, 6) + 1)), CHR (13), '');

             INSERT INTO cms_acct_batch_adjustment (cab_batch_id, cab_acct_no, cab_trans_type, cab_trans_amount,
                                                    cab_trans_narration, cab_reason_code, cab_balimpact_flag, cab_remark)
                  VALUES (p_batch_id_in, l_acct_no, l_txn_type, l_txn_amt,
                          l_txn_narration, l_reason_code, l_indicator, l_txn_remark);
          EXCEPTION
             WHEN exp_rej_rec THEN
                INSERT INTO vms_rewardfile_upd_errlog (vru_batch_id,vru_rec_no,
                                                       vru_rec,vru_errmsg,vru_date)
                     VALUES (p_batch_id_in,l_recno,
                             l_filebuffer,l_errmsg,SYSDATE);
             WHEN NO_DATA_FOUND THEN
                EXIT;
             WHEN OTHERS THEN
                l_errmsg:='Error wile uploading record-'||SUBSTR (SQLERRM, 1, 200);
                INSERT INTO vms_rewardfile_upd_errlog (vru_batch_id,vru_rec_no,
                                                       vru_rec,vru_errmsg,vru_date)
                     VALUES (p_batch_id_in,l_recno,
                             l_filebuffer,l_errmsg,SYSDATE);
          END;
       END LOOP;

       UTL_FILE.fclose (l_file_handle);
       COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
         p_resp_msg_out :='Main excp from load_reward_file-' || SUBSTR (SQLERRM, 1, 200);
    END load_reward_file;

	PROCEDURE sweep_acct_job_yearend
	IS
	   l_rrn           transactionlog.rrn%TYPE;
	   l_txn_code      transactionlog.txn_code%TYPE;
	   l_rrn_cnt       NUMBER := 0;
	   l_errmsg        VARCHAR2 (1000);
	   l_rsncode       NUMBER;
	   l_cardstat      cms_appl_pan.cap_card_stat%TYPE := '9';
	   l_instcode      cms_appl_pan.cap_inst_code%TYPE := 1;
	   l_pan_code      cms_appl_pan.cap_pan_code%TYPE;
	   l_pan_encr      cms_appl_pan.cap_pan_code_encr%TYPE;
	   l_card_stat     cms_appl_pan.cap_card_stat%TYPE;
	   l_prod_code     cms_appl_pan.cap_prod_code%TYPE;
	   l_card_type     cms_appl_pan.cap_card_type%TYPE;
	   l_sweep_flag    cms_prod_cattype.cpc_sweep_flag%TYPE;
	   l_active_flag   NUMBER;
	   l_remark        VARCHAR2 (300);
	   excp_rej_rec    EXCEPTION;
	   l_year		   NUMBER;
	   l_monthday	   NUMBER;
	   l_acct_bal	   cms_acct_mast.cam_acct_bal%TYPE;
	   l_ledger_bal    cms_acct_mast.cam_ledger_bal%TYPE;
	   l_cr_amt		   cms_statements_log.csl_trans_amount%TYPE;
	   l_tran_amt	   cms_acct_mast.cam_ledger_bal%TYPE;
       l_date          VARCHAR2(20);
       l_param_value   cms_inst_param.cip_param_value%type;  --added for VMS_6608
       l_toggle_value  cms_inst_param.cip_param_value%type;  --added for VMS_6608
	BEGIN

		  BEGIN

			SELECT TO_CHAR(SYSDATE,'YYYY'),TO_CHAR(SYSDATE,'MMDD')
			INTO   l_year,l_monthday
			FROM DUAL;

			IF l_monthday = '1231' THEN
				l_year := l_year + 1;
			END IF;

		  EXCEPTION
			WHEN OTHERS THEN
				RETURN;
		  END;


		  FOR l_idx
			 IN (SELECT DISTINCT 
					a.cap_acct_no acctno,
					b.cam_acct_bal acctbal,
					b.cam_ledger_bal ledgbal
				  FROM cms_appl_pan a,
					cms_acct_mast b,
					cms_prod_cattype c
				  WHERE a.cap_inst_code   = c.cpc_inst_code
				  AND a.cap_prod_code     = c.cpc_prod_code
				  AND a.cap_card_type     = c.cpc_card_type
				  AND c.cpc_sweep_flag    = 'Y'
				  AND a.cap_card_stat     <> l_cardstat
				  AND b.cam_inst_code     = a.cap_inst_code
				  AND b.cam_acct_no       = a.cap_acct_no
				  AND b.cam_acct_bal     > 0
				  AND b.cam_acct_bal      = b.cam_ledger_bal
				  --AND a.cap_expry_date   <= SYSDATE - NVL (c.cpc_addl_sweep_period, 0)
				  AND NVL(C.CPC_YEAREND_SWEEP,'N') = 'Y'
				  AND NOT EXISTS (SELECT vli_pan_code                                         -- VMS-1081 (Enhance Sweep Job for Amex products)
								   FROM vms_line_item_dtl d,
									vms_order_details e,
									vms_sweep_state_exclusion f
								   WHERE d.vli_pan_code        = a.cap_pan_code
								   AND d.vli_order_id          = e.vod_order_id
								   AND d.vli_partner_id        = e.vod_partner_id
								   AND f.vss_bank_id           = c.cpc_issubank_id
								   AND f.vss_state_switch_code = fn_dmaps_main(e.vod_state)
								   AND f.vss_switch_cntry_code = fn_dmaps_main(e.vod_country)
								   AND e.vod_order_type        = 'IND'
								   )
								   )
		  LOOP
			 BEGIN
				l_errmsg := 'OK';

				BEGIN
				   SELECT *
					 INTO l_pan_code, l_pan_encr, l_card_stat,
						  l_prod_code, l_card_type, l_sweep_flag, l_active_flag
					 FROM (  SELECT a.cap_pan_code cardno, a.cap_pan_code_encr cardno_encr, a.cap_card_stat cardstat,
									a.cap_prod_code prodcode, a.cap_card_type cardtype, NVL (b.cpc_sweep_flag, 'N') sweepflag,
									SUM (CASE WHEN a.cap_active_date IS NULL THEN 0 ELSE 1 END)
									OVER (PARTITION BY a.cap_acct_no) active_flag
							   FROM cms_appl_pan a, cms_prod_cattype b
							  WHERE     a.cap_inst_code = l_instcode
									AND a.cap_acct_no = l_idx.acctno
									AND b.cpc_inst_code = a.cap_inst_code
									AND b.cpc_prod_code = a.cap_prod_code
									AND b.cpc_card_type = a.cap_card_type
						   ORDER BY a.cap_pangen_date DESC)
					WHERE ROWNUM = 1;
				EXCEPTION
				   WHEN OTHERS
				   THEN
					  l_errmsg :=
						 'Error while selecting activation dtls-'
						 || SUBSTR (SQLERRM, 1, 200);
					  RAISE excp_rej_rec;
				END;

				IF l_sweep_flag = 'N'
				THEN
				   CONTINUE;
				END IF;

				l_rrn_cnt := l_rrn_cnt + 1;

				BEGIN
				   SELECT TO_CHAR (SYSDATE, 'ddmmhh24miss')
						  || LPAD (l_rrn_cnt, 5, 0)
					 INTO l_rrn
					 FROM DUAL;
				EXCEPTION
				   WHEN OTHERS
				   THEN
					  l_errmsg :=
						 'Error while selecting txn dtls-'
						 || SUBSTR (SQLERRM, 1, 200);
					  RAISE excp_rej_rec;
				END;

					l_rsncode := 296;
					l_remark := 'Calendar Year sweep - Debit/Incomm';

				IF l_active_flag = 0
				THEN
				   l_txn_code := '60';
				ELSE
				   l_txn_code := '61';
				END IF;
                
--Sn added for VMS_6608	

            BEGIN
                SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
                INTO l_toggle_value
                FROM vmscms.cms_inst_param
                    WHERE cip_inst_code = 1
                    AND cip_param_key = 'VMS_6608_TOGGLE';
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                     l_toggle_value := 'Y';
            END;

    IF l_toggle_value = 'Y' THEN

            BEGIN 
                select CIP_PARAM_VALUE 
                into l_param_value
                from VMSCMS.CMS_INST_PARAM
                where CIP_INST_CODE = 1
                and CIP_PARAM_KEY = 'GEISINGER_PRODUCT';


                
             IF l_param_value = l_prod_code||':'||to_char(l_card_type) THEN
                   
                       l_txn_code := '83';

             END IF;
                 EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    null; 
            END;
    END IF;
--En added for VMS_6608	




				BEGIN
					 SELECT cam_acct_bal, cam_ledger_bal
					   INTO l_acct_bal, l_ledger_bal
					   FROM cms_acct_mast
					  WHERE cam_inst_code = l_instcode AND cam_acct_no = l_idx.acctno
					 FOR UPDATE;
				  EXCEPTION
					 WHEN OTHERS THEN
						l_errmsg := 'Error while selecting acct dtls-' || SUBSTR (SQLERRM, 1, 200);
						RAISE excp_rej_rec;
				  END;

				  IF l_acct_bal <> l_ledger_bal THEN
					CONTINUE;
				END IF;

				  BEGIN
					l_date := '0101'||l_year||' 00:00:00';

					SELECT
						SUM(CSL_TRANS_AMOUNT)
					INTO l_cr_amt
					FROM
						CMS_STATEMENTS_LOG
					WHERE
					CSL_INST_CODE = l_instcode
					AND CSL_ACCT_NO = l_idx.acctno 
					AND CSL_INS_DATE > TO_DATE(L_DATE, 'DDMMYYYY HH24:MI:SS')
					AND CSL_TRANS_TYPE = 'CR'; 
                    EXCEPTION
				WHEN OTHERS THEN
					l_errmsg := 'Error while selecting CR AMOUNT-' || SUBSTR (SQLERRM, 1, 200);
					RAISE excp_rej_rec;
			  END;

					l_tran_amt := ROUND (l_idx.ledgbal, 2) - nvl(l_cr_amt,0); 

				IF l_tran_amt <= 0 THEN
					CONTINUE;
				END IF;


				BEGIN
				   vmsautojobs.acct_bal_adjustment (l_instcode,
													l_rrn,
													l_pan_code,
													l_pan_encr,
													l_idx.acctno,
													l_prod_code,
													l_card_type,
													l_card_stat,
													l_tran_amt,
													'DR',
													l_rsncode,
													l_remark,
													l_remark,
													l_errmsg,
													'B',
													NULL,
													l_txn_code);

				   IF l_errmsg <> 'OK'
				   THEN
					  RAISE excp_rej_rec;
				   END IF;
				EXCEPTION
				   WHEN excp_rej_rec
				   THEN
					  RAISE;
				   WHEN OTHERS
				   THEN
					  l_errmsg :=
						 'Error while calling ACCT_BAL_ADJUSTMENT-'
						 || SUBSTR (SQLERRM, 1, 200);
					  RAISE excp_rej_rec;
				END;
			 EXCEPTION
				WHEN excp_rej_rec
				THEN
				   ROLLBACK;

				   INSERT INTO vms_sweepjob_fail_dtl
						VALUES (l_pan_code,
								l_idx.acctno,
								l_errmsg,
								SYSDATE);
				WHEN OTHERS
				THEN
				   ROLLBACK;
				   l_errmsg :=
					  'Error while processing-' || SUBSTR (SQLERRM, 1, 200);

				   INSERT INTO vms_sweepjob_fail_dtl
						VALUES (l_pan_code,
								l_idx.acctno,
								l_errmsg,
								SYSDATE);
			 END;

			 COMMIT;
		  END LOOP;
	END sweep_acct_job_yearend;

END vmsautojobs;
/
show error