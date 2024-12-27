create or replace
PROCEDURE        VMSCMS.SP_CONCURRENT_CHECK_LOGCLEAR
 (p_pan_no_in             IN  VARCHAR2,
  p_delivery_channel_in   IN  VARCHAR2,
  p_txn_code_in           IN  VARCHAR2,
  p_resp_msg_out          OUT VARCHAR2
 )
IS
  --PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   DELETE FROM vms_concurrency_check 
         WHERE vcc_card_no = p_pan_no_in 
           AND vcc_delivery_channel = p_delivery_channel_in
           AND vcc_txn_code = p_txn_code_in;
   p_resp_msg_out := 'OK';
  -- COMMIT;
 EXCEPTION
   WHEN OTHERS THEN
      p_resp_msg_out := substr(sqlerrm, 1, 200);
    --  ROLLBACK;
END sp_concurrent_check_logclear;
/
show error

 
 
 
 
 