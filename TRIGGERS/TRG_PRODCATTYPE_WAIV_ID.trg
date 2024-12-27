CREATE OR REPLACE TRIGGER VMSCMS.trg_prodcattype_waiv_id
   BEFORE INSERT
   ON cms_prodcattype_waiv
   FOR EACH ROW
DECLARE
   v_seq_prodcattype_waiv   NUMBER;
BEGIN                                                    --Trigger body begins
   SELECT seq_prodcattype_waiv.NEXTVAL
     INTO v_seq_prodcattype_waiv
     FROM DUAL;

   :NEW.cpw_waiv_id := v_seq_prodcattype_waiv;
   DBMS_OUTPUT.put_line (   'new value '
                         || v_seq_prodcattype_waiv
                         || :NEW.cpw_waiv_id
                        );
END;
/


