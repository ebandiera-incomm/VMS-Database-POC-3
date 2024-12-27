CREATE OR REPLACE TRIGGER VMSCMS.trg_cgr_seq_no
   BEFORE INSERT
   ON cms_group_bulkreissue
   FOR EACH ROW
DECLARE
   v_seq_no   NUMBER;
BEGIN
   SELECT seq_grp_bulkreissue.NEXTVAL
     INTO v_seq_no
     FROM DUAL;

   :NEW.cgr_seq_no := v_seq_no;
END;
/


