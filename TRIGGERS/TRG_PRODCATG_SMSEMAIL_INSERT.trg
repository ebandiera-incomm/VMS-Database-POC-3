create or replace TRIGGER vmscms.trg_prodcatg_smsemail_insert
   BEFORE INSERT
   ON vmscms.CMS_PROD_CATTYPE    FOR EACH ROW

DECLARE errmsg VARCHAR2(100);

/*************************************************

     * Created Date     :
     * Created By       :
     * PURPOSE          : Insert default alert message for alert type ,if insert happen in table CMS_PROD_CATTYPE
     * Modified By:     : A.Sivakaminathan
     * Modified Date    : 30-Jan-2013
     * Build Number     :

       * Modified By    : Santosh P
     * Modified Date    : 16-Aug-2013
     * Modified for     : MOB-31
     * Modified Reason  : Card To Card Transfer  message added
     * Reviewer         : Dhiraj
     * Reviewed Date    : 16-Aug-2013
     * Build Number     :  RI0024.4_B0003

     * Modified By      : MageshKumar.S
     * Modified Date    : 18-Sep-2013
     * Modified for     : JH-6
     * Modified Reason  : Fast50 && Federal and Tax Refund Alerts
     * Reviewer         : Dhiraj
     * Reviewed Date    : 19-Sep-2013
     * Build Number     : RI0024.5_B0001

	 * Modified By      : MageshKumar.S
     * Modified Date    : 10-OCT-2013
     * Modified for     : Mantis Id : 12600 & 12602
     * Modified Reason  :
     * Reviewer         : Dhiraj
     * Reviewed Date    : 10-OCT-2013
     * Build Number     : RI0024.5_B0002

     * Modified By      : Siva A
     * Modified Date    : 10-OCT-2013
     * Modified for     : JH-7
     * Modified Reason  : MobileNumber Update Alert
     * Reviewer         : Dhiraj
     * Reviewed Date    : 10-OCT-2013
     * Build Number     : RI0024.6_B0001

	 * Modified By      : Ramesh
     * Modified Date    : 13-Mar-2014
     * Modified for     : MVCSD-4121 and FWR-43
     * Modified Reason  : Renewal card alert
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     : RI0027.2_B0002

      * Modified By      : Raja Gopal G
     * Modified Date    : 30-Jul-2014
     * Modified for     : FR 3.2
     * Modified Reason  : Check Deposit Pending ,Accepted And Rejected Alerts
     * Reviewer         :
     * Reviewed Date    :
     * Build Number     :
     
      * Modified By      : Ramesh A
     * Modified Date    : 13-Aug-2015
     * Modified for     : FWR-59
     * Modified Reason  : SMS and Email Alerts
     * Reviewer         : Pankaj S
     * Reviewed Date    : 13-Aug-2015
     * Build Number     : VMSGPRHOST 3.1
 ***********************************************/
 --Added for FWR-59
CURSOR alertMsg is
SELECT CSF_ALERT_ID,CSF_MSG_FORMAT FROM CMS_SMS_ALERT_MESSAGE_FORMAT WHERE CSF_CONFIG_FLAG='Y' ORDER BY CSF_ALERT_ID;

CURSOR alertLang is
SELECT VAS_ALERT_LANG_ID FROM VMS_ALERTS_SUPPORTLANG ORDER BY VAS_ALERT_LANG_ID;

BEGIN    --Trigger body begins

errmsg :='OK';
--Added for FWR-59
FOR J IN alertLang LOOP
  
   FOR I IN alertMsg LOOP
  
    IF J.VAS_ALERT_LANG_ID = 1 THEN
      
       INSERT INTO CMS_PRODCATG_SMSEMAIL_ALERTS(CPS_INST_CODE,CPS_PROD_CODE,CPS_CARD_TYPE,CPS_CONFIG_FLAG,CPS_OPTINOPTOUT_STATUS,CPS_DEFALERT_LANG_FLAG,CPS_ALERT_LANG_ID,CPS_ALERT_ID,CPS_ALERT_MSG,CPS_INS_USER,CPS_INS_DATE)   
       VALUES(:NEW.CPC_INST_CODE,:NEW.CPC_PROD_CODE,:NEW.CPC_CARD_TYPE,'N',0,'Y',J.VAS_ALERT_LANG_ID,I.CSF_ALERT_ID,0||'~'||I.CSF_MSG_FORMAT||'~'||I.CSF_MSG_FORMAT,:new.cpc_ins_user,sysdate);
       
    ELSE
    
      INSERT INTO CMS_PRODCATG_SMSEMAIL_ALERTS(CPS_INST_CODE,CPS_PROD_CODE,CPS_CARD_TYPE,CPS_CONFIG_FLAG,CPS_OPTINOPTOUT_STATUS,CPS_DEFALERT_LANG_FLAG,CPS_ALERT_LANG_ID,CPS_ALERT_ID,CPS_ALERT_MSG,CPS_INS_USER,CPS_INS_DATE)   
      VALUES(:NEW.CPC_INST_CODE,:NEW.CPC_PROD_CODE,:NEW.CPC_CARD_TYPE,'N',0,'N',J.VAS_ALERT_LANG_ID,I.CSF_ALERT_ID,'0~ ~ ',:new.cpc_ins_user,sysdate);
    
    END IF;
  
  END LOOP;
  
END LOOP;

 
    
EXCEPTION  --Exception of Trigger Body Begin
WHEN OTHERS THEN
RAISE_APPLICATION_ERROR(-20001,'Main Execption -- '||SQLERRM || errmsg) ;
END;    --Trigger body ends
/
show error;