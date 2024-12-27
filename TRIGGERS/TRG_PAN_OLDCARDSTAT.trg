



create or replace TRIGGER VMSCMS.TRG_PAN_OLDCARDSTAT
   BEFORE UPDATE OF cap_card_stat
   ON VMSCMS.CMS_APPL_PAN    REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
DECLARE
  --L_LMTPRFL     CMS_PRODUCT_PARAM.CPP_B2B_LMTPRFL%TYPE;
  l_lmtprfl     cms_prod_cattype.CPC_B2B_LMTPRFL%TYPE;

/***************************************************************************************
         * Modified By        : UBAIDUR RAHMAN
         * Modified Date      : 09-Jan-2019
         * Modified Reason    : Modified to NULL the CAP_CARDSTATUS_EXPIRY
	 				FROM CCA update CARD STATUS.
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 09-Jan-2019
         * Build Number       : R11_B0001
         
         
         
         * Modified By        : UBAIDUR RAHMAN
         * Modified Date      : 06-Jan-2019
         * Modified Reason    : VMS-1261 Implementation for adding missing Primary Key for VMS Table "CMS_PAN_STATUS" - Phase 2
         * Reviewer           : SaravanaKumar A
         * Reviewed Date      : 08-Nov-2019
         * Build Number       : R22_B0002
         
         
***************************************************************************************/
BEGIN

  IF :old.cap_card_stat <> :new.cap_card_stat THEN --Added for FSS-5225
   :new.cap_old_cardstat := :old.cap_card_stat;

   INSERT INTO CMS_PAN_STATUS (CPS_PAN_CODE, CPS_ACCOUNT_NUM, CPS_OLD_CARDSTAT,
                               CPS_NEW_CARDSTAT, CPS_CHANGED_DATE,CPS_UNIQUE_ID)
        VALUES (:old.cap_pan_code, :old.cap_acct_no, :old.cap_card_stat,
                :NEW.CAP_CARD_STAT, SYSDATE,SEQ_PAN_STATUS_UNIQUE_ID.NEXTVAL);  --- Modified for VMS-1261

  END IF;
 
   IF (:old.cap_card_stat='0' OR :old.cap_card_stat='13') AND :new.cap_card_stat='1' THEN
    BEGIN
    /*   SELECT cpp_b2b_lmtprfl
         INTO l_lmtprfl
         FROM cms_product_param
        WHERE cpp_inst_code = 1
          AND cpp_prod_code = :old.cap_prod_code;
    */
      SELECT CPC_B2B_LMTPRFL
         INTO L_LMTPRFL
         FROM CMS_PROD_CATTYPE
        WHERE CPC_INST_CODE = 1
          AND CPC_PROD_CODE = :OLD.CAP_PROD_CODE
          AND CPC_CARD_TYPE=:OLD.CAP_CARD_TYPE;

       IF l_lmtprfl IS NOT NULL THEN
           :new.cap_prfl_code:=l_lmtprfl;
           :new.cap_prfl_levl:=1;
       END IF;
    EXCEPTION
       WHEN OTHERS THEN
          NULL;
    END;
   END IF;
      
      -- Modified for VMS - 736  Modified to NULL the CAP_CARDSTATUS_EXPIRY FROM CCA update CARD STATUS.
   IF :new.cap_card_stat <> '19' AND :old.CAP_CARDSTATUS_EXPIRY IS NOT NULL 
        THEN 

    :new.CAP_CARDSTATUS_EXPIRY := null;

    END IF;
    
END;
/
show error