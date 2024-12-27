CREATE OR REPLACE PROCEDURE VMSCMS.migr_file_roll_info (
   prm_migr_seqno   IN   NUMBER,
   prm_table_name   IN   VARCHAR2,
   prm_sel_cnt      IN   NUMBER,
   prm_del_cnt      IN   NUMBER
)
AS
--   PRAGMA AUTONOMOUS_TRANSACTION;
   v_chk_log   NUMBER (5);
BEGIN
   SELECT count(1)
     INTO v_chk_log
     FROM migr_roll_count
    WHERE mrc_table_name = prm_table_name
      AND mrc_migr_seqno = prm_migr_seqno;

   IF v_chk_log = 0
   THEN
      INSERT INTO migr_roll_count
                  (mrc_table_name, mrc_sel_cnt, mrc_del_cnt, 
                   mrc_migr_seqno
                  )
           VALUES (prm_table_name, prm_sel_cnt, prm_del_cnt,
                   prm_migr_seqno
                  );
   ELSE
      UPDATE migr_roll_count
         SET mrc_sel_cnt = mrc_sel_cnt + prm_sel_cnt,
             mrc_del_cnt = mrc_del_cnt + prm_del_cnt
       WHERE mrc_table_name = prm_table_name
         AND mrc_migr_seqno = prm_migr_seqno;
   END IF;
-- COMMIT;
END;
/

show error;