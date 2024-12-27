/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_telephones (telephone_id,
                                                     telephone_ovid,
                                                     telephone_name,
                                                     business_info_id,
                                                     business_info_ovid,
                                                     business_info_name,
                                                     phone_number,
                                                     phone_type,
                                                     design_ovid
                                                    )
AS
   SELECT telephone_id, telephone_ovid, telephone_name, business_info_id,
          business_info_ovid, business_info_name, phone_number, phone_type,
          design_ovid
     FROM dmrs_telephones;


