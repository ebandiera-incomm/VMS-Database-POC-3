--insert script for Token provisioning Successful 
DECLARE
  v_err VARCHAR2(500);
  CURSOR cur_smsemail_msg
  IS
    SELECT DISTINCT CPS_ALERT_LANG_ID,cps_card_type,CPS_DEFALERT_LANG_FLAG,
      CPS_INST_CODE,
      cps_prod_code
    FROM vmscms.CMS_PRODCATG_SMSEMAIL_ALERTS;
BEGIN
  FOR I IN cur_smsemail_msg
  LOOP
 
    INSERT
    INTO vmscms.CMS_PRODCATG_SMSEMAIL_ALERTS
      (
        CPS_INST_CODE,
        CPS_PROD_CODE,
        CPS_CARD_TYPE,
        CPS_CONFIG_FLAG,
        CPS_OPTINOPTOUT_STATUS,
        CPS_DEFALERT_LANG_FLAG,
        CPS_ALERT_LANG_ID,
        CPS_ALERT_ID,
        CPS_ALERT_MSG,
        CPS_INS_USER,
        CPS_INS_DATE
      )
      VALUES
      (
        I.CPS_INST_CODE,
        I.cps_prod_code,
        I.cps_card_type,
        'Y',
        1,
        I.CPS_DEFALERT_LANG_FLAG,
        i.CPS_ALERT_LANG_ID,31,
        '0~Token has been provisioned Successfully~Token has been provisioned Successfully',
        1,
        sysdate
      );
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  v_err:=SUBSTR(sqlerrm,1,200);
  dbms_output.put_line(v_err);
END;
/

--insert script for Token provisioning Failure

DECLARE
  v_err VARCHAR2(500);
  CURSOR cur_smsemail_msg
  IS
    SELECT DISTINCT CPS_ALERT_LANG_ID,cps_card_type,CPS_DEFALERT_LANG_FLAG,
      CPS_INST_CODE,
      cps_prod_code
    FROM vmscms.CMS_PRODCATG_SMSEMAIL_ALERTS;
BEGIN
  FOR I IN cur_smsemail_msg
  LOOP
 
    INSERT
    INTO vmscms.CMS_PRODCATG_SMSEMAIL_ALERTS
      (
        CPS_INST_CODE,
        CPS_PROD_CODE,
        CPS_CARD_TYPE,
        CPS_CONFIG_FLAG,
        CPS_OPTINOPTOUT_STATUS,
        CPS_DEFALERT_LANG_FLAG,
        CPS_ALERT_LANG_ID,
        CPS_ALERT_ID,
        CPS_ALERT_MSG,
        CPS_INS_USER,
        CPS_INS_DATE
      )
      VALUES
      (
        I.CPS_INST_CODE,
        I.cps_prod_code,
        I.cps_card_type,
        'Y',
        1,
        I.CPS_DEFALERT_LANG_FLAG,
        i.CPS_ALERT_LANG_ID,32,
        '0~Token provisoning failed due to invalid data~Token provisoning failed due to invalid data',
        1,
        sysdate
      );
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  v_err:=SUBSTR(sqlerrm,1,200);
  dbms_output.put_line(v_err);
END;
/

