/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_info_structures (info_structure_id,
                                                          info_structure_ovid,
                                                          info_structure_name,
                                                          model_id,
                                                          model_ovid,
                                                          model_name,
                                                          growth_rate_unit,
                                                          growth_rate_percent,
                                                          volume,
                                                          design_ovid
                                                         )
AS
   SELECT info_structure_id, info_structure_ovid, info_structure_name,
          model_id, model_ovid, model_name, growth_rate_unit,
          growth_rate_percent, volume, design_ovid
     FROM dmrs_info_structures;


