CREATE OR REPLACE TRIGGER VMSCMS.TRG_CARDSUMRY_DWMY_STD
   BEFORE UPDATE
   ON vmscms.cms_cardsumry_dwmy
   FOR EACH ROW
BEGIN                                                
   :new.ccd_lupd_date := SYSDATE;
END;                                                 
/