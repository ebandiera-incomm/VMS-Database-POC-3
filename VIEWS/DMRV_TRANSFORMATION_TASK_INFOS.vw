/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_transformation_task_infos (transformation_task_id,
                                                                    transformation_task_ovid,
                                                                    transformation_task_name,
                                                                    info_store_id,
                                                                    info_store_ovid,
                                                                    info_store_name,
                                                                    source_target_flag,
                                                                    design_ovid
                                                                   )
AS
   SELECT transformation_task_id, transformation_task_ovid,
          transformation_task_name, info_store_id, info_store_ovid,
          info_store_name, source_target_flag, design_ovid
     FROM dmrs_transformation_task_infos;


