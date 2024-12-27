create or replace TRIGGER VMSCMS.TRG_PROD_WAIV_AUDIT AFTER DELETE OR UPDATE
ON  cms_prod_waiv
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   exp_audit     EXCEPTION;
   V_TYPE        CHAR(1);
   v_errm        varchar(1000);
/*************************************************
  
     * Created Date       : 08/AUG/2012
     * Created By         : B.Besky Anand.
     * PURPOSE            : Insert into History table at the time if update and delete in table cms_prod_waiv
     * Modified By:       :
     * Modified Date      :
     * Build Number       :CMS3.5.1RI0015_B0001
 ***********************************************/
BEGIN                                                 
 
       IF UPDATING THEN
         V_TYPE:='U';
       ELSIF DELETING THEN
         V_TYPE:='D';
       END IF;
 
  
      BEGIN
      INSERT INTO cms_prod_waiv_hist
             (
              CPW_INST_CODE,CPW_PROD_CODE,CPW_FEE_CODE,
              CPW_WAIV_PRCNT,CPW_VALID_FROM,CPW_VALID_TO,
              CPW_WAIV_DESC,CPW_INS_USER,CPW_INS_DATE,
              CPW_LUPD_USER,CPW_LUPD_DATE,CPW_FEE_PLAN,
              CPW_WAIV_ID,CPW_ACT_DATE,CPW_ACT_TYPE
              )
      VALUES
              (
             :OLD.CPW_INST_CODE,:OLD.CPW_PROD_CODE,:OLD.CPW_FEE_CODE,
             :OLD.CPW_WAIV_PRCNT,:OLD.CPW_VALID_FROM,:OLD.CPW_VALID_TO,
             :OLD.CPW_WAIV_DESC,:OLD.CPW_INS_USER,:OLD.CPW_INS_DATE,
             :OLD.CPW_LUPD_USER,:OLD.CPW_LUPD_DATE,
             :OLD.CPW_FEE_PLAN,:OLD.CPW_WAIV_ID,SYSDATE,V_TYPE 
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
                                  'Error While Updating or deleting  Audit for ProdType waiver  '
                               || v_errm
                              );     
    END; 

/

show error;