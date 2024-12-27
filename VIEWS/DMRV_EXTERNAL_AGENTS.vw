/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_external_agents (external_agent_id,
                                                          external_agent_ovid,
                                                          external_agent_name,
                                                          diagram_id,
                                                          diagram_ovid,
                                                          diagram_name,
                                                          external_agent_type,
                                                          file_location,
                                                          file_source,
                                                          file_name,
                                                          file_type,
                                                          file_owner,
                                                          data_capture_type,
                                                          field_separator,
                                                          text_delimiter,
                                                          skip_records,
                                                          self_describing,
                                                          design_ovid
                                                         )
AS
   SELECT external_agent_id, external_agent_ovid, external_agent_name,
          diagram_id, diagram_ovid, diagram_name, external_agent_type,
          file_location, file_source, file_name, file_type, file_owner,
          data_capture_type, field_separator, text_delimiter, skip_records,
          self_describing, design_ovid
     FROM dmrs_external_agents;


