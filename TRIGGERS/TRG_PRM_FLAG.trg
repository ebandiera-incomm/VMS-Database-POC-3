create or replace
TRIGGER VMSCMS.TRG_PRM_FLAG
	BEFORE INSERT OR UPDATE ON cms_prm_flag
		FOR EACH ROW
DECLARE

     ERRMSG         varchar2(1000);   
     
    /*************************************************
     * Created Date     :  31/July/2012
     * Created By       :  Ramkumar
     * PURPOSE          :  To update the sysdate for inserted and update date 
     * Modified By      :    
     * Modified Date    :  
     * Modified Reason  :  
     * Reviewer         :  B.Besky Anand.
     * Reviewed Date    :  01/Aug/2012
     * Release Number   :  CMS3.5.1_RI0012.1_B0001
 *************************************************/
 
BEGIN	--Trigger body begins

	IF INSERTING THEN
		:new.CPF_INS_DATE := sysdate;
		:new.CPF_LUPD_DATE := sysdate;
	ELSIF UPDATING THEN
		:new.CPF_LUPD_DATE := sysdate;
	END IF;
        
EXCEPTION
 WHEN OTHERS THEN
    ERRMSG := 'Main Error  - ' || SUBSTR(SQLERRM, 1, 250);
    RAISE_APPLICATION_ERROR(-20002, ERRMSG);
END;	 
/
SHOW ERROR;