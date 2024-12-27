/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_fact_entities_joins (join_id,
                                                              join_name,
                                                              join_ovid,
                                                              cube_id,
                                                              cube_name,
                                                              cube_ovid,
                                                              left_entity_id,
                                                              left_entity_name,
                                                              left_entity_ovid,
                                                              right_entity_id,
                                                              right_entity_name,
                                                              right_entity_ovid,
                                                              design_ovid
                                                             )
AS
   SELECT join_id, join_name, join_ovid, cube_id, cube_name, cube_ovid,
          left_entity_id, left_entity_name, left_entity_ovid, right_entity_id,
          right_entity_name, right_entity_ovid, design_ovid
     FROM dmrs_fact_entities_joins;


