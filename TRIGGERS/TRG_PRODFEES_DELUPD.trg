CREATE OR REPLACE TRIGGER VMSCMS.trg_prodfees_delupd before
  DELETE OR
  UPDATE ON VMSCMS.CMS_PROD_FEES FOR EACH row
DISABLE
DECLARE
    err VARCHAR2(200);  
  v_cpw_fee_code_count NUMBER (2);
  
  BEGIN   --<< main begin >>--
    err :=0;
    SELECT COUNT (cpw_fee_code)
    INTO v_cpw_fee_code_count
    FROM cms_prod_waiv
    WHERE cpw_inst_code = :OLD.cpf_inst_code
    AND cpw_prod_code   = :OLD.cpf_prod_code
    AND cpw_fee_code    = :OLD.cpf_fee_code
    AND cpw_valid_from >= :OLD.cpf_valid_from
    AND cpw_valid_to   <= :OLD.cpf_valid_to;
    
    BEGIN
      IF DELETING THEN
        IF :OLD.cpf_valid_from <= SYSDATE AND :OLD.cpf_valid_to >= SYSDATE THEN
          err:= 1;
        ELSIF v_cpw_fee_code_count > 0 THEN
          err:= 2;
        END IF;
      END IF;
      
      IF UPDATING
      THEN
         IF (v_cpw_fee_code_count > 0) AND (:NEW.cpf_valid_to < :OLD.cpf_valid_to)
         THEN
            err := 2;
         END IF;
      END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         err := 0;
      WHEN OTHERS THEN
         raise_application_error(-20001,'Waiver is attached with the fees, we cant remove this fees');
    END;
    
    IF err = 1
    THEN
      raise_application_error(-20001,'This Fees is using by the system, we cant remove this fees'
                              || v_cpw_fee_code_count|| ' DATES '|| :OLD.cpf_valid_from || ' TO '
                              || :OLD.cpf_valid_to
                              );
    END IF;
    
    IF err = 2
    THEN
      raise_application_error(-20001, 'Waiver is attached with the fees, we cant remove this fees'
                              || v_cpw_fee_code_count
                              );
    END IF;
  EXCEPTION         --<< main exception >>--
   WHEN OTHERS THEN
      raise_application_error (-20001,'Main Error Message'||SQLERRM);
  END;
/


