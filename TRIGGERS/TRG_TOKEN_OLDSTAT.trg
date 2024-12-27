create or replace TRIGGER VMSCMS.TRG_TOKEN_OLDSTAT 
   BEFORE UPDATE OF vti_token_stat
   ON vmscms.vms_token_info    REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
BEGIN
   :new.vti_token_old_status := :old.vti_token_stat;
   :new.vti_lupd_date := sysdate;
   
    INSERT INTO vms_token_status_hist
      ( vts_card_no, vts_token_no, vts_token_old_stat,
        vts_token_new_stat, vts_changed_date )
      VALUES
      ( :old.vti_token_pan, :old.vti_token, :old.vti_token_stat,
        :new.vti_token_stat, systimestamp );
EXCEPTION
 WHEN OTHERS THEN
  NULL;
END;
/
show error