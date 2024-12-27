create or replace TRIGGER VMSCMS.TRG_CARDEXCP_WAIV_AUDIT AFTER DELETE OR UPDATE
ON  cms_card_excpwaiv
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   exp_audit     EXCEPTION;
   V_TYPE        CHAR(1);
   v_errm        varchar(1000);
/*************************************************
  
     * Created Date       : 08/AUG/2012
     * Created By         : B.Besky Anand.
     * PURPOSE            : Insert into History table at the time if update and delete in table cms_card_excpwaiv
     * Modified By:       :
     * Modified Date      :
     * Build Number       :CMS3.5.1_RI0015_B0001
 ***********************************************/
BEGIN                                                 
 
       IF UPDATING THEN
         V_TYPE:='U';
       ELSIF DELETING THEN
         V_TYPE:='D';
       END IF;
 
  
      BEGIN
      INSERT INTO cms_card_excpwaiv_hist
             (
              CCE_INST_CODE,CCE_FEE_CODE,CCE_WAIV_PRCNT,
              CCE_PAN_CODE,CCE_MBR_NUMB,CCE_VALID_FROM,
              CCE_VALID_TO,CCE_WAIV_DESC,CCE_FLOW_SOURCE,
              CCE_INS_USER,CCE_INS_DATE,CCE_LUPD_USER,
              CCE_LUPD_DATE,CCE_CARD_WAIV_ID,CCE_PAN_CODE_ENCR,
              CCE_FEE_PLAN,CCE_ACT_DATE,CCE_ACT_TYPE
              )
      VALUES
              (
              :OLD.CCE_INST_CODE,:OLD.CCE_FEE_CODE,:OLD.CCE_WAIV_PRCNT,
              :OLD.CCE_PAN_CODE,:OLD.CCE_MBR_NUMB,:OLD.CCE_VALID_FROM,
              :OLD.CCE_VALID_TO,:OLD.CCE_WAIV_DESC,:OLD.CCE_FLOW_SOURCE,
              :OLD.CCE_INS_USER,:OLD.CCE_INS_DATE,:OLD.CCE_LUPD_USER,
              :OLD.CCE_LUPD_DATE,:OLD.CCE_CARD_WAIV_ID,:OLD.CCE_PAN_CODE_ENCR,
              :OLD.CCE_FEE_PLAN,SYSDATE,V_TYPE
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
                                  'Error While Updating or deleting  Audit for card_excp waiver  '
                               || SQLERRM
                              );     
    END;    

/
show error;