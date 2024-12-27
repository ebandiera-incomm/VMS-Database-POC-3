create or replace TRIGGER VMSCMS.trg_cms_limt_mast_std
   BEFORE UPDATE
   ON cms_limt_mast
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
   IF UPDATING
   THEN
      :NEW.clm_upld_date := SYSDATE;
   END IF;
END;                                                        --Trigger body end 

/

show error;