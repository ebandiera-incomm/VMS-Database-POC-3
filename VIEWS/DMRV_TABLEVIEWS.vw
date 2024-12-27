/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_tableviews (tableview_name,
                                                     object_id,
                                                     ovid,
                                                     import_id,
                                                     model_id,
                                                     model_ovid,
                                                     structured_type_id,
                                                     structured_type_ovid,
                                                     structured_type_name,
                                                     where_clause,
                                                     having_clause,
                                                     user_defined,
                                                     engineer,
                                                     allow_type_substitution,
                                                     oid_columns,
                                                     model_name,
                                                     design_ovid
                                                    )
AS
   SELECT tableview_name, object_id, ovid, import_id, model_id, model_ovid,
          structured_type_id, structured_type_ovid, structured_type_name,
          where_clause, having_clause, user_defined, engineer,
          allow_type_substitution, oid_columns, model_name, design_ovid
     FROM dmrs_tableviews;


