/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_flows (flow_id,
                                                flow_ovid,
                                                flow_name,
                                                diagram_id,
                                                diagram_ovid,
                                                diagram_name,
                                                event_id,
                                                event_ovid,
                                                event_name,
                                                source_id,
                                                source_ovid,
                                                source_name,
                                                destination_id,
                                                destination_ovid,
                                                destination_name,
                                                parent_id,
                                                parent_ovid,
                                                parent_name,
                                                source_type,
                                                destination_type,
                                                system_objective,
                                                LOGGING,
                                                op_create,
                                                op_read,
                                                op_update,
                                                op_delete,
                                                crud_code,
                                                design_ovid
                                               )
AS
   SELECT flow_id, flow_ovid, flow_name, diagram_id, diagram_ovid,
          diagram_name, event_id, event_ovid, event_name, source_id,
          source_ovid, source_name, destination_id, destination_ovid,
          destination_name, parent_id, parent_ovid, parent_name, source_type,
          destination_type, system_objective, LOGGING, op_create, op_read,
          op_update, op_delete, crud_code, design_ovid
     FROM dmrs_flows;


