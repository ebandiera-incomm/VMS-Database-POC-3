CREATE OR REPLACE TRIGGER VMSCMS.trg_hsm_servemast AFTER
  INSERT OR
  UPDATE ON hsm_server_master FOR EACH row
DISABLE
DECLARE
  ERRMSG  VARCHAR2(1000);
  BEGIN
  ERRMSG :='OK';
    BEGIN
    --raise_application_error(-20004,'inst code is '|| :new.HSM_INST_CODE ||' '|| :new.hsm_number);
      UPDATE hsm_config_master
      SET hcm_number     = :new.hsm_number
      WHERE hcm_inst_code=:new.HSM_INST_CODE
      and hsm_process in('CVV','AUTH','PIN');
      EXCEPTION 
      WHEN no_data_found THEN
        BEGIN
          INSERT
          INTO hsm_config_master
            (
              HCM_NUMBER,
              HSM_PROCESS,
              HCM_LUPD_DATE,
              HCM_INST_CODE,
              HCM_LUPD_USER,
              HCM_INS_DATE,
              HCM_INS_USER
            )
            VALUES
            (
              :new.hsm_number,
              'CVV',
              SYSDATE,
              :new.hsm_inst_code,
              :new.hsm_ins_user,
              SYSDATE,
              :new.hsm_ins_user
            );
          INSERT
          INTO hsm_config_master
            (
              HCM_NUMBER,
              HSM_PROCESS,
              HCM_LUPD_DATE,
              HCM_INST_CODE,
              HCM_LUPD_USER,
              HCM_INS_DATE,
              HCM_INS_USER
            )
            VALUES
            (
              :new.hsm_number,
              'AUTH',
              SYSDATE,
              :new.hsm_inst_code,
              :new.hsm_ins_user,
              SYSDATE,
              :new.hsm_ins_user
            );
          INSERT
          INTO hsm_config_master
            (
              HCM_NUMBER,
              HSM_PROCESS,
              HCM_LUPD_DATE,
              HCM_INST_CODE,
              HCM_LUPD_USER,
              HCM_INS_DATE,
              HCM_INS_USER
            )
            VALUES
            (
              :new.hsm_number,
              'PIN',
              SYSDATE,
              :new.hsm_inst_code,
              :new.hsm_ins_user,
              SYSDATE,
              :new.hsm_ins_user
            );
        EXCEPTION WHEN OTHERS THEN
          ERRMSG := 'Error while inserting in config master '||substr(sqlerrm,1,200);
          raise_application_error(-20003,ERRMSG);
        END;
      WHEN OTHERS THEN 
        ERRMSG := 'Error while updating config table '||substr(sqlerrm,1,500);
        dbms_output.put_line(ERRMSG);
        raise_application_error(-20002,ERRMSG);
      END;
  EXCEPTION WHEN OTHERS THEN
    ERRMSG := 'Error while inserting data in server maste table '||substr(sqlerrm,1,500);
    dbms_output.put_line(ERRMSG);
    raise_application_error(-20001,ERRMSG);
  END;
/


