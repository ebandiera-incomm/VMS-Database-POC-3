CREATE OR REPLACE PROCEDURE VMSCMS.migr_shrink_segments (
   prm_table_name   IN       VARCHAR2,
   prm_errmsg       OUT      VARCHAR2
)
AS
   v_string1        VARCHAR2 (100);
   v_string2        VARCHAR2 (100);
   exp_shrink_fhm   EXCEPTION;
BEGIN
   prm_errmsg := 'OK';
   v_string1 := 'alter table ' || prm_table_name || ' shrink space';
   v_string2 := 'analyze table ' || prm_table_name || ' estimate statistics';

   BEGIN

      EXECUTE IMMEDIATE v_string1;

      BEGIN

         INSERT INTO migr_shrink_segments_log
              VALUES (prm_table_name || '- shrink space done successfuly',
                      SYSDATE, 'S');
      END;
      
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while shrinking space '
            || prm_table_name
            || '-'
            || SUBSTR (SQLERRM, 1, 200);
      
         RAISE exp_shrink_fhm;
         
   END;

   BEGIN
   
      EXECUTE IMMEDIATE v_string2;

      INSERT INTO migr_shrink_segments_log
           VALUES (prm_table_name || '- analyzed table successfuly', SYSDATE,'S');
           
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while analyzing table '
            || prm_table_name
            || '-'
            || SUBSTR (SQLERRM, 1, 200);
            
         RAISE exp_shrink_fhm;
         
   END;
   
EXCEPTION
   WHEN exp_shrink_fhm
   THEN
   
      INSERT INTO migr_shrink_segments_log
           VALUES (prm_errmsg, SYSDATE, 'E');
           
END;
/

SHOW ERRORS;