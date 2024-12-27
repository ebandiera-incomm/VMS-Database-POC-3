/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_domains (domain_id,
                                                  domain_name,
                                                  ovid,
                                                  synonyms,
                                                  logical_type_id,
                                                  logical_type_ovid,
                                                  t_size,
                                                  t_precision,
                                                  t_scale,
                                                  native_type,
                                                  lt_name,
                                                  design_id,
                                                  design_ovid,
                                                  design_name,
                                                  DEFAULT_VALUE,
                                                  unit_of_measure,
                                                  char_units
                                                 )
AS
   SELECT domain_id, domain_name, ovid, synonyms, logical_type_id,
          logical_type_ovid, t_size, t_precision, t_scale, native_type,
          lt_name, design_id, design_ovid, design_name, DEFAULT_VALUE,
          unit_of_measure, char_units
     FROM dmrs_domains;


