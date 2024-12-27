CREATE OR REPLACE TRIGGER VMSCMS.trg_summary_stock
   AFTER DELETE
   ON VMSCMS.CMS_SUMMARY_STOCK    REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
DECLARE   
   
   v_errmsg   VARCHAR2(1000);
BEGIN
   INSERT INTO cms_summary_stock_hist
               (css_inst_code, css_file_name,
                css_tot_records, css_success_records,
                css_error_records, css_process_flag,
                css_err_msg, css_ins_user, css_ins_date,
                css_lupd_user, css_lupd_date
               )
        VALUES (:OLD.css_inst_code, :OLD.css_file_name,
                :OLD.css_tot_records, :OLD.css_success_records,
                :OLD.css_error_records, :OLD.css_process_flag,
                :OLD.css_err_msg, :OLD.css_ins_user, SYSDATE,
                :OLD.css_lupd_user, :OLD.css_lupd_date
               );
EXCEPTION               
WHEN OTHERS THEN
v_errmsg  := 'Main Error - '||SUBSTR(SQLERRM,1,250);
RAISE_APPLICATION_ERROR(-20002, v_errmsg);               
END;
/

show errors;