CREATE OR REPLACE PROCEDURE VMSCMS.sp_grp_deblock (
   instcode   IN       NUMBER,
   lupduser   IN       NUMBER,
   errmsg     OUT      VARCHAR2
)
AS
   v_mbrnumb    VARCHAR2 (3);
   v_remark     cms_pan_spprt.cps_func_remark%TYPE;
   v_spprtrsn   cms_pan_spprt.cps_spprt_rsncode%TYPE;
   dum          NUMBER;

   CURSOR c1
   IS
      SELECT TRIM (cgd_pan_code) cgd_pan_code, cgd_remark, ROWID
        FROM cms_group_deblock
       WHERE cgd_pin_deblock = 'N';
BEGIN
   errmsg := 'OK';
   v_remark := 'Group DeBlock';
   v_spprtrsn := 1;

   FOR x IN c1
   LOOP
      BEGIN
         SELECT 1
           INTO dum
           FROM cms_appl_pan
          WHERE cap_pan_code = x.cgd_pan_code;

         IF dum = 1
         THEN
            -- Rahul and  Hari 22 Feb - workmode - fhm
            sp_deblock_pan (instcode,
                            x.cgd_pan_code,
                            v_mbrnumb,
                            v_spprtrsn,
                            x.cgd_remark,
                            lupduser,
                            0,
                            errmsg
                           );

            IF errmsg = 'OK'
            THEN
               UPDATE cms_group_deblock
                  SET cgd_pin_deblock = 'Y',
                      cgd_result = 'SUCCESSFULL'
                WHERE ROWID = x.ROWID;
            ELSE
               UPDATE cms_group_deblock
                  SET cgd_pin_deblock = 'E',
                      cgd_result = errmsg
                WHERE ROWID = x.ROWID;

               sp_auton (NULL, x.cgd_pan_code, errmsg);
            END IF;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            errmsg := 'The Given Pan not found in Master';

            UPDATE cms_group_deblock
               SET cgd_pin_deblock = 'E',
                   cgd_result = errmsg
             WHERE ROWID = x.ROWID;

            sp_auton (NULL, x.cgd_pan_code, errmsg);
         WHEN OTHERS
         THEN
            errmsg := SQLERRM;

            UPDATE cms_group_deblock
               SET cgd_pin_deblock = 'E',
                   cgd_result = errmsg
             WHERE ROWID = x.ROWID;

            sp_auton (NULL, x.cgd_pan_code, errmsg);
      END;
   END LOOP;

   errmsg := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      errmsg := 'Main Excp -- ' || SQLERRM;
END;
/


