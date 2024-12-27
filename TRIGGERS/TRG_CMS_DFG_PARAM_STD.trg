CREATE OR REPLACE TRIGGER VMSCMS.TRG_CMS_DFG_PARAM_STD
 BEFORE INSERT OR UPDATE ON CMS_DFG_PARAM
  FOR EACH ROW
/*************************************************
     * Created Date     :  18-Jan-2013
     * Created By       :  Saravanakumar
     * Purpose          :  Inserting inserted date and updated date
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  18-Jan-2013
      * Build Number     :  CMS3.5.1_RI0023.1_B0003

 *************************************************/

BEGIN 
 IF INSERTING THEN
  :new.CDP_INS_DATE := sysdate;
  :new.CDP_LUPD_DATE := sysdate;
 ELSIF UPDATING THEN
  :new.CDP_LUPD_DATE := sysdate;
 END IF;
END; 
/
show error