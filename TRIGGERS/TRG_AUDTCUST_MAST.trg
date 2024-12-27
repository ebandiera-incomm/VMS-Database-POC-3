CREATE OR REPLACE TRIGGER VMSCMS.TRG_AUDTCUST_MAST
   AFTER INSERT OR UPDATE
   ON vmscms.CMS_CUST_MAST
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
   l_reason_no_tax  vms_param_config_mast.vpc_param_name%TYPE;
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
       WHERE vam_table_name = 'CMS_CUST_MAST';
   EXCEPTION
      WHEN OTHERS THEN
         RETURN;
   END;

   SELECT vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user,vad_action_username
     INTO l_rrn, l_del_chnnl, l_txn_code, l_cust_code, l_action_user, l_action_username
     FROM VMS_AUDITTXN_DTLS;

   l_trg_info (1).col_name := 'CCM_FIRST_NAME';
   l_trg_info (2).col_name := 'CCM_LAST_NAME';
   l_trg_info (3).col_name := 'CCM_SSN';
   l_trg_info (4).col_name := 'CCM_BIRTH_DATE';
   l_trg_info (5).col_name := 'CCM_AUTH_USER';
   l_trg_info (6).col_name := 'CCM_OCCUPATION';
   l_trg_info (7).col_name := 'CCM_ID_PROVINCE';
   l_trg_info (8).col_name := 'CCM_ID_COUNTRY';
   l_trg_info (9).col_name := 'CCM_VERIFICATION_DATE';
   l_trg_info (10).col_name := 'CCM_TAX_RES_OF_CANADA';
   l_trg_info (11).col_name := 'CCM_TAX_PAYER_ID_NUM';
   l_trg_info (12).col_name := 'CCM_REASON_FOR_NO_TAX_ID';
   l_trg_info (13).col_name := 'CCM_JURISDICTION_OF_TAX_RES';
   l_trg_info (14).col_name := 'CCM_OCCUPATION_OTHERS';
   l_trg_info (15).col_name := 'CCM_ID_TYPE';
   l_trg_info (16).col_name := 'CCM_IDEXPRY_DATE';
   l_trg_info (17).col_name := 'CCM_THIRD_PARTY_ENABLED';
   l_trg_info (18).col_name := 'CCM_REASON_FOR_NO_TAXID_OTHERS';
   l_trg_info (19).col_name := 'CCM_CANADA_CREDIT_AGENCY';
   l_trg_info (20).col_name := 'CCM_CREDIT_FILE_REF_NUMBER';
   l_trg_info (21).col_name := 'CCM_DATE_OF_VERIFICATION';

   IF INSERTING
   THEN
      l_action := 'I';
      l_trg_info (1).new_value := :NEW.ccm_first_name;
      l_trg_info (2).new_value := :NEW.ccm_last_name;
      l_trg_info (3).new_value := :NEW.ccm_ssn;
      l_trg_info (4).new_value := to_char(:NEW.ccm_birth_date,'mm/dd/yyyy');
      l_trg_info (5).new_value := :NEW.ccm_auth_user;
      l_trg_info (6).new_value := :NEW.CCM_OCCUPATION;
      l_trg_info (7).new_value := :NEW.CCM_ID_PROVINCE;
      l_trg_info (8).new_value := :NEW.CCM_ID_COUNTRY;
      l_trg_info (9).new_value := to_char(:NEW.CCM_VERIFICATION_DATE,'mm/dd/yyyy');
      l_trg_info (10).new_value := :NEW.CCM_TAX_RES_OF_CANADA;
      l_trg_info (11).new_value := :NEW.CCM_TAX_PAYER_ID_NUM;
      l_trg_info (12).new_value := :NEW.CCM_REASON_FOR_NO_TAX_ID;
      l_trg_info (13).new_value := :NEW.CCM_JURISDICTION_OF_TAX_RES;
      select VOM_OCCU_name into l_occu_name from vms_occupation_mast where VOM_OCCU_CODE=:NEW.CCM_OCCUPATION;
      l_trg_info (14).new_value := case when :NEW.CCM_OCCUPATION= '00' then
                                   :NEW.CCM_OCCUPATION_OTHERS
                                  else
                                   l_occu_name end;
      l_trg_info (15).new_value := :NEW.CCM_ID_TYPE;
      l_trg_info (16).new_value := to_char(:NEW.CCM_IDEXPRY_DATE,'mm/dd/yyyy');
      l_trg_info (17).new_value := :NEW.CCM_THIRD_PARTY_ENABLED;
      select vpc_param_name into l_reason_no_tax from vms_param_config_mast where vpc_param_type='Reason_For_Not_Having_Tax' and  VPC_PARAM_ID=:NEW.CCM_REASON_FOR_NO_TAX_ID;
	    l_trg_info (18).new_value := case when :NEW.CCM_REASON_FOR_NO_TAX_ID= '3' then
                                 :NEW.CCM_REASON_FOR_NO_TAXID_OTHERS
                                  else
                                   l_reason_no_tax end;
	  l_trg_info (19).new_value := :NEW.CCM_CANADA_CREDIT_AGENCY;
	  l_trg_info (20).new_value := :NEW.CCM_CREDIT_FILE_REF_NUMBER;
	  l_trg_info (21).new_value := to_char(:NEW.CCM_DATE_OF_VERIFICATION,'mm/dd/yyyy');
	  
      
   END IF;

   IF UPDATING
   THEN
      l_action := 'U';
      l_trg_info (1).old_value := :OLD.ccm_first_name;
      l_trg_info (2).old_value := :OLD.ccm_last_name;
      l_trg_info (3).old_value := :OLD.ccm_ssn;
      l_trg_info (4).old_value := to_char(:OLD.ccm_birth_date,'mm/dd/yyyy');
      l_trg_info (5).old_value := :OLD.ccm_auth_user;
      l_trg_info (6).old_value := :OLD.CCM_OCCUPATION;
      l_trg_info (7).old_value := :OLD.CCM_ID_PROVINCE;
      l_trg_info (8).old_value := :OLD.CCM_ID_COUNTRY;
      l_trg_info (9).old_value := to_char(:OLD.CCM_VERIFICATION_DATE,'mm/dd/yyyy');
      l_trg_info (10).old_value := :OLD.CCM_TAX_RES_OF_CANADA;
      l_trg_info (11).old_value := :OLD.CCM_TAX_PAYER_ID_NUM;
      l_trg_info (12).old_value := :OLD.CCM_REASON_FOR_NO_TAX_ID;
      l_trg_info (13).old_value := :OLD.CCM_JURISDICTION_OF_TAX_RES;
      select VOM_OCCU_name into l_occu_name from vms_occupation_mast where VOM_OCCU_CODE=:OLD.CCM_OCCUPATION;
      l_trg_info (14).old_value := case when :OLD.CCM_OCCUPATION= '00' then
                                   :OLD.CCM_OCCUPATION_OTHERS
                                  else
                                   l_occu_name end;
      l_trg_info (15).old_value := :OLD.CCM_ID_TYPE;
      l_trg_info (16).old_value := to_char(:OLD.CCM_IDEXPRY_DATE,'mm/dd/yyyy');
      l_trg_info (17).old_value := :OLD.CCM_THIRD_PARTY_ENABLED;
      select vpc_param_name into l_reason_no_tax from vms_param_config_mast where vpc_param_type='Reason_For_Not_Having_Tax' and  VPC_PARAM_ID=:OLD.CCM_REASON_FOR_NO_TAX_ID;
	    l_trg_info (18).old_value :=  case when :OLD.CCM_REASON_FOR_NO_TAX_ID= '3' then
                                    :OLD.CCM_REASON_FOR_NO_TAXID_OTHERS
                                    else
                                    l_reason_no_tax end;
	    l_trg_info (19).old_value := :OLD.CCM_CANADA_CREDIT_AGENCY;
	    l_trg_info (20).old_value := :OLD.CCM_CREDIT_FILE_REF_NUMBER;
	    l_trg_info (21).old_value := to_char(:OLD.CCM_DATE_OF_VERIFICATION,'mm/dd/yyyy');

       l_trg_info (1).new_value := :NEW.ccm_first_name;
      l_trg_info (2).new_value := :NEW.ccm_last_name;
      l_trg_info (3).new_value := :NEW.ccm_ssn;
      l_trg_info (4).new_value := to_char(:NEW.ccm_birth_date,'mm/dd/yyyy');
      l_trg_info (5).new_value := :NEW.ccm_auth_user;
      l_trg_info (6).new_value := :NEW.CCM_OCCUPATION;
      l_trg_info (7).new_value := :NEW.CCM_ID_PROVINCE;
      l_trg_info (8).new_value := :NEW.CCM_ID_COUNTRY;
      l_trg_info (9).new_value := to_char(:NEW.CCM_VERIFICATION_DATE,'mm/dd/yyyy');
      l_trg_info (10).new_value := :NEW.CCM_TAX_RES_OF_CANADA;
      l_trg_info (11).new_value := :NEW.CCM_TAX_PAYER_ID_NUM;
      l_trg_info (12).new_value := :NEW.CCM_REASON_FOR_NO_TAX_ID;
      l_trg_info (13).new_value := :NEW.CCM_JURISDICTION_OF_TAX_RES;
      select VOM_OCCU_name into l_occu_name from vms_occupation_mast where VOM_OCCU_CODE=:NEW.CCM_OCCUPATION;
      l_trg_info (14).new_value := case when :NEW.CCM_OCCUPATION= '00' then
                                   :NEW.CCM_OCCUPATION_OTHERS
                                   else
                                   l_occu_name end;
      l_trg_info (15).new_value := :NEW.CCM_ID_TYPE;
      l_trg_info (16).new_value := to_char(:NEW.CCM_IDEXPRY_DATE,'mm/dd/yyyy');
      l_trg_info (17).new_value := :NEW.CCM_THIRD_PARTY_ENABLED;
      select vpc_param_name into l_reason_no_tax from vms_param_config_mast where vpc_param_type='Reason_For_Not_Having_Tax' and  VPC_PARAM_ID=:NEW.CCM_REASON_FOR_NO_TAX_ID;
	    l_trg_info (18).new_value := case when :NEW.CCM_REASON_FOR_NO_TAX_ID= '3' then
                                 :NEW.CCM_REASON_FOR_NO_TAXID_OTHERS
                                  else
                                   l_reason_no_tax end;
	  l_trg_info (19).new_value := :NEW.CCM_CANADA_CREDIT_AGENCY;
	  l_trg_info (20).new_value := :NEW.CCM_CREDIT_FILE_REF_NUMBER;
	  l_trg_info (21).new_value := to_char(:NEW.CCM_DATE_OF_VERIFICATION,'mm/dd/yyyy');
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
                         nvl(l_cust_code,:NEW.ccm_cust_code), l_tbl_id, l_trg_info (i).col_name,
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