/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_diagram_elements (NAME,
                                                           TYPE,
                                                           geometry_type,
                                                           object_id,
                                                           ovid,
                                                           view_id,
                                                           source_id,
                                                           source_ovid,
                                                           source_view_id,
                                                           target_id,
                                                           target_ovid,
                                                           target_view_id,
                                                           model_id,
                                                           model_ovid,
                                                           location_x,
                                                           height,
                                                           width,
                                                           bg_color,
                                                           fg_color,
                                                           use_default_color,
                                                           formatting,
                                                           points,
                                                           diagram_ovid,
                                                           diagram_id,
                                                           diagram_name,
                                                           source_name,
                                                           target_name,
                                                           model_name,
                                                           design_ovid
                                                          )
AS
   SELECT NAME, TYPE, geometry_type, object_id, ovid, view_id, source_id,
          source_ovid, source_view_id, target_id, target_ovid, target_view_id,
          model_id, model_ovid, location_x, height, width, bg_color, fg_color,
          use_default_color, formatting, points, diagram_ovid, diagram_id,
          diagram_name, source_name, target_name, model_name, design_ovid
     FROM dmrs_diagram_elements;


