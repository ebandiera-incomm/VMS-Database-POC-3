/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_models (design_id,
                                                 design_ovid,
                                                 design_name,
                                                 model_id,
                                                 model_ovid,
                                                 model_name,
                                                 model_type,
                                                 rdbms_type
                                                )
AS
   SELECT design_id, design_ovid, design_name, model_id, model_ovid,
          model_name, model_type, rdbms_type
     FROM dmrs_models;


