/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_logical_to_native (design_id,
                                                            design_ovid,
                                                            design_name,
                                                            logical_type_id,
                                                            logical_type_ovid,
                                                            lt_name,
                                                            native_type,
                                                            rdbms_type,
                                                            rdbms_version,
                                                            has_size,
                                                            has_precision,
                                                            has_scale
                                                           )
AS
   SELECT design_id, design_ovid, design_name, logical_type_id,
          logical_type_ovid, lt_name, native_type, rdbms_type, rdbms_version,
          has_size, has_precision, has_scale
     FROM dmrs_logical_to_native;


