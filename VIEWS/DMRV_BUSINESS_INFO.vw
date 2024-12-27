/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_business_info (design_id,
                                                        design_ovid,
                                                        design_name,
                                                        business_info_id,
                                                        business_info_ovid,
                                                        business_info_name
                                                       )
AS
   SELECT design_id, design_ovid, design_name, business_info_id,
          business_info_ovid, business_info_name
     FROM dmrs_business_info;


