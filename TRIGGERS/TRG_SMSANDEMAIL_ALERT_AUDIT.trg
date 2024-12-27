CREATE OR REPLACE TRIGGER VMSCMS."TRG_SMSANDEMAIL_ALERT_AUDIT" 
AFTER DELETE OR UPDATE
ON  VMSCMS.CMS_SMSANDEMAIL_ALERT
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   v_cai_ins_date   DATE      := SYSDATE;
   update_audit     EXCEPTION;
   delete_audit     EXCEPTION;
   v_errm varchar(1000);
/*************************************************
     * Created Date       : 19/DEC/2011
     * PURPOSE          : Insert into History table at the time if update
                      and delete in table cms_smsandemail_alert

     * Modified By      : MageshKumar.S
     * Modified Date    : 18-Sep-2013
     * Modified for     : JH-6
     * Modified Reason  : Fast50 && Federal and Tax Refund Alerts           
     * Reviewer         : Dhiraj
     * Reviewed Date    : 19-Sep-2013
     * Build Number     : RI0024.5_B0001

     * Modified By      : Raja Gopal G
     * Modified Date    : 30-Jul-2014
     * Modified for     : FR 3.2
     * Modified Reason  : Check Deposit Pending ,Accepted And Rejected Alerts
     * Build Number     : RI0027.3.1_B0002
     
      * Modified By      : Ramesh A
     * Modified Date    : 13-Aug-2015
     * Modified for     : FWR-59
     * Modified Reason  : SMS and Email Alerts
     * Reviewer         : Pankaj S
     * Reviewed Date    : 13-Aug-2015
     * Build Number     : VMSGPRHOST 3.1
 ***********************************************/
BEGIN                                                 --SN Trigger body begins
   IF UPDATING
   THEN
      BEGIN
         INSERT INTO CMS_SMSANDEMAIL_ALERT_HIST
                     (    CSA_INST_CODE,
                CSA_PAN_CODE,
                CSA_PAN_CODE_ENCR,
                CSA_CELLPHONECARRIER,
                CSA_LOADORCREDIT_FLAG,
                CSA_LOWBAL_FLAG,
                CSA_LOWBAL_AMT,
                CSA_NEGBAL_FLAG,
                CSA_HIGHAUTHAMT_FLAG,
                CSA_HIGHAUTHAMT,
                CSA_DAILYBAL_FLAG,
                CSA_BEGIN_TIME,
                CSA_END_TIME,
                CSA_INSUFF_FLAG,
                CSA_INCORRPIN_FLAG,
                CSA_FAST50_FLAG, -- Added on 18-09-2013 for JH-6
                CSA_FEDTAX_REFUND_FLAG, -- Added on 18-09-2013 for JH-6
                CSA_DEPPENDING_FLAG, --Added For FR 3.2 on 30-Jul-2014
                CSA_DEPACCEPTED_FLAG, --Added For FR 3.2 on 30-Jul-2014
                CSA_DEPREJECTED_FLAG, --Added For FR 3.2 on 30-Jul-2014
                CSA_INS_USER,
                CSA_INS_DATE,
                CSA_LUPD_USER,
                CSA_LUPD_DATE,
                CSA_ACT_DATE,
                CSA_ACT_TYPE,
                CSA_ALERT_LANG_ID  --Added for FWR-59
                     )
              VALUES(    :OLD.CSA_INST_CODE,
                :OLD.CSA_PAN_CODE,
                :OLD.CSA_PAN_CODE_ENCR,
                :OLD.CSA_CELLPHONECARRIER,
                :OLD.CSA_LOADORCREDIT_FLAG,
                :OLD.CSA_LOWBAL_FLAG,
                :OLD.CSA_LOWBAL_AMT,
                :OLD.CSA_NEGBAL_FLAG,
                :OLD.CSA_HIGHAUTHAMT_FLAG,
                :OLD.CSA_HIGHAUTHAMT,
                :OLD.CSA_DAILYBAL_FLAG,
                :OLD.CSA_BEGIN_TIME,
                :OLD.CSA_END_TIME,
                :OLD.CSA_INSUFF_FLAG,
                :OLD.CSA_INCORRPIN_FLAG,
                :OLD.CSA_FAST50_FLAG, -- Added on 18-09-2013 for JH-6
                :OLD.CSA_FEDTAX_REFUND_FLAG, -- Added on 18-09-2013 for JH-6
                :OLD.CSA_DEPPENDING_FLAG, --Added For FR 3.2 on 30-Jul-2014
                :OLD.CSA_DEPACCEPTED_FLAG, --Added For FR 3.2 on 30-Jul-2014
                :OLD.CSA_DEPREJECTED_FLAG, --Added For FR 3.2 on 30-Jul-2014
                :OLD.CSA_INS_USER,
                :OLD.CSA_INS_DATE,
                :OLD.CSA_LUPD_USER,
                :OLD.CSA_LUPD_DATE,
                          v_cai_ins_date, 'U',
                          :OLD.CSA_ALERT_LANG_ID  --Added for FWR-59
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE update_audit;
      END;
   ELSIF DELETING
   THEN
      BEGIN
         INSERT INTO CMS_SMSANDEMAIL_ALERT_HIST
                     (    CSA_INST_CODE,
                CSA_PAN_CODE,
                CSA_PAN_CODE_ENCR,
                CSA_CELLPHONECARRIER,
                CSA_LOADORCREDIT_FLAG,
                CSA_LOWBAL_FLAG,
                CSA_LOWBAL_AMT,
                CSA_NEGBAL_FLAG,
                CSA_HIGHAUTHAMT_FLAG,
                CSA_HIGHAUTHAMT,
                CSA_DAILYBAL_FLAG,
                CSA_BEGIN_TIME,
                CSA_END_TIME,
                CSA_INSUFF_FLAG,
                CSA_INCORRPIN_FLAG,
                CSA_FAST50_FLAG, -- Added on 18-09-2013 for JH-6
                CSA_FEDTAX_REFUND_FLAG, -- Added on 18-09-2013 for JH-6
                CSA_DEPPENDING_FLAG, --Added For FR 3.2 on 30-Jul-2014
                CSA_DEPACCEPTED_FLAG, --Added For FR 3.2 on 30-Jul-2014
                CSA_DEPREJECTED_FLAG, --Added For FR 3.2 on 30-Jul-2014
                CSA_INS_USER,
                CSA_INS_DATE,
                CSA_LUPD_USER,
                CSA_LUPD_DATE,
                CSA_ACT_DATE,
                CSA_ACT_TYPE,
                CSA_ALERT_LANG_ID --Added for FWR-59
                     )
              VALUES(    :OLD.CSA_INST_CODE,
                :OLD.CSA_PAN_CODE,
                :OLD.CSA_PAN_CODE_ENCR,
                :OLD.CSA_CELLPHONECARRIER,
                :OLD.CSA_LOADORCREDIT_FLAG,
                :OLD.CSA_LOWBAL_FLAG,
                :OLD.CSA_LOWBAL_AMT,
                :OLD.CSA_NEGBAL_FLAG,
                :OLD.CSA_HIGHAUTHAMT_FLAG,
                :OLD.CSA_HIGHAUTHAMT,
                :OLD.CSA_DAILYBAL_FLAG,
                :OLD.CSA_BEGIN_TIME,
                :OLD.CSA_END_TIME,
                :OLD.CSA_INSUFF_FLAG,
                :OLD.CSA_INCORRPIN_FLAG,
                :OLD.CSA_FAST50_FLAG, -- Added on 18-09-2013 for JH-6
                :OLD.CSA_FEDTAX_REFUND_FLAG, -- Added on 18-09-2013 for JH-6
                :OLD.CSA_DEPPENDING_FLAG, --Added For FR 3.2 on 30-Jul-2014
                :OLD.CSA_DEPACCEPTED_FLAG, --Added For FR 3.2 on 30-Jul-2014
                :OLD.CSA_DEPREJECTED_FLAG, --Added For FR 3.2 on 30-Jul-2014
                :OLD.CSA_INS_USER,
                :OLD.CSA_INS_DATE,
                :OLD.CSA_LUPD_USER,
                :OLD.CSA_LUPD_DATE,
                          v_cai_ins_date, 'D',
                          :OLD.CSA_ALERT_LANG_ID --Added for FWR-59
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
         v_errm :=  SQLERRM;
            RAISE delete_audit;
      END;
   END IF;
EXCEPTION
   WHEN update_audit
   THEN
      raise_application_error (-20001,
                                  'Error While Update Audit for smsandemail_alert '
                               || SQLERRM
                              );
   WHEN delete_audit
   THEN
      raise_application_error
                             (-20002,
                                 'Error While Delete  Audit for smsandemail_alert '
                              || v_errm
                             );
END;
/
show error;

