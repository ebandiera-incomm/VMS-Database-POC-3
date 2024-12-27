create or replace TRIGGER VMSCMS.TRG_PRODCATG_SMSEMAILALT_AUDIT
AFTER DELETE OR UPDATE
ON  VMSCMS.CMS_PRODCATG_SMSEMAIL_ALERTS
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE 
   v_cai_ins_date   DATE      := SYSDATE;
   update_audit     EXCEPTION;
   delete_audit     EXCEPTION;
   v_errm varchar(1000);
/*************************************************
  
     * Created Date       : 19/DEC/2011
     * Created By         : 
     * PURPOSE            : Insert alert message for alert type ,if update,delete happen in table CMS_PRODCATG_SMSEMAIL_ALERTS
     * Modified By:       : A.Sivakaminathan
     * Modified Date      : 30-Jan-2013
     * Build Number       :
     
     * Modified By      : MageshKumar.S
     * Modified Date    : 18-Sep-2013
     * Modified for     : JH-6
     * Modified Reason  : Fast50  and Tax Refund Alerts           
     * Reviewer         : Dhiraj
     * Reviewed Date    : 19-Sep-2013
     * Build Number     : RI0024.5_B0001
     
     * Modified By      : Siva Arcot
     * Modified Date    : 08-Oct-2013
     * Modified for     : JH-7
     * Modified Reason  : Mobile Number Update Alerts           
     * Reviewer         : Dhiraj 
     * Reviewed Date    : 17-Oct-2013
     * Build Number     : RI0024.6_B0001
     
     * Modified By      : Dayanand Kesarkar
     * Modified Date    : 28-JAN-2013
     * Modified for     : MANTIS-13558 
     * Modified Reason  : Card to Card transfer Alerts           
     * Reviewer         : dhiraj
     * Reviewed Date    : 
     * Build Number     : RI0027_B0005
     
     * Modified By      : Dayanand Kesarkar
     * Modified Date    : 07-FEB-2013
     * Modified for     : SPIL3.0 
     * Modified Reason  : KYC ALERT           
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : RI0027.1_B0001

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
BEGIN                                                 --SN Trigger body begins
   IF UPDATING
   THEN
      BEGIN
         INSERT INTO CMS_PRODCATG_SMSEMAIL_ALT_HIST
                     (    CPS_INST_CODE,
                CPS_PROD_CODE,
                CPS_CARD_TYPE,
                CPS_CONFIG_FLAG,
                CPS_LOADCREDIT_FLAG,
                CPS_LOWBAL_FLAG,
                CPS_NEGATIVEBAL_FLAG,
                CPS_HIGHAUTHAMT_FLAG,
                CPS_DAILYBAL_FLAG,
                CPS_INSUFFUND_FLAG,
                CPS_INCORRECTPIN_FLAG,
                CPS_INS_USER,
                CPS_INS_DATE,
                CPS_LUPD_USER,
                CPS_LUPD_DATE,
                CPS_ACT_DATE,
                CPS_ACT_TYPE,
                CPS_WELCOME_FLAG,
                CPS_WELCOME_MSG,
                CPS_LOADCREDIT_MSG,
                CPS_LOWBAL_MSG,
                CPS_NEGATIVEBAL_MSG,
                CPS_HIGHAUTHAMT_MSG,
                CPS_DAILYBAL_MSG,
                CPS_INSUFFUND_MSG,
                CPS_INCORRECTPIN_MSG,
                CPS_INCORRECTPIN_IVR_MSG,
                CPS_INCORRECTPIN_CHW_MSG,
        CPS_FAST50_FLAG,-- Added By MageshKumar.S for jh-6 on 18 SEP 13
        CPS_FAST50_MSG, -- Added By MageshKumar.S for jh-6 on 18 SEP 13
        CPS_FEDTAX_REFUND_FLAG, -- Added By MageshKumar.S for jh-6 on 18 SEP 13
        CPS_FEDTAX_REFUND_MSG, -- Added By MageshKumar.S for jh-6 on 18 SEP 13
        CPS_MOBUPDATE_FLAG, -- Added By Siva Arcot for jh-7 on 08-oct-2013
        CPS_MOBUPDATE_MSG, -- Added By Siva Arcot for jh-7 on 08-oct-2013
            CPS_CARDTOCARD_TRANS_FLAG, --Added By Dayanand for MANTIS-13558 on 28-jan-2014
            CPS_CARDTOCARD_TRANS_MSG, --Added By Dayanand for MANTIS-13558 on 28-jan-2014
        CPS_KYCFAIL_FLAG, --Added By Dayanand for SPIL3.0 on 07-feb-2014
        CPS_KYCFAIL_MSG, --Added By Dayanand for SPIL3.0 on 07-feb-2014
        CPS_KYCSUCCESS_FLAG,--Added By Dayanand for SPIL3.0 on 07-feb-2014
        CPS_KYCSUCCESS_MSG,--Added By Dayanand for SPIL3.0 on 07-feb-2014
        CPS_RENEWALALT_FLAG,--Added for MVCSD-4121 and FWR-43 on 13-Mar-2014
        CPS_RENEWALALT_MSG,--Added for MVCSD-4121 and FWR-43 on 13-Mar-2014
        CPS_CHKPENDING_FLAG, --Added For FR 3.2 on 30-Jul-2014
        CPS_CHKPENDING_MSG, --Added For FR 3.2 on 30-Jul-2014
        CPS_CHKAPPROVED_FLAG, --Added For FR 3.2 on 30-Jul-2014
        CPS_CHKAPPROVED_MSG, --Added For FR 3.2 on 30-Jul-2014
        CPS_CHKREJECTED_FLAG, --Added For FR 3.2 on 30-Jul-2014
        CPS_CHKREJECTED_MSG, --Added For FR 3.2 on 30-Jul-2014
         CPS_ALERT_LANG_ID, --Added for FWR-59
         CPS_ALERT_ID, --Added for FWR-59
         CPS_ALERT_MSG, --Added for FWR-59
         CPS_DEFALERT_LANG_FLAG --Added for FWR-59
                     )
              VALUES(    :OLD.CPS_INST_CODE,
                :OLD.CPS_PROD_CODE,
                :OLD.CPS_CARD_TYPE,
                :OLD.CPS_CONFIG_FLAG,
                :OLD.CPS_LOADCREDIT_FLAG,
                :OLD.CPS_LOWBAL_FLAG,
                :OLD.CPS_NEGATIVEBAL_FLAG,
                :OLD.CPS_HIGHAUTHAMT_FLAG,
                :OLD.CPS_DAILYBAL_FLAG,
                :OLD.CPS_INSUFFUND_FLAG,
                :OLD.CPS_INCORRECTPIN_FLAG,
                :OLD.CPS_INS_USER,
                :OLD.CPS_INS_DATE,
                :OLD.CPS_LUPD_USER,
                :OLD.CPS_LUPD_DATE,
                          v_cai_ins_date, 'U',
                :OLD.CPS_WELCOME_FLAG,
                :OLD.CPS_WELCOME_MSG,
                :OLD.CPS_LOADCREDIT_MSG,
                :OLD.CPS_LOWBAL_MSG,
                :OLD.CPS_NEGATIVEBAL_MSG,
                :OLD.CPS_HIGHAUTHAMT_MSG,
                :OLD.CPS_DAILYBAL_MSG,
                :OLD.CPS_INSUFFUND_MSG,
                :OLD.CPS_INCORRECTPIN_MSG,
                :OLD.CPS_INCORRECTPIN_IVR_MSG,
                :OLD.CPS_INCORRECTPIN_CHW_MSG,
        :OLD.CPS_FAST50_FLAG, -- Added By MageshKumar.S for jh-6 on 18 SEP 13
        :OLD.CPS_FAST50_MSG, -- Added By MageshKumar.S for jh-6 on 18 SEP 13
        :OLD.CPS_FEDTAX_REFUND_FLAG, -- Added By MageshKumar.S for jh-6 on 18 SEP 13
        :OLD.CPS_FEDTAX_REFUND_MSG, -- Added By MageshKumar.S for jh-6 on 18 SEP 13
        :OLD.CPS_MOBUPDATE_FLAG,  -- Added By Siva Arcot for jh-7 on 08-oct-2013
        :OLD.CPS_MOBUPDATE_MSG,  -- Added By Siva Arcot for jh-7 on 08-oct-2013
            :OLD.CPS_CARDTOCARD_TRANS_FLAG, --Added By Dayanand for MANTIS-13558 on 28-jan-2014
            :OLD.CPS_CARDTOCARD_TRANS_MSG, --Added By Dayanand for MANTIS-13558 on 28-jan-2014
        :OLD.CPS_KYCFAIL_FLAG, --Added By Dayanand for SPIL3.0 on 07-feb-2014
        :OLD.CPS_KYCFAIL_MSG, --Added By Dayanand for SPIL3.0 on 07-feb-2014
        :OLD.CPS_KYCSUCCESS_FLAG,--Added By Dayanand for SPIL3.0 on 07-feb-2014
        :OLD.CPS_KYCSUCCESS_MSG,--Added By Dayanand for SPIL3.0 on 07-feb-2014
        :OLD.CPS_RENEWALALT_FLAG, --Added for MVCSD-4121 and FWR-43 on 13-Mar-2014
        :OLD.CPS_RENEWALALT_MSG, --Added for MVCSD-4121 and FWR-43 on 13-Mar-2014
        :OLD.CPS_CHKPENDING_FLAG, --Added For FR 3.2 on 30-Jul-2014
        :OLD.CPS_CHKPENDING_MSG, --Added For FR 3.2 on 30-Jul-2014
        :OLD.CPS_CHKAPPROVED_FLAG, --Added For FR 3.2 on 30-Jul-2014
        :OLD.CPS_CHKAPPROVED_MSG, --Added For FR 3.2 on 30-Jul-2014
        :OLD.CPS_CHKREJECTED_FLAG, --Added For FR 3.2 on 30-Jul-2014
        :OLD.CPS_CHKREJECTED_MSG, --Added For FR 3.2 on 30-Jul-2014
        :OLD.CPS_ALERT_LANG_ID, --Added for FWR-59
         :OLD.CPS_ALERT_ID, --Added for FWR-59
         :OLD.CPS_ALERT_MSG, --Added for FWR-59
         :OLD.CPS_DEFALERT_LANG_FLAG --Added for FWR-59
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE update_audit;
      END;
   ELSIF DELETING
   THEN
      BEGIN
         INSERT INTO CMS_PRODCATG_SMSEMAIL_ALT_HIST
                     (    CPS_INST_CODE,
                CPS_PROD_CODE,
                CPS_CARD_TYPE,
                CPS_CONFIG_FLAG,
                CPS_LOADCREDIT_FLAG,
                CPS_LOWBAL_FLAG,
                CPS_NEGATIVEBAL_FLAG,
                CPS_HIGHAUTHAMT_FLAG,
                CPS_DAILYBAL_FLAG,
                CPS_INSUFFUND_FLAG,
                CPS_INCORRECTPIN_FLAG,
                CPS_INS_USER,
                CPS_INS_DATE,
                CPS_LUPD_USER,
                CPS_LUPD_DATE,
                CPS_ACT_DATE,
                CPS_ACT_TYPE,
                CPS_WELCOME_FLAG,
                CPS_WELCOME_MSG,
                CPS_LOADCREDIT_MSG,
                CPS_LOWBAL_MSG,
                CPS_NEGATIVEBAL_MSG,
                CPS_HIGHAUTHAMT_MSG,
                CPS_DAILYBAL_MSG,
                CPS_INSUFFUND_MSG,
                CPS_INCORRECTPIN_MSG,
                CPS_INCORRECTPIN_IVR_MSG,
                CPS_INCORRECTPIN_CHW_MSG,
        CPS_FAST50_FLAG, -- Added By MageshKumar.S for jh-6 on 18 SEP 13
        CPS_FAST50_MSG, -- Added By MageshKumar.S for jh-6 on 18 SEP 13
        CPS_FEDTAX_REFUND_FLAG, -- Added By MageshKumar.S for jh-6 on 18 SEP 13
        CPS_FEDTAX_REFUND_MSG, -- Added By MageshKumar.S for jh-6 on 18 SEP 13
        CPS_MOBUPDATE_FLAG, -- Added By Siva Arcot for jh-7 on 08-oct-2013
        CPS_MOBUPDATE_MSG, -- Added By Siva Arcot for jh-7 on 08-oct-2013
            CPS_CARDTOCARD_TRANS_FLAG, --Added By Dayanand for MANTIS-13558 on 28-jan-2014
        CPS_CARDTOCARD_TRANS_MSG, --Added By Dayanand for MANTIS-13558 on 28-jan-2014
        CPS_KYCFAIL_FLAG, --Added By Dayanand for SPIL3.0 on 07-feb-2014
        CPS_KYCFAIL_MSG, --Added By Dayanand for SPIL3.0 on 07-feb-2014
        CPS_KYCSUCCESS_FLAG,--Added By Dayanand for SPIL3.0 on 07-feb-2014
        CPS_KYCSUCCESS_MSG,--Added By Dayanand for SPIL3.0 on 07-feb-2014
        CPS_RENEWALALT_FLAG,--Added for MVCSD-4121 and FWR-43 on 13-Mar-2014
        CPS_RENEWALALT_MSG,--Added for MVCSD-4121 and FWR-43 on 13-Mar-2014
        CPS_CHKPENDING_FLAG, --Added For FR 3.2 on 30-Jul-2014
        CPS_CHKPENDING_MSG, --Added For FR 3.2 on 30-Jul-2014
        CPS_CHKAPPROVED_FLAG, --Added For FR 3.2 on 30-Jul-2014
        CPS_CHKAPPROVED_MSG, --Added For FR 3.2 on 30-Jul-2014
        CPS_CHKREJECTED_FLAG, --Added For FR 3.2 on 30-Jul-2014
        CPS_CHKREJECTED_MSG, --Added For FR 3.2 on 30-Jul-2014
         CPS_ALERT_LANG_ID, --Added for FWR-59
         CPS_ALERT_ID, --Added for FWR-59
         CPS_ALERT_MSG, --Added for FWR-59
         CPS_DEFALERT_LANG_FLAG --Added for FWR-59
                     )
              VALUES(    :OLD.CPS_INST_CODE,
                :OLD.CPS_PROD_CODE,
                :OLD.CPS_CARD_TYPE,
                :OLD.CPS_CONFIG_FLAG,
                :OLD.CPS_LOADCREDIT_FLAG,
                :OLD.CPS_LOWBAL_FLAG,
                :OLD.CPS_NEGATIVEBAL_FLAG,
                :OLD.CPS_HIGHAUTHAMT_FLAG,
                :OLD.CPS_DAILYBAL_FLAG,
                :OLD.CPS_INSUFFUND_FLAG,
                :OLD.CPS_INCORRECTPIN_FLAG,
                :OLD.CPS_INS_USER,
                :OLD.CPS_INS_DATE,
                :OLD.CPS_LUPD_USER,
                :OLD.CPS_LUPD_DATE,
                          v_cai_ins_date, 'D',
                :OLD.CPS_WELCOME_FLAG,
                :OLD.CPS_WELCOME_MSG,
                :OLD.CPS_LOADCREDIT_MSG,
                :OLD.CPS_LOWBAL_MSG,
                :OLD.CPS_NEGATIVEBAL_MSG,
                :OLD.CPS_HIGHAUTHAMT_MSG,
                :OLD.CPS_DAILYBAL_MSG,
                :OLD.CPS_INSUFFUND_MSG,
                :OLD.CPS_INCORRECTPIN_MSG,
                :OLD.CPS_INCORRECTPIN_IVR_MSG,
                :OLD.CPS_INCORRECTPIN_CHW_MSG,
        :OLD.CPS_FAST50_FLAG, -- Added By MageshKumar.S for jh-6 on 18 SEP 13
        :OLD.CPS_FAST50_MSG, -- Added By MageshKumar.S for jh-6 on 18 SEP 13
        :OLD.CPS_FEDTAX_REFUND_FLAG, -- Added By MageshKumar.S for jh-6 on 18 SEP 13
        :OLD.CPS_FEDTAX_REFUND_MSG, -- Added By MageshKumar.S for jh-6 on 18 SEP 13
        :OLD.CPS_MOBUPDATE_FLAG,  -- Added By Siva Arcot for jh-7 on 08-oct-2013
        :OLD.CPS_MOBUPDATE_MSG , -- Added By Siva Arcot for jh-7 on 08-oct-2013
        :OLD.CPS_CARDTOCARD_TRANS_FLAG, --Added By Dayanand for MANTIS-13558  on 28-jan-2014
            :OLD.CPS_CARDTOCARD_TRANS_MSG, --Added By Dayanand for MANTIS-13558 on 28-jan-2014 
        :OLD.CPS_KYCFAIL_FLAG, --Added By Dayanand for SPIL3.0 on 07-feb-2014
        :OLD.CPS_KYCFAIL_MSG, --Added By Dayanand for SPIL3.0 on 07-feb-2014
        :OLD.CPS_KYCSUCCESS_FLAG,--Added By Dayanand for SPIL3.0 on 07-feb-2014
        :OLD.CPS_KYCSUCCESS_MSG,--Added By Dayanand for SPIL3.0 on 07-feb-2014
        :OLD.CPS_RENEWALALT_FLAG, --Added for MVCSD-4121 and FWR-43 on 13-Mar-2014
        :OLD.CPS_RENEWALALT_MSG, --Added for MVCSD-4121 and FWR-43 on 13-Mar-2014
        :OLD.CPS_CHKPENDING_FLAG, --Added For FR 3.2 on 30-Jul-2014
        :OLD.CPS_CHKPENDING_MSG, --Added For FR 3.2 on 30-Jul-2014
        :OLD.CPS_CHKAPPROVED_FLAG, --Added For FR 3.2 on 30-Jul-2014
        :OLD.CPS_CHKAPPROVED_MSG, --Added For FR 3.2 on 30-Jul-2014
        :OLD.CPS_CHKREJECTED_FLAG, --Added For FR 3.2 on 30-Jul-2014
        :OLD.CPS_CHKREJECTED_MSG, --Added For FR 3.2 on 30-Jul-2014
        :OLD.CPS_ALERT_LANG_ID, --Added for FWR-59
         :OLD.CPS_ALERT_ID, --Added for FWR-59
         :OLD.CPS_ALERT_MSG, --Added for FWR-59
         :OLD.CPS_DEFALERT_LANG_FLAG --Added for FWR-59
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
                                  'Error While Update Audit for PRODCATG_SMSEMAIL_ALERTS '
                               || SQLERRM
                              );
   WHEN delete_audit
   THEN
      raise_application_error
                             (-20002,
                                 'Error While Delete  Audit for PRODCATG_SMSEMAIL_ALERTS '
                              || v_errm
                             );
END;                                                  --EN Trigger body begins
/
SHOW ERROR;