CREATE OR REPLACE PROCEDURE VMSCMS.sp_set_gen_custdata_no_out
(
  prm_inst_code   			IN NUMBER,
  prm_cust_rec    			IN  TYPE_CUST_REC_ARRAY,
  prm_err_msg  				OUT     varchar2
)
IS
v_cusr_rec_outdata TYPE_CUST_REC_ARRAY;
v_error_message  VARCHAR2(300);
exp_cust_reject_record EXCEPTION;
BEGIN   --<< main begin >>
 prm_err_msg := 'OK';
 v_error_message := 'OK';
EXCEPTION  --<< main exception >>
 WHEN exp_cust_reject_record THEN
  prm_err_msg := v_error_message;
 WHEN OTHERS THEN
  prm_err_msg := 'Error from main' || substr(sqlerrm,1,200);
END;
/


SHOW ERRORS