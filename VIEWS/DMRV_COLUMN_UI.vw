/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_column_ui (label,
                                                    format_mask,
                                                    form_display_width,
                                                    form_maximum_width,
                                                    display_as,
                                                    form_height,
                                                    displayed_on_forms,
                                                    displayed_on_reports,
                                                    read_only,
                                                    help_text,
                                                    object_id,
                                                    object_ovid,
                                                    object_name,
                                                    design_ovid
                                                   )
AS
   SELECT label, format_mask, form_display_width, form_maximum_width,
          display_as, form_height, displayed_on_forms, displayed_on_reports,
          read_only, help_text, object_id, object_ovid, object_name,
          design_ovid
     FROM dmrs_column_ui;


