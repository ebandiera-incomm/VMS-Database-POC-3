/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_column_groups (table_id,
                                                        table_ovid,
                                                        SEQUENCE,
                                                        columngroup_id,
                                                        columngroup_ovid,
                                                        columngroup_name,
                                                        COLUMNS,
                                                        notes,
                                                        table_name,
                                                        design_ovid
                                                       )
AS
   SELECT table_id, table_ovid, SEQUENCE, columngroup_id, columngroup_ovid,
          columngroup_name, COLUMNS, notes, table_name, design_ovid
     FROM dmrs_column_groups;


