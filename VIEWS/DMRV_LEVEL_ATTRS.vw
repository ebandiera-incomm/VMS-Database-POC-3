/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_level_attrs (level_id,
                                                      level_name,
                                                      level_ovid,
                                                      attribute_id,
                                                      attribute_name,
                                                      attribute_ovid,
                                                      is_default_attr,
                                                      is_level_key_attr,
                                                      is_parent_key_attr,
                                                      is_descriptive_key_attr,
                                                      is_calculated_attr,
                                                      descriptive_name,
                                                      descriptive_is_indexed,
                                                      descriptive_slow_changing,
                                                      calculated_expr,
                                                      design_ovid
                                                     )
AS
   SELECT level_id, level_name, level_ovid, attribute_id, attribute_name,
          attribute_ovid, is_default_attr, is_level_key_attr,
          is_parent_key_attr, is_descriptive_key_attr, is_calculated_attr,
          descriptive_name, descriptive_is_indexed, descriptive_slow_changing,
          calculated_expr, design_ovid
     FROM dmrs_level_attrs;


