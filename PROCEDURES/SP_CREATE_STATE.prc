CREATE OR REPLACE PROCEDURE vmscms.sp_create_state (
   prm_instcode    IN       NUMBER,
   prm_filename    IN       VARCHAR2,
   prm_lupduser    IN       VARCHAR2,
   prm_cntrycode   IN       NUMBER,
   prm_statecode   OUT      NUMBER,
   prm_errmsg      OUT      VARCHAR2
)
AS
   CURSOR c1
   IS
      SELECT DISTINCT cci_seg12_state
                 FROM cms_caf_info_temp
                WHERE cci_file_name = prm_filename
                  AND cci_seg12_state NOT IN (
                         SELECT gsm_switch_state_code
                           FROM gen_state_mast
                          WHERE gsm_inst_code = prm_instcode
                            AND gsm_cntry_code = prm_cntrycode);
BEGIN
   FOR x IN c1
   LOOP
      prm_errmsg := 'OK';

      BEGIN
         SELECT MAX (gsm_state_code) + 1
           INTO prm_statecode
           FROM gen_state_mast
          WHERE gsm_inst_code = prm_instcode
                AND gsm_cntry_code = prm_cntrycode;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                'Error while getting state code ' || SUBSTR (SQLERRM, 1, 200);
      END;

      BEGIN
         INSERT INTO gen_state_mast
                     (gsm_inst_code, gsm_cntry_code, gsm_state_code,
                      gsm_state_name, gsm_lupd_user, gsm_lupd_date,
                      gsm_ins_date, gsm_ins_user, gsm_switch_state_code
                     )
              VALUES (prm_instcode, prm_cntrycode, prm_statecode,
                      x.cci_seg12_state || '-DFLT', prm_lupduser, SYSDATE,
                      SYSDATE, prm_lupduser, x.cci_seg12_state
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                    'Error while creating state ' || SUBSTR (SQLERRM, 1, 200);
      END;
   END LOOP;
END;
/

SHOW ERROR