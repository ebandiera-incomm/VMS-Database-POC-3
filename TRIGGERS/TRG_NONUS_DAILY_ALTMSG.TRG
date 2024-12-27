
  CREATE OR REPLACE TRIGGER "VMSCMS"."TRG_NONUS_DAILY_ALTMSG" 
   AFTER UPDATE
   ON VMS_NONUS_DAILY_ALTMSG    FOR EACH ROW
DECLARE
   v_status   char(1);
   /*************************************************
     * Created Date       : 03/Feb/2016
     * PURPOSE          : this trigger is used to maintain history details of sms/email send for Canada
 ***********************************************/
BEGIN
    v_status   := :NEW.VND_PROCESS_STATUS;
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
  VALUES(	:NEW.VND_INST_CODE,
          :NEW.VND_SERIAL_NO,
			  	:NEW.VND_PAN_CODE,
  				:NEW.VND_PAN_CODE_ENCR,
  				:NEW.VND_MOBILE_NUMBER,
  				:NEW.VND_EMAIL,
  				:NEW.VND_DAILYBAL_MSG,
  				:NEW.VND_LOWBAL_MSG,
  				:NEW.VND_INS_DATE,
  				:NEW.VND_BEGIN_INTERVAL,
  				:NEW.VND_END_INTERVAL,
  				:NEW.VND_PROCESS_STATUS,
  				:NEW.VND_PROCESS_DATE
                     );
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      RAISE_APPLICATION_ERROR (-20003,
                                  'WHILE INSERT RECORD INTO vms_nonus_daily_altmsg_HIST'
                               || SQLERRM
                              );
END;

ALTER TRIGGER "VMSCMS"."TRG_NONUS_DAILY_ALTMSG" ENABLE
 