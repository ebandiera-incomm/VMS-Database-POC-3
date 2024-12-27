/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_contacts (contact_id,
                                                   contact_ovid,
                                                   contact_name,
                                                   business_info_id,
                                                   business_info_ovid,
                                                   business_info_name,
                                                   design_ovid
                                                  )
AS
   SELECT contact_id, contact_ovid, contact_name, business_info_id,
          business_info_ovid, business_info_name, design_ovid
     FROM dmrs_contacts;


