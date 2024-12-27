CREATE OR REPLACE TRIGGER VMSCMS.TRG_PRODCATTYPEFEE_DELUPD
BEFORE DELETE OR UPDATE
ON VMSCMS.CMS_PRODCATTYPE_FEES 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DISABLE
DECLARE
   err                    NUMBER (2);
   v_cpw_fee_code_count   NUMBER (2);
   /*************************************************
     * VERSION             :  1.0
     * Created Date       : 06/MAR/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Checking Attached waiver before delete and update 
     * Modified By:    :
     * Modified Date  :
   ***********************************************/
BEGIN
err :=0;
   SELECT COUNT (cpw_fee_code)
     INTO v_cpw_fee_code_count
     FROM cms_prodcattype_waiv
    WHERE cpw_inst_code = :OLD.cpf_inst_code
      AND cpw_prod_code = :OLD.cpf_prod_code
      AND cpw_card_type = :OLD.cpf_card_type
      AND cpw_fee_code = :OLD.cpf_fee_code
      AND cpw_valid_from >= :OLD.cpf_valid_from
      AND cpw_valid_to <= :OLD.cpf_valid_to;

   BEGIN
      IF DELETING
      THEN
         IF :OLD.cpf_valid_from <= SYSDATE AND :OLD.cpf_valid_to >= SYSDATE
         THEN
            err := 1;
         ELSIF v_cpw_fee_code_count > 0
         THEN
            err := 2;
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
      WHEN NO_DATA_FOUND
      THEN
         err := 0;
      WHEN OTHERS
      THEN
         raise_application_error
             (-20001,
                 'Waiver is attached with the fees, we cant remove this fees'
              
             );
   END;

   IF err = 1
   THEN
      raise_application_error
             (-20001,
                 'This Fees is using by the system, we cant remove this fees'
              || v_cpw_fee_code_count
              || ' DATES '
              || :OLD.cpf_valid_from
              || ' TO '
              || :OLD.cpf_valid_to
             );
   END IF;

   IF err = 2
   THEN
      raise_application_error
             (-20001,
                 'Waiver is attached with the fees, we cant remove this fees'
              || v_cpw_fee_code_count
             );
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      raise_application_error (-20001,'Main Error Message'||SQLERRM);
END;                                                             --END TRIGGER
/


