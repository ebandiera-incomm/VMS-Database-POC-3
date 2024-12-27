/* Formatted on 2012/07/02 15:13 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_change_requests (design_id,
                                                          design_ovid,
                                                          design_name,
                                                          change_request_id,
                                                          change_request_ovid,
                                                          change_request_name,
                                                          request_status,
                                                          request_date_string,
                                                          completion_date_string,
                                                          is_completed,
                                                          reason
                                                         )
AS
   SELECT design_id, design_ovid, design_name, change_request_id,
          change_request_ovid, change_request_name, request_status,
          request_date_string, completion_date_string, is_completed, reason
     FROM dmrs_change_requests;


