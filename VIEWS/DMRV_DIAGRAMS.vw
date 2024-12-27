/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_diagrams (diagram_name,
                                                   object_id,
                                                   ovid,
                                                   diagram_type,
                                                   is_display,
                                                   visible,
                                                   master_diagram_id,
                                                   master_diagram_ovid,
                                                   model_id,
                                                   model_ovid,
                                                   model_name,
                                                   subview_id,
                                                   subview_ovid,
                                                   subview_name,
                                                   display_id,
                                                   display_ovid,
                                                   display_name,
                                                   notation,
                                                   show_all_details,
                                                   show_names_only,
                                                   show_elements,
                                                   show_datatype,
                                                   SHOW_KEYS,
                                                   autoroute,
                                                   box_in_box,
                                                   master_diagram_name,
                                                   diagram_svg,
                                                   diagram_pdf,
                                                   design_ovid
                                                  )
AS
   SELECT diagram_name, object_id, ovid, diagram_type, is_display, visible,
          master_diagram_id, master_diagram_ovid, model_id, model_ovid,
          model_name, subview_id, subview_ovid, subview_name, display_id,
          display_ovid, display_name, notation, show_all_details,
          show_names_only, show_elements, show_datatype, SHOW_KEYS, autoroute,
          box_in_box, master_diagram_name, diagram_svg, diagram_pdf,
          design_ovid
     FROM dmrs_diagrams;


