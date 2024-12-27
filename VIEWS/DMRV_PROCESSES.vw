/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_processes (process_id,
                                                    process_ovid,
                                                    process_name,
                                                    diagram_id,
                                                    diagram_ovid,
                                                    diagram_name,
                                                    transformation_task_id,
                                                    transformation_task_ovid,
                                                    transformation_task_name,
                                                    parent_process_id,
                                                    parent_process_ovid,
                                                    parent_process_name,
                                                    process_number,
                                                    process_type,
                                                    process_mode,
                                                    priority,
                                                    frequency_times,
                                                    frequency_time_unit,
                                                    peak_periods_string,
                                                    parameters_wrappers_string,
                                                    interactive_max_response_time,
                                                    interactive_response_time_unit,
                                                    batch_min_transactions,
                                                    batch_time_unit,
                                                    design_ovid
                                                   )
AS
   SELECT process_id, process_ovid, process_name, diagram_id, diagram_ovid,
          diagram_name, transformation_task_id, transformation_task_ovid,
          transformation_task_name, parent_process_id, parent_process_ovid,
          parent_process_name, process_number, process_type, process_mode,
          priority, frequency_times, frequency_time_unit, peak_periods_string,
          parameters_wrappers_string, interactive_max_response_time,
          interactive_response_time_unit, batch_min_transactions,
          batch_time_unit, design_ovid
     FROM dmrs_processes;


