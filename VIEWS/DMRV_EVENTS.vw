/* Formatted on 2012/07/02 15:14 (Formatter Plus v4.8.8) */
CREATE OR REPLACE FORCE VIEW vmscms.dmrv_events (event_id,
                                                 event_ovid,
                                                 event_name,
                                                 model_id,
                                                 model_ovid,
                                                 model_name,
                                                 flow_id,
                                                 flow_ovid,
                                                 flow_name,
                                                 event_type,
                                                 times_when_run,
                                                 day_of_week,
                                                 months,
                                                 frequency,
                                                 time_frequency,
                                                 MINUTE,
                                                 HOUR,
                                                 day_of_month,
                                                 quarter,
                                                 YEAR,
                                                 on_day,
                                                 at_time,
                                                 fiscal,
                                                 text,
                                                 design_ovid
                                                )
AS
   SELECT event_id, event_ovid, event_name, model_id, model_ovid, model_name,
          flow_id, flow_ovid, flow_name, event_type, times_when_run,
          day_of_week, months, frequency, time_frequency, MINUTE, HOUR,
          day_of_month, quarter, YEAR, on_day, at_time, fiscal, text,
          design_ovid
     FROM dmrs_events;


