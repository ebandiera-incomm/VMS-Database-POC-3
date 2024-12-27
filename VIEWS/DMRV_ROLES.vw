/* Formatted on 2012/07/02 15:16 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_roles (role_id,
                                                role_ovid,
                                                ROLE,
                                                model_id,
                                                model_ovid,
                                                model_name,
                                                description,
                                                design_ovid
                                               )
AS
   SELECT role_id, role_ovid, role_name, model_id, model_ovid, model_name,
          description, design_ovid
     FROM dmrs_roles;


