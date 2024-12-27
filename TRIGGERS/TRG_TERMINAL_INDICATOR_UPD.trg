CREATE OR REPLACE TRIGGER VMSCMS.trg_terminal_indicator_upd
   BEFORE UPDATE
   ON VMSCMS.PCMS_TERMINAL_MAST    REFERENCING OLD AS OLD NEW AS NEW
   FOR EACH ROW
   /*************************************************
     * VERSION             :  1.0 
     * Created Date       : 30/MAR/2009 
     * Created By        : Kaustubh.Dave 
     * PURPOSE          :This Trigger is used for change the status of indicator
	   					 before every update on table pcms_terminal_mast 
     * Modified By:    :
     * Modified Date  :
   **************************************************/
BEGIN
   :NEW.ptm_terminal_indicator := 1;
END;
/


