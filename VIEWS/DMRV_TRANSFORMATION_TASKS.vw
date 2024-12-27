/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_transformation_tasks (transformation_task_id,
                                                               transformation_task_ovid,
                                                               transformation_task_name,
                                                               transformation_package_id,
                                                               transformation_package_ovid,
                                                               transformation_package_name,
                                                               process_id,
                                                               process_ovid,
                                                               process_name,
                                                               top_level,
                                                               design_ovid
                                                              )
AS
   SELECT transformation_task_id, transformation_task_ovid,
          transformation_task_name, transformation_package_id,
          transformation_package_ovid, transformation_package_name,
          process_id, process_ovid, process_name, top_level, design_ovid
     FROM dmrs_transformation_tasks;


