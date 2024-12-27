/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_structured_types (design_id,
                                                           design_ovid,
                                                           design_name,
                                                           model_ovid,
                                                           model_name,
                                                           structured_type_id,
                                                           structured_type_ovid,
                                                           structured_type_name,
                                                           super_type_id,
                                                           super_type_ovid,
                                                           super_type_name,
                                                           predefined,
                                                           st_final,
                                                           st_instantiable
                                                          )
AS
   SELECT design_id, design_ovid, design_name, model_ovid, model_name,
          structured_type_id, structured_type_ovid, structured_type_name,
          super_type_id, super_type_ovid, super_type_name, predefined,
          st_final, st_instantiable
     FROM dmrs_structured_types;


