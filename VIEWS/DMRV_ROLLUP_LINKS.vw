/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_rollup_links (rollup_link_id,
                                                       rollup_link_name,
                                                       rollup_link_ovid,
                                                       model_id,
                                                       model_name,
                                                       model_ovid,
                                                       parent_object_id,
                                                       parent_object_name,
                                                       parent_object_ovid,
                                                       child_object_id,
                                                       child_object_name,
                                                       child_object_ovid,
                                                       fact_entity_id,
                                                       fact_entity_name,
                                                       fact_entity_ovid,
                                                       parent_object_type,
                                                       child_object_type,
                                                       oracle_long_name,
                                                       oracle_plural_name,
                                                       oracle_short_name,
                                                       default_aggr_operator,
                                                       is_role_playing,
                                                       is_sparse_dimension,
                                                       description,
                                                       design_ovid
                                                      )
AS
   SELECT rollup_link_id, rollup_link_name, rollup_link_ovid, model_id,
          model_name, model_ovid, parent_object_id, parent_object_name,
          parent_object_ovid, child_object_id, child_object_name,
          child_object_ovid, fact_entity_id, fact_entity_name,
          fact_entity_ovid, parent_object_type, child_object_type,
          oracle_long_name, oracle_plural_name, oracle_short_name,
          default_aggr_operator, is_role_playing, is_sparse_dimension,
          description, design_ovid
     FROM dmrs_rollup_links;


