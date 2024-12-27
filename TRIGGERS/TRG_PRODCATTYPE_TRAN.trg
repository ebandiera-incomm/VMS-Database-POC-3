CREATE OR REPLACE TRIGGER VMSCMS.trg_prodcattype_tran
   BEFORE INSERT OR UPDATE
   ON cms_prod_cattype
   FOR EACH ROW
DECLARE
   prdcnt    NUMBER;
   packcnt   NUMBER;
   PACKID NUMBER;
BEGIN                                                    --Trigger body begins
   IF INSERTING THEN
      IF :NEW.cpc_prod_id IS NULL AND :NEW.cpc_package_id IS NULL THEN
         raise_application_error (-20003,'Product ID / Package ID Cannot be NULL');
      END IF;

      IF :NEW.cpc_prod_id IS NOT NULL AND :NEW.cpc_package_id IS NOT NULL THEN
         raise_application_error(-20003,'Product ID / Package ID Both Cannot be Provided');
      END IF;

      IF :NEW.cpc_prod_id IS NOT NULL THEN
         
            SELECT COUNT (*) INTO prdcnt FROM cms_prod_cattype  WHERE cpc_prod_id = :NEW.cpc_prod_id OR  cpc_package_id = :NEW.cpc_prod_id; 

            IF prdcnt > 0 THEN
               raise_application_error(-20003,'Product ID / Package ID Already Exists');
            END IF;
          
      END IF;

      IF :NEW.cpc_package_id IS NOT NULL THEN
         PACKID:=:NEW.cpc_package_id ;
            SELECT COUNT (*) INTO packcnt FROM cms_prod_cattype WHERE cpc_prod_id = :NEW.cpc_package_id  OR  cpc_package_id = :NEW.cpc_package_id ; 

            IF packcnt > 0 THEN
               raise_application_error(-20003,'Product ID / Package ID Already Exists');
            END IF;
      END IF;
   ELSIF UPDATING THEN
      IF :NEW.cpc_prod_id IS NULL AND :NEW.cpc_package_id IS NULL THEN
         raise_application_error (-20003,'Product ID / Package ID Cannot be NULL');
      END IF;

      IF :NEW.cpc_prod_id IS NOT NULL AND :NEW.cpc_package_id IS NOT NULL THEN
         raise_application_error(-20003,'Product ID / Package ID Both Cannot be Provided');
      END IF;

   /*  IF :NEW.cpc_prod_id IS NOT NULL THEN
         
            SELECT COUNT (*) INTO prdcnt FROM cms_prod_cattype WHERE cpc_prod_id = :NEW.cpc_prod_id OR cpc_package_id = :NEW.cpc_prod_id;

            IF prdcnt > 0
            THEN
               raise_application_error(-20003,'Product ID / Package ID Already Exists');
            END IF;
         
      END IF;

      IF :NEW.cpc_package_id IS NOT NULL THEN
          
            SELECT COUNT (*) INTO packcnt FROM cms_prod_cattype WHERE cpc_prod_id = :NEW.cpc_package_id OR cpc_package_id = :NEW.cpc_package_id;

            IF packcnt > 0 THEN 
               raise_application_error(-20003,'Product ID / Package ID Already Exists');
            END IF;
        
      END IF;*/
   END IF;
END;                                                       --Trigger body ends
/


