/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_role_processes (role_id,
                                                         role_ovid,
                                                         ROLE,
                                                         process_id,
                                                         process_ovid,
                                                         process_name,
                                                         design_ovid
                                                        )
AS
   SELECT role_id, role_ovid, role_name, process_id, process_ovid,
          process_name, design_ovid
     FROM dmrs_role_processes;


