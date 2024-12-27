/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_task_params_items (task_params_item_id,
                                                            task_params_item_ovid,
                                                            task_params_item_name,
                                                            task_params_id,
                                                            task_params_ovid,
                                                            task_params_name,
                                                            logical_type_id,
                                                            logical_type_ovid,
                                                            logical_type_name,
                                                            task_params_item_type,
                                                            design_ovid
                                                           )
AS
   SELECT task_params_item_id, task_params_item_ovid, task_params_item_name,
          task_params_id, task_params_ovid, task_params_name, logical_type_id,
          logical_type_ovid, logical_type_name, task_params_item_type,
          design_ovid
     FROM dmrs_task_params_items;


