CREATE OR REPLACE TRIGGER VMSCMS.TRG_CMS_PROD_ADHOCFEE
BEFORE UPDATE
   ON VMSCMS.CMS_PROD_ADHOCFEE    REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
BEGIN
/*******************************************************************
    * VERSION             :  1.0
    * Created Date        : 12-MAR-2013
    * Created By          : Sagar M.
    * PURPOSE             : To maintain history of old values
    * Modified By:        : NA
    * Modified Date       : NA
    * Reviewer            : Dhiraj
    * Build Number        : RI0024_B0002
    ****************************************************************/


   INSERT INTO CMS_PROD_ADHOCFEE_HIST
               (
                CPA_INST_CODE,
                CPA_PROD_CODE,
                CPA_SPPRT_RSNCODE,
                CPA_FEE_AMT,
                CPA_INS_USER,
                CPA_INS_DATE,
                CPA_LUPD_USER,
                CPA_LUPd_DATE
               )
        VALUES (
                :OLD.CPA_INST_CODE,
                :OLD.CPA_PROD_CODE,
                :OLD.CPA_SPPRT_RSNCODE,
                :OLD.CPA_FEE_AMT,
                :OLD.CPA_INS_USER,
                :OLD.CPA_INS_DATE,
                :OLD.CPA_LUPD_USER,
                :OLD.CPA_LUPD_DATE
               );


EXCEPTION
   WHEN OTHERS
   THEN
      raise_application_error
                       (-20001,'Error While Inserting into CMS_PROD_ADHOCFEE_HIST '|| SQLERRM);
END;
/
SHOW ERRORS;


