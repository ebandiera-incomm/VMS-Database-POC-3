CREATE OR REPLACE TRIGGER vmscms.trg_calllog_details
   BEFORE INSERT
   ON vmscms.cms_calllog_details
   FOR EACH ROW
BEGIN                                                    --Trigger body begins
   SELECT cpp_partner_id
     INTO :NEW.ccd_partner_id
     FROM cms_appl_pan, cms_product_param
    WHERE     cap_pan_code = :NEW.ccd_pan_code
          AND cpp_prod_code = cap_prod_code
          AND cpp_inst_code = cap_inst_code;
EXCEPTION
   WHEN OTHERS
   THEN
      NULL;
END;
/
SHOW ERROR