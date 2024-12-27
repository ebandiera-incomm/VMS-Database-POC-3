/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_locations (location_id,
                                                    location_ovid,
                                                    location_name,
                                                    business_info_id,
                                                    business_info_ovid,
                                                    business_info_name,
                                                    loc_address,
                                                    loc_city,
                                                    loc_post_code,
                                                    loc_area,
                                                    loc_country,
                                                    loc_type,
                                                    design_ovid
                                                   )
AS
   SELECT location_id, location_ovid, location_name, business_info_id,
          business_info_ovid, business_info_name, loc_address, loc_city,
          loc_post_code, loc_area, loc_country, loc_type, design_ovid
     FROM dmrs_locations;


