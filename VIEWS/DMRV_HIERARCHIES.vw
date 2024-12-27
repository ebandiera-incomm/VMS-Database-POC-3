/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_hierarchies (hierarchy_id,
                                                      hierarchy_name,
                                                      hierarchy_ovid,
                                                      model_id,
                                                      model_name,
                                                      model_ovid,
                                                      dimension_id,
                                                      dimension_name,
                                                      dimension_ovid,
                                                      oracle_long_name,
                                                      oracle_plural_name,
                                                      oracle_short_name,
                                                      is_default_hierarchy,
                                                      is_ragged_hierarchy,
                                                      is_value_based_hierarchy,
                                                      description,
                                                      design_ovid
                                                     )
AS
   SELECT hierarchy_id, hierarchy_name, hierarchy_ovid, model_id, model_name,
          model_ovid, dimension_id, dimension_name, dimension_ovid,
          oracle_long_name, oracle_plural_name, oracle_short_name,
          is_default_hierarchy, is_ragged_hierarchy, is_value_based_hierarchy,
          description, design_ovid
     FROM dmrs_hierarchies;


