CREATE OR REPLACE FUNCTION VMSCMS.fn_add_interval (
   prm_date         DATE,
   prm_process_id   NUMBER
)
   RETURN DATE
AS
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 05/AUG/2009.
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Add Interval In date
     * Modified By:    :
     * Modified Date  :
   ***********************************************/
   v_process_interval    NUMBER (5);
   v_procinterval_type   VARCHAR2 (5);
   v_return_date         DATE;
   v_main_date           VARCHAR2 (25);
BEGIN
   v_main_date := TO_CHAR (prm_date, 'MM/DD/YYYY HH24:MI:SS');

   SELECT pps_process_interval, pps_procinterval_type
     INTO v_process_interval, v_procinterval_type
     FROM pcms_process_schedule
    WHERE pps_process_id = prm_process_id;

   -- IF TO_DATE (v_main_date, 'MM/DD/YYYY HH24:MI:SS') <= SYSDATE
   -- THEN
   IF v_procinterval_type = 'HH'
   THEN
      v_return_date :=
           TO_DATE (v_main_date, 'MM/DD/YYYY HH24:MI:SS')
         + v_process_interval / 24;
      RETURN v_return_date;
   END IF;

   IF v_procinterval_type = 'MM'
   THEN
      v_return_date :=
           TO_DATE (v_main_date, 'MM/DD/YYYY HH24:MI:SS')
         + v_process_interval / 1440;
      RETURN v_return_date;
   END IF;

   IF v_procinterval_type = 'MM'
   THEN
      v_return_date :=
           TO_DATE (v_main_date, 'MM/DD/YYYY HH24:MI:SS')
         + v_process_interval / 86400;
      RETURN v_return_date;
   END IF;
  --ELSE
    -- v_return_date := TO_DATE (v_main_date, 'MM/DD/YYYY HH24:MI:SS');
     --RETURN v_return_date;
--  END IF;
END;
/
show error