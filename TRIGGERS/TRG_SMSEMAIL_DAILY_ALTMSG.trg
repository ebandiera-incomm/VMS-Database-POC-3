CREATE OR REPLACE TRIGGER VMSCMS.trg_SMSEMAIL_DAILY_ALTMSG
   AFTER UPDATE
   ON VMSCMS.CMS_SMSEMAIL_DAILY_ALTMSG    FOR EACH ROW
DECLARE
   v_status   char(1);
   /*************************************************
     * Created Date       : 21/Dec/2011
     * PURPOSE          : this trigger is used to maintain history details of sms/email send
 ***********************************************/
BEGIN
    v_status   := :NEW.CSD_PROCESS_STATUS;
   IF (v_status ='Y')
   THEN
  INSERT INTO CMS_SMSEMAIL_DAILY_ALTMSG_HIST
        (	CSD_INST_CODE,
  				CSD_SERIAL_NO,
				  CSD_PAN_CODE,
  				CSD_PAN_CODE_ENCR,
  				CSD_MOBILE_NUMBER,
  				CSD_EMAIL,
  				CSD_DAILYBAL_MSG,
  				CSD_LOWBAL_MSG,
  				CSD_INS_DATE,
  				CSD_BEGIN_INTERVAL,
  				CSD_END_INTERVAL,
  				CSD_PROCESS_STATUS,
  				CSD_PROCESS_DATE
                     )
  VALUES(	:NEW.CSD_INST_CODE,
          :NEW.CSD_SERIAL_NO,
			  	:NEW.CSD_PAN_CODE,
  				:NEW.CSD_PAN_CODE_ENCR,
  				:NEW.CSD_MOBILE_NUMBER,
  				:NEW.CSD_EMAIL,
  				:NEW.CSD_DAILYBAL_MSG,
  				:NEW.CSD_LOWBAL_MSG,
  				:NEW.CSD_INS_DATE,
  				:NEW.CSD_BEGIN_INTERVAL,
  				:NEW.CSD_END_INTERVAL,
  				:NEW.CSD_PROCESS_STATUS,
  				:NEW.CSD_PROCESS_DATE
                     );
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      RAISE_APPLICATION_ERROR (-20003,
                                  'WHILE INSERT RECORD INTO cms_smsemail_daily_altmsg_HIST'
                               || SQLERRM
                              );
END;
/


