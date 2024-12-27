/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_model_naming_options (object_type,
                                                               max_name_length,
                                                               character_case,
                                                               valid_characters,
                                                               model_id,
                                                               model_ovid,
                                                               model_name,
                                                               model_type,
                                                               design_ovid
                                                              )
AS
   SELECT object_type, max_name_length, character_case, valid_characters,
          model_id, model_ovid, model_name, model_type, design_ovid
     FROM dmrs_model_naming_options;


