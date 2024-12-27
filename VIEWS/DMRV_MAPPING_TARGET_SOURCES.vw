/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_mapping_target_sources (object_id,
                                                                 object_ovid,
                                                                 object_name,
                                                                 target_id,
                                                                 target_ovid,
                                                                 target_name,
                                                                 source_id,
                                                                 source_ovid,
                                                                 source_name,
                                                                 object_type,
                                                                 target_type,
                                                                 source_type,
                                                                 design_ovid
                                                                )
AS
   SELECT object_id, object_ovid, object_name, target_id, target_ovid,
          target_name, source_id, source_ovid, source_name, object_type,
          target_type, source_type, design_ovid
     FROM dmrs_mapping_target_sources;


