CREATE OR REPLACE PROCEDURE vmscms.sp_renew_pan_debit (
   instcode   IN       NUMBER,
   remark     IN       VARCHAR2,
   indate     IN       DATE,
   binlist    IN       VARCHAR2,
   frombran   IN       VARCHAR2,
   tobran     IN       VARCHAR2,
   lupduser   IN       NUMBER,
   errmsg     OUT      VARCHAR2
)
AS
   v_expiryparam         NUMBER;
   v_renew_param         NUMBER;
   renew_cnt             NUMBER                                    := 0;
   v_rencaf_fname        cms_rencaf_header.crh_rencaf_fname%TYPE;
   v_pan                 cms_appl_pan.cap_pan_code%TYPE;
   v_errmsg              VARCHAR2 (500);
   v_date1               DATE;
   v_date2               DATE;
   v_date3               DATE;
   v_binlist             VARCHAR2 (500);
   v_from_bran           VARCHAR2 (50);
   v_to_bran             VARCHAR2 (50);
   v_binflag             VARCHAR2 (1);
   v_branflag            VARCHAR2 (1);
   v_number_of_bins      NUMBER;
   v_prod_code           cms_appl_pan.cap_prod_code%TYPE;
   start_point           NUMBER;
   acctcnt               NUMBER;
   dum                   NUMBER;
   v_filter              VARCHAR2 (1);
   v_filter_count        NUMBER;
   v_hsm_mode            VARCHAR2 (1);
   v_emboss_flag         VARCHAR2 (1);
   noaccountsexception   EXCEPTION;
   rencafexception       EXCEPTION;
   filterpan             EXCEPTION;
   inactivecards         EXCEPTION;
   record_exist          NUMBER;
   v_cardstat            CHAR (1);

   CURSOR c1 (p_date1 DATE, p_date2 DATE)
   IS
      SELECT cap_pan_code, cap_mbr_numb, cap_prod_catg, cap_acct_no,
             cap_disp_name, cap_expry_date, cap_card_stat, cap_prod_code,
             cap_appl_bran, cap_pan_code_encr
        FROM cms_appl_pan, cms_bran_mast
       WHERE cap_expry_date >= p_date1
         AND cap_expry_date <= p_date2
         AND cap_prod_catg = 'D'
         AND cbm_inst_code = instcode
         AND cbm_bran_code = cap_appl_bran;
BEGIN
   errmsg := 'OK';

   BEGIN
      SELECT cip_param_value
        INTO v_hsm_mode
        FROM cms_inst_param
       WHERE cip_param_key = 'HSM_MODE';

      IF v_hsm_mode = 'Y'
      THEN
         v_emboss_flag := 'Y';
      ELSE
         v_emboss_flag := 'N';
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_hsm_mode := 'N';
         v_emboss_flag := 'N';
   END;

   SELECT TO_NUMBER (cip_param_value)
     INTO v_renew_param
     FROM cms_inst_param
    WHERE cip_param_key = 'RENEWCAF';

   v_date1 :=
      TO_DATE (TO_CHAR (indate, 'yyyy-mm-dd') || ' 00:00:00',
               'yyyy-mm-dd hh24:mi:ss'
              );
   v_date2 :=
      LAST_DAY (TO_DATE (TO_CHAR (indate, 'yyyy-mm-dd') || ' 23:59:59',
                         'yyyy-mm-dd hh24:mi:ss'
                        )
               );
   v_from_bran := frombran;
   v_to_bran := tobran;
   v_binlist := binlist;
   v_binflag := 'N';

   IF (v_binlist != 'ALL')
   THEN
      v_number_of_bins := LENGTH (v_binlist) / 6;
   END IF;

   FOR x IN c1 (v_date1, v_date2)
   LOOP
      BEGIN
         BEGIN
            SELECT cpm_validity_period
              INTO v_expiryparam
              FROM cms_prod_mast
             WHERE cpm_inst_code = instcode
                   AND cpm_prod_code = x.cap_prod_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_expiryparam := 120;
         END;

         v_date3 := LAST_DAY (ADD_MONTHS (indate, v_expiryparam));
         v_binflag := 'N';
         v_branflag := 'N';
         dum := 0;

         IF (v_binlist = 'ALL')
         THEN
            v_binflag := 'Y';
         ELSE
            BEGIN
               start_point := 1;

               FOR i IN 1 .. v_number_of_bins
               LOOP
                  IF ((TO_NUMBER (SUBSTR (v_binlist, start_point, 6))) =
                         (TO_NUMBER
                                  (SUBSTR (fn_dmaps_main (x.cap_pan_code_encr),
                                           1,
                                           6
                                          )
                                  )
                         )
                     )
                  THEN
                     v_binflag := 'Y';
                     EXIT;
                  END IF;

                  start_point := start_point + 6;
               END LOOP;
            END;
         END IF;

         IF (    NVL (LENGTH (TRIM (v_from_bran)), 0) = 0
             AND NVL (LENGTH (TRIM (v_to_bran)), 0) = 0
            )
         THEN
            v_branflag := 'Y';
         END IF;

         DBMS_OUTPUT.put_line ('Before cond');

         IF (    NVL (LENGTH (TRIM (v_from_bran)), 0) != 0
             AND NVL (LENGTH (TRIM (v_to_bran)), 0) = 0
            )
         THEN
            DBMS_OUTPUT.put_line ('After cond');

            BEGIN
               SELECT COUNT (1)
                 INTO dum
                 FROM cms_branch_region
                WHERE cbr_inst_code = instcode
                  AND cbr_region_id = v_from_bran
                  AND cbr_bran_code = x.cap_appl_bran;

               IF (dum = 0)
               THEN
                  v_branflag := 'N';
               ELSE
                  v_branflag := 'Y';
               END IF;
            END;
         END IF;

         IF (    NVL (LENGTH (TRIM (v_from_bran)), 0) != 0
             AND NVL (LENGTH (TRIM (v_to_bran)), 0) != 0
            )
         THEN
            IF (    (TO_NUMBER (x.cap_appl_bran) >= TO_NUMBER (v_from_bran))
                AND (TO_NUMBER (x.cap_appl_bran) <= TO_NUMBER (v_to_bran))
               )
            THEN
               v_branflag := 'Y';
            END IF;
         END IF;

         IF (v_branflag = 'Y' AND v_binflag = 'Y')
         THEN
            IF (x.cap_card_stat != '1')
            THEN
               RAISE inactivecards;
            END IF;

            IF renew_cnt = 0
            THEN
               DBMS_OUTPUT.put_line ('SP_CREATE_RENEWCAFFNAME');
               sp_create_rencaffname (instcode,
                                      lupduser,
                                      v_rencaf_fname,
                                      errmsg
                                     );

               IF errmsg != 'OK'
               THEN
                  errmsg := 'Error while creating filename -- ' || errmsg;
                  RAISE rencafexception;
               END IF;
            END IF;

            BEGIN
               SELECT COUNT (1)
                 INTO v_filter_count
                 FROM cms_ren_pan_temp
                WHERE crp_pan_code = x.cap_pan_code;

               IF v_filter_count > 0
               THEN
                  RAISE filterpan;
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
            END;

            BEGIN
               SELECT DISTINCT cpa_pan_code
                          INTO v_pan
                          FROM cms_pan_acct
                         WHERE cpa_inst_code = instcode
                           AND cpa_pan_code = x.cap_pan_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  RAISE noaccountsexception;
            END;

            IF (v_hsm_mode = 'N')
            THEN
               UPDATE cms_appl_pan
                  SET cap_expry_date = v_date3,
                      cap_lupd_date = SYSDATE
                WHERE cap_pan_code = x.cap_pan_code
                  AND cap_mbr_numb = x.cap_mbr_numb;
            ELSE
               UPDATE cms_appl_pan
                  SET cap_expry_date = v_date3,
                      cap_lupd_date = SYSDATE,
                      cap_embos_flag = 'Y'
                WHERE cap_pan_code = x.cap_pan_code
                  AND cap_mbr_numb = x.cap_mbr_numb;
            END IF;

            INSERT INTO cms_ren_temp
                 VALUES (x.cap_pan_code, x.cap_appl_bran, x.cap_card_stat,
                         SUBSTR (fn_dmaps_main (x.cap_pan_code), 1, 6), 'Y',
                         TO_CHAR (v_date1, 'MON-YYYY'), SYSDATE, instcode,
                         lupduser, SYSDATE, lupduser, remark,
                         x.cap_pan_code_encr);

            INSERT INTO cms_pan_spprt
                        (cps_inst_code, cps_pan_code, cps_mbr_numb,
                         cps_prod_catg, cps_spprt_key, cps_spprt_rsncode,
                         cps_func_remark, cps_ins_user, cps_lupd_user,
                         cps_pan_code_encr
                        )
                 VALUES (instcode, x.cap_pan_code, x.cap_mbr_numb,
                         x.cap_prod_catg, 'RENEW', 1,
                         remark, lupduser, lupduser,
                         x.cap_pan_code_encr
                        );

            record_exist := 1;

            BEGIN
               SELECT cci_crd_stat
                 INTO v_cardstat
                 FROM cms_caf_info
                WHERE cci_inst_code = instcode
                  AND cci_pan_code = x.cap_pan_code
                  AND cci_mbr_numb = x.cap_mbr_numb
                  AND cci_file_gen = 'N';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  record_exist := 0;
            END;

            DELETE FROM cms_caf_info
                  WHERE cci_inst_code = instcode
                    AND cci_pan_code = x.cap_pan_code
                    AND cci_mbr_numb = x.cap_mbr_numb;

            sp_caf_rfrsh (instcode,
                          x.cap_pan_code,
                          NULL,
                          SYSDATE,
                          'C',
                          NULL,
                          'RENEW',
                          lupduser,
                          x.cap_pan_code_encr,
                          errmsg
                         );

            IF errmsg != 'OK'
            THEN
               errmsg := 'From Caf Refresh -- ' || errmsg;
            ELSE
               renew_cnt := renew_cnt + 1;

               IF renew_cnt = v_renew_param
               THEN
                  renew_cnt := 0;
               END IF;

               IF record_exist = 1
               THEN
                  UPDATE cms_caf_info
                     SET cci_crd_stat = v_cardstat,
                         cci_file_name = v_rencaf_fname
                   WHERE cci_inst_code = instcode
                     AND cci_pan_code = x.cap_pan_code
                     AND cci_mbr_numb = x.cap_mbr_numb;
               ELSE
                  UPDATE cms_caf_info
                     SET cci_file_name = v_rencaf_fname
                   WHERE cci_inst_code = instcode
                     AND cci_pan_code = x.cap_pan_code
                     AND cci_mbr_numb = x.cap_mbr_numb;
               END IF;
            END IF;
         END IF;
      EXCEPTION
         WHEN inactivecards
         THEN
            v_errmsg := 'The PAN is not in active state ...';
         WHEN filterpan
         THEN
            v_errmsg := 'The PAN is filtered for the process ...';
         WHEN noaccountsexception
         THEN
            v_errmsg := 'Account not Present in Masters';
         WHEN rencafexception
         THEN
            v_errmsg := 'Problem in creating rencaf filename';
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg := 'EXCP 1.2 ' || SQLERRM;
      END;
   END LOOP;

   COMMIT;
EXCEPTION
   WHEN OTHERS
   THEN
      errmsg := 'Main Excp -- ' || v_errmsg || SQLERRM;
      ROLLBACK;
END;
/

SHOW ERROR