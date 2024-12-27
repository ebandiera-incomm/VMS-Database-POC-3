/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_notes (object_id,
                                                ovid,
                                                object_name,
                                                model_ovid,
                                                model_id,
                                                model_name,
                                                design_ovid
                                               )
AS
   SELECT object_id, ovid, object_name, model_ovid, model_id, model_name,
          design_ovid
     FROM dmrs_notes;


