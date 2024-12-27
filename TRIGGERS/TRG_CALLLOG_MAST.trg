CREATE OR REPLACE TRIGGER vmscms.trg_calllog_mast
   BEFORE INSERT
   ON vmscms.cms_calllog_mast
   FOR EACH ROW
BEGIN                                                    --Trigger body begins
   SELECT cpp_partner_id
     INTO :NEW.ccm_partner_id
     FROM cms_appl_pan, cms_product_param
    WHERE     cap_pan_code = :NEW.ccm_pan_code
          AND cpp_prod_code = cap_prod_code
          AND cpp_inst_code = cap_inst_code;
EXCEPTION
   WHEN OTHERS
   THEN
      NULL;
END;
/
SHOW ERROR