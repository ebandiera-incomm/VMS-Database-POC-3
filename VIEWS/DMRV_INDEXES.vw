/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_indexes (index_name,
                                                  object_id,
                                                  ovid,
                                                  import_id,
                                                  container_id,
                                                  container_ovid,
                                                  state,
                                                  functional,
                                                  expression,
                                                  engineer,
                                                  table_name,
                                                  spatial_index,
                                                  spatial_layer_type,
                                                  geodetic_index,
                                                  number_of_dimensions,
                                                  design_ovid
                                                 )
AS
   SELECT index_name, object_id, ovid, import_id, container_id,
          container_ovid, state, functional, expression, engineer, table_name,
          spatial_index, spatial_layer_type, geodetic_index,
          number_of_dimensions, design_ovid
     FROM dmrs_indexes;


