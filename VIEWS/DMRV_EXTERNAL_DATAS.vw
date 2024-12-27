/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_external_datas (external_data_id,
                                                         external_data_ovid,
                                                         external_data_name,
                                                         model_id,
                                                         model_ovid,
                                                         model_name,
                                                         logical_type_id,
                                                         logical_type_ovid,
                                                         logical_type_name,
                                                         starting_pos,
                                                         description,
                                                         design_ovid
                                                        )
AS
   SELECT external_data_id, external_data_ovid, external_data_name, model_id,
          model_ovid, model_name, logical_type_id, logical_type_ovid,
          logical_type_name, starting_pos, description, design_ovid
     FROM dmrs_external_datas;


