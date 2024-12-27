CREATE OR REPLACE TRIGGER VMSCMS.TRG_PRODCATTYPEWAIV_INSERT
BEFORE INSERT
ON VMSCMS.CMS_PRODCATTYPE_WAIV 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   v_count            NUMBER (2);
   err                NUMBER (1);
   v_cpf_valid_from   DATE;
   v_cpf_valid_to     DATE;
   /*************************************************
     * VERSION             :  1.0 
     * Created Date       : 16/MAR/2009 
     * Created By        : Kaustubh.Dave 
     * PURPOSE          :validate Attached Waiver with prodcattype before insert/update 
     * Modified By:    :
     * Modified Date  :
   ***********************************************/
BEGIN                                                    --trigger body begins
   SELECT cpf_valid_from, cpf_valid_to
     INTO v_cpf_valid_from, v_cpf_valid_to
     FROM cms_prodcattype_fees
    WHERE cpf_inst_code = :NEW.cpw_inst_code
      AND cpf_fee_code  = :NEW.cpw_fee_code
      AND cpf_prod_code = :NEW.cpw_prod_code
      AND cpf_card_type = :NEW.cpw_card_type
    AND TRUNC (:NEW.cpw_valid_from) >= TRUNC (cpf_valid_from)
    AND TRUNC (:NEW.cpw_valid_from) <=  TRUNC (cpf_valid_to)
    AND TRUNC (:NEW.cpw_valid_to) >= TRUNC (cpf_valid_from)
    AND TRUNC (:NEW.cpw_valid_to) <= TRUNC (cpf_valid_to);

IF SQL%FOUND AND TRUNC(:NEW.cpw_valid_from) > TRUNC(SYSDATE) AND TRUNC(:NEW.cpw_valid_TO) > TRUNC(SYSDATE) 
   THEN
      BEGIN
         SELECT COUNT (cpw_fee_code)
           INTO v_count
           FROM cms_prodcattype_waiv
          WHERE cpw_inst_code = :NEW.cpw_inst_code
            AND cpw_fee_code = :NEW.cpw_fee_code
            AND cpw_prod_code = :NEW.cpw_prod_code
            AND cpw_card_type = :NEW.cpw_card_type
            AND (   (cpw_valid_from BETWEEN :NEW.cpw_valid_from
                                        AND :NEW.cpw_valid_to
                    )
                 OR (cpw_valid_to BETWEEN :NEW.cpw_valid_from
                                      AND :NEW.cpw_valid_to
                    )
                 OR (:NEW.cpw_valid_from BETWEEN cpw_valid_from AND cpw_valid_to
                    )
                 OR (:NEW.cpw_valid_to BETWEEN cpw_valid_from AND cpw_valid_to
                    )
                );

         IF v_count > 0
         THEN
            raise_application_error
                               (-20003,
                                   'Same Waiver is already Attached between '
                                || :NEW.cpw_valid_from
                                || ' and '
                                || :NEW.cpw_valid_to
                               );
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            err := 0;
         WHEN OTHERS
         THEN
            raise_application_error
                               (-20003,
                                   'Same Waiver is already Attached between '
                                || :NEW.cpw_valid_from
                                || ' and '
                                || :NEW.cpw_valid_to 
                               );
      END;
ELSIF SQL%NOTFOUND THEN
	  raise_application_error
                 (-20001,
                  'Waiver dates have to be within or equal to Fee daterange./'
				  ||'From Date and To Date Must be grater then current date'
				 );
END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      raise_application_error
                 (-20001,
                  'Waiver dates have to be within or equal to Fee daterange.'
                 );
END;
/


