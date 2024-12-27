CREATE OR REPLACE PROCEDURE vmscms.sp_create_gl_errorlog (
   prm_acct_no           VARCHAR2,
   prm_ins_msg           VARCHAR2,
   prm_ins_date          DATE,
   prm_inst_code         NUMBER,
   prm_err_msg     OUT   VARCHAR2
)
IS
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   INSERT INTO cms_gl_update_errorlog
               (cge_acct_no, cge_err_msg, cge_ins_date, cge_inst_code
               )
        VALUES (prm_acct_no, prm_ins_msg, prm_ins_date, prm_inst_code
               );

   COMMIT;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_err_msg := 'Error while inserting into GL error log';
END;
/

SHOW ERROR