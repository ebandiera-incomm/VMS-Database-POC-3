/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_view_containers (view_ovid,
                                                          view_id,
                                                          view_name,
                                                          container_id,
                                                          container_ovid,
                                                          container_name,
                                                          TYPE,
                                                          alias,
                                                          SEQUENCE,
                                                          model_id,
                                                          model_ovid,
                                                          model_name,
                                                          design_ovid
                                                         )
AS
   SELECT view_ovid, view_id, view_name, container_id, container_ovid,
          container_name, TYPE, alias, SEQUENCE, model_id, model_ovid,
          model_name, design_ovid
     FROM dmrs_view_containers;


