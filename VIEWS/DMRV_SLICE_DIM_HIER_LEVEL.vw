/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_slice_dim_hier_level (slice_id,
                                                               slice_name,
                                                               slice_ovid,
                                                               dimension_id,
                                                               dimension_name,
                                                               dimension_ovid,
                                                               hierarchy_id,
                                                               hierarchy_name,
                                                               hierarchy_ovid,
                                                               level_id,
                                                               level_name,
                                                               level_ovid,
                                                               design_ovid
                                                              )
AS
   SELECT slice_id, slice_name, slice_ovid, dimension_id, dimension_name,
          dimension_ovid, hierarchy_id, hierarchy_name, hierarchy_ovid,
          level_id, level_name, level_ovid, design_ovid
     FROM dmrs_slice_dim_hier_level;


