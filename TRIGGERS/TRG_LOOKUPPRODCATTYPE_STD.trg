CREATE OR REPLACE TRIGGER VMSCMS.trg_lookupprodcattype_std
   BEFORE UPDATE OR DELETE  --Insert removed on 25_Jan_13 by Pankaj S. for Mantis Id -0010031
   ON VMSCMS.CMS_PROD_CATTYPE    FOR EACH ROW
DECLARE
   bin               cms_prod_bin.cpb_inst_bin%TYPE;
   v_iriscnt         NUMBER (5);  --Added on 25_Jan_13 by Pankaj S. for Mantis Id-0010031
   v_errmsg          VARCHAR2 (300);
   exp_raise_error   EXCEPTION;
  /********************************************************************************************
      * Created BY      : NA
      * Created for     : NA
      * Created Date    : NA
      * Modified BY      : Pankaj S.
      * Modified for     : Mantis Id-0010031
      * Modified Date    : 25/01/2013
      * Reviewer         : Dhiraj
      * Reviewed Date    : 25/01/2013
    ************************************************************************************************/
BEGIN                                                    --Trigger body begins
   --Sn Added on 25_Jan_13 by Pankaj S. for Mantis Id - 0010031(Product category Exception).
   SELECT COUNT (1)
     INTO v_iriscnt
     FROM cms_iris_prodcatgmast
    WHERE cpm_inst_code = :OLD.cpc_inst_code
      AND cpm_prod_code = :OLD.cpc_prod_code
      AND cpm_catg_code = :OLD.cpc_card_type
      AND cpm_iris_flag = 'Y';
   --En Added on 25_Jan_13 by Pankaj S. for Mantis Id - 0010031(Product category Exception).
   
   IF v_iriscnt <> 0 THEN  --Added on 25_Jan_13 by Pankaj S. for Mantis Id - 0010031(Product category Exception).
      BEGIN
         SELECT cpb_inst_bin
           INTO bin
           FROM cms_prod_bin
          WHERE cpb_prod_code = :NEW.cpc_prod_code
            AND cpb_inst_code = :NEW.cpc_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            raise_application_error (-20004, 'Error while selecting product Bin-' || SUBSTR (SQLERRM, 1, 200));
      END;

      --Sn Commented on 25_Jan_13 by Pankaj S. for Mantis Id - 0010031(Product category Exception).
      /*  IF INSERTING THEN
        -- For Card Type [ Bin + Sub Bin]
         BEGIN
             INSERT INTO cms_lookup_mast
                         (clm_inst_code, clm_record_type, clm_file_name,
                          clm_field_name, clm_code_name,
                          clm_code_desc, clm_ins_date, clm_ins_user
                         )
                  VALUES (:NEW.cpc_inst_code, 'D', 'C',
                          'Card_Type', bin || :NEW.cpc_prod_prefix,
                          :NEW.cpc_cardtype_desc, SYSDATE, :NEW.cpc_ins_user
                         );
         EXCEPTION
         WHEN OTHERS THEN
           RAISE_APPLICATION_ERROR(-20001,'Error while creating record in lookup segment for card type'||substr(sqlerrm,1,200));
         END;
         -- For Product ID [ Bin + Sub Bin]
         BEGIN
             INSERT INTO cms_lookup_mast
                         (clm_inst_code, clm_record_type, clm_file_name,
                          clm_field_name, clm_code_name,
                          clm_code_desc, clm_ins_date, clm_ins_user
                         )
                  VALUES (:NEW.cpc_inst_code, 'D', 'A',
                          'Product_ID', bin || :NEW.cpc_prod_prefix,
                          :NEW.cpc_cardtype_desc, SYSDATE, :NEW.cpc_ins_user
                         );
          EXCEPTION
          WHEN OTHERS THEN
           RAISE_APPLICATION_ERROR(-20002,'Error while creating record in lookup segment For product ID'||substr(sqlerrm,1,200));
          END;*/
          --En Commented on 25_Jan_13 by Pankaj S. for Mantis Id - 0010031(Product category Exception).
          
      IF UPDATING THEN
         BEGIN
            UPDATE cms_lookup_mast  -- Both product Id & Card Type will be updated
               SET clm_code_name = bin || :NEW.cpc_prod_prefix,
                   clm_code_desc = :NEW.cpc_cardtype_desc,
                   clm_lupd_date = SYSDATE,
                   clm_lupd_user = :NEW.cpc_lupd_user
             WHERE clm_code_name = bin || :OLD.cpc_prod_prefix
               AND clm_code_desc = :OLD.cpc_cardtype_desc;

            IF SQL%ROWCOUNT = 0 THEN
               v_errmsg := 'Prod Prefix not found for updating info';
               RAISE exp_raise_error;
            END IF;
         EXCEPTION
            WHEN exp_raise_error THEN
               raise_application_error (-20003, v_errmsg);
            WHEN OTHERS THEN
               raise_application_error(-20004,'Error while updating record in lookup segment-'|| SUBSTR (SQLERRM, 1, 200));
         END;
      ELSIF DELETING THEN
         BEGIN
            DELETE FROM cms_lookup_mast
                  WHERE clm_code_name = bin || :OLD.cpc_prod_prefix
                    AND clm_code_desc = :OLD.cpc_cardtype_desc;

            IF SQL%ROWCOUNT = 0 THEN
               v_errmsg := 'Prod prefix not found for deleting record';
               RAISE exp_raise_error;
            END IF;
         EXCEPTION
            WHEN exp_raise_error THEN
               raise_application_error (-20005, v_errmsg);
            WHEN OTHERS THEN
               raise_application_error (-20006,'Error while deleting record in lookup segment-' || SUBSTR (SQLERRM, 1, 200));
         END;
      END IF;
   END IF;
END;                                                       --Trigger body ends
/
SHOW ERRORS;

