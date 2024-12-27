CREATE OR REPLACE TRIGGER VMSCMS.trg_aftinst_tranmast
   AFTER INSERT OR DELETE
   ON VMSCMS.CMS_TRANSACTION_MAST    REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
BEGIN
/**********************************************
    * VERSION             :  1.0
    * Created Date        : 16-Sep-2012
    * Created By          : Dhiraj Gaikwad
    * PURPOSE             : Enable Transaction for IRIS Extract Report
    * Modified By:        :
    * Modified Date       :
    * Reviewer            :
    ******************************************/

  IF INSERTING
  THEN

   INSERT INTO cms_iristransaction_mast
               (cim_inst_code, cim_tran_code, cim_tran_desc,
                cim_credit_debit_flag, cim_delivery_channel,
                cim_output_type, cim_tran_type,
                cim_support_type, cim_lupd_date,
                cim_lupd_user, cim_ins_date, cim_ins_user,
                cim_support_catg, cim_preauth_flag,
                cim_amnt_transfer_flag, cim_login_txn,
                cim_prfl_flag, cim_fee_flag
               )
        VALUES (:NEW.ctm_inst_code, :NEW.ctm_tran_code, :NEW.ctm_tran_desc,
                :NEW.ctm_credit_debit_flag, :NEW.ctm_delivery_channel,
                :NEW.ctm_output_type, :NEW.ctm_tran_type,
                :NEW.ctm_support_type, :NEW.ctm_lupd_date,
                :NEW.ctm_lupd_user, :NEW.ctm_ins_date, :NEW.ctm_ins_user,
                :NEW.ctm_support_catg, :NEW.ctm_preauth_flag,
                :NEW.ctm_amnt_transfer_flag, :NEW.ctm_login_txn,
                :NEW.ctm_prfl_flag, :NEW.ctm_fee_flag
               );

  ELSIF DELETING
  THEN

      DELETE FROM cms_iristransaction_mast
            WHERE CIM_INST_CODE =  :OLD.CTM_INST_CODE
              AND CIM_TRAN_CODE =  :OLD.CTM_TRAN_CODE
              AND CIM_DELIVERY_CHANNEL = :OLD.ctm_delivery_channel;

  END IF;

EXCEPTION
   WHEN OTHERS
   THEN
      raise_application_error
                       (-20001,
                           'Error While Inserting into Transaction IRIS mast'
                        || SQLERRM
                       );
END;
/
SHOW ERRORS;


