/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_table_constraints (table_id,
                                                            table_ovid,
                                                            SEQUENCE,
                                                            constraint_id,
                                                            constraint_ovid,
                                                            constraint_name,
                                                            text,
                                                            table_name,
                                                            design_ovid
                                                           )
AS
   SELECT table_id, table_ovid, SEQUENCE, constraint_id, constraint_ovid,
          constraint_name, text, table_name, design_ovid
     FROM dmrs_table_constraints;


