/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_native_to_logical (rdbms_type,
                                                            rdbms_version,
                                                            native_type,
                                                            lt_name,
                                                            logical_type_id,
                                                            logical_type_ovid,
                                                            design_id,
                                                            design_ovid,
                                                            design_name
                                                           )
AS
   SELECT rdbms_type, rdbms_version, native_type, lt_name, logical_type_id,
          logical_type_ovid, design_id, design_ovid, design_name
     FROM dmrs_native_to_logical;


