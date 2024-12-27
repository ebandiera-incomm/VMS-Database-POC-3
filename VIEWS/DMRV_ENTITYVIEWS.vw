/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_entityviews (entityview_name,
                                                      object_id,
                                                      ovid,
                                                      model_id,
                                                      model_ovid,
                                                      import_id,
                                                      structured_type_id,
                                                      structured_type_ovid,
                                                      structured_type_name,
                                                      user_defined,
                                                      view_type,
                                                      model_name,
                                                      design_ovid
                                                     )
AS
   SELECT entityview_name, object_id, ovid, model_id, model_ovid, import_id,
          structured_type_id, structured_type_ovid, structured_type_name,
          user_defined, view_type, model_name, design_ovid
     FROM dmrs_entityviews;


