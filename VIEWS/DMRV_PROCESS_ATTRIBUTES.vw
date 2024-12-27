/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_process_attributes (process_id,
                                                             process_ovid,
                                                             entity_id,
                                                             entity_ovid,
                                                             flow_id,
                                                             flow_ovid,
                                                             dfd_id,
                                                             dfd_ovid,
                                                             process_name,
                                                             entity_name,
                                                             flow_name,
                                                             dfd_name,
                                                             op_read,
                                                             op_create,
                                                             op_update,
                                                             op_delete,
                                                             crud_code,
                                                             flow_direction,
                                                             attribute_id,
                                                             attribute_ovid,
                                                             attribute_name,
                                                             design_ovid
                                                            )
AS
   SELECT process_id, process_ovid, entity_id, entity_ovid, flow_id,
          flow_ovid, dfd_id, dfd_ovid, process_name, entity_name, flow_name,
          dfd_name, op_read, op_create, op_update, op_delete, crud_code,
          flow_direction, attribute_id, attribute_ovid, attribute_name,
          design_ovid
     FROM dmrs_process_attributes;


