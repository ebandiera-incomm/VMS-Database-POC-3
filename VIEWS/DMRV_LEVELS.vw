/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_levels (level_id,
                                                 level_name,
                                                 level_ovid,
                                                 model_id,
                                                 model_name,
                                                 model_ovid,
                                                 entity_id,
                                                 entity_name,
                                                 entity_ovid,
                                                 name_column_id,
                                                 name_column_name,
                                                 name_column_ovid,
                                                 value_column_id,
                                                 value_column_name,
                                                 value_column_ovid,
                                                 oracle_long_name,
                                                 oracle_plural_name,
                                                 oracle_short_name,
                                                 root_identification,
                                                 identification_value,
                                                 selection_criteria,
                                                 selection_criteria_description,
                                                 is_value_based_hierarchy,
                                                 description,
                                                 design_ovid
                                                )
AS
   SELECT level_id, level_name, level_ovid, model_id, model_name, model_ovid,
          entity_id, entity_name, entity_ovid, name_column_id,
          name_column_name, name_column_ovid, value_column_id,
          value_column_name, value_column_ovid, oracle_long_name,
          oracle_plural_name, oracle_short_name, root_identification,
          identification_value, selection_criteria,
          selection_criteria_description, is_value_based_hierarchy,
          description, design_ovid
     FROM dmrs_levels;


