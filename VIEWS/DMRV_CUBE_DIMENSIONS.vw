/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_cube_dimensions (cube_id,
                                                          cube_name,
                                                          cube_ovid,
                                                          dimension_id,
                                                          dimension_name,
                                                          dimension_ovid,
                                                          design_ovid
                                                         )
AS
   SELECT cube_id, cube_name, cube_ovid, dimension_id, dimension_name,
          dimension_ovid, design_ovid
     FROM dmrs_cube_dimensions;


