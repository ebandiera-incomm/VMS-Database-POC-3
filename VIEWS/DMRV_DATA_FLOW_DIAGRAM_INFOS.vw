/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_data_flow_diagram_infos (diagram_id,
                                                                  diagram_ovid,
                                                                  diagram_name,
                                                                  info_store_id,
                                                                  info_store_ovid,
                                                                  info_store_name,
                                                                  design_ovid
                                                                 )
AS
   SELECT diagram_id, diagram_ovid, diagram_name, info_store_id,
          info_store_ovid, info_store_name, design_ovid
     FROM dmrs_data_flow_diagram_infos;


