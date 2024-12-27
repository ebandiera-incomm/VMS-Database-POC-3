/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_mapping_targets (object_id,
                                                          object_ovid,
                                                          object_name,
                                                          target_id,
                                                          target_ovid,
                                                          target_name,
                                                          object_type,
                                                          target_type,
                                                          transformation_type,
                                                          description,
                                                          design_ovid
                                                         )
AS
   SELECT object_id, object_ovid, object_name, target_id, target_ovid,
          target_name, object_type, target_type, transformation_type,
          description, design_ovid
     FROM dmrs_mapping_targets;


