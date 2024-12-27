CREATE OR REPLACE TRIGGER VMSCMS.TRG_PRODCATTYPE_FEEEXIST
BEFORE INSERT
ON VMSCMS.CMS_PRODCATTYPE_FEES REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DISABLE
DECLARE
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 06/MAR/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Checking Attached Fee before insert
     * Modified By:    :
     * Modified Date  :
   ***********************************************/
   v_message            NUMBER                                := 0;
   v_cft_feetype_desc   cms_fee_types.cft_feetype_desc%TYPE;
  v_cft_existfeetype_desc   cms_fee_types.cft_feetype_desc%TYPE;

   CURSOR cur_prodcattype_fees
   IS
      SELECT cpf_fee_code,cpf_fee_type, cpf_valid_from,
             cpf_valid_to
               /*Check any fee is attached with the criteria and date range*/
        FROM cms_prodcattype_fees
       WHERE cpf_inst_code = :NEW.cpf_inst_code
         AND cpf_tran_code = :NEW.cpf_tran_code
         AND cpf_prod_code = :NEW.cpf_prod_code
         AND cpf_card_type = :NEW.cpf_card_type
         AND (   (cpf_valid_from BETWEEN :NEW.cpf_valid_from AND :NEW.cpf_valid_to
                 )
              OR (cpf_valid_to BETWEEN :NEW.cpf_valid_from AND :NEW.cpf_valid_to
                 )
              OR (:NEW.cpf_valid_from BETWEEN cpf_valid_from AND cpf_valid_to
                 )
              OR (:NEW.cpf_valid_to BETWEEN cpf_valid_from AND cpf_valid_to)
             );
BEGIN                                                 --SN Trigger body begins
  
    BEGIN
      SELECT cft_feetype_desc
        INTO v_cft_feetype_desc
        FROM cms_fee_types
       WHERE cft_feetype_code = :NEW.cpf_fee_type;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         raise_application_error (-20003, 'FEE TYPE NOT DEFINED');
   /* find the fee type description*/
   END;
   
   
    /*************************************************
     *Trigger modified in such a way that 
     *Fee code check alone is made in the cursor 
     *irrespective of the Fee Type description
     *since there can be any  Fee Type description 
     *other than Transaction Fee,Support Function Fee
     *
   ***********************************************/
   IF :NEW.cpf_valid_from > SYSDATE 
   THEN
      FOR x IN cur_prodcattype_fees
      LOOP
  
       IF cur_prodcattype_fees%ROWCOUNT > 0
         THEN
         
            SELECT cft_feetype_desc
                    INTO v_cft_existfeetype_desc
                    FROM cms_fee_types
                    WHERE cft_feetype_code = x.cpf_fee_type;  
  /* cursor count if greater then 0 that means same fee is already attached*/
            v_message := 1;
        END IF;

      EXIT WHEN cur_prodcattype_fees%NOTFOUND;
      
        IF v_message = 1
            THEN
            raise_application_error
                        (-20001,
                            'Same fee is already attached with the Fee Type '
                         || v_cft_existfeetype_desc
                         || ' between this date range From '
                         || x.cpf_valid_from
                         || ' and to '
                         || x.cpf_valid_to
                        );
        END IF;
        
      END LOOP;
   
   ELSIF :NEW.cpf_valid_from <= SYSDATE THEN
      raise_application_error(-20001,'Cannot attach fee on same current date');
    END IF;
    
  

EXCEPTION
   WHEN OTHERS
   THEN
      raise_application_error (-20001, 'Error While generating' || SQLERRM);
END;                                                   --EN Trigger body begin
/


