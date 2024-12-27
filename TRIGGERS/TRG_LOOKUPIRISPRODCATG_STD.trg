CREATE OR REPLACE TRIGGER VMSCMS.TRG_LOOKUPIRISPRODCATG_STD
   BEFORE INSERT OR UPDATE 
   ON VMSCMS.cms_iris_prodcatgmast
   FOR EACH ROW
DECLARE
   v_bin             cms_prod_bin.cpb_inst_bin%TYPE;
   v_prod_prefix     cms_prod_cattype.cpc_prod_prefix%TYPE;
   v_cardtype_desc   cms_prod_cattype.cpc_cardtype_desc%TYPE;
   v_inst_code       cms_iris_prodcatgmast.cpm_inst_code%TYPE;
   v_prod_code       cms_iris_prodcatgmast.cpm_prod_code%TYPE;
   v_prod_catg       cms_iris_prodcatgmast.cpm_catg_code%TYPE;
   v_errmsg          VARCHAR2 (300);
   exp_raise_error   EXCEPTION;
   /********************************************************************************************
      * Created BY      : Pankaj S.
      * Created for     : Mantis Id-0010031
      * Creatd Date    : 25/01/2013
      * Reviewer         : Dhiraj
      * Reviewed Date    : 25/01/2013
    ************************************************************************************************/
BEGIN                                                    --Trigger body begins
   IF INSERTING THEN
      v_inst_code := :NEW.cpm_inst_code;
      v_prod_code := :NEW.cpm_prod_code;
      v_prod_catg := :NEW.cpm_catg_code;
   ELSE
      v_inst_code := :OLD.cpm_inst_code;
      v_prod_code := :OLD.cpm_prod_code;
      v_prod_catg := :OLD.cpm_catg_code;
   END IF;

   BEGIN
      SELECT cpc_prod_prefix, cpc_cardtype_desc, cpb_inst_bin
        INTO v_prod_prefix, v_cardtype_desc, v_bin
        FROM cms_prod_cattype, cms_prod_bin
       WHERE cpb_prod_code = cpc_prod_code
         AND cpb_inst_code = cpc_inst_code
         AND cpc_inst_code = v_inst_code
         AND cpc_prod_code = v_prod_code
         AND cpc_card_type = v_prod_catg;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_application_error (-20004,'Error while selecting product details-'|| SUBSTR (SQLERRM, 1, 200));
   END;

   IF (INSERTING OR UPDATING) AND :NEW.cpm_iris_flag='Y' THEN
      -- For Card Type [ Bin + Sub Bin]
      BEGIN
         INSERT INTO cms_lookup_mast
                     (clm_inst_code, clm_record_type, clm_file_name,
                      clm_field_name, clm_code_name, clm_code_desc,
                      clm_ins_date, clm_ins_user
                     )
              VALUES (:NEW.cpm_inst_code, 'D', 'C',
                      'Card_Type', v_bin || v_prod_prefix, v_cardtype_desc,
                      SYSDATE, :NEW.cpm_ins_user
                     );
      EXCEPTION
         WHEN OTHERS THEN
            raise_application_error(-20001,'Error while creating record in lookup segment for card type'|| SUBSTR (SQLERRM, 1, 200));
      END;

      -- For Product ID [ Bin + Sub Bin]
      BEGIN
         INSERT INTO cms_lookup_mast
                     (clm_inst_code, clm_record_type, clm_file_name,
                      clm_field_name, clm_code_name, clm_code_desc,
                      clm_ins_date, clm_ins_user
                     )
              VALUES (:NEW.cpm_inst_code, 'D', 'A',
                      'Product_ID', v_bin || v_prod_prefix, v_cardtype_desc,
                      SYSDATE, :NEW.cpm_ins_user
                     );
      EXCEPTION
         WHEN OTHERS THEN
            raise_application_error(-20002,'Error while creating record in lookup segment For product ID'|| SUBSTR (SQLERRM, 1, 200));
      END;
   ELSIF UPDATING AND :NEW.cpm_iris_flag='N' THEN
      BEGIN
         DELETE FROM cms_lookup_mast
               WHERE clm_code_name = v_bin || v_prod_prefix
                 AND clm_code_desc = v_cardtype_desc;

         IF SQL%ROWCOUNT = 0 THEN
            v_errmsg := 'Prod prefix not found for deleting record';
            RAISE exp_raise_error;
         END IF;
      EXCEPTION
         WHEN exp_raise_error THEN
            raise_application_error (-20005, v_errmsg);
         WHEN OTHERS THEN
            raise_application_error(-20006,'Error while deleting record in lookup segment-'|| SUBSTR (SQLERRM, 1, 200));
      END;
   END IF;
END;                                                       --Trigger body ends
/
SHOW ERRORS;