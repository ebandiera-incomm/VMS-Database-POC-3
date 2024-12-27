CREATE OR REPLACE TRIGGER VMSCMS.TRG_CARD_FEEEXISTINSERT
BEFORE INSERT
ON VMSCMS.CMS_CARD_EXCPFEE REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DISABLE
DECLARE
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 06/MAR/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Checking Attached Fee with card before insert
     * Modified By:    :
     * Modified Date  :
   ***********************************************/
   v_message            NUMBER                                := 0;
   v_cft_feetype_desc   cms_fee_types.cft_feetype_desc%TYPE;
   v_cft_existfeetype_desc   cms_fee_types.cft_feetype_desc%TYPE;

   CURSOR cur_card_fees
   IS
      SELECT cce_fee_code,cce_fee_type, cce_valid_from,
             cce_valid_to
               /*Check any fee is attached with the criteria and date range*/
        FROM cms_card_excpfee
       WHERE cce_pan_code = :NEW.cce_pan_code
         AND cce_inst_code = :NEW.cce_inst_code
         AND cce_tran_code = :NEW.cce_tran_code
         AND cce_mbr_numb = :NEW.cce_mbr_numb
         AND (   (cce_valid_from BETWEEN :NEW.cce_valid_from AND :NEW.cce_valid_to
                 )
              OR (cce_valid_to BETWEEN :NEW.cce_valid_from AND :NEW.cce_valid_to
                 )
              OR (:NEW.cce_valid_from BETWEEN cce_valid_from AND cce_valid_to
                 )
              OR (:NEW.cce_valid_to BETWEEN cce_valid_from AND cce_valid_to)
             );
BEGIN                                                 --SN Trigger body begins
   BEGIN
      SELECT cft_feetype_desc
        INTO v_cft_feetype_desc
        FROM cms_fee_types
       WHERE cft_feetype_code = :NEW.cce_fee_type;
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

    IF :NEW.cce_valid_from>SYSDATE THEN
dbms_output.put_line('FROM DATE :'||:NEW.cce_valid_from);
dbms_output.put_line('FROM DATE :'||:NEW.cce_valid_to);
dbms_output.put_line('FROM DATE :'||:NEW.cce_tran_code);
dbms_output.put_line('FROM DATE :'||:NEW.cce_inst_code);
dbms_output.put_line('FROM DATE :'||:NEW.cce_mbr_numb);
      FOR x IN cur_card_fees
      LOOP
    
         IF cur_card_fees%ROWCOUNT > 0
         THEN
            SELECT cft_feetype_desc
                    INTO v_cft_existfeetype_desc
                    FROM cms_fee_types
                    WHERE cft_feetype_code = x.cce_fee_type;  
         
  /* cursor count if greater then 0 that means same fee is already attached*/
            v_message := 1;
         END IF;

         EXIT WHEN cur_card_fees%NOTFOUND;
          IF v_message = 1
            THEN
                raise_application_error
                        (-20001,
                            'Same fee is already attached with the Fee Type '
                         || v_cft_existfeetype_desc
                         || ' between this date range From '
                         || x.cce_valid_from
                         || ' and to '
                         || x.cce_valid_to
                        );
          END IF;
         
      END LOOP;
   
    ELSIF :NEW.cce_valid_from=SYSDATE THEN

        raise_application_error(-20001,'Cannot add fees on same current date');
    END IF    ;                


  
EXCEPTION
   WHEN OTHERS
   THEN
      raise_application_error (-20001, 'Error While generating' || SQLERRM);
END;                                                   --EN Trigger body begin
/


