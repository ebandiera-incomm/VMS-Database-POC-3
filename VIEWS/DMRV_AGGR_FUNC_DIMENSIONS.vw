/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_aggr_func_dimensions (aggregate_function_id,
                                                               aggregate_function_name,
                                                               aggregate_function_ovid,
                                                               dimension_id,
                                                               dimension_name,
                                                               dimension_ovid,
                                                               design_ovid
                                                              )
AS
   SELECT aggregate_function_id, aggregate_function_name,
          aggregate_function_ovid, dimension_id, dimension_name,
          dimension_ovid, design_ovid
     FROM dmrs_aggr_func_dimensions;


