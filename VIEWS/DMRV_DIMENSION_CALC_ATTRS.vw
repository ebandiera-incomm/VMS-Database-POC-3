/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_dimension_calc_attrs (dimension_id,
                                                               dimension_name,
                                                               dimension_ovid,
                                                               calc_attribute_id,
                                                               calc_attribute_name,
                                                               calc_attribute_ovid,
                                                               calculated_expr,
                                                               design_ovid
                                                              )
AS
   SELECT dimension_id, dimension_name, dimension_ovid, calc_attribute_id,
          calc_attribute_name, calc_attribute_ovid, calculated_expr,
          design_ovid
     FROM dmrs_dimension_calc_attrs;


