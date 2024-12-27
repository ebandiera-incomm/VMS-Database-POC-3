CREATE OR REPLACE TRIGGER vmscms.trg_grpaudt_mast
   BEFORE INSERT OR UPDATE
   ON vmscms.vms_grpaudt_mast
   FOR EACH ROW
DECLARE
   l_errmsg   VARCHAR2 (1000);
BEGIN
   IF INSERTING
   THEN
      :NEW.vgm_grp_id := seq_tblaudit_grpid.NEXTVAL;
      :NEW.vgm_ins_date := SYSDATE;
      :NEW.vgm_ins_user := 1;
   ELSIF UPDATING
   THEN
      IF (:NEW.vgm_audt_flag <> :OLD.vgm_audt_flag) OR :NEW.vgm_audt_flag = 'Y'
      THEN
         vmstableaudit.generate_audit_trg (:NEW.vgm_grp_id, :NEW.vgm_audt_flag , l_errmsg);

         IF l_errmsg <> 'OK'
         THEN
            RAISE_APPLICATION_ERROR (-20001, l_errmsg);
         END IF;
      END IF;
   END IF;
END;
/
SHOW ERROR