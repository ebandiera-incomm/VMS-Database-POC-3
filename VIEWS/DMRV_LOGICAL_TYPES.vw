/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_logical_types (design_id,
                                                        design_ovid,
                                                        design_name,
                                                        logical_type_id,
                                                        ovid,
                                                        lt_name
                                                       )
AS
   SELECT design_id, design_ovid, design_name, logical_type_id, ovid, lt_name
     FROM dmrs_logical_types;


