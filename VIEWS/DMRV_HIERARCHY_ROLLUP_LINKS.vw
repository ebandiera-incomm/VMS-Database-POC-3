/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_hierarchy_rollup_links (hierarchy_id,
                                                                 hierarchy_name,
                                                                 hierarchy_ovid,
                                                                 rollup_link_id,
                                                                 rollup_link_name,
                                                                 rollup_link_ovid,
                                                                 design_ovid
                                                                )
AS
   SELECT hierarchy_id, hierarchy_name, hierarchy_ovid, rollup_link_id,
          rollup_link_name, rollup_link_ovid, design_ovid
     FROM dmrs_hierarchy_rollup_links;


