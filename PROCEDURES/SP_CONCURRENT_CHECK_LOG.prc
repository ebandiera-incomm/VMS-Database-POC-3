CREATE OR REPLACE
PROCEDURE        VMSCMS.SP_CONCURRENT_CHECK_LOG
 (p_pan_no_in             IN  VARCHAR2,
  p_delivery_channel_in   IN  VARCHAR2,
  p_txn_code_in           IN  VARCHAR2,
  p_resp_msg_out          OUT VARCHAR2)
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   INSERT INTO vms_concurrency_check (vcc_card_no, vcc_delivery_channel, vcc_txn_code) 
							VALUES  (p_pan_no_in,p_delivery_channel_in, p_txn_code_in );
   p_resp_msg_out := 'OK';
   COMMIT;
 EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
         p_resp_msg_out := 'Concurrent transaction in process';
         ROLLBACK;
    WHEN OTHERS THEN
    p_resp_msg_out := substr(sqlerrm, 1, 200);
    ROLLBACK;
END sp_concurrent_check_log;
/
show error;

 
 
 
 
 