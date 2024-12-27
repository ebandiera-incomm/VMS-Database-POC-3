
CREATE OR REPLACE TRIGGER VMSCMS.TRG_PROD_FEES_AUDIT AFTER DELETE OR UPDATE
ON  cms_prod_fees
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   exp_audit     EXCEPTION;
   V_TYPE        CHAR(1);
   v_errm        varchar(1000);
/*************************************************
  
     * Created Date       : 13/JULY/2012
     * Created By         : B.Besky Anand.
     * PURPOSE            : Insert into History table at the time if updateand delete in table cms_prod_fees
     * Modified By:       :Deepa T
     * Modified Date      :13-Aug-2012
     * Modified reason     : To include Uniue ID for the Feeplan attached to Product 
     * Reviewer         :  B.Besky Anand
      * Reviewed Date    :  21-Aug-2012
      * Build Number     :  CMS3.5.1_RI0015_B0001
 ***********************************************/
BEGIN                                                 
 
       IF UPDATING THEN
         V_TYPE:='U';
       ELSIF DELETING THEN
         V_TYPE:='D';
       END IF;
 
  
      BEGIN
      INSERT INTO cms_prod_fees_hist
             (
              CPF_INST_CODE,CPF_FUNC_CODE,CPF_PROD_CODE,CPF_FEE_TYPE,
              CPF_FEE_CODE,CPF_CRGL_CATG,CPF_CRGL_CODE,CPF_CRSUBGL_CODE,
              CPF_CRACCT_NO,CPF_DRGL_CATG,CPF_DRGL_CODE,CPF_DRSUBGL_CODE,
              CPF_DRACCT_NO,CPF_VALID_FROM,CPF_VALID_TO,CPF_FLOW_SOURCE,
              CPF_INS_USER,CPF_INS_DATE,CPF_LUPD_USER,CPF_LUPD_DATE,
              CPF_ST_CRGL_CATG,CPF_ST_CRGL_CODE,CPF_ST_CRSUBGL_CODE,
              CPF_ST_CRACCT_NO,CPF_ST_DRGL_CATG,CPF_ST_DRGL_CODE,
              CPF_ST_DRSUBGL_CODE,CPF_ST_DRACCT_NO,CPF_CESS_CRGL_CATG,
              CPF_CESS_CRGL_CODE,CPF_CESS_CRSUBGL_CODE,CPF_CESS_CRACCT_NO,
              CPF_CESS_DRGL_CATG,CPF_CESS_DRGL_CODE,CPF_CESS_DRSUBGL_CODE,
              CPF_CESS_DRACCT_NO,CPF_ST_CALC_FLAG,CPF_CESS_CALC_FLAG,
              CPF_TRAN_CODE,CPF_FEE_PLAN,CPF_ACT_DATE,CPF_ACT_TYPE,CPF_PRODFEEPLAN_ID
              )
      VALUES

               (
              :OLD.CPF_INST_CODE,:OLD.CPF_FUNC_CODE,:OLD.CPF_PROD_CODE,:OLD.CPF_FEE_TYPE,
              :OLD.CPF_FEE_CODE,:OLD.CPF_CRGL_CATG,:OLD.CPF_CRGL_CODE,:OLD.CPF_CRSUBGL_CODE,
              :OLD.CPF_CRACCT_NO,:OLD.CPF_DRGL_CATG,:OLD.CPF_DRGL_CODE,:OLD.CPF_DRSUBGL_CODE,
              :OLD.CPF_DRACCT_NO,:OLD.CPF_VALID_FROM,:OLD.CPF_VALID_TO,:OLD.CPF_FLOW_SOURCE,
              :OLD.CPF_INS_USER,:OLD.CPF_INS_DATE,:OLD.CPF_LUPD_USER,:OLD.CPF_LUPD_DATE,
              :OLD.CPF_ST_CRGL_CATG,:OLD.CPF_ST_CRGL_CODE,:OLD.CPF_ST_CRSUBGL_CODE,
              :OLD.CPF_ST_CRACCT_NO,:OLD.CPF_ST_DRGL_CATG,:OLD.CPF_ST_DRGL_CODE,
              :OLD.CPF_ST_DRSUBGL_CODE,:OLD.CPF_ST_DRACCT_NO,:OLD.CPF_CESS_CRGL_CATG,
              :OLD.CPF_CESS_CRGL_CODE,:OLD.CPF_CESS_CRSUBGL_CODE,:OLD.CPF_CESS_CRACCT_NO,
              :OLD.CPF_CESS_DRGL_CATG,:OLD.CPF_CESS_DRGL_CODE,:OLD.CPF_CESS_DRSUBGL_CODE,
              :OLD.CPF_CESS_DRACCT_NO,:OLD.CPF_ST_CALC_FLAG,:OLD.CPF_CESS_CALC_FLAG,
              :OLD.CPF_TRAN_CODE,:OLD.CPF_FEE_PLAN,SYSDATE,V_TYPE,:OLD.CPF_PRODFEEPLAN_ID
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
                                  'Error While Updating or deleting  Audit for ProdType '
                               || SQLERRM
                              );     
    END;
/


show error;