/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_contact_res_locators (contact_id,
                                                               contact_ovid,
                                                               contact_name,
                                                               resource_locator_id,
                                                               resource_locator_ovid,
                                                               resource_locator_name,
                                                               design_ovid
                                                              )
AS
   SELECT contact_id, contact_ovid, contact_name, resource_locator_id,
          resource_locator_ovid, resource_locator_name, design_ovid
     FROM dmrs_contact_res_locators;


