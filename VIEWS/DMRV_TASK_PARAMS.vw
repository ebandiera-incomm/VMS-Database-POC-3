/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_task_params (task_params_id,
                                                      task_params_ovid,
                                                      task_params_name,
                                                      transformation_task_id,
                                                      transformation_task_ovid,
                                                      transformation_task_name,
                                                      task_params_type,
                                                      multiplicity,
                                                      system_objective,
                                                      design_ovid
                                                     )
AS
   SELECT task_params_id, task_params_ovid, task_params_name,
          transformation_task_id, transformation_task_ovid,
          transformation_task_name, task_params_type, multiplicity,
          system_objective, design_ovid
     FROM dmrs_task_params;


