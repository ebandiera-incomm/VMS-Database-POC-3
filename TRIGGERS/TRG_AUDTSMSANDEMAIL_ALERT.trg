CREATE OR REPLACE TRIGGER VMSCMS.TRG_AUDTSMSANDEMAIL_ALERT
   AFTER INSERT OR UPDATE
   ON vmscms.CMS_SMSANDEMAIL_ALERT
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
   l_action_username  vms_audittxn_dtls.vad_action_user%TYPE;
   excp_error    EXCEPTION;

   TYPE rec_trg_info IS RECORD
   (
      col_name    VARCHAR2 (60),
      old_value   VARCHAR2 (60),
      new_value   VARCHAR2 (60)
   );

   TYPE tab_trg_info IS TABLE OF rec_trg_info INDEX BY BINARY_INTEGER;

   l_trg_info    tab_trg_info;
BEGIN
   BEGIN
      SELECT vam_table_id
        INTO l_tbl_id
        FROM vms_audit_mast
       WHERE vam_table_name = 'CMS_SMSANDEMAIL_ALERT';
   EXCEPTION
      WHEN OTHERS THEN
         RETURN;
   END;

   SELECT vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user, vad_action_username
     INTO l_rrn, l_del_chnnl, l_txn_code, l_cust_code, l_action_user, l_action_username
     FROM vms_audittxn_dtls;

   l_trg_info (1).col_name := 'CSA_LOADORCREDIT_FLAG';
   l_trg_info (2).col_name := 'CSA_LOWBAL_FLAG';
   l_trg_info (3).col_name := 'CSA_LOWBAL_AMT';
   l_trg_info (4).col_name := 'CSA_NEGBAL_FLAG';
   l_trg_info (5).col_name := 'CSA_HIGHAUTHAMT_FLAG';
   l_trg_info (6).col_name := 'CSA_HIGHAUTHAMT';
   l_trg_info (7).col_name := 'CSA_DAILYBAL_FLAG';
   l_trg_info (8).col_name := 'CSA_INSUFF_FLAG';
   l_trg_info (9).col_name := 'CSA_INCORRPIN_FLAG';
   l_trg_info (10).col_name := 'CSA_FAST50_FLAG';
   l_trg_info (11).col_name := 'CSA_FEDTAX_REFUND_FLAG';
   l_trg_info (12).col_name := 'CSA_ALERT_LANG_ID';

   IF INSERTING
   THEN
      l_action := 'I';
       l_trg_info (1).new_value := :NEW.CSA_LOADORCREDIT_FLAG;
       l_trg_info (2).new_value :=  :NEW.CSA_LOWBAL_FLAG;
       l_trg_info (3).new_value :=  :NEW.CSA_LOWBAL_AMT;
       l_trg_info (4).new_value :=  :NEW.CSA_NEGBAL_FLAG;
       l_trg_info (5).new_value :=  :NEW.CSA_HIGHAUTHAMT_FLAG;
       l_trg_info (6).new_value :=  :NEW.CSA_HIGHAUTHAMT;
       l_trg_info (7).new_value :=  :NEW.CSA_DAILYBAL_FLAG;
       l_trg_info (8).new_value :=  :NEW.CSA_INSUFF_FLAG;
       l_trg_info (9).new_value :=  :NEW.CSA_INCORRPIN_FLAG;
       l_trg_info (10).new_value :=  :NEW.CSA_FAST50_FLAG;
       l_trg_info (11).new_value :=  :NEW.CSA_FEDTAX_REFUND_FLAG;
       l_trg_info (12).new_value :=  :NEW.CSA_ALERT_LANG_ID;
   END IF;

   IF UPDATING
   THEN
      l_action := 'U';
        l_trg_info (1).old_value := :OLD.CSA_LOADORCREDIT_FLAG;
       l_trg_info (2).old_value :=  :OLD.CSA_LOWBAL_FLAG;
       l_trg_info (3).old_value :=  :OLD.CSA_LOWBAL_AMT;
       l_trg_info (4).old_value :=  :OLD.CSA_NEGBAL_FLAG;
       l_trg_info (5).old_value :=  :OLD.CSA_HIGHAUTHAMT_FLAG;
       l_trg_info (6).old_value :=  :OLD.CSA_HIGHAUTHAMT;
       l_trg_info (7).old_value :=  :OLD.CSA_DAILYBAL_FLAG;
       l_trg_info (8).old_value :=  :OLD.CSA_INSUFF_FLAG;
       l_trg_info (9).old_value :=  :OLD.CSA_INCORRPIN_FLAG;
       l_trg_info (10).old_value :=  :OLD.CSA_FAST50_FLAG;
       l_trg_info (11).old_value :=  :OLD.CSA_FEDTAX_REFUND_FLAG;
       l_trg_info (12).old_value :=  :OLD.CSA_ALERT_LANG_ID;

       l_trg_info (1).new_value := :NEW.CSA_LOADORCREDIT_FLAG;
       l_trg_info (2).new_value :=  :NEW.CSA_LOWBAL_FLAG;
       l_trg_info (3).new_value :=  :NEW.CSA_LOWBAL_AMT;
       l_trg_info (4).new_value :=  :NEW.CSA_NEGBAL_FLAG;
       l_trg_info (5).new_value :=  :NEW.CSA_HIGHAUTHAMT_FLAG;
       l_trg_info (6).new_value :=  :NEW.CSA_HIGHAUTHAMT;
       l_trg_info (7).new_value :=  :NEW.CSA_DAILYBAL_FLAG;
       l_trg_info (8).new_value :=  :NEW.CSA_INSUFF_FLAG;
       l_trg_info (9).new_value :=  :NEW.CSA_INCORRPIN_FLAG;
       l_trg_info (10).new_value :=  :NEW.CSA_FAST50_FLAG;
       l_trg_info (11).new_value :=  :NEW.CSA_FEDTAX_REFUND_FLAG;
       l_trg_info (12).new_value :=  :NEW.CSA_ALERT_LANG_ID;
   END IF;

   FOR i IN 1 .. l_trg_info.COUNT
   LOOP
      IF (l_action = 'U' AND (NVL (l_trg_info (i).old_value, 0) <> NVL (l_trg_info (i).new_value, 0))) OR (l_action = 'I' AND l_trg_info (i).new_value IS NOT NULL)
      THEN
         BEGIN
            INSERT INTO VMS_AUDIT_INFO (vai_rrn, vai_del_chnnl, vai_txn_code,
                                        vai_cust_code, vai_table_id, vai_column_name,
                                        vai_old_val, vai_new_val, vai_action_type,
                                        vai_action_user, vai_action_date, vai_action_username)
                 VALUES (l_rrn, l_del_chnnl, l_txn_code,
                         l_cust_code, l_tbl_id, l_trg_info (i).col_name,
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
 show error