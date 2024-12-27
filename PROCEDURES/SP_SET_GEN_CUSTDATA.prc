CREATE OR REPLACE PROCEDURE vmscms.sp_set_gen_custdata (
   prm_inst_code      IN       NUMBER,
   prm_cust_rec       IN       type_cust_rec_array,
   prm_cust_rec_out   OUT      type_cust_rec_array,
   prm_err_msg        OUT      VARCHAR2
)
IS
   v_cusr_rec_outdata       type_cust_rec_array;
   v_error_message          VARCHAR2 (300);
   exp_cust_reject_record   EXCEPTION;
BEGIN
   prm_err_msg := 'OK';
   v_error_message := 'OK';

   BEGIN
      prm_cust_rec_out := prm_cust_rec;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_error_message :=
                        'Error in fetching data ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_cust_reject_record;
   END;
EXCEPTION
   WHEN exp_cust_reject_record
   THEN
      prm_err_msg := v_error_message;
   WHEN OTHERS
   THEN
      prm_err_msg := 'Error from main' || SUBSTR (SQLERRM, 1, 200);
END;
/

SHOW ERROR