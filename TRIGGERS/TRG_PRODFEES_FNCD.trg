CREATE OR REPLACE TRIGGER VMSCMS.trg_prodfees_fncd before
  INSERT ON cms_prod_fees FOR EACH row
DECLARE
  v_delivery_channel CMS_FEE_MAST.CFM_DELIVERY_CHANNEL%TYPE;  
  v_tran_code CMS_FEE_MAST.CFM_TRAN_CODE%TYPE;
  v_tran_mode CMS_FEE_MAST.CFM_TRAN_MODE%TYPE;
  v_fun_code CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  BEGIN --<< main begin >>--
    BEGIN
      IF trim(:new.cpf_fee_code) IS NOT NULL THEN
        BEGIN
          SELECT cfm_delivery_channel,
                 cfm_tran_code,
                 cfm_tran_mode
          INTO v_delivery_channel,
               v_tran_code,
               v_tran_mode
          FROM cms_fee_mast
          WHERE cfm_fee_code=:new.cpf_fee_code
          AND cfm_inst_code =:new.cpf_inst_code;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          :NEW.CPF_FUNC_CODE := 'DEF';
        WHEN OTHERS THEN
          :NEW.CPF_FUNC_CODE := 'DEF';
        END;
        
        BEGIN
          SELECT CFM_FUNC_CODE
          INTO  v_fun_code 
          FROM CMS_FUNC_MAST
          WHERE CFM_TXN_CODE = v_tran_code
          AND CFM_TXN_MODE =  v_tran_mode
          AND CFM_DELIVERY_CHANNEL = v_delivery_channel
          AND CFM_INST_CODE=:new.cpf_inst_code;

           :NEW.CPF_FUNC_CODE := v_fun_code;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
           :NEW.CPF_FUNC_CODE := 'DEF';
          WHEN OTHERS THEN
           :NEW.CPF_FUNC_CODE := 'DEF';
          END;	 
      ELSE
        :NEW.CPF_FUNC_CODE := 'DEF';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        :NEW.CPF_FUNC_CODE := 'DEF';
      END;		 
  EXCEPTION  --<< main exception >>--
  WHEN OTHERS THEN
  RAISE_APPLICATION_ERROR(-20001, 'Error While generating function code '||SQLERRM);
  END;
/


