/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_view_columns (view_ovid,
                                                       view_id,
                                                       view_name,
                                                       container_id,
                                                       container_ovid,
                                                       container_name,
                                                       container_alias,
                                                       is_expression,
                                                       column_id,
                                                       column_ovid,
                                                       column_name,
                                                       column_alias,
                                                       native_type,
                                                       TYPE,
                                                       expression,
                                                       SEQUENCE,
                                                       personally_id_information,
                                                       sensitive_information,
                                                       mask_for_none_production,
                                                       model_id,
                                                       model_ovid,
                                                       model_name,
                                                       design_ovid
                                                      )
AS
   SELECT view_ovid, view_id, view_name, container_id, container_ovid,
          container_name, container_alias, is_expression, column_id,
          column_ovid, column_name, column_alias, native_type, TYPE,
          expression, SEQUENCE, personally_id_information,
          sensitive_information, mask_for_none_production, model_id,
          model_ovid, model_name, design_ovid
     FROM dmrs_view_columns;


