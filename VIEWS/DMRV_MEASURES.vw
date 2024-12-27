/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_measures (measure_id,
                                                   measure_name,
                                                   measure_ovid,
                                                   model_id,
                                                   model_name,
                                                   model_ovid,
                                                   cube_id,
                                                   cube_name,
                                                   cube_ovid,
                                                   fact_object_id,
                                                   fact_object_name,
                                                   fact_object_ovid,
                                                   oracle_long_name,
                                                   oracle_plural_name,
                                                   oracle_short_name,
                                                   fact_object_type,
                                                   additivity_type,
                                                   is_fact_dimension,
                                                   is_formula,
                                                   is_custom_formula,
                                                   formula,
                                                   where_clause,
                                                   description,
                                                   design_ovid
                                                  )
AS
   SELECT measure_id, measure_name, measure_ovid, model_id, model_name,
          model_ovid, cube_id, cube_name, cube_ovid, fact_object_id,
          fact_object_name, fact_object_ovid, oracle_long_name,
          oracle_plural_name, oracle_short_name, fact_object_type,
          additivity_type, is_fact_dimension, is_formula, is_custom_formula,
          formula, where_clause, description, design_ovid
     FROM dmrs_measures;


