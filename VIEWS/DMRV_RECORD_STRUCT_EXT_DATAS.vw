/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_record_struct_ext_datas (record_structure_id,
                                                                  record_structure_ovid,
                                                                  record_structure_name,
                                                                  external_data_id,
                                                                  external_data_ovid,
                                                                  external_data_name,
                                                                  design_ovid
                                                                 )
AS
   SELECT record_structure_id, record_structure_ovid, record_structure_name,
          external_data_id, external_data_ovid, external_data_name,
          design_ovid
     FROM dmrs_record_struct_ext_datas;


