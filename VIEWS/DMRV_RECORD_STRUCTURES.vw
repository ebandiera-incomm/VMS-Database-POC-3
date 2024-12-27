/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_record_structures (record_structure_id,
                                                            record_structure_ovid,
                                                            record_structure_name,
                                                            model_id,
                                                            model_ovid,
                                                            model_name,
                                                            design_ovid
                                                           )
AS
   SELECT record_structure_id, record_structure_ovid, record_structure_name,
          model_id, model_ovid, model_name, design_ovid
     FROM dmrs_record_structures;


