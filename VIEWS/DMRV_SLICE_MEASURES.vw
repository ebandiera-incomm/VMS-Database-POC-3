/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_slice_measures (slice_id,
                                                         slice_name,
                                                         slice_ovid,
                                                         measure_id,
                                                         measure_name,
                                                         measure_ovid,
                                                         aggregate_function_id,
                                                         aggregate_function_name,
                                                         aggregate_function_ovid,
                                                         measure_alias,
                                                         design_ovid
                                                        )
AS
   SELECT slice_id, slice_name, slice_ovid, measure_id, measure_name,
          measure_ovid, aggregate_function_id, aggregate_function_name,
          aggregate_function_ovid, measure_alias, design_ovid
     FROM dmrs_slice_measures;


