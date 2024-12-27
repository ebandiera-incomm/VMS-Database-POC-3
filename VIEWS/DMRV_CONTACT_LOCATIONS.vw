/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_contact_locations (contact_id,
                                                            contact_ovid,
                                                            contact_name,
                                                            location_id,
                                                            location_ovid,
                                                            location_name,
                                                            design_ovid
                                                           )
AS
   SELECT contact_id, contact_ovid, contact_name, location_id, location_ovid,
          location_name, design_ovid
     FROM dmrs_contact_locations;


