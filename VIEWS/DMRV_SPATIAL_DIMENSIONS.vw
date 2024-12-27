/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_spatial_dimensions (definition_id,
                                                             definition_ovid,
                                                             definition_name,
                                                             dimension_name,
                                                             low_boundary,
                                                             upper_boundary,
                                                             tolerance,
                                                             design_ovid
                                                            )
AS
   SELECT definition_id, definition_ovid, definition_name, dimension_name,
          low_boundary, upper_boundary, tolerance, design_ovid
     FROM dmrs_spatial_dimensions;


