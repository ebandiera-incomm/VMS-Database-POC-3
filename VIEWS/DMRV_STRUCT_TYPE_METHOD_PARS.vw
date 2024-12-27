/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_struct_type_method_pars (parameter_id,
                                                                  parameter_ovid,
                                                                  parameter_name,
                                                                  method_id,
                                                                  method_ovid,
                                                                  method_name,
                                                                  return_value,
                                                                  REFERENCE,
                                                                  seq,
                                                                  t_size,
                                                                  t_precision,
                                                                  t_scale,
                                                                  type_id,
                                                                  type_ovid,
                                                                  type_name,
                                                                  design_ovid
                                                                 )
AS
   SELECT parameter_id, parameter_ovid, parameter_name, method_id,
          method_ovid, method_name, return_value, REFERENCE, seq, t_size,
          t_precision, t_scale, type_id, type_ovid, type_name, design_ovid
     FROM dmrs_struct_type_method_pars;


