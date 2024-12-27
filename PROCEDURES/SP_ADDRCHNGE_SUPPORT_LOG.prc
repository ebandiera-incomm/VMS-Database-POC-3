CREATE OR REPLACE PROCEDURE vmscms.sp_addrchnge_support_log (
   prm_inst_code       IN       NUMBER,
   prm_card_no         IN       VARCHAR2,
   prm_file_name       IN       VARCHAR2,
   prm_remarks         IN       VARCHAR2,
   prm_msg24_flag      IN       VARCHAR2,
   prm_processs_flag   IN       VARCHAR2,
   prm_process_msg     IN       VARCHAR2,
   prm_process_mode    IN       VARCHAR2,
   prm_ins_user        IN       VARCHAR2,
   prm_ins_date        IN       DATE,
   prm_activity_type   IN       VARCHAR2,
   prm_tran_code       IN       VARCHAR2,
   prm_delv_chnl       IN       VARCHAR2,
   prm_tran_amt        IN       NUMBER,
   prm_source          IN       VARCHAR2,
   prm_reason_desc     IN       VARCHAR2,
   prm_support_type    IN       VARCHAR2,
   prm_errmsg          OUT      VARCHAR2
)
IS
   v_hash_pan   cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan   cms_appl_pan.cap_pan_code_encr%TYPE;
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   prm_errmsg := 'OK';

   BEGIN
      v_hash_pan := gethash (prm_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   BEGIN
      v_encr_pan := fn_emaps_main (prm_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;

   BEGIN
      INSERT INTO cms_addrchng_detail
                  (crd_inst_code, crd_card_no, crd_file_name, crd_remarks,
                   crd_msg24_flag, crd_process_flag, crd_process_msg,
                   crd_process_mode, crd_ins_user, crd_ins_date,
                   crd_lupd_user, crd_lupd_date, crd_card_no_encr
                  )
           VALUES (prm_inst_code, v_hash_pan, NULL, prm_remarks,
                   prm_msg24_flag, prm_processs_flag, prm_process_msg,
                   prm_process_mode, prm_ins_user, prm_ins_date,
                   prm_ins_user, prm_ins_date, v_encr_pan
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while creating record in detail table '
            || SUBSTR (SQLERRM, 1, 150);
         RETURN;
   END;

   BEGIN
      INSERT INTO process_audit_log
                  (pal_inst_code, pal_card_no, pal_activity_type,
                   pal_transaction_code, pal_delv_chnl, pal_tran_amt,
                   pal_source, pal_success_flag, pal_ins_user,
                   pal_ins_date, pal_process_msg, pal_reason_desc,
                   pal_remarks, pal_spprt_type, pal_card_no_encr
                  )
           VALUES (prm_inst_code, v_hash_pan, prm_activity_type,
                   prm_tran_code, prm_delv_chnl, prm_tran_amt,
                   prm_source, prm_processs_flag, prm_ins_user,
                   prm_ins_date, prm_process_msg, prm_reason_desc,
                   prm_remarks, prm_support_type, v_encr_pan
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while creating record in detail table '
            || SUBSTR (SQLERRM, 1, 150);
         RETURN;
   END;

   COMMIT;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg :=
            'Error while creating record in log table '
         || SUBSTR (SQLERRM, 1, 150);
      RETURN;
END;
/

SHOW ERROR