CREATE OR REPLACE TRIGGER VMSCMS.TRG_CARDEXCPFEE_DELUPD
BEFORE DELETE OR UPDATE
ON VMSCMS.CMS_CARD_EXCPFEE REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DISABLE
DECLARE
   err                    NUMBER (2);
   v_cce_fee_code_count   NUMBER (2);
   /*************************************************
     * VERSION             :  1.0
     * Created Date       : 06/MAR/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Checking Attached waiver before delete and update
     * Modified By:    :
     * Modified Date  :
   ***********************************************/
BEGIN
   SELECT COUNT (cce_fee_code)
     INTO v_cce_fee_code_count
     FROM CMS_CARD_EXCPWAIV
    WHERE cce_inst_code = :OLD.cce_inst_code
      AND cce_fee_code = :OLD.cce_pan_code
      AND cce_mbr_numb = :OLD.cce_mbr_numb
      AND cce_fee_code = :OLD.cce_fee_code
      AND cce_valid_from >= :OLD.cce_valid_from
      AND cce_valid_to <= :OLD.cce_valid_to;

   BEGIN
      IF DELETING
      THEN
         IF :OLD.cce_valid_from <= SYSDATE AND :OLD.cce_valid_to >= SYSDATE
         THEN
            err := 1;
         ELSIF v_cce_fee_code_count > 0
         THEN
            err := 2;
         END IF;
      END IF;

      IF UPDATING
      THEN
         IF (v_cce_fee_code_count > 0) AND (:NEW.cce_valid_to < :OLD.cce_valid_to)
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
              || SQLERRM
             );
   END;

   IF err = 1
   THEN
      raise_application_error
             (-20001,
                 'This Fees is using by the system, we cant remove this fees'
              || v_cce_fee_code_count
              || ' DATES '
              || :OLD.cce_valid_from
              || ' TO '
              || :OLD.cce_valid_to
             );
   END IF;

   IF err = 2
   THEN
      raise_application_error
             (-20001,
                 'Waiver is attached with the fees, we cant remove this fees'
              || v_cce_fee_code_count
             );
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      raise_application_error (-20001, SQLERRM);
END;
/


