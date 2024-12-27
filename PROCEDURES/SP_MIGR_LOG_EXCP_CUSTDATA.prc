CREATE OR REPLACE PROCEDURE VMSCMS.sp_migr_log_excp_custdata (
   prm_file_name       IN   VARCHAR2,
   prm_record_number   IN   NUMBER,
   prm_card_number     IN   VARCHAR2,
   prm_process_flag    IN   VARCHAR2,
   prm_process_msg     IN   VARCHAR2,
   prm_sql_errmsg      IN   VARCHAR2
)
AS
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   INSERT INTO migr_cust_data_excp
               (mce_file_name, mce_record_number, mce_card_number,
                mce_process_flag, mce_process_msg, mce_ins_date, mce_sql_err
               )
        VALUES (prm_file_name, prm_record_number, prm_card_number,
                prm_process_flag, prm_process_msg, SYSDATE, prm_sql_errmsg
               );

   COMMIT;
END;
/

SHOW ERRORS;