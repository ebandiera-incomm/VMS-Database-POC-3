CREATE OR REPLACE TRIGGER VMSCMS.trg_prodcccfees_feeexist
   BEFORE INSERT
   ON VMSCMS.CMS_PRODCCC_FEES    FOR EACH ROW
DECLARE
   v_message            NUMBER                                := 0;
   v_cft_feetype_desc   cms_fee_types.cft_feetype_desc%TYPE;
   v_cft_existfeetype_desc   cms_fee_types.cft_feetype_desc%TYPE;

   CURSOR cur_prodccc_fees
   IS
      SELECT cpf_fee_code,cpf_fee_type, cpf_valid_from, cpf_valid_to
        /*Check any fee is attached with the criteria and date range*/
      FROM   cms_prodccc_fees
       WHERE cpf_inst_code = :NEW.cpf_inst_code
         AND cpf_tran_code = :NEW.cpf_tran_code
         AND cpf_prod_code = :NEW.cpf_prod_code
         AND (   (cpf_valid_from BETWEEN :NEW.cpf_valid_from AND :NEW.cpf_valid_to
                 )
              OR (cpf_valid_to BETWEEN :NEW.cpf_valid_from AND :NEW.cpf_valid_to
                 )
              OR (:NEW.cpf_valid_from BETWEEN cpf_valid_from AND cpf_valid_to
                 )
              OR (:NEW.cpf_valid_to BETWEEN cpf_valid_from AND cpf_valid_to)
             );
BEGIN                                                     --<< main begin >>--
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
     *Transaction code or support Key(cpf_tran_code) 
     *check alone is made in the cursor 
     *irrespective of the Fee Type description
     *and fee code since for a single product there  
     *can be only one type of transaction 
     *attached for the same date range
     *
   ***********************************************/

   IF :NEW.cpf_valid_from > SYSDATE
   THEN
        FOR x IN cur_prodccc_fees
         LOOP
     
            IF cur_prodccc_fees%ROWCOUNT > 0
            THEN
                SELECT cft_feetype_desc
                    INTO v_cft_existfeetype_desc
                    FROM cms_fee_types
                    WHERE cft_feetype_code = x.cpf_fee_type;  
             /* cursor count if greater then 0 that means same fee is already attached*/
               v_message := 1;
            END IF;

            EXIT WHEN cur_prodccc_fees%NOTFOUND;
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
      
   ELSIF :NEW.cpf_valid_from <= SYSDATE
   THEN
      raise_application_error (-20001,'Cannot attach fee on same current date');
   END IF;

 

EXCEPTION                                             --<< main exception >>--
   WHEN OTHERS
   THEN
      raise_application_error (-20001, 'Error While generating' || SQLERRM);
END;                                                  --<< main begin end >>--
/


