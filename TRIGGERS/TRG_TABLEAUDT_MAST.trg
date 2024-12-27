CREATE OR REPLACE TRIGGER vmscms.trg_tableaudt_mast
   BEFORE INSERT
   ON vmscms.vms_tableaudt_mast
   FOR EACH ROW
DECLARE
   l_errmsg   VARCHAR2 (1000);
BEGIN
      :NEW.vtm_tbl_id := seq_tblaudit_tblid.NEXTVAL;
      :NEW.vtm_ins_date := SYSDATE;
      :NEW.vtm_ins_user := 1;
END;
/
SHOW ERROR