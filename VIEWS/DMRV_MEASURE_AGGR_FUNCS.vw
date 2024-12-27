/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_measure_aggr_funcs (measure_id,
                                                             measure_name,
                                                             measure_ovid,
                                                             aggregate_function_id,
                                                             aggregate_function_name,
                                                             aggregate_function_ovid,
                                                             measure_alias,
                                                             is_default,
                                                             design_ovid
                                                            )
AS
   SELECT measure_id, measure_name, measure_ovid, aggregate_function_id,
          aggregate_function_name, aggregate_function_ovid, measure_alias,
          is_default, design_ovid
     FROM dmrs_measure_aggr_funcs;


