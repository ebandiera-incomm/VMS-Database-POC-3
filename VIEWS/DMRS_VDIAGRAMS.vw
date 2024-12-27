/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrs_vdiagrams (diagram_name,
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
                                                    notation,
                                                    show_all_details,
                                                    show_names_only,
                                                    show_elements,
                                                    show_datatype,
                                                    SHOW_KEYS,
                                                    autoroute,
                                                    box_in_box,
                                                    diagram_svg,
                                                    diagram_pdf,
                                                    design_ovid,
                                                    pdf_name
                                                   )
AS
   SELECT diagram_name, object_id, ovid, diagram_type, is_display, visible,
          master_diagram_id, master_diagram_ovid, model_id, model_ovid,
          model_name, notation, show_all_details, show_names_only,
          show_elements, show_datatype, SHOW_KEYS, autoroute, box_in_box,
          diagram_svg, diagram_pdf, design_ovid, diagram_name || '.PDF'
     FROM dmrs_diagrams;


