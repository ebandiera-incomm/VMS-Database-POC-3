create or replace TRIGGER VMSCMS.trg_cms_lmtprfl_mast_std
   BEFORE INSERT OR UPDATE
   ON cms_lmtprfl_mast
   FOR EACH ROW

/*************************************************
     * Created Date       : 12/09/2012
     * Created By         : Ganesh 
     * PURPOSE            : Inserting and Updating the sysdate.
     * Modified By:       :
     * Modified Date      :
     * VERSION            : CMS3.5.1_RI0016_B0002
     * Reviewed by        : Saravanakumar
     * Reviewed Date      : 12/09/2012
   ***********************************************/

BEGIN                                                    --Trigger body begins
   IF INSERTING
   THEN
      :NEW.clm_ins_date := SYSDATE;
      :NEW.clm_lupd_date := SYSDATE;
   ELSIF UPDATING
   THEN
      :NEW.clm_lupd_date := SYSDATE;
   END IF;
END;                                                       --Trigger body ends 

/

show error;