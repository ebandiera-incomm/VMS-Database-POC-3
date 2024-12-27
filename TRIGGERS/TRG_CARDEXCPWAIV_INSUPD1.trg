CREATE OR REPLACE TRIGGER VMSCMS.TRG_CARDEXCPWAIV_INSUPD1
BEFORE INSERT 
ON VMSCMS.CMS_CARD_EXCPWAIV 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   err                NUMBER (1);
   v_count            NUMBER (1);
   v_cce_valid_from   DATE;
   v_cce_valid_to     DATE;
      /*************************************************
     * VERSION             :  1.0  
     * Created Date       : 16/MAR/2009  
     * Created By        : Kaustubh.Dave 
     * PURPOSE          :validate Attached Waiver with Card before insert/update 
     * Modified By:    :
     * Modified Date  :
   ***********************************************/
BEGIN
   --trigger body begins
   SELECT cce_valid_from, cce_valid_to
     INTO v_cce_valid_from, v_cce_valid_to
     FROM cms_card_excpfee
    WHERE cce_inst_code = :NEW.cce_inst_code
      AND cce_fee_code = :NEW.cce_fee_code
      AND cce_pan_code = :NEW.cce_pan_code
      AND cce_mbr_numb = :NEW.cce_mbr_numb
      AND TRUNC (:NEW.cce_valid_from) >= TRUNC (cce_valid_from)
      AND TRUNC (:NEW.cce_valid_from) <= TRUNC (cce_valid_to)
      AND TRUNC (:NEW.cce_valid_to) >= TRUNC (cce_valid_from)
      AND TRUNC (:NEW.cce_valid_to) <= TRUNC (cce_valid_to);

   IF SQL%FOUND AND TRUNC(:NEW.cce_valid_from) > TRUNC(SYSDATE) AND TRUNC(:NEW.cce_valid_TO) > TRUNC(SYSDATE)
   THEN
      BEGIN
         err := 0;

         SELECT COUNT (cce_fee_code)
           INTO v_count
           FROM cms_card_excpwaiv
          WHERE cce_inst_code = :NEW.cce_inst_code
            AND cce_fee_code = :NEW.cce_fee_code
            AND cce_pan_code = :NEW.cce_pan_code
            AND cce_mbr_numb = :NEW.cce_mbr_numb
            AND (   (cce_valid_from BETWEEN :NEW.cce_valid_from
                                        AND :NEW.cce_valid_to
                    )
                 OR (cce_valid_to BETWEEN :NEW.cce_valid_from
                                      AND :NEW.cce_valid_to
                    )
                 OR (:NEW.cce_valid_from BETWEEN cce_valid_from AND cce_valid_to
                    )
                 OR (:NEW.cce_valid_to BETWEEN cce_valid_from AND cce_valid_to
                    )
                );

	         IF v_count > 0
	         THEN
	            raise_application_error
	                               (-20003,
	                                   'Same Waiver is already Attached between '
	                                || :NEW.cce_valid_from
	                                || ' and '
	                                || :NEW.cce_valid_to
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
	                                || :NEW.cce_valid_from
	                                || ' and '
	                                || :NEW.cce_valid_to
	                               );
	      END;
  	  ELSIF SQL%NOTFOUND THEN
	  raise_application_error
                 (-20001,
                  'Waiver dates have to be within or equal to Fee daterange./'
				  ||'From Date and To Date must be grater then current date'
				 );
 	  END IF;

EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      raise_application_error
                 (-20001,
                  'Waiver dates have to be within or equal to Fee daterange.'
                 );
END;
/


