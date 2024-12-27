CREATE OR REPLACE TRIGGER VMSCMS.TRG_CUST_OPTINOPTOUT_STD
   BEFORE UPDATE OR DELETE
   ON VMSCMS.CMS_CUST_OPTINOPTOUT   REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW

 /********************************************************************************
   * Created By       : Ramesh
   * Created Date     : 09-Oct-2013
   * Created for      : LYFEHOST-79/88/99
   * Reviewer         : Dhiraj
   * Reviewed Date    : 09-Oct-2013
   * Build Number     : RI0024.5_B0001

*********************************************************************************/
DECLARE

   v_errmsg   VARCHAR2(1000);
BEGIN
   INSERT INTO cms_cust_optinoptout_hist
               (CCO_INST_CODE,CCO_CUST_CODE,cco_optinoptout_status,
                CCO_INS_USER,CCO_INS_DATE,CCO_LUPD_USER ,CCO_LUPD_DATE,
                cco_optoutalert_status,cco_file_name
               )
        VALUES (:OLD.CCO_INST_CODE,:OLD.CCO_CUST_CODE,:OLD.cco_optinoptout_status,
                :OLD.CCO_INS_USER,sysdate,:OLD.CCO_LUPD_USER ,:OLD.CCO_LUPD_DATE,
                :OLD.cco_optoutalert_status,:OLD.cco_file_name
               );
EXCEPTION
WHEN OTHERS THEN
v_errmsg  := 'Main Error - '||SUBSTR(SQLERRM,1,250);
RAISE_APPLICATION_ERROR(-20002, v_errmsg);
END;
/
SHOW ERRORS;


