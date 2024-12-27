/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_collection_types (design_id,
                                                           design_ovid,
                                                           design_name,
                                                           collection_type_id,
                                                           collection_type_ovid,
                                                           collection_type_name,
                                                           c_type,
                                                           datatype_id,
                                                           datatype_ovid,
                                                           datatype_name,
                                                           dt_type,
                                                           dt_ref,
                                                           max_element,
                                                           predefined
                                                          )
AS
   SELECT design_id, design_ovid, design_name, collection_type_id,
          collection_type_ovid, collection_type_name, c_type, datatype_id,
          datatype_ovid, datatype_name, dt_type, dt_ref, max_element,
          predefined
     FROM dmrs_collection_types;


