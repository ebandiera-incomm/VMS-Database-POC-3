 CREATE OR REPLACE TRIGGER VMSCMS.TRG_PROD_WAIV_ID
   BEFORE INSERT
   ON cms_prod_waiv
   FOR EACH ROW
DECLARE
   v_seq_prod_waiv   NUMBER;
BEGIN                                                    --Trigger body begins
   SELECT seq_prod_waiv.NEXTVAL
     INTO v_seq_prod_waiv
     FROM DUAL;

   :NEW.cpw_waiv_id := v_seq_prod_waiv;
   DBMS_OUTPUT.put_line (   'new value '
                         || v_seq_prod_waiv
                         || :NEW.cpw_waiv_id
                        );
END;
/
show error;