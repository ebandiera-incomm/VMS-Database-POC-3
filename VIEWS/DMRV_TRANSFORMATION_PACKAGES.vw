/* Formatted on 2012/07/02 15:17 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_transformation_packages (transformation_package_id,
                                                                  transformation_package_ovid,
                                                                  transformation_package_name,
                                                                  model_id,
                                                                  model_ovid,
                                                                  model_name,
                                                                  system_objective,
                                                                  design_ovid
                                                                 )
AS
   SELECT transformation_package_id, transformation_package_ovid,
          transformation_package_name, model_id, model_ovid, model_name,
          system_objective, design_ovid
     FROM dmrs_transformation_packages;


