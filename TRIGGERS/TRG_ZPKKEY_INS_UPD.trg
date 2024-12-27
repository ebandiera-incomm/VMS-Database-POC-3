CREATE OR REPLACE TRIGGER VMSCMS.TRG_ZPKKEY_INS_UPD
AFTER INSERT OR UPDATE
ON VMSCMS.CMS_KEY_MASTER FOR EACH ROW
/*************************************************
     * Created Date     :  04-OCT-2013
     * Created By       :  Kaleeswaran P
     * PURPOSE          :  To Maintian Key Master details
 *************************************************/
DECLARE
    v_ins_date DATE :=sysdate;
    v_upd_date DATE :=sysdate;
    insert_data EXCEPTION;
    update_data EXCEPTION;

BEGIN
    IF INSERTING
        THEN
            BEGIN
                INSERT INTO CMS_KEY_MASTER_HIST
                (
                    CKM_KEK_ENCR,
                    CKM_DEK_ENCR,
                    CKM_SERVICE_TYPE,
                    CKM_BIN,
                    CKM_INS_USER,
                    CKM_INS_DATE,
                    CKM_LUPD_USER,
                    CKM_LUPD_DATE,
                    CKM_INST_CODE,
                    CKM_HSM_TYPE,
                    CKM_HSM_NUMBER,
                    CKM_INTERFACE_CODE,
                    PROCESS_TYPE
                 )
                VALUES
                (
                  :NEW.CKM_KEK_ENCR,
                  :NEW.CKM_DEK_ENCR,
                  :NEW.CKM_SERVICE_TYPE,
                  :NEW.CKM_BIN,
                  :NEW.CKM_INS_USER,
                  v_ins_date,
                  :NEW.CKM_LUPD_USER,
                  :NEW.CKM_LUPD_DATE,
                  :NEW.CKM_INST_CODE,
                  :NEW.CKM_HSM_TYPE,
                  :NEW.CKM_HSM_NUMBER,
                  :NEW.CKM_INTERFACE_CODE,
                  'I'
                );

        EXCEPTION
          WHEN OTHERS
        THEN
            RAISE insert_data;
        END;

    ELSIF UPDATING
        Then
            BEGIN
                INSERT INTO CMS_KEY_MASTER_HIST
                (
                    CKM_KEK_ENCR,
                    CKM_DEK_ENCR,
                    CKM_SERVICE_TYPE,
                    CKM_BIN,
                    CKM_INS_USER,
                    CKM_INS_DATE,
                    CKM_LUPD_USER,
                    CKM_LUPD_DATE,
                    CKM_INST_CODE,
                    CKM_HSM_TYPE,
                    CKM_HSM_NUMBER,
                    CKM_INTERFACE_CODE,
                    CKM_DEK_ENCR_NEWKEY,
                    PROCESS_TYPE
                )
               VALUES
                (
                    :OLD.CKM_KEK_ENCR,
                    :OLD.CKM_DEK_ENCR,
                    :OLD.CKM_SERVICE_TYPE,
                    :OLD.CKM_BIN,
                    :OLD.CKM_INS_USER,
                    :OLD.CKM_INS_DATE,
                    :OLD.CKM_LUPD_USER,
                    v_upd_date,
                    :OLD.CKM_INST_CODE,
                    :OLD.CKM_HSM_TYPE,
                    :OLD.CKM_HSM_NUMBER,
                    :OLD.CKM_INTERFACE_CODE,
                    :NEW.CKM_DEK_ENCR,
                    'U'
                );

        EXCEPTION
          WHEN OTHERS
        THEN
            RAISE update_data;
        END;

    END IF;

        EXCEPTION
        WHEN insert_data THEN
            raise_application_error (-20001,'Error While Inserting Details for Keys_Mast ' || SQLERRM );
        WHEN update_data THEN
            raise_application_error (-20001,'Error While Updating Details for Keys_Mast ' || SQLERRM );
END;
/
SHOW ERRORS;


