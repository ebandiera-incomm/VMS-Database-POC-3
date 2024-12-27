/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_struct_type_methods (method_id,
                                                              method_ovid,
                                                              method_name,
                                                              structured_type_id,
                                                              structured_type_ovid,
                                                              structured_type_name,
                                                              BODY,
                                                              CONSTRUCTOR,
                                                              overridden_method_id,
                                                              overridden_method_ovid,
                                                              overridden_method_name,
                                                              design_ovid
                                                             )
AS
   SELECT stm.method_id, stm.method_ovid, stm.method_name,
          stm.structured_type_id, stm.structured_type_ovid,
          stm.structured_type_name, lt.text, stm.CONSTRUCTOR,
          stm.overridden_method_id, stm.overridden_method_ovid,
          stm.overridden_method_name, stm.design_ovid
     FROM dmrs_struct_type_methods stm, dmrs_large_text lt
    WHERE stm.method_id = lt.object_id;


