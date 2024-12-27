CREATE OR REPLACE PROCEDURE VMSCMS.SP_MIGR_LOG_EXCP_ACCOUNTDATA
(
prm_file_name IN VARCHAR2,
prm_record_number IN NUMBER,
prm_acct_number IN VARCHAR2,
prm_process_flag IN VARCHAR2,
prm_process_msg IN VARCHAR2,
prm_sql_errmsg IN VARCHAR2 --Added On 24.06.2013
)
AS
PRAGMA autonomous_transaction;
BEGIN
  INSERT INTO migr_acct_data_excp
                             (mae_file_name, mae_record_number,
                              mae_acct_number, mae_process_flag,
                              mae_process_msg, mae_ins_date,
                              mae_sql_err--Added On 24.06.2013
                             )
                      VALUES (prm_file_name, prm_record_number,
                              prm_acct_number, prm_process_flag,
                              prm_process_msg, SYSDATE,
                              prm_sql_errmsg--Added On 24.06.2013
                             );
COMMIT;
end;
/

SHOW ERRORS;