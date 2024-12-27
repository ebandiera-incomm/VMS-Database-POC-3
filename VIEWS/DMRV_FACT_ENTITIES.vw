/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_fact_entities (cube_id,
                                                        cube_name,
                                                        cube_ovid,
                                                        entity_id,
                                                        entity_name,
                                                        entity_ovid,
                                                        design_ovid
                                                       )
AS
   SELECT cube_id, cube_name, cube_ovid, entity_id, entity_name, entity_ovid,
          design_ovid
     FROM dmrs_fact_entities;


