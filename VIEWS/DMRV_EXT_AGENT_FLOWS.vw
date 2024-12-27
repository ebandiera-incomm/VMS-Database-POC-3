/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_ext_agent_flows (external_agent_id,
                                                          external_agent_ovid,
                                                          external_agent_name,
                                                          flow_id,
                                                          flow_ovid,
                                                          flow_name,
                                                          incoming_outgoing_flag,
                                                          design_ovid
                                                         )
AS
   SELECT external_agent_id, external_agent_ovid, external_agent_name,
          flow_id, flow_ovid, flow_name, incoming_outgoing_flag, design_ovid
     FROM dmrs_ext_agent_flows;


