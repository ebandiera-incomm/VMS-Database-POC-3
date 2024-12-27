CREATE OR REPLACE TRIGGER vmscms.trg_cms_dispute_txns
   BEFORE INSERT
   ON vmscms.cms_dispute_txns
   FOR EACH ROW
BEGIN
   BEGIN
      SELECT cpp_partner_id
        INTO :NEW.cdt_partner_id
        FROM cms_appl_pan, cms_product_param
       WHERE     cap_pan_code = :NEW.cdt_pan_code
             AND cpp_prod_code = cap_prod_code
             AND cpp_inst_code = cap_inst_code;
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;
END;
/
SHOW ERROR