CREATE OR REPLACE TRIGGER VMSCMS.TRG_ISOREQ_MAPPING

       BEFORE INSERT OR UPDATE ON VMSCMS.CMS_ISO_REQMAPPING            FOR EACH ROW
   /*************************************************
     * Created Date     :  30-Apr-2012
     * Created By       :  Srinivasu
     * PURPOSE          :  For Inserting date
     * Reviewer         :  Saravanakumar
     * Reviewed Date    :  10-May-2012
     * Release Number   :  CMS3.4.3_RI0008_B0003
*************************************************/
BEGIN
       IF INSERTING THEN
           :new.CIR_INS_DATE := sysdate;
           :new.CIR_LUPD_DATE := sysdate;
       ELSIF UPDATING THEN
   		:new.CIR_LUPD_DATE := sysdate;
   	END IF;
    END;
/


