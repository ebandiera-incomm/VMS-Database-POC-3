/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_transformation_flows (transformation_flow_id,
                                                               transformation_flow_ovid,
                                                               transformation_flow_name,
                                                               transformation_task_id,
                                                               transformation_task_ovid,
                                                               transformation_task_name,
                                                               source_id,
                                                               source_ovid,
                                                               source_name,
                                                               destination_id,
                                                               destination_ovid,
                                                               destination_name,
                                                               source_type,
                                                               destination_type,
                                                               system_objective,
                                                               LOGGING,
                                                               op_create,
                                                               op_read,
                                                               op_update,
                                                               op_delete,
                                                               crud_code,
                                                               design_ovid
                                                              )
AS
   SELECT transformation_flow_id, transformation_flow_ovid,
          transformation_flow_name, transformation_task_id,
          transformation_task_ovid, transformation_task_name, source_id,
          source_ovid, source_name, destination_id, destination_ovid,
          destination_name, source_type, destination_type, system_objective,
          LOGGING, op_create, op_read, op_update, op_delete, crud_code,
          design_ovid
     FROM dmrs_transformation_flows;


