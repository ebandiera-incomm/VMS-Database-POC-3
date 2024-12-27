/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_designs (design_id,
                                                  design_ovid,
                                                  design_name,
                                                  date_published,
                                                  published_by,
                                                  persistence_version,
                                                  version_comments
                                                 )
AS
   SELECT design_id, design_ovid, design_name, date_published, published_by,
          persistence_version, version_comments
     FROM dmrs_designs;


