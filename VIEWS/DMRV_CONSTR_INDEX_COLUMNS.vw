/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_constr_index_columns (index_id,
                                                               index_ovid,
                                                               column_id,
                                                               column_ovid,
                                                               table_id,
                                                               table_ovid,
                                                               index_name,
                                                               table_name,
                                                               column_name,
                                                               SEQUENCE,
                                                               sort_order,
                                                               design_ovid
                                                              )
AS
   SELECT index_id, index_ovid, column_id, column_ovid, table_id, table_ovid,
          index_name, table_name, column_name, SEQUENCE, sort_order,
          design_ovid
     FROM dmrs_constr_index_columns;


