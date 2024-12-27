/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_resource_locators (resource_locator_id,
                                                            resource_locator_ovid,
                                                            resource_locator_name,
                                                            business_info_id,
                                                            business_info_ovid,
                                                            business_info_name,
                                                            url,
                                                            design_ovid
                                                           )
AS
   SELECT resource_locator_id, resource_locator_ovid, resource_locator_name,
          business_info_id, business_info_ovid, business_info_name, url,
          design_ovid
     FROM dmrs_resource_locators;


