create or replace
TRIGGER "VMSCMS"."TRG_AUDTADDR_MAST" 
   AFTER INSERT OR UPDATE
   ON vmscms.CMS_ADDR_MAST
   FOR EACH ROW
DECLARE
   l_errmsg      VARCHAR2 (500) := '0K';
   l_action      VARCHAR2 (2);
   l_tbl_id      NUMBER (5);
   l_rrn          vms_audittxn_dtls.vad_rrn%TYPE;
   l_del_chnnl   vms_audittxn_dtls.vad_del_chnnl%TYPE;
   l_txn_code    vms_audittxn_dtls.vad_txn_code%TYPE;
   l_cust_code   vms_audittxn_dtls.vad_cust_code%TYPE;
   l_action_user  vms_audittxn_dtls.vad_action_user%TYPE;
   l_action_username  vms_audittxn_dtls.vad_action_username%TYPE;

   excp_error    EXCEPTION;

   TYPE rec_trg_info IS RECORD
   (
      col_name    VARCHAR2 (60),
      old_value   VARCHAR2 (1000),
      new_value   VARCHAR2 (1000)
   );

   TYPE tab_trg_info IS TABLE OF rec_trg_info INDEX BY BINARY_INTEGER;

   l_trg_info    tab_trg_info;
BEGIN
   BEGIN
      SELECT vam_table_id
        INTO l_tbl_id
        FROM vms_audit_mast
       WHERE vam_table_name = 'CMS_ADDR_MAST';
   EXCEPTION
      WHEN OTHERS THEN
         RETURN;
   END;

   SELECT vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user, vad_action_username
     INTO l_rrn, l_del_chnnl, l_txn_code, l_cust_code, l_action_user, l_action_username
     FROM vms_audittxn_dtls;

   l_trg_info (1).col_name := 'CAM_ADD_ONE';
   l_trg_info (2).col_name := 'CAM_ADD_TWO';
   l_trg_info (3).col_name := 'CAM_CITY_NAME';
   l_trg_info (4).col_name := 'CAM_CNTRY_CODE';
   l_trg_info (5).col_name := 'CAM_STATE_CODE';
   l_trg_info (6).col_name := 'CAM_PIN_CODE';
   l_trg_info (7).col_name := 'CAM_MOBL_ONE';
   l_trg_info (8).col_name := 'CAM_PHONE_ONE';
   l_trg_info (9).col_name := 'CAM_EMAIL';

   IF INSERTING
   THEN
      l_action := 'I';
      l_trg_info (1).new_value := :NEW.cam_add_one;
      l_trg_info (2).new_value := :NEW.cam_add_two;
      l_trg_info (3).new_value := :NEW.cam_city_name;
      l_trg_info (4).new_value := :NEW.cam_cntry_code;
      l_trg_info (5).new_value := :NEW.cam_cntry_code||'-'||:NEW.cam_state_code;
      l_trg_info (6).new_value := :NEW.cam_pin_code;
      l_trg_info (7).new_value := :NEW.cam_mobl_one;
      l_trg_info (8).new_value := :NEW.cam_phone_one;
      l_trg_info (9).new_value := :NEW.cam_email;
   END IF;

   IF UPDATING
   THEN
      l_action := 'U';
      l_trg_info (1).old_value := :OLD.cam_add_one;
      l_trg_info (2).old_value := :OLD.cam_add_two;
      l_trg_info (3).old_value := :OLD.cam_city_name;
      l_trg_info (4).old_value := :OLD.cam_cntry_code;
      l_trg_info (5).old_value := :OLD.cam_cntry_code||'-'||:OLD.cam_state_code;
      l_trg_info (6).old_value := :OLD.cam_pin_code;
      l_trg_info (7).old_value := :OLD.cam_mobl_one;
      l_trg_info (8).old_value := :OLD.cam_phone_one;
      l_trg_info (9).old_value := :OLD.cam_email;

      l_trg_info (1).new_value := :NEW.cam_add_one;
      l_trg_info (2).new_value := :NEW.cam_add_two;
      l_trg_info (3).new_value := :NEW.cam_city_name;
      l_trg_info (4).new_value := :NEW.cam_cntry_code;
      l_trg_info (5).new_value := :NEW.cam_cntry_code||'-'||:NEW.cam_state_code;
      l_trg_info (6).new_value := :NEW.cam_pin_code;
      l_trg_info (7).new_value := :NEW.cam_mobl_one;
      l_trg_info (8).new_value := :NEW.cam_phone_one;
      l_trg_info (9).new_value := :NEW.cam_email;
   END IF;

   FOR i IN 1 .. l_trg_info.COUNT
   LOOP
   IF NOT ( :New.cam_addr_flag = 'O' AND ( l_trg_info (i).col_name = 'CAM_MOBL_ONE' OR l_trg_info (i).col_name = 'CAM_PHONE_ONE' OR l_trg_info (i).col_name = 'CAM_EMAIL') )
   THEN
      IF (l_action = 'U' AND (NVL (l_trg_info (i).old_value, 0) <> NVL (l_trg_info (i).new_value, 0))) OR (l_action = 'I' AND l_trg_info (i).new_value IS NOT NULL)
      THEN
         BEGIN
            INSERT INTO VMS_AUDIT_INFO (vai_rrn, vai_del_chnnl, vai_txn_code,
                                        vai_cust_code, vai_table_id, vai_column_name,
                                        vai_old_val, vai_new_val, vai_action_type,
                                        vai_action_user, vai_action_date, vai_action_username)
                 VALUES (l_rrn, l_del_chnnl, l_txn_code,
                         nvl(l_cust_code,:NEW.cam_cust_code), l_tbl_id, :New.cam_addr_flag||'-'||l_trg_info (i).col_name,
                         TO_CHAR (l_trg_info (i).old_value), TO_CHAR (l_trg_info (i).new_value), l_action,
                         l_action_user, SYSDATE, l_action_username);
         EXCEPTION
            WHEN OTHERS THEN
               l_errmsg := 'While inserting in Audit Table-' || SUBSTR (SQLERRM, 1, 250);
               RAISE excp_error;
         END;
      END IF;
    END IF;  
   END LOOP;
EXCEPTION
   WHEN excp_error THEN
      raise_application_error (-20001, 'Error - ' || l_errmsg);
   WHEN NO_DATA_FOUND THEN
      RETURN;
   WHEN OTHERS THEN
      l_errmsg := 'Main Error  - ' || SUBSTR (SQLERRM, 1, 250);
      raise_application_error (-20002, l_errmsg);
END;
/
show error
