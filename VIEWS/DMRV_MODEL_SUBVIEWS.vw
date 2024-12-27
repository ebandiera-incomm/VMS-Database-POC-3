/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_model_subviews (subview_id,
                                                         subview_ovid,
                                                         subview_name,
                                                         model_id,
                                                         model_ovid,
                                                         model_name,
                                                         design_ovid
                                                        )
AS
   SELECT subview_id, subview_ovid, subview_name, model_id, model_ovid,
          model_name, design_ovid
     FROM dmrs_model_subviews;


