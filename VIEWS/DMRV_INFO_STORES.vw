/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_info_stores (info_store_id,
                                                      info_store_ovid,
                                                      info_store_name,
                                                      model_id,
                                                      model_ovid,
                                                      model_name,
                                                      info_store_type,
                                                      object_type,
                                                      implementation_name,
                                                      LOCATION,
                                                      SOURCE,
                                                      file_name,
                                                      file_type,
                                                      owner,
                                                      rdbms_site,
                                                      SCOPE,
                                                      transfer_type,
                                                      field_separator,
                                                      text_delimiter,
                                                      skip_records,
                                                      self_describing,
                                                      system_objective,
                                                      design_ovid
                                                     )
AS
   SELECT info_store_id, info_store_ovid, info_store_name, model_id,
          model_ovid, model_name, info_store_type, object_type,
          implementation_name, LOCATION, SOURCE, file_name, file_type, owner,
          rdbms_site, SCOPE, transfer_type, field_separator, text_delimiter,
          skip_records, self_describing, system_objective, design_ovid
     FROM dmrs_info_stores;


