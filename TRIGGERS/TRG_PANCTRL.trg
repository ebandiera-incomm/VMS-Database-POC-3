CREATE OR REPLACE TRIGGER VMSCMS.trg_panctrl
    BEFORE INSERT OR UPDATE ON cms_pan_ctrl
        FOR EACH ROW
        
  /*********************************************************************************
      * Created Date     :  31-Aug-2012
      * Created By       :  Ramkumar
      * PURPOSE          :  To update the insert and update date.
     * Modified By       : 
     * Modified Reason  :  
     * Modified Date    :  
     * Reviewer         :  B.Besky Anand.
     * Reviewed Date    :  03-Aug-2012  
     * Build Number     : CMS3.5.1_RI0015.1_B0001  


  ************************************************************************************/

BEGIN    --Trigger body begins
    IF INSERTING THEN
        :new.CPC_INS_DATE := sysdate;
        :new.CPC_LUPD_DATE := sysdate;
    ELSIF UPDATING THEN
        :new.CPC_LUPD_DATE := sysdate;
    END IF;
END;    --Trigger body ends
/
SHOW ERROR;