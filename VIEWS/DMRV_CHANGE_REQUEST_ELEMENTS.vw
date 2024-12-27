/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_change_request_elements (change_request_id,
                                                                  change_request_ovid,
                                                                  change_request_name,
                                                                  element_id,
                                                                  element_ovid,
                                                                  element_name,
                                                                  element_type,
                                                                  design_ovid
                                                                 )
AS
   SELECT change_request_id, change_request_ovid, change_request_name,
          element_id, element_ovid, element_name, element_type, design_ovid
     FROM dmrs_change_request_elements;


