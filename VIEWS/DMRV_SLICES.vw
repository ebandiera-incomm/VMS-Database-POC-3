/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_slices (slice_id,
                                                 slice_name,
                                                 slice_ovid,
                                                 model_id,
                                                 model_name,
                                                 model_ovid,
                                                 cube_id,
                                                 cube_name,
                                                 cube_ovid,
                                                 entity_id,
                                                 entity_name,
                                                 entity_ovid,
                                                 oracle_long_name,
                                                 oracle_plural_name,
                                                 oracle_short_name,
                                                 is_fully_realized,
                                                 is_read_only,
                                                 description,
                                                 design_ovid
                                                )
AS
   SELECT slice_id, slice_name, slice_ovid, model_id, model_name, model_ovid,
          cube_id, cube_name, cube_ovid, entity_id, entity_name, entity_ovid,
          oracle_long_name, oracle_plural_name, oracle_short_name,
          is_fully_realized, is_read_only, description, design_ovid
     FROM dmrs_slices;


