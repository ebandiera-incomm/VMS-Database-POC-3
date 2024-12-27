create or replace
TRIGGER vmscms.TRG_GPRVALIDCARDSTAT_STD
   BEFORE INSERT OR UPDATE
   ON vmscms.gpr_valid_cardstat
   FOR EACH ROW
BEGIN
   IF INSERTING
   THEN
      :new.gvc_ins_date := SYSDATE;
      :new.gvc_lupd_date := SYSDATE;
      :new.gvc_validcrdstat_seq := seq_valid_cardstat.NEXTVAL;
   ELSIF UPDATING
   THEN
      :new.gvc_lupd_date := SYSDATE;
   END IF;
END;
/
show error