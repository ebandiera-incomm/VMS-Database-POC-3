/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_mappings (logical_model_id,
                                                   logical_model_ovid,
                                                   logical_model_name,
                                                   logical_object_id,
                                                   logical_object_ovid,
                                                   logical_object_name,
                                                   logical_object_type,
                                                   relational_model_id,
                                                   relational_model_ovid,
                                                   relational_model_name,
                                                   relational_object_id,
                                                   relational_object_ovid,
                                                   relational_object_name,
                                                   relational_object_type,
                                                   entity_id,
                                                   entity_ovid,
                                                   entity_name,
                                                   table_id,
                                                   table_ovid,
                                                   table_name,
                                                   design_id,
                                                   design_ovid,
                                                   design_name
                                                  )
AS
   SELECT logical_model_id, logical_model_ovid, logical_model_name,
          logical_object_id, logical_object_ovid, logical_object_name,
          logical_object_type, relational_model_id, relational_model_ovid,
          relational_model_name, relational_object_id, relational_object_ovid,
          relational_object_name, relational_object_type, entity_id,
          entity_ovid, entity_name, table_id, table_ovid, table_name,
          design_id, design_ovid, design_name
     FROM dmrs_mappings;


