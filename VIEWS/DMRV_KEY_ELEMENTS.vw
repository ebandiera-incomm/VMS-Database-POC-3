/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_key_elements (key_id,
                                                       key_ovid,
                                                       TYPE,
                                                       element_id,
                                                       element_ovid,
                                                       element_name,
                                                       SEQUENCE,
                                                       source_label,
                                                       target_label,
                                                       entity_id,
                                                       key_name,
                                                       entity_ovid,
                                                       entity_name,
                                                       design_ovid
                                                      )
AS
   SELECT key_id, key_ovid, TYPE, element_id, element_ovid, element_name,
          SEQUENCE, source_label, target_label, entity_id, key_name,
          entity_ovid, entity_name, design_ovid
     FROM dmrs_key_elements;


