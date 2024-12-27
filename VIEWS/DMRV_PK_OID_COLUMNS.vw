/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_pk_oid_columns (column_id,
                                                         column_ovid,
                                                         table_id,
                                                         table_ovid,
                                                         table_name,
                                                         column_name,
                                                         design_ovid
                                                        )
AS
   SELECT column_id, column_ovid, table_id, table_ovid, table_name,
          column_name, design_ovid
     FROM dmrs_pk_oid_columns;


