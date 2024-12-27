create or replace
PROCEDURE        vmscms.sp_rrn_logging (
   p_inst_code          IN       VARCHAR2,
   p_rrn                IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_card_no            IN       VARCHAR2,
   p_tran_date          IN       VARCHAR2,
   p_tran_time          IN       VARCHAR2,
   p_time_takenms       IN       VARCHAR2,
   p_sever_name         IN       VARCHAR2,
   P_MSG_TYPE           IN       VARCHAR2,
   p_error_msg          OUT      VARCHAR2,
   P_DBRESP_TIME        IN       VARCHAR2 DEFAULT NULL
)
IS
/*************************************************


     * Modified By      : RAVI  N
     * Modified Date    : 05-03-2014
     * Modified Reason  : RRNLogging changes
     * Reviewer         : Dhiraj
     * Reviewed Date    : 05-03-2014
     * Build Number     : RI0027.2_B0001
     
     * Modified By      : Mageshkumar S
     * Modified Date    : 20-11-2014
     * Modified For     : Logging MsgType
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 21-Nov-2014
     * Build Number     : RI0027.4.2.2_B0003
     
     * Modified By      : Sai Prasad
     * Modified Date    : 11-FEB-2015
     * Modified for     : Logging DB Response Time(2.4.2.4.2 & 2.4.3.1 integration)
     * Reviewer         : Spankaj
     * Release Number   : RI0027.5_B0007

 *************************************************/
   v_error_msg   VARCHAR2 (900) DEFAULT 'OK';
   v_hash_pan    VARCHAR2 (90);
BEGIN
   IF p_card_no IS NOT NULL
   THEN
      v_hash_pan := gethash (p_card_no);
   END IF;

   BEGIN
      INSERT INTO cms_rrn_logging
                  (crl_inst_code, crl_rrn, crl_delivery_channel,
                   crl_txn_code, crl_card_no, crl_trans_date,
                   crl_trans_time, crl_time_takenms, crl_sever,
                   crl_time_stamp,CRL_MSG_TYPE,crl_dbresp_timems
                  )
           VALUES (p_inst_code, p_rrn, p_delivery_channel,
                   p_txn_code, v_hash_pan, p_tran_date,
                   p_tran_time, p_time_takenms, p_sever_name,
                   SYSTIMESTAMP,P_MSG_TYPE,P_DBRESP_TIME
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_error_msg :=
               'Error in CMS_RRNLOGGING_TEMP inseration  '
            || SUBSTR (SQLERRM, 1, 200);
   END;

   p_error_msg := v_error_msg;
END; 
/
show error