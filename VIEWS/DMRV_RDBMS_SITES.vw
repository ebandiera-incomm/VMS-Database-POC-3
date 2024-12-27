/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_rdbms_sites (site_name,
                                                      site_id,
                                                      site_ovid,
                                                      rdbms_type,
                                                      design_ovid
                                                     )
AS
   SELECT site_name, site_id, site_ovid, rdbms_type, design_ovid
     FROM dmrs_rdbms_sites;


