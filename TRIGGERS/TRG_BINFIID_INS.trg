CREATE OR REPLACE TRIGGER VMSCMS.trg_binfiid_ins
   BEFORE INSERT OR UPDATE
   ON cms_bin_fiid
   FOR EACH ROW
DECLARE
   sname   cms_inst_mast.cim_inst_shortname%TYPE;

  
   CURSOR bin
   IS
      SELECT CVC_VERIFY_CNAME,CVC_DAO_CNAME,CVC_DELIVERY_CHANEL,CVC_TXN_CODE,CVC_MSG_TYPE,CVC_REVERSAL_CODE
        FROM cms_verification_classes;
BEGIN                                                    --Trigger body begins
   FOR x IN bin
   LOOP
      SELECT cim_inst_shortname
        INTO sname
        FROM cms_inst_mast
       WHERE cim_inst_code = :NEW.CBF_INST_CODE;

      IF INSERTING
      THEN
         INSERT INTO cms_transaction_verifications
                     (ctv_txn_code, ctv_msg_type,
                      ctv_verify_cname, ctv_inst_code, ctv_inst_bin,
                      ctv_short_name, ctv_reversal_code, ctv_dao_cname,
                      ctv_delivery_chanel
                     )
              VALUES (x.CVC_TXN_CODE, x.CVC_MSG_TYPE,
                      x.CVC_VERIFY_CNAME, :NEW.CBF_INST_CODE, :new.CBF_BIN,
                      sname, x.CVC_REVERSAL_CODE, x.CVC_DAO_CNAME,
                      x.CVC_DELIVERY_CHANEL
                     );
      END IF;
   END LOOP;
END;                                                       --Trigger body ends
/


