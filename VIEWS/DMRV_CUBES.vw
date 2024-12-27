/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_cubes (cube_id,
                                                cube_name,
                                                cube_ovid,
                                                model_id,
                                                model_name,
                                                model_ovid,
                                                part_dimension_id,
                                                part_dimension_name,
                                                part_dimension_ovid,
                                                part_hierarchy_id,
                                                part_hierarchy_name,
                                                part_hierarchy_ovid,
                                                part_level_id,
                                                part_level_name,
                                                part_level_ovid,
                                                full_cube_slice_id,
                                                full_cube_slice_name,
                                                full_cube_slice_ovid,
                                                oracle_long_name,
                                                oracle_plural_name,
                                                oracle_short_name,
                                                is_compressed_composites,
                                                is_global_composites,
                                                is_partitioned,
                                                is_virtual,
                                                part_description,
                                                description,
                                                design_ovid
                                               )
AS
   SELECT cube_id, cube_name, cube_ovid, model_id, model_name, model_ovid,
          part_dimension_id, part_dimension_name, part_dimension_ovid,
          part_hierarchy_id, part_hierarchy_name, part_hierarchy_ovid,
          part_level_id, part_level_name, part_level_ovid, full_cube_slice_id,
          full_cube_slice_name, full_cube_slice_ovid, oracle_long_name,
          oracle_plural_name, oracle_short_name, is_compressed_composites,
          is_global_composites, is_partitioned, is_virtual, part_description,
          description, design_ovid
     FROM dmrs_cubes;


