/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_model_displays (display_id,
                                                         display_ovid,
                                                         display_name,
                                                         model_id,
                                                         model_ovid,
                                                         model_name,
                                                         design_ovid
                                                        )
AS
   SELECT display_id, display_ovid, display_name, model_id, model_ovid,
          model_name, design_ovid
     FROM dmrs_model_displays;


