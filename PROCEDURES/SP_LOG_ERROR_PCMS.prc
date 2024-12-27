CREATE OR REPLACE PROCEDURE VMSCMS.sp_log_error_pcms (
   p_inst_code     IN   VARCHAR2,
   p_file_name     IN   VARCHAR2,
   p_process_id    IN   NUMBER,
   p_source_name   IN   VARCHAR2,
   p_item_code     IN   VARCHAR2,
   p_row_id        IN   NUMBER,
   p_errmsg        IN   VARCHAR2,
   p_lupduser      IN   NUMBER
)
AS
    /*
     * VERSION               : 1.0
     * DATE OF CREATION      : 18/Feb/2006
     * CREATED BY            : Chandrashekar Gurram.
     * PURPOSE               : Log error messages for process failures
     * MODIFICATION REASON   :
     *
     *
     * LAST MODIFICATION DONE BY :
     * LAST MODIFICATION DATE    :
     *
   ***/
   PRAGMA AUTONOMOUS_TRANSACTION;
   v_sort_seq   NUMBER (30);
BEGIN
--
-- get sequence no for sorting dependent errors in error log
   SELECT seq_err_log.NEXTVAL
     INTO v_sort_seq
     FROM DUAL;

-- Log error details
   INSERT INTO PCMS_ERROR_LOG
               (pcel_inst_code, pcel_file_name, pcel_process_id,
                pcel_source_name, pcel_item_code, pcel_error_mesg,
                pcel_prob_action, pcel_row_id, pcel_error_cnt,
                pcel_lupd_user, pcel_lupd_date, pcel_seq#
               )
        VALUES (p_inst_code, p_file_name, p_process_id,
                p_source_name, p_item_code, p_errmsg,
                'Please contact site administrator', p_row_id, NULL,
                p_lupduser, SYSDATE, v_sort_seq
               );

   COMMIT;
END;
/
SHOW ERRORS

