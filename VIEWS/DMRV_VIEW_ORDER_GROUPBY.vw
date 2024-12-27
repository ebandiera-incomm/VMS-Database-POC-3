/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_view_order_groupby (view_ovid,
                                                             view_id,
                                                             view_name,
                                                             container_id,
                                                             container_ovid,
                                                             container_name,
                                                             container_alias,
                                                             is_expression,
                                                             USAGE,
                                                             SEQUENCE,
                                                             column_id,
                                                             column_ovid,
                                                             column_name,
                                                             column_alias,
                                                             sort_order,
                                                             expression,
                                                             design_ovid
                                                            )
AS
   SELECT view_ovid, view_id, view_name, container_id, container_ovid,
          container_name, container_alias, is_expression, USAGE, SEQUENCE,
          column_id, column_ovid, column_name, column_alias, sort_order,
          expression, design_ovid
     FROM dmrs_view_order_groupby;


