/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_dimension_levels (dimension_id,
                                                           dimension_name,
                                                           dimension_ovid,
                                                           level_id,
                                                           level_name,
                                                           level_ovid,
                                                           design_ovid
                                                          )
AS
   SELECT dimension_id, dimension_name, dimension_ovid, level_id, level_name,
          level_ovid, design_ovid
     FROM dmrs_dimension_levels;


