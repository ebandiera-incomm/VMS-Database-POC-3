CREATE OR REPLACE PROCEDURE VMSCMS.sp_migr_log_excp_txns (
   prm_file_name          IN   VARCHAR2,
   prm_record_number      IN   NUMBER,
   prm_card_no            IN   VARCHAR2,
   prm_rrn                IN   VARCHAR2,
   prm_busness_date       IN   VARCHAR2,
   prm_business_time      IN   VARCHAR2,
   prm_txn_code           IN   VARCHAR2,
   prm_delivery_channel   IN   VARCHAR2,
   prm_amount             IN   NUMBER,
   prm_process_flag       IN   VARCHAR2,
   prm_process_msg        IN   VARCHAR2
)
AS
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   INSERT INTO migr_txnlog_excp
               (mte_file_name, mte_record_number, mte_card_no, mte_rrn,
                mte_busness_date, mte_business_time, mte_txn_code,
                mte_delivery_channel, mte_amount, mte_process_flag,
                mte_process_msg, mte_ins_date
               )
        VALUES (prm_file_name, prm_record_number, prm_card_no, prm_rrn,
                prm_busness_date, prm_business_time, prm_txn_code,
                prm_delivery_channel, prm_amount, 'E',
                prm_process_msg, SYSDATE
               );

   COMMIT;
END;
/

SHOW ERRORS;