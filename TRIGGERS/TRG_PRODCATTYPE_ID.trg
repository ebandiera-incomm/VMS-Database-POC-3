CREATE OR REPLACE TRIGGER VMSCMS.TRG_PRODCATTYPE_ID
before insert on cms_prodcattype_fees
for each row
DECLARE
v_seq_prodcattype_id NUMBER;
BEGIN --Trigger body begins
 SELECT SEQ_PRODCATTYPE_ID.NEXTVAL
 INTO v_seq_prodcattype_id
 FROM dual;
  :new.CPF_PRODCATTYPE_ID := v_seq_prodcattype_id;
 dbms_output.put_line('new value '|| v_seq_prodcattype_id||:new.CPF_PRODCATTYPE_ID);
END;
/


