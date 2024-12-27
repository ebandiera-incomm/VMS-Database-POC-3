CREATE OR REPLACE PROCEDURE VMSCMS.SP_MIGR_LOG_EXCP_CALLOGDATA
(
prm_file_name IN VARCHAR2,
prm_record_number IN NUMBER,
prm_card_number IN VARCHAR2,
prm_process_flag IN VARCHAR2,
prm_process_msg IN VARCHAR2,
prm_sql_errmsg IN VARCHAR2 
)
AS
PRAGMA autonomous_transaction;
BEGIN
  INSERT INTO MIGR_CALLOG_DATA_EXCP
                             (mcd_file_name, mcd_record_number,
                              mcd_card_number, mcd_process_flag,
                              mcd_process_msg, mcd_ins_date,
                              mcd_sql_err
                             )
                      VALUES (prm_file_name, prm_record_number,
                              prm_card_number, prm_process_flag,
                              prm_process_msg, SYSDATE,
                              prm_sql_errmsg
                             );
COMMIT;
end;
/

SHOW ERRORS;
