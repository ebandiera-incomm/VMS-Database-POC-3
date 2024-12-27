/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_ext_agent_ext_datas (external_agent_id,
                                                              external_agent_ovid,
                                                              external_agent_name,
                                                              external_data_id,
                                                              external_data_ovid,
                                                              external_data_name,
                                                              design_ovid
                                                             )
AS
   SELECT external_agent_id, external_agent_ovid, external_agent_name,
          external_data_id, external_data_ovid, external_data_name,
          design_ovid
     FROM dmrs_ext_agent_ext_datas;


