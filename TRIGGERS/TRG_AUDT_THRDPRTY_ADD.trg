CREATE OR REPLACE TRIGGER VMSCMS.TRG_AUDT_THRDPRTY_ADD
   AFTER INSERT OR UPDATE
   ON vmscms.vms_thirdparty_address
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
   l_occu_name  vms_occupation_mast.VOM_OCCU_name%TYPE;

   TYPE rec_trg_info IS RECORD
   (
      col_name    vms_audit_info.VAI_COLUMN_NAME%type,
      old_value   vms_audit_info.VAI_OLD_VAL%type,
      new_value   vms_audit_info.VAI_NEW_VAL%type
   );

   TYPE tab_trg_info IS TABLE OF rec_trg_info INDEX BY BINARY_INTEGER;

   l_trg_info    tab_trg_info;
BEGIN
   BEGIN
      SELECT vam_table_id
        INTO l_tbl_id
        FROM vms_audit_mast
       WHERE vam_table_name = 'VMS_THIRDPARTY_ADDRESS';
   EXCEPTION
      WHEN OTHERS THEN
         RETURN;
   END;

   SELECT vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user, vad_action_username
     INTO l_rrn, l_del_chnnl, l_txn_code, l_cust_code, l_action_user, l_action_username
     FROM VMS_AUDITTXN_DTLS;


   l_trg_info (1).col_name := 'VTA_THIRDPARTY_TYPE';
   l_trg_info (2).col_name := 'VTA_FIRST_NAME';
   l_trg_info (3).col_name := 'VTA_LAST_NAME';
   l_trg_info (4).col_name := 'VTA_ADDRESS_ONE';
   l_trg_info (5).col_name := 'VTA_ADDRESS_TWO';
   l_trg_info (6).col_name := 'VTA_CITY_NAME';
   l_trg_info (7).col_name := 'VTA_STATE_CODE';  
   l_trg_info (8).col_name := 'VTA_STATE_DESC';
   l_trg_info (9).col_name := 'VTA_CNTRY_CODE';
   l_trg_info (10).col_name := 'VTA_PIN_CODE';
   l_trg_info (11).col_name := 'VTA_OCCUPATION';
   l_trg_info (12).col_name := 'VTA_OCCUPATION_OTHERS';
   l_trg_info (13).col_name := 'VTA_NATURE_OF_BUSINESS';
   l_trg_info (14).col_name := 'VTA_DOB';
   l_trg_info (15).col_name := 'VTA_NATURE_OF_RELEATIONSHIP';
   l_trg_info (16).col_name := 'VTA_CORPORATION_NAME';
   l_trg_info (17).col_name := 'VTA_INCORPORATION_NUMBER';





   IF INSERTING
   THEN
      l_action := 'I';
      l_trg_info (1).new_value := :NEW.VTA_THIRDPARTY_TYPE;
      l_trg_info (2).new_value := :NEW.VTA_FIRST_NAME;
      l_trg_info (3).new_value := :NEW.VTA_LAST_NAME;
      l_trg_info (4).new_value := :NEW.VTA_ADDRESS_ONE;                                  
      l_trg_info (5).new_value := :NEW.VTA_ADDRESS_TWO;
      l_trg_info (6).new_value := :NEW.VTA_CITY_NAME;
      l_trg_info (7).new_value := :NEW.VTA_cntry_code||'-'||:NEW.VTA_STATE_CODE;    
      l_trg_info (8).new_value := :NEW.VTA_STATE_DESC;                             
      l_trg_info (9).new_value := to_char(:NEW.VTA_cntry_code);
      l_trg_info (10).new_value := :NEW.VTA_PIN_CODE;
      l_trg_info (11).new_value := :NEW.VTA_OCCUPATION;
      select VOM_OCCU_name into l_occu_name from vms_occupation_mast where VOM_OCCU_CODE=:NEW.VTA_OCCUPATION;
      l_trg_info (12).new_value := case when :NEW.VTA_OCCUPATION= '00' then
                                   :NEW.VTA_OCCUPATION_OTHERS
                                  else
                                   l_occu_name end;
      l_trg_info (13).new_value := :NEW.VTA_NATURE_OF_BUSINESS;
      l_trg_info (14).new_value := to_char(:NEW.VTA_DOB,'mm/dd/yyyy');   
      l_trg_info (15).new_value := :NEW.VTA_NATURE_OF_RELEATIONSHIP;          
      l_trg_info (16).new_value := :NEW.VTA_CORPORATION_NAME;
	  l_trg_info (17).new_value := :NEW.VTA_INCORPORATION_NUMBER;
    
      
   END IF;

   IF UPDATING
   THEN
      l_action := 'U';
      l_trg_info (1).old_value := :OLD.VTA_THIRDPARTY_TYPE;
      l_trg_info (2).old_value := :OLD.VTA_FIRST_NAME;
      l_trg_info (3).old_value := :OLD.VTA_LAST_NAME;
      l_trg_info (4).old_value := :OLD.VTA_ADDRESS_ONE;                                  
      l_trg_info (5).old_value := :OLD.VTA_ADDRESS_TWO;
      l_trg_info (6).old_value := :OLD.VTA_CITY_NAME;
      l_trg_info (7).old_value := :OLD.VTA_cntry_code||'-'||:OLD.VTA_STATE_CODE;     
      l_trg_info (8).old_value := :OLD.VTA_STATE_DESC;                             
      l_trg_info (9).old_value := to_char(:OLD.VTA_CNTRY_CODE);
      l_trg_info (10).old_value := :OLD.VTA_PIN_CODE;
      l_trg_info (11).old_value := :OLD.VTA_OCCUPATION;
      select VOM_OCCU_name into l_occu_name from vms_occupation_mast where VOM_OCCU_CODE=:OLD.VTA_OCCUPATION;
      l_trg_info (12).old_value := case when :OLD.VTA_OCCUPATION= '00' then
                                   :OLD.VTA_OCCUPATION_OTHERS
                                  else
                                   l_occu_name end;
      l_trg_info (13).old_value := :OLD.VTA_NATURE_OF_BUSINESS;
      l_trg_info (14).old_value := to_char(:OLD.VTA_DOB,'mm/dd/yyyy');   
      l_trg_info (15).old_value := :OLD.VTA_NATURE_OF_RELEATIONSHIP;          
      l_trg_info (16).old_value := :OLD.VTA_CORPORATION_NAME;
	    l_trg_info (17).old_value := :OLD.VTA_INCORPORATION_NUMBER;

     
      l_trg_info (1).new_value := :NEW.VTA_THIRDPARTY_TYPE;
      l_trg_info (2).new_value := :NEW.VTA_FIRST_NAME;
      l_trg_info (3).new_value := :NEW.VTA_LAST_NAME;
      l_trg_info (4).new_value := :NEW.VTA_ADDRESS_ONE;                                  
      l_trg_info (5).new_value := :NEW.VTA_ADDRESS_TWO;
      l_trg_info (6).new_value := :NEW.VTA_CITY_NAME;
      l_trg_info (7).new_value := :NEW.VTA_cntry_code||'-'||:NEW.VTA_STATE_CODE;    
      l_trg_info (8).new_value := :NEW.VTA_STATE_DESC;                             
      l_trg_info (9).new_value := to_char(:NEW.VTA_CNTRY_CODE);
      l_trg_info (10).new_value := :NEW.VTA_PIN_CODE;
      l_trg_info (11).new_value := :NEW.VTA_OCCUPATION;
      select VOM_OCCU_name into l_occu_name from vms_occupation_mast where VOM_OCCU_CODE=:NEW.VTA_OCCUPATION;
      l_trg_info (12).new_value := case when :NEW.VTA_OCCUPATION= '00' then
                                   :NEW.VTA_OCCUPATION_OTHERS
                                  else
                                   l_occu_name end;
      l_trg_info (13).new_value := :NEW.VTA_NATURE_OF_BUSINESS;
      l_trg_info (14).new_value := to_char(:NEW.VTA_DOB,'mm/dd/yyyy');   
      l_trg_info (15).new_value := :NEW.VTA_NATURE_OF_RELEATIONSHIP;          
      l_trg_info (16).new_value := :NEW.VTA_CORPORATION_NAME;
	  l_trg_info (17).new_value := :NEW.VTA_INCORPORATION_NUMBER;
      
   END IF;

   FOR i IN 1 .. l_trg_info.COUNT
   LOOP
      IF (l_action = 'U' AND (NVL (l_trg_info (i).old_value, '0') <> NVL (l_trg_info (i).new_value, '0'))) OR (l_action = 'I' AND l_trg_info (i).new_value IS NOT NULL)
      THEN
         BEGIN
            INSERT INTO VMS_AUDIT_INFO (vai_rrn, vai_del_chnnl, vai_txn_code,
                                        vai_cust_code, vai_table_id, vai_column_name,
                                        vai_old_val, vai_new_val, vai_action_type,
                                        vai_action_user, vai_action_date, vai_action_username)
                 VALUES (l_rrn, l_del_chnnl, l_txn_code,
                         nvl(l_cust_code,:NEW.vta_cust_code), l_tbl_id, l_trg_info (i).col_name,
                         TO_CHAR (l_trg_info (i).old_value), TO_CHAR (l_trg_info (i).new_value), l_action,
                         l_action_user, SYSDATE, l_action_username);
         EXCEPTION
            WHEN OTHERS THEN
               l_errmsg := 'While inserting in Audit Table-' || SUBSTR (SQLERRM, 1, 250);
               RAISE excp_error;
         END;
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
show error;