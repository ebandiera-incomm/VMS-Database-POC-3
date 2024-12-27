/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_struct_type_attrs (attribute_id,
                                                            attribute_ovid,
                                                            attribute_name,
                                                            structured_type_id,
                                                            structured_type_ovid,
                                                            structured_type_name,
                                                            mandatory,
                                                            REFERENCE,
                                                            t_size,
                                                            t_precision,
                                                            t_scale,
                                                            type_id,
                                                            type_ovid,
                                                            type_name,
                                                            design_ovid
                                                           )
AS
   SELECT attribute_id, attribute_ovid, attribute_name, structured_type_id,
          structured_type_ovid, structured_type_name, mandatory, REFERENCE,
          t_size, t_precision, t_scale, type_id, type_ovid, type_name,
          design_ovid
     FROM dmrs_struct_type_attrs;


