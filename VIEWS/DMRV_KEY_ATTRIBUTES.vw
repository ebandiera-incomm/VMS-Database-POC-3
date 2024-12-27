/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_key_attributes (key_id,
                                                         key_ovid,
                                                         attribute_id,
                                                         attribute_ovid,
                                                         entity_id,
                                                         entity_ovid,
                                                         key_name,
                                                         entity_name,
                                                         attribute_name,
                                                         SEQUENCE,
                                                         relationship_id,
                                                         relationship_ovid,
                                                         relationship_name,
                                                         design_ovid
                                                        )
AS
   SELECT key_id, key_ovid, attribute_id, attribute_ovid, entity_id,
          entity_ovid, key_name, entity_name, attribute_name, SEQUENCE,
          relationship_id, relationship_ovid, relationship_name, design_ovid
     FROM dmrs_key_attributes;


