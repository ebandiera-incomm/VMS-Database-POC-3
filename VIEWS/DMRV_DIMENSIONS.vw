/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_dimensions (dimension_id,
                                                     dimension_name,
                                                     dimension_ovid,
                                                     model_id,
                                                     model_name,
                                                     model_ovid,
                                                     base_entity_id,
                                                     base_entity_name,
                                                     base_entity_ovid,
                                                     base_level_id,
                                                     base_level_name,
                                                     base_level_ovid,
                                                     oracle_long_name,
                                                     oracle_plural_name,
                                                     oracle_short_name,
                                                     description,
                                                     design_ovid
                                                    )
AS
   SELECT dimension_id, dimension_name, dimension_ovid, model_id, model_name,
          model_ovid, base_entity_id, base_entity_name, base_entity_ovid,
          base_level_id, base_level_name, base_level_ovid, oracle_long_name,
          oracle_plural_name, oracle_short_name, description, design_ovid
     FROM dmrs_dimensions;


