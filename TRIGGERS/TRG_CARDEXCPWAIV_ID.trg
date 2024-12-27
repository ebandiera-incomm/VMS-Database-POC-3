CREATE OR REPLACE TRIGGER VMSCMS.trg_cardexcpwaiv_id
   BEFORE INSERT
   ON cms_card_excpwaiv
   FOR EACH ROW
DECLARE
   v_seq_card_waiv_id   NUMBER;
BEGIN
   SELECT seq_card_waiv_id.NEXTVAL
     INTO v_seq_card_waiv_id
     FROM DUAL;

   :NEW.cce_card_waiv_id := v_seq_card_waiv_id;
END;
/


