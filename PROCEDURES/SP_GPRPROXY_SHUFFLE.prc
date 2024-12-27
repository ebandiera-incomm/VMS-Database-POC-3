CREATE OR REPLACE PROCEDURE VMSCMS.sp_gprproxy_shuffle (p_errm OUT VARCHAR2)
IS
   v_errm                   VARCHAR2 (500)                       := 'OK';
   v_cap_pan_code           cms_appl_pan.cap_pan_code%TYPE;
   v_cap_proxy_number       cms_appl_pan.cap_proxy_number%TYPE;
   v_min_cap_pan_code       cms_appl_pan.cap_pan_code%TYPE;
   v_min_cap_proxy_number   cms_appl_pan.cap_proxy_number%TYPE;
   savepoint1               NUMBER (10)                          := 0;
   exp_loop                 EXCEPTION;
   exp_main                 EXCEPTION;
BEGIN
   BEGIN
      SELECT MIN (cap_proxy_number)
        INTO v_min_cap_proxy_number
        FROM cms_cardissuance_status, cms_appl_pan
       WHERE ccs_card_status = '2'
         AND ccs_pan_code = cap_pan_code
         AND cap_startercard_flag = 'Y';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_errm := 'Min proxy number not found';
         RAISE exp_main;
      WHEN OTHERS
      THEN
         p_errm :=
                'while feching min proxy number ' || SUBSTR (SQLERRM, 1, 100);
         RAISE exp_main;
   END;

   FOR i IN (SELECT cap_pan_code, ccs_card_status, cap_startercard_flag,
                    cap_proxy_number
               FROM cms_appl_pan, cms_cardissuance_status
              WHERE ccs_pan_code = cap_pan_code
                AND cap_startercard_flag = 'N'
                AND ccs_card_status = '2')
   LOOP
      BEGIN
         savepoint1 := savepoint1 + 1;
         SAVEPOINT savepoint1;

         BEGIN
            SELECT cap_pan_code, cap_proxy_number
              INTO v_cap_pan_code, v_cap_proxy_number
              FROM cms_appl_pan
             WHERE cap_proxy_number =
                      (SELECT MAX (cap_proxy_number)
                         FROM cms_cardissuance_status, cms_appl_pan
                        WHERE ccs_card_status = '2'
                          AND ccs_pan_code = cap_pan_code
                          AND cap_startercard_flag = 'Y')
               AND cap_startercard_flag = 'Y';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errm := 'Max Proxy not found';
               RAISE exp_loop;
            WHEN OTHERS
            THEN
               v_errm :=
                       'while feching max proxy ' || SUBSTR (SQLERRM, 1, 100);
               RAISE exp_loop;
         END;

         IF     v_min_cap_proxy_number < i.cap_proxy_number
            AND v_cap_proxy_number > i.cap_proxy_number
         THEN
            BEGIN
               -- UPDATE GPR CARD
               UPDATE cms_appl_pan
                  SET cap_proxy_number = v_cap_proxy_number
                WHERE cap_pan_code = i.cap_pan_code;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_errm :=
                       'while updating GPR card ' || SUBSTR (SQLERRM, 1, 100);
                  RAISE exp_loop;
               END IF;
            END;

            BEGIN
               -- UPDATE STARTER CARD
               UPDATE cms_appl_pan
                  SET cap_proxy_number = i.cap_proxy_number
                WHERE cap_pan_code = v_cap_pan_code;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_errm :=
                        'while updating STARTER card '
                     || SUBSTR (SQLERRM, 1, 100);
                  RAISE exp_loop;
               END IF;
            END;

            INSERT INTO drp_prxy_shfl
                 VALUES (i.cap_pan_code, i.cap_proxy_number,
                         v_cap_proxy_number, v_cap_pan_code,
                         v_cap_proxy_number, i.cap_proxy_number, 'SUCCESS',
                         'Y');

         ELSE

         v_errm := 'GPR PROXY NUMBER NOT IN RANGE ';

         INSERT INTO drp_prxy_shfl
                 VALUES (i.cap_pan_code, i.cap_proxy_number,
                         v_cap_proxy_number, v_cap_pan_code,
                         v_cap_proxy_number, i.cap_proxy_number, v_errm, 'E');

         END IF;

      EXCEPTION
         WHEN exp_loop
         THEN
            ROLLBACK TO savepoint1;

            INSERT INTO drp_prxy_shfl
                 VALUES (i.cap_pan_code, i.cap_proxy_number,
                         v_cap_proxy_number, v_cap_pan_code,
                         v_cap_proxy_number, i.cap_proxy_number, v_errm, 'E');
      END;
   END LOOP;
EXCEPTION
   WHEN exp_main
   THEN
      p_errm := p_errm;
END;
/

SHOW ERRORS;


