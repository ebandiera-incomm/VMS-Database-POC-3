CREATE OR REPLACE PROCEDURE VMSCMS.SP_MIGR_FILE_DETL (
   prm_migr_type        IN   VARCHAR2,
   prm_file_name        IN   VARCHAR2,
   prm_file_header      IN   VARCHAR2,
   prm_file_rec_cnt     IN   NUMBER,
   prm_succ_rec_cnt     IN   NUMBER,
   prm_err_rec_cnt      IN   NUMBER,
   prm_file_load_flag   IN   VARCHAR2,
   prm_file_load_mesg   IN   VARCHAR2
)
AS
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   INSERT INTO migr_file_detl
               (mfd_migr_type, mfd_file_name, mfd_file_header,
                mfd_file_rec_cnt, mfd_succ_rec_cnt, mfd_err_rec_cnt,
                mfd_file_load_flag, mfd_process_msg, mfd_ins_date
               )
        VALUES (prm_migr_type, prm_file_name, prm_file_header,
                prm_file_rec_cnt, prm_succ_rec_cnt, prm_err_rec_cnt,
                prm_file_load_flag, prm_file_load_mesg, SYSDATE
               );

   COMMIT;
END;
/
SHOW ERRORS;