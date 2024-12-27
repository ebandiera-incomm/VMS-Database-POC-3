/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_spatial_column_definition (table_id,
                                                                    table_ovid,
                                                                    definition_id,
                                                                    definition_ovid,
                                                                    definition_name,
                                                                    table_name,
                                                                    column_id,
                                                                    column_ovid,
                                                                    column_name,
                                                                    use_function,
                                                                    function_expression,
                                                                    coordinate_system_id,
                                                                    has_spatial_index,
                                                                    spatial_index_id,
                                                                    spatial_index_ovid,
                                                                    spatial_index_name,
                                                                    design_ovid
                                                                   )
AS
   SELECT table_id, table_ovid, definition_id, definition_ovid,
          definition_name, table_name, column_id, column_ovid, column_name,
          use_function, function_expression, coordinate_system_id,
          has_spatial_index, spatial_index_id, spatial_index_ovid,
          spatial_index_name, design_ovid
     FROM dmrs_spatial_column_definition;


