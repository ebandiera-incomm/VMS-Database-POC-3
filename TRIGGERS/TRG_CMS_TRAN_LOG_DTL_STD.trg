CREATE OR REPLACE TRIGGER "VMSCMS"."TRG_CMS_TRAN_LOG_DTL_STD" 
    BEFORE INSERT OR UPDATE ON vmscms.cms_transaction_log_dtl
        FOR EACH ROW
DECLARE  
  v_lupd_user   NUMBER (5);                  --Added on 13/04/2016 for migration		
BEGIN    --Trigger body begins
    BEGIN
      SELECT cum_user_pin
        INTO v_lupd_user
        FROM cms_user_mast
       WHERE cum_user_code = 'MIGR_USER' AND cum_inst_code = 1;
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;

   IF v_lupd_user = NVL(:NEW.ctd_ins_user,0) THEN
      IF UPDATING THEN
         :NEW.ctd_lupd_date := SYSDATE;
      END IF;
   ELSE
    IF INSERTING THEN
        :new.CTD_INS_DATE := sysdate;
        :new.CTD_LUPD_DATE := sysdate;
    ELSIF UPDATING THEN
        :new.CTD_LUPD_DATE := sysdate;
    END IF;
   END IF;	
END;    --Trigger body ends
/
SHOW ERROR