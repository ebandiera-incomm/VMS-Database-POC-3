create or replace TRIGGER VMSCMS.trg_statemast_std
   BEFORE INSERT OR UPDATE
   ON gen_state_mast
   FOR EACH ROW

/*************************************************
     * Created Date       : 
     * Created By         :  
     * PURPOSE            : 
     * Modified By:       : Ganesh
     * Modified Date      : 12/09/2012
     * Modified reason    : Inserting and Updating the sysdate.
     * VERSION            : CMS3.5.1_RI0016_B0002
     * Reviewed by        : Saravanakumar
     * Reviewed Date      : 12/09/2012
   ***********************************************/

BEGIN                                                    --Trigger body begins
   IF INSERTING
   THEN
      :NEW.gsm_ins_date := SYSDATE;
      :NEW.gsm_lupd_date := SYSDATE;
   ELSIF UPDATING
   THEN
      :NEW.gsm_lupd_date := SYSDATE;
   END IF;
END;                                                       --Trigger body ends 

/

show error;