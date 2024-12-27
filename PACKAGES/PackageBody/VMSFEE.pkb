CREATE OR REPLACE PACKAGE BODY VMSCMS.vmsfee
IS
   PROCEDURE fee_freecnt_check (p_acctno_in                VARCHAR2,
                                p_feecode_in               NUMBER,
                                p_freecnt_freq_in          VARCHAR2,
                                p_confgcnt_in              NUMBER,
                                p_freefreq_change_in       DATE,
                                p_free_txn_out         OUT VARCHAR2,
                                p_resp_out             OUT VARCHAR2)
   IS
      l_last_txndt    DATE;
      l_biweekly_dt   DATE;
      l_resetflag     VARCHAR2 (1);
      l_currcnt       NUMBER;
      excp_reset      EXCEPTION;
   BEGIN
      p_resp_out := 'OK';

      BEGIN
         SELECT DECODE (p_freecnt_freq_in,
                        'D', vfd_daly_cnt,
                        'W', vfd_wkly_cnt,
                        'BW', vfd_biwkly_cnt,
                        'M', vfd_mntly_cnt,
                        'BM', vfd_bimntly_cnt,
                        'Y', vfd_yerly_cnt,
                        0),
                vfd_lupd_date
           INTO l_currcnt, l_last_txndt
           FROM vms_feesumry_dwmy
          WHERE vfd_acct_no = p_acctno_in AND vfd_fee_code = p_feecode_in;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_resetflag := '0';
            RAISE excp_reset;
         WHEN OTHERS
         THEN
            p_resp_out :=
               'Error while selecting freefee_sumry-'
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      IF TRUNC (SYSDATE) > l_last_txndt
      THEN
         IF p_freecnt_freq_in = 'D'
         THEN
            l_currcnt := 0;
         ELSIF p_freecnt_freq_in = 'W'
               AND (TRIM (TO_CHAR (SYSDATE, 'DAY')) = 'SUNDAY'
                    OR SYSDATE > NEXT_DAY (l_last_txndt, 'SUNDAY'))
         THEN
            l_currcnt := 0;
         ELSIF p_freecnt_freq_in = 'BW'
         THEN
            l_biweekly_dt := NEXT_DAY (p_freefreq_change_in, 'SUNDAY') + 7;

            LOOP
               EXIT WHEN l_biweekly_dt > TRUNC (l_last_txndt);
               l_biweekly_dt := l_biweekly_dt + 14;
            END LOOP;

            IF TRUNC (SYSDATE) >= l_biweekly_dt
            THEN
               l_currcnt := 0;
            END IF;
         ELSIF p_freecnt_freq_in = 'M'
               AND (TRIM (TO_CHAR (SYSDATE, 'DD')) = '01'
                    OR TRUNC (SYSDATE, 'MM') > l_last_txndt)
         THEN
            l_currcnt := 0;
         ELSIF p_freecnt_freq_in = 'BM'
         THEN
            IF (TRUNC (SYSDATE, 'MM') > l_last_txndt
                OR TRUNC (SYSDATE, 'MM') + 15 > l_last_txndt)
               AND TRUNC (SYSDATE) > l_last_txndt
            THEN
               l_currcnt := 0;
            END IF;
         ELSIF p_freecnt_freq_in = 'Y'
               AND (TRIM (TO_CHAR (SYSDATE, 'DDMM')) = '0101'
                    OR TRUNC (SYSDATE, 'YY') > l_last_txndt)
         THEN
            l_currcnt := 0;
         END IF;

         IF l_currcnt = 0
         THEN
            l_resetflag := '1';
            RAISE excp_reset;
         END IF;
      END IF;

      IF l_currcnt >= p_confgcnt_in
      THEN
         p_free_txn_out := 'N';
         RETURN;
      ELSE
         l_resetflag := '2';
         RAISE excp_reset;
      END IF;
   EXCEPTION
      WHEN excp_reset
      THEN
         vmsfee.fee_freecnt_reset (p_acctno_in,
                                   p_feecode_in,
                                   p_freecnt_freq_in,
                                   l_resetflag,
                                   p_resp_out);
      WHEN OTHERS
      THEN
         p_resp_out :=
            'Main Excp from fee_freecnt_check-' || SUBSTR (SQLERRM, 1, 200);
         ROLLBACK;
   END;

   PROCEDURE fee_freecnt_reset (p_acctno_in             VARCHAR2,
                                p_feecode_in            NUMBER,
                                p_freecnt_freq_in       VARCHAR2,
                                p_reset_flag_in         VARCHAR2,
                                p_resp_out          OUT VARCHAR2)
   IS
      l_txn_dt   DATE;
   BEGIN
      p_resp_out := 'OK';

      IF p_reset_flag_in = '0'
      THEN
         BEGIN
            INSERT INTO vms_feesumry_dwmy (vfd_acct_no,
                                           vfd_fee_code,
                                           vfd_daly_cnt,
                                           vfd_wkly_cnt,
                                           vfd_biwkly_cnt,
                                           vfd_mntly_cnt,
                                           vfd_bimntly_cnt,
                                           vfd_yerly_cnt,
                                           vfd_lupd_date,
                                           vfd_ins_date)
                 VALUES (p_acctno_in,
                         p_feecode_in,
                         DECODE (p_freecnt_freq_in, 'D', 1, 0),
                         DECODE (p_freecnt_freq_in, 'W', 1, 0),
                         DECODE (p_freecnt_freq_in, 'BW', 1, 0),
                         DECODE (p_freecnt_freq_in, 'M', 1, 0),
                         DECODE (p_freecnt_freq_in, 'BM', 1, 0),
                         DECODE (p_freecnt_freq_in, 'Y', 1, 0),
                         SYSDATE,
                         SYSDATE);
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_out :=
                  'Error While inserting into feesumry_dwmy table-'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      ELSE
         BEGIN
            UPDATE vms_feesumry_dwmy
               SET vfd_daly_cnt =
                      DECODE (
                         p_freecnt_freq_in,
                         'D', DECODE (p_reset_flag_in,
                                      '1', 1,
                                      '2', vfd_daly_cnt + 1,
                                      vfd_daly_cnt),
                         0),
                   vfd_wkly_cnt =
                      DECODE (
                         p_freecnt_freq_in,
                         'W', DECODE (p_reset_flag_in,
                                      '1', 1,
                                      '2', vfd_wkly_cnt + 1,
                                      vfd_wkly_cnt),
                         0),
                   vfd_biwkly_cnt =
                      DECODE (
                         p_freecnt_freq_in,
                         'BW', DECODE (p_reset_flag_in,
                                       '1', 1,
                                       '2', vfd_biwkly_cnt + 1,
                                       vfd_biwkly_cnt),
                         0),
                   vfd_mntly_cnt =
                      DECODE (
                         p_freecnt_freq_in,
                         'M', DECODE (p_reset_flag_in,
                                      '1', 1,
                                      '2', vfd_mntly_cnt + 1,
                                      vfd_mntly_cnt),
                         0),
                   vfd_bimntly_cnt =
                      DECODE (
                         p_freecnt_freq_in,
                         'BM', DECODE (p_reset_flag_in,
                                       '1', 1,
                                       '2', vfd_bimntly_cnt + 1,
                                       vfd_bimntly_cnt),
                         0),
                   vfd_yerly_cnt =
                      DECODE (
                         p_freecnt_freq_in,
                         'Y', DECODE (p_reset_flag_in,
                                      '1', 1,
                                      '2', vfd_yerly_cnt + 1,
                                      vfd_yerly_cnt),
                         0),
                   vfd_lupd_date = SYSDATE
             WHERE vfd_acct_no = p_acctno_in AND vfd_fee_code = p_feecode_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_out :=
                  'Error While updating feesumry_dwmy table-'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_out :=
            'Main Excp from fee_freecnt_reset-' || SUBSTR (SQLERRM, 1, 200);
   END;

   PROCEDURE fee_freecnt_reverse (p_acctno_in        VARCHAR2,
                                  p_feecode_in       VARCHAR2,
                                  p_resp_out     OUT VARCHAR2)
   IS
      l_resp_code   VARCHAR2 (3) := '00';
   BEGIN
      p_resp_out := 'OK';

      IF p_feecode_in IS NOT NULL AND p_acctno_in IS NOT NULL
      THEN
         BEGIN
            UPDATE vms_feesumry_dwmy
               SET vfd_daly_cnt =
                      CASE
                         WHEN vfd_daly_cnt > 0 THEN vfd_daly_cnt - 1
                         ELSE 0
                      END,
                   vfd_wkly_cnt =
                      CASE
                         WHEN vfd_wkly_cnt > 0 THEN vfd_wkly_cnt - 1
                         ELSE 0
                      END,
                   vfd_biwkly_cnt =
                      CASE
                         WHEN vfd_biwkly_cnt > 0 THEN vfd_biwkly_cnt - 1
                         ELSE 0
                      END,
                   vfd_mntly_cnt =
                      CASE
                         WHEN vfd_mntly_cnt > 0 THEN vfd_mntly_cnt - 1
                         ELSE 0
                      END,
                   vfd_bimntly_cnt =
                      CASE
                         WHEN vfd_bimntly_cnt > 0 THEN vfd_bimntly_cnt - 1
                         ELSE 0
                      END,
                   vfd_yerly_cnt =
                      CASE
                         WHEN vfd_yerly_cnt > 0 THEN vfd_yerly_cnt - 1
                         ELSE 0
                      END,
                   vfd_lupd_date = SYSDATE
             WHERE vfd_acct_no = p_acctno_in AND vfd_fee_code = p_feecode_in;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_out :=
                  'Error While updating feesumry_dwmy table-'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_out :=
            'Main Excp from fee_freecnt_reverse-' || SUBSTR (SQLERRM, 1, 200);
   END;
END vmsfee;
/

SHOW ERROR