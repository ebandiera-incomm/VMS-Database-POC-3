/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_table_include_scripts (table_id,
                                                                table_ovid,
                                                                table_name,
                                                                TYPE,
                                                                SEQUENCE,
                                                                text,
                                                                design_ovid
                                                               )
AS
   SELECT table_id, table_ovid, table_name, TYPE, SEQUENCE, text, design_ovid
     FROM dmrs_table_include_scripts;


