/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_distinct_types (design_id,
                                                         design_ovid,
                                                         design_name,
                                                         distinct_type_id,
                                                         distinct_type_ovid,
                                                         distinct_type_name,
                                                         logical_type_id,
                                                         logical_type_ovid,
                                                         logical_type_name,
                                                         t_size,
                                                         t_precision,
                                                         t_scale
                                                        )
AS
   SELECT design_id, design_ovid, design_name, distinct_type_id,
          distinct_type_ovid, distinct_type_name, logical_type_id,
          logical_type_ovid, logical_type_name, t_size, t_precision, t_scale
     FROM dmrs_distinct_types;


