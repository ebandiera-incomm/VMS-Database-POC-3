/* Formatted on 2012/07/02 15:15 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_keys (key_name,
                                               object_id,
                                               ovid,
                                               import_id,
                                               container_id,
                                               container_ovid,
                                               state,
                                               synonyms,
                                               entity_name,
                                               design_ovid
                                              )
AS
   SELECT key_name, object_id, ovid, import_id, container_id, container_ovid,
          state, synonyms, entity_name, design_ovid
     FROM dmrs_keys;


