CREATE OR REPLACE TRIGGER vmscms.trg_feemast_freefrqchang
   BEFORE INSERT OR UPDATE OF cfm_duration
   ON vmscms.cms_fee_mast
   FOR EACH ROW
BEGIN                                                    --Trigger body begins
   :new.cfm_duration_change := SYSDATE;
END;                                                       --Trigger body ends
/
SHOW ERROR