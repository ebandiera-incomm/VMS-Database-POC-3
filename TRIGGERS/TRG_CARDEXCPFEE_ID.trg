CREATE OR REPLACE TRIGGER VMSCMS.trg_cardexcpfee_id
   BEFORE INSERT
   ON cms_card_excpfee
   FOR EACH ROW
DECLARE
v_seq_cardexcpfee_id NUMBER;
BEGIN
   SELECT seq_cardexcpfee_id.NEXTVAL
     INTO v_seq_cardexcpfee_id
     FROM DUAL;

   :NEW.cce_cardfee_id := v_seq_cardexcpfee_id;
END;
/


