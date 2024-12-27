/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_ragged_hier_links (ragged_hier_link_id,
                                                            ragged_hier_link_name,
                                                            ragged_hier_link_ovid,
                                                            model_id,
                                                            model_name,
                                                            model_ovid,
                                                            parent_level_id,
                                                            parent_level_name,
                                                            parent_level_ovid,
                                                            child_level_id,
                                                            child_level_name,
                                                            child_level_ovid,
                                                            description,
                                                            design_ovid
                                                           )
AS
   SELECT ragged_hier_link_id, ragged_hier_link_name, ragged_hier_link_ovid,
          model_id, model_name, model_ovid, parent_level_id,
          parent_level_name, parent_level_ovid, child_level_id,
          child_level_name, child_level_ovid, description, design_ovid
     FROM dmrs_ragged_hier_links;


