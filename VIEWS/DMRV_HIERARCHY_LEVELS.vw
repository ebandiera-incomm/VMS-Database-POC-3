/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_hierarchy_levels (hierarchy_id,
                                                           hierarchy_name,
                                                           hierarchy_ovid,
                                                           level_id,
                                                           level_name,
                                                           level_ovid,
                                                           design_ovid
                                                          )
AS
   SELECT hierarchy_id, hierarchy_name, hierarchy_ovid, level_id, level_name,
          level_ovid, design_ovid
     FROM dmrs_hierarchy_levels;


