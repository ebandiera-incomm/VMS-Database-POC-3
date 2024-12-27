/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_flow_info_structures (flow_id,
                                                               flow_ovid,
                                                               flow_name,
                                                               info_structure_id,
                                                               info_structure_ovid,
                                                               info_structure_name,
                                                               design_ovid
                                                              )
AS
   SELECT flow_id, flow_ovid, flow_name, info_structure_id,
          info_structure_ovid, info_structure_name, design_ovid
     FROM dmrs_flow_info_structures;


