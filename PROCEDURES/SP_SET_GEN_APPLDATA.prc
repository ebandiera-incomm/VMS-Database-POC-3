CREATE OR REPLACE PROCEDURE vmscms.sp_set_gen_appldata (
   prm_appl_rec       IN       type_appl_rec_array,
   prm_appl_rec_out   OUT      type_appl_rec_array,
   prm_err_msg        OUT      VARCHAR2
)
IS
   v_appl_rec_outdata       type_acct_rec_array;
   v_error_message          VARCHAR2 (300);
   exp_appl_reject_record   EXCEPTION;
BEGIN
   prm_err_msg := 'OK';
   v_error_message := 'OK';

   BEGIN
      prm_appl_rec_out := prm_appl_rec;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_error_message :=
                        'Error in fetching data ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_appl_reject_record;
   END;
EXCEPTION
   WHEN exp_appl_reject_record
   THEN
      prm_err_msg := v_error_message;
   WHEN OTHERS
   THEN
      prm_err_msg := 'Error from main' || SUBSTR (SQLERRM, 1, 200);
END;
/

SHOW ERROR