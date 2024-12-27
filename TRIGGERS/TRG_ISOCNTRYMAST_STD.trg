CREATE OR REPLACE TRIGGER VMSCMS.trg_isocntrymast_std
   BEFORE INSERT OR UPDATE
   ON VMSCMS.CMS_ISOCNTRY_MAST    FOR EACH ROW
 /*************************************************
      * Created By       :  Deepa
      * Created Date     :  13-NOV-2013
      * Purpose          :
      * Reviewer         :  Dhiraj
      * Reviewed Date    :
      * Build Number     :  RI0024.3.10_B0001
  *************************************************/
BEGIN                                                    --Trigger body begins
   IF INSERTING
   THEN
      :NEW.cim_ins_date := SYSDATE;
      :NEW.cim_lupd_date := SYSDATE;
   ELSIF UPDATING
   THEN
      :NEW.cim_lupd_date := SYSDATE;
   END IF;
END;
/
SHOW ERRORS;


