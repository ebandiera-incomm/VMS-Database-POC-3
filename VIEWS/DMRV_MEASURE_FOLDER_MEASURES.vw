/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_measure_folder_measures (measure_folder_id,
                                                                  measure_folder_name,
                                                                  measure_folder_ovid,
                                                                  measure_id,
                                                                  measure_name,
                                                                  measure_ovid,
                                                                  parent_object_id,
                                                                  parent_object_name,
                                                                  parent_object_ovid,
                                                                  parent_object_type,
                                                                  design_ovid
                                                                 )
AS
   SELECT measure_folder_id, measure_folder_name, measure_folder_ovid,
          measure_id, measure_name, measure_ovid, parent_object_id,
          parent_object_name, parent_object_ovid, parent_object_type,
          design_ovid
     FROM dmrs_measure_folder_measures;


