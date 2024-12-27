CREATE OR REPLACE TRIGGER VMSCMS.TRG_FEE_FEEPLAN_AUDIT AFTER DELETE
ON  VMSCMS.cms_fee_feeplan
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   exp_audit     EXCEPTION;
   V_TYPE        CHAR(1);
   v_errm        varchar(1000);
/*************************************************
  
     * Created Date      : 13/OCt/2013
     * Created By        : Deepa T
     * PURPOSE           : Insert into History table at the time if update and delete in table cms_fee_feeplan    
     * Reviewer          : Dhiraj 
     * Reviewed Date     : 13/OCt/2013
     * Build Number      : RI0024.5_B0003 
 ***********************************************/
BEGIN                                                 
       IF DELETING THEN
         V_TYPE:='D';
       END IF;
 
  
      BEGIN
      INSERT INTO cms_fee_feeplan_hist
             (
             CFF_FEE_CODE,CFF_FEE_PLAN,CFF_INST_CODE,CFF_INS_USER,CFF_INS_DATE,CFF_LUPD_USER,CFF_LUPD_DATE,
             CFF_FEE_FREQ,CFF_ACT_TYPE              
              )
      VALUES

               (
              :OLD.CFF_FEE_CODE,:OLD.CFF_FEE_PLAN,:OLD.CFF_INST_CODE,:OLD.CFF_INS_USER,:OLD.CFF_INS_DATE,:OLD.CFF_LUPD_USER,:OLD.CFF_LUPD_DATE,
             :OLD.CFF_FEE_FREQ,V_TYPE
              );
    
      EXCEPTION
         WHEN OTHERS
         THEN
         v_errm :=  SQLERRM;
          RAISE exp_audit;
      END;
      
 EXCEPTION
   WHEN exp_audit
   THEN
      raise_application_error (-20001,
                                  'Error While Updating or deleting  Audit for Fee attached to the feeplan '
                               || SQLERRM
                              );     
    END;
/
show error;

