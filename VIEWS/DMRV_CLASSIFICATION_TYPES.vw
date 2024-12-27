/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_classification_types (type_id,
                                                               type_ovid,
                                                               type_name,
                                                               design_id,
                                                               design_ovid,
                                                               design_name
                                                              )
AS
   SELECT type_id, type_ovid, type_name, design_id, design_ovid, design_name
     FROM dmrs_classification_types;


