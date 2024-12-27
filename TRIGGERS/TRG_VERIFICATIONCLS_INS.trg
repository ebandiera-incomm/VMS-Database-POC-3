CREATE OR REPLACE TRIGGER VMSCMS.trg_verificationcls_ins
   BEFORE   INSERT OR UPDATE OR DELETE
   ON VMSCMS.CMS_VERIFICATION_CLASSES    FOR EACH ROW
DECLARE
   sname   cms_inst_mast.cim_inst_shortname%TYPE;

   CURSOR bin
   IS
      SELECT cbf_bin, cbf_inst_code
        FROM cms_bin_fiid
       WHERE cbf_inst_code = :NEW.cvc_inst_code;

/*************************************************
     * Created Date     :  NA
     * Created By       :  NA
     * Purpose          :  For calculating interest for saving account.
     * Modified BY      :  Naveena
     * Modified Date    :  30-May-2012
     * Reason           :  To delete the records.
     * Reviewer         :  B.Besky Anand
     * Reviewed Date    :  30-May-2012
     * Release Number   :  CMS3.4.4_RI0008_B00019
*************************************************/
BEGIN                                                    --Trigger body begins
   FOR x IN bin
   LOOP
      SELECT cim_inst_shortname
        INTO sname
        FROM cms_inst_mast
       WHERE cim_inst_code = :NEW.cvc_inst_code;

      IF INSERTING
      THEN
         INSERT INTO cms_transaction_verifications
                     (ctv_txn_code, ctv_msg_type,
                      ctv_verify_cname, ctv_inst_code, ctv_inst_bin,
                      ctv_short_name, ctv_reversal_code, ctv_dao_cname,
                      ctv_delivery_chanel
                     )
              VALUES (:NEW.cvc_txn_code, :NEW.cvc_msg_type,
                      :NEW.cvc_verify_cname, x.cbf_inst_code, x.cbf_bin,
                      sname, :NEW.cvc_reversal_code, :NEW.cvc_dao_cname,
                      :NEW.cvc_delivery_chanel
                     );
      ELSIF UPDATING
      THEN
         UPDATE cms_transaction_verifications
            SET ctv_txn_code = :NEW.cvc_txn_code,
                ctv_msg_type = :NEW.cvc_msg_type,
                ctv_verify_cname = :NEW.cvc_verify_cname,
                ctv_reversal_code = :NEW.cvc_reversal_code,
                ctv_dao_cname = :NEW.cvc_dao_cname,
                ctv_delivery_chanel = :NEW.cvc_delivery_chanel
          WHERE ctv_txn_code = :OLD.cvc_txn_code
            AND ctv_msg_type = :OLD.cvc_msg_type
            AND ctv_verify_cname = :OLD.cvc_verify_cname
            AND ctv_reversal_code = :OLD.cvc_reversal_code
            AND ctv_dao_cname = :OLD.cvc_dao_cname
            AND ctv_delivery_chanel = :OLD.cvc_delivery_chanel
            AND ctv_inst_bin = x.cbf_bin
            AND ctv_inst_code = x.cbf_inst_code;

      END IF;
   END LOOP;

   IF DELETING
      THEN
         DELETE FROM cms_transaction_verifications
               WHERE ctv_txn_code = :OLD.cvc_txn_code
                 AND ctv_msg_type = :OLD.cvc_msg_type
                 AND ctv_verify_cname = :OLD.cvc_verify_cname
                 AND ctv_reversal_code = :OLD.cvc_reversal_code
                 AND ctv_dao_cname = :OLD.cvc_dao_cname
                 AND ctv_delivery_chanel = :OLD.cvc_delivery_chanel ;
    END if;
END;                                                       --Trigger body ends
/


