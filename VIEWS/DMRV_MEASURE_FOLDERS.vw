/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_measure_folders (measure_folder_id,
                                                          measure_folder_name,
                                                          measure_folder_ovid,
                                                          model_id,
                                                          model_name,
                                                          model_ovid,
                                                          parent_folder_id,
                                                          parent_folder_name,
                                                          parent_folder_ovid,
                                                          oracle_long_name,
                                                          oracle_plural_name,
                                                          oracle_short_name,
                                                          is_leaf,
                                                          description,
                                                          design_ovid
                                                         )
AS
   SELECT measure_folder_id, measure_folder_name, measure_folder_ovid,
          model_id, model_name, model_ovid, parent_folder_id,
          parent_folder_name, parent_folder_ovid, oracle_long_name,
          oracle_plural_name, oracle_short_name, is_leaf, description,
          design_ovid
     FROM dmrs_measure_folders;


