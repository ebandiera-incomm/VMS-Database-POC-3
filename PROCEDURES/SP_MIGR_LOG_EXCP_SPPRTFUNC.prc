CREATE OR REPLACE PROCEDURE VMSCMS.SP_MIGR_LOG_EXCP_SPPRTFUNC
( prm_file_name IN VARCHAR2,
  prm_record_number IN NUMBER,
  prm_card_no IN VARCHAR2,
  prm_new_card_no IN VARCHAR2,
  prm_spprt_key IN VARCHAR2,
  prm_txn_code IN VARCHAR2,
  prm_process_flag IN VARCHAR2,
  prm_process_msg IN VARCHAR2
)
AS
pragma autonomous_transaction;
BEGIN
  INSERT
          INTO migr_spprt_func_excp
            (
              mse_file_name,
              mse_record_number,
              mse_card_no,
              mse_new_card_no,
              mse_spprt_key,
              mse_txn_code,
              mse_process_flag,
              mse_process_msg,
              mse_ins_date
            )
            VALUES
            (
              prm_file_name,
              prm_record_number,
              prm_card_no,
              prm_new_card_no,
              prm_spprt_key,
              prm_txn_code,
              prm_process_flag,
              prm_process_msg,
              SYSDATE
            );
commit;
END;
/

SHOW ERRORS;