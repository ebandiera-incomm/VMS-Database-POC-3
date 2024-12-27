CREATE OR REPLACE PROCEDURE VMSCMS.sp_gprproxy_shuffle_roll (
   p_errm   OUT   VARCHAR2
)
IS
   v_errm       VARCHAR2 (500) := 'OK';
   savepoint1   NUMBER (10)    := 0;
   exp_loop     EXCEPTION;
BEGIN

p_errm :=  'OK' ;

   FOR i IN (SELECT dps_gpr_pan, dps_gprold_proxy, dps_gprnew_proxy,
                    dps_statr_pan, dps_statrold_proxy, dps_statrnew_proxy,
                    dps_msg
               FROM drp_prxy_shfl
              WHERE dps_flag = 'Y')
   LOOP
      BEGIN
         savepoint1 := savepoint1 + 1;
         SAVEPOINT savepoint1;

         UPDATE cms_appl_pan
            SET cap_proxy_number = i.dps_gprold_proxy
          WHERE cap_pan_code = i.dps_gpr_pan
            AND cap_proxy_number = i.dps_gprnew_proxy;

         IF SQL%ROWCOUNT = 0
         THEN
            v_errm :=
                 'Error while updating GPR card ' || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_loop;
         END IF;

         UPDATE cms_appl_pan
            SET cap_proxy_number = i.dps_statrold_proxy
          WHERE cap_pan_code = i.dps_statr_pan
            AND cap_proxy_number = i.dps_statrnew_proxy;

         IF SQL%ROWCOUNT = 0
         THEN
            v_errm :=
                  'Error while updating Starter card is '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_loop;
         END IF;

         INSERT INTO roll_prxy_shfl
              VALUES (i.dps_gpr_pan, i.dps_gprold_proxy, i.dps_gprnew_proxy,
                      i.dps_statr_pan, i.dps_statrold_proxy,
                      i.dps_statrnew_proxy, 'SUCCESS', 'Y');
      EXCEPTION
         WHEN exp_loop
         THEN
            ROLLBACK TO savepoint1;

            INSERT INTO roll_prxy_shfl
                 VALUES (i.dps_gpr_pan, i.dps_gprold_proxy,
                         i.dps_gprnew_proxy, i.dps_statr_pan,
                         i.dps_statrold_proxy, i.dps_statrnew_proxy, v_errm,
                         'E');
         WHEN OTHERS
         THEN
            ROLLBACK TO savepoint1;
            v_errm := 'Loop error ' || SUBSTR (SQLERRM, 1, 100);

            INSERT INTO roll_prxy_shfl
                 VALUES (i.dps_gpr_pan, i.dps_gprold_proxy,
                         i.dps_gprnew_proxy, i.dps_statr_pan,
                         i.dps_statrold_proxy, i.dps_statrnew_proxy, v_errm,
                         'E');
      END;
   END LOOP;

EXCEPTION

    WHEN others THEN

        p_errm := 'Main exception is ' || SUBSTR (SQLERRM, 1, 100);
END;
/

SHOW ERRORS;


