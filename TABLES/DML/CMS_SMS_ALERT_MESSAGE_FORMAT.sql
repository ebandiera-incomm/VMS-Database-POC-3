DECLARE
   v_chk_tab   VARCHAR2 (10);
   v_err       VARCHAR2 (1000);
   v_cnt       NUMBER (2);
BEGIN
   SELECT COUNT (1)
     INTO v_chk_tab
     FROM all_objects
    WHERE owner = 'VMSCMS'
      AND object_type = 'TABLE'
      AND object_name = 'CMS_SMS_ALERT_MSG4MAT_R1705B2';

   IF v_chk_tab = 1
   THEN
      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_sms_alert_message_format
       WHERE csf_inst_code = 1 AND csf_alert_type = 'Token Provisioning Successful';

      IF v_cnt = 0
      THEN
        INSERT INTO vmscms.CMS_SMS_ALERT_MSG4MAT_R1705B2(CSF_ALERT_ID,CSF_CONFIG_FLAG,CSF_INST_CODE,CSF_ALERT_TYPE,CSF_MSG_FORMAT,CSF_INS_USER,CSF_INS_DATE,CSF_CONFIGURED_TOKENS)
VALUES(31,'Y',1,'Token Provisioning Successful','Token has been provisioned Successfully',1,SYSDATE,'<<LAST 4 DIGITS OF CARD NUMBER>>~<<TOKEN DEVICE NAME>>~<<TOKEN DEVICE ID>>~<<TOKEN DEVICE NUMBER>>');
      END IF;

      SELECT COUNT (1)
        INTO v_cnt
        FROM vmscms.cms_sms_alert_message_format
       WHERE csf_inst_code = 1 AND csf_alert_type = 'Token Provisioning Failure';

      IF v_cnt = 0
      THEN
        INSERT INTO vmscms.CMS_SMS_ALERT_MSG4MAT_R1705B2(CSF_ALERT_ID,CSF_CONFIG_FLAG,CSF_INST_CODE,CSF_ALERT_TYPE,CSF_MSG_FORMAT,CSF_INS_USER,CSF_INS_DATE,CSF_CONFIGURED_TOKENS)
VALUES(32,'Y',1,'Token Provisioning Failure','Token provisoning failed due to invalid data',1,SYSDATE,'<<LAST 4 DIGITS OF CARD NUMBER>>~<<TOKEN DEVICE NAME>>~<<TOKEN DEVICE ID>>~<<TOKEN DEVICE NUMBER>>');
      END IF;

      
      INSERT INTO vmscms.cms_sms_alert_message_format
         SELECT *
           FROM vmscms.CMS_SMS_ALERT_MSG4MAT_R1705B2
          WHERE (csf_inst_code, csf_alert_type) NOT IN (
                                      SELECT csf_inst_code, csf_alert_type
                                        FROM vmscms.cms_sms_alert_message_format);

      DBMS_OUTPUT.put_line (SQL%ROWCOUNT || ' rows inserted ');
   ELSE
      DBMS_OUTPUT.put_line ('Backup Object Not Found');
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      v_err := SUBSTR (SQLERRM, 1, 100);
      DBMS_OUTPUT.put_line ('Main Excp ' || v_err);
END;
/
