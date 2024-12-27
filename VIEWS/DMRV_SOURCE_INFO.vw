/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_source_info (source_info_ovid,
                                                      source_info_type,
                                                      ddl_file_name,
                                                      ddl_path_name,
                                                      ddl_db_type,
                                                      datadict_connection_name,
                                                      datadict_connection_url,
                                                      datadict_db_type,
                                                      model_id,
                                                      model_ovid,
                                                      model_name,
                                                      design_ovid
                                                     )
AS
   SELECT source_info_ovid, source_info_type, ddl_file_name, ddl_path_name,
          ddl_db_type, datadict_connection_name, datadict_connection_url,
          datadict_db_type, model_id, model_ovid, model_name, design_ovid
     FROM dmrs_source_info;


