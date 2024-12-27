CREATE OR REPLACE TRIGGER VMSCMS.trg_loctype_id
 /*
  * VERSION               :  1.0
  * DATE OF CREATION      : 13/Mar/2006
  * PURPOSE               : Creation of base file version for configuration mgt.
  * MODIFICATION REASON   :
  *
  *
  * LAST MODIFICATION DONE BY :
  * LAST MODIFICATION DATE    :
  *
***/
   BEFORE INSERT
   ON VMSCMS.PCMS_INVENTORY_LOCTYPE    FOR EACH ROW
BEGIN               --Trigger body begins
   SELECT seq_pil_loctype_id.NEXTVAL
     INTO :NEW.loc_type_id
     FROM DUAL;
END;
/


