create or replace TRIGGER VMSCMS.TRG_TARGET_MERCH_AUDIT
AFTER  UPDATE
ON  VMSCMS.CMS_TARGETMERCH_MAST
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE   
   update_audit     EXCEPTION;   
   v_errm varchar(1000);
/*************************************************
  
     * Created Date       : Santosh
     * Created By         : 
     * PURPOSE            : Insert alert message for alert type ,if update,delete happen in table CMS_TARGETMERCH_MAST
     * Modified By:       : 
     * Modified Date      : 30-Jan-2013
     * Build Number       : RI0027.1_B0001
          
 ***********************************************/
BEGIN                                                 --SN Trigger body begins
   
      BEGIN
         INSERT INTO CMS_TARGETMERCH_MAST_HIST
                     (	CTM_MERCHANT_NAME,
                     CTM_INST_CODE,                   
                     CTM_LUPD_USER,
                     CTM_LUPD_DATE   
                     )
              VALUES(	:OLD.CTM_MERCHANT_NAME,
                      :NEW.CTM_INST_CODE,                      
                      :NEW.CTM_LUPD_USER,
                      :NEW.CTM_LUPD_DATE
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE update_audit;
      END;
   
EXCEPTION
   WHEN update_audit
   THEN
      raise_application_error (-20001,
                                  'Error While Update Audit for CMS_TARGETMERCH_MAST '
                               || SQLERRM
                              );
  
END;                                                  
/
show error;