CREATE OR REPLACE TRIGGER vmscms.TRG_CMS_STATEMENTS_LOG_STD
   BEFORE INSERT OR UPDATE
   ON vmscms.cms_statements_log
   FOR EACH ROW
/*************************************************
     * Created Date       : 12/09/2012
     * Created By         : Ganesh
     * PURPOSE            : Inserting and Updating the sysdate.
     * Modified By:       :
     * Modified Date      :
     * VERSION            : CMS3.5.1_RI0016
     * Reviewed by        : Saravanakumar
     * Reviewed Date      : 12/09/2012
   ***********************************************/
DECLARE
   v_lupd_user   NUMBER (5);                  -- Added on 13/04/2016 for migration
BEGIN                                --Trigger body begins
   BEGIN
      SELECT cum_user_pin
        INTO v_lupd_user
        FROM cms_user_mast
       WHERE cum_user_code = 'MIGR_USER' AND cum_inst_code = 1;
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;

  IF V_LUPD_USER = NVL(:NEW.CSL_INS_USER,0) THEN
    IF INSERTING THEN
	  :NEW.csl_txn_seq:=seq_txn_order.nextval;
	  
    ELSIF UPDATING THEN
         :NEW.csl_lupd_date := SYSDATE;
    END IF;
  ELSE                                              
   IF INSERTING
   THEN
      :NEW.csl_ins_date := SYSDATE;
      :NEW.csl_lupd_date := SYSDATE;
      :NEW.csl_txn_seq:=seq_txn_order.nextval;
   ELSIF UPDATING
   THEN
      :NEW.csl_lupd_date := SYSDATE;
   END IF;
  END IF; 
END;                                                       --Trigger body ends
/
SHOW ERROR